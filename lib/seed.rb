# A Seed is a nascent Node or NodeSet.
# You can ask it to grow by sending it arguments (for attributes or a string) or a block (for child nodes and text).
#
module Nokorector
  class Seed
    def initialize(builder, options = {})
      @builder = builder
      @prior = options[:prior]
      @next = options[:next]
      @active_node = options[:node]
      @builder._seed = self
      @prior._next = self if @prior  # todo: test
    end

    # for debugging
    def to_s
      a = ["#<#{self.class.name.split('::').last}:0x#{(object_id<<1).to_s(16)}"]

      unless @in_to_s
        @in_to_s = true

        if @active_node
          # a << @active_node.class.name
          case @active_node
          when Nokogiri::XML::CharacterData
            a << @active_node.content.inspect
          else
            a << @active_node.name
            a << @active_node.attributes.inspect
          end
        end

        [:child, :prior, :next].each do |name|
          var = "@#{name}".to_sym
          if (val = instance_variable_get var)
            val = val.to_s.gsub(/^\t/, "\t\t")
            a << "\n\t#{name}=#{val}"
          end
        end
      end

      a << ">"
      a.join(" ")
    ensure
      @in_to_s = false
    end

    def _doc
      @builder._doc
    end

    # todo: test that this lifts its child nodes
    def _node
      # todo: make sure this is idempotent
      if @child
        @active_node.children.unlink # hmm... can we think of a case where we need this?
        if @child._seeds.include? self
          # d { self.object_id }
          # d { @child._seeds.map(&:object_id) }
          raise "wtf"
        end
        child_nodeset = @child._nodeset
        # d { self }
        # d { child_nodeset }
        @active_node << child_nodeset
      end
      @active_node
    end

    def _prior
      @prior
    end

    def _prior= seed
      raise "uhoh" if seed == self
      @prior = seed
    end

    def _next
      @next
    end

    def _next= seed
      raise "uhoh" if seed == self
      @next = seed
    end

    # todo: test?
    def _tail
      if @next
        @next._tail
      else
        self
      end
    end

    # todo: remove active_node altogether
    alias :_active_node :_node

    # todo: optimize
    # todo: move into SeedBed or whatever
    def _seeds
      raise "uhoh" if @prior == self
      seeds = if @prior
        # puts "jumping to #{@prior}"
        @prior._seeds
      else
        []
      end
      seeds << self unless @active_node.nil?
      # d { seeds }
      seeds
    end

    def _nodes
      _seeds.map do |seed|
        seed._node
      end.compact  # todo: why does a nil sneak in here?
    end

    def _nodeset
      # d { _nodes }
      Nokogiri::XML::NodeSet.new(_doc, _nodes)
    end

    def _sprout(node=nil)
      @next = Seed.new(@builder, prior: self, node: node)
      @next
    end

    def _detach
      @prior._next = @next if @prior
      @next._prior = @prior if @next
      @builder._seed = @prior if @builder._seed == self
      @prior = @next = nil
      self
    end

    def _tag tag_name
      @active_node = _doc.create_element tag_name.to_s
      self
    end

    def _text s
      node = Nokogiri::XML::Text.new s, _doc
      if @active_node
        _sprout node
      else
        @active_node = node
        self
      end
    end

    def _child
      @child ||= Seed.new(@builder)
    end

    # attach some stuff after this seed
    # return the new seed (which points to this one)
    def << value
      raise "can't attach #{value} to a middling seed" if @next
      raise "can't add a seed to itself" if value == self or (value.is_a? Seed and value._seeds.include? self)
      seed = case value
      when Seed
        value._detach
        @next = value
        value._prior = self
        value
      when Nokogiri::XML::Node
        _sprout(value)
      else
        _text value.to_s
      end

      seed
    end

    def _add_child content
        # keep stepping the child pointer ahead... maybe we should encapsulate
        # this into a SeedBed collection (or Pot or Planter)... also we can
        # probably unify Child and Builder as Pots
      @child = (self._child << content)
      raise "uhoh" if @child == self
    end

    def _remove_child
      @child = nil
    end

    def _grow *args, &block
      if args.last.is_a?(Hash)
        _set_attributes args.pop
      end

      begin
        @builder._seed = _child

        # why would an arg be nil?  todo: try without compact
        args.compact.each do |content|
          _add_child content
        end

        if block

          value = block.call

          # move this node's child pointer forward, to comprise all seeds added during the block
          @child = @child._tail

          if value.nil?
            # ignore
          elsif value.is_a? Seed
            # ignore? or add it? it's already there, right?
          else
            seed = _child._sprout
            puts "setting #{value} in #{seed}"
            seed._text value
            @child = seed
          end


        end

      ensure
        @builder._seed = self
      end

      self  # ??
    end

    # todo: should we rename this?
    def to_html(*args)
      # puts "before to_html: #{@nodes.inspect}"
      _nodeset.to_html(*args)
    end

    def _set_attributes hash = {}
      hash.each do |k,v|
        @active_node[k.to_s] = ((@active_node[k.to_s] || '').split(/\s/) + [v]).join(' ')
      end
      self
    end

    def _add_to_attribute name, value
      @active_node[name] =
        ((@active_node[name] || '').split(/\s/) + [value]).join(' ')
    end

    # handle all the fun stuff like dot-bang-id
    def method_missing(method_name, *args, &block)
      exit 2 if caller[0] =~ /method_missing/
      raise "sorry, can't do fun stuff to a text node" if @active_node.is_a? Nokogiri::XML::CharacterData
  #    puts "#{@active_node.name}.#{method_name}(#{args.map(&:inspect).join(',')})"
      case method_name.to_s
      when /^_(.*)$/
        super
      when /^(.*)=$/
        super
      when /^(.*)!$/
        @active_node['id'] = $1
      else
        puts "setting class='#{method_name}' from #{caller.first}"
        _add_to_attribute 'class', method_name.to_s
      end

      puts ""
      _grow *args, &block
      self
    end


  end
end
