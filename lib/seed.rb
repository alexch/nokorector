# A Seed is a nascent Node or NodeSet. 
# You can ask it to grow by sending it arguments (for attributes or a string) or a block (for child nodes and text).
#
module Nokorector
  class Seed
    def initialize(widget, parent = nil)
      @widget = widget
      @parent = parent
      @nodes = Nokogiri::XML::NodeSet.new(_doc)
    end

    def _doc
      @widget._doc
    end

    def _nodes
      @nodes
    end

    def _active_node
      @active_node
    end

    def _tag tag_name
      @active_node = _doc.create_element tag_name.to_s
      @nodes << @active_node
      self
    end

    def << value
      case value
      when Seed
        # only push the current node, not all the nodes, otherwise
        # we'll drag along all the prior stuff
        value._nodes.delete value._active_node
        self << value._active_node
      when Nokogiri::XML::Node
        @nodes << value
      else
        @nodes << (Nokogiri::XML::Text.new value.to_s, _doc)
      end     
      self
    end

    def _grow *args, &block
      _set_attributes args.last.is_a?(Hash) ? args.pop : {}

      # why would an arg be nil?  todo: try without compact
      args.compact.each do |content|
        @active_node << content
      end

      if block
        begin
          child_seed = Seed.new(@widget, self)
          @widget._seed = child_seed

          value = block.call
          if value.nil?
            # ignore
          elsif value.is_a? Seed
            # ignore? or add it? it's already there, right?
          else
            child_seed._nodes << (Nokogiri::XML::Text.new value, _doc)
          end

          @active_node << child_seed._nodes

          # nodes.compact.each do |n| 
          #   n.unlink if n.is_a? Nokogiri::XML::Node
          #   @active_node << n
          # end

        ensure
          @widget._seed = self
        end
      end

      self  # ??
    end

    # todo: should we rename this?
    def to_html(*args)
      # puts "before to_html: #{@nodes.inspect}"
      @nodes.to_html(*args)
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
  #    puts "#{@active_node.name}.#{method_name}(#{args.map(&:inspect).join(',')})"
      case method_name.to_s
      when /^(.*)!$/
        @active_node['id'] = $1
      when /^(.*)=$/
        raise "attribute assignment not supported"
      else
        _add_to_attribute 'class', method_name.to_s
      end

      _grow *args, &block
      self
    end


  end
end
