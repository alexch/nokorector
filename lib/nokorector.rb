require 'nokogiri'

module Nokorector
  def erect &block
    # todo:
    # include Widget, execute block, *un*include Widget
    builder = Nokogiri::HTML::Builder.new &block
    builder.doc.root
  end
end

module Widget
  def _doc
    @_doc ||= Nokogiri::HTML::Document.new
  end

  # the current chunk of nodes to which we're adding tags and text
  def _seed
    @_seed ||= _create_seed
  end

  def _seed=(new_seed)
    @_seed = new_seed
  end

  def _create_seed
    Seed.new(self)
  end

  def self.included into
    class << into
      def tag tag_name
        define_method(tag_name) do |*args, &block|
          # puts "#{tag_name}(#{args.map(&:inspect).join(',')})"
          _seed._tag tag_name
          _seed._grow *args, &block
        end
      end
    end
  end
end

# A Seed is a nascent Node or NodeSet. 
# You can ask it to grow by sending it arguments (for attributes or a string) or a block (for child nodes and text).
#
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

  #todo: rename @node to @latest_node
  def _tag tag_name
    @node = _doc.create_element tag_name.to_s
    @nodes << @node
    @node
  end

  def _grow *args, &block
    _set_attributes args.last.is_a?(Hash) ? args.pop : {}

    # why would an arg be nil?  todo: try without compact
    args.compact.each do |content|
      @node << content
    end

    if block
      begin
        child_seed = Seed.new(@widget, self)
        @widget._seed = child_seed

        value = block.call
        if value.nil?
          # ignore
        elsif value.is_a? Seed
          # ignore?
        else
          child_seed._nodes << (Nokogiri::XML::Text.new value, _doc)
        end

        @node << child_seed._nodes

        # nodes.compact.each do |n| 
        #   n.unlink if n.is_a? Nokogiri::XML::Node
        #   @node << n
        # end

      ensure
        @widget._seed = self
      end
    end

    self  # ??
  end

  # todo: should we rename this?
  def to_html
    @nodes.to_html
  end

  def _set_attributes hash = {}
    hash.each do |k,v|
      @node[k.to_s] = ((@node[k.to_s] || '').split(/\s/) + [v]).join(' ')
    end
    self
  end

  def _add_to_attribute name, value
    @node[name] =
      ((@node[name] || '').split(/\s/) + [value]).join(' ')
  end

  # handle all the fun stuff like dot-bang-id
  def method_missing(method_name, *args, &block)
    exit 2 if caller[0] =~ /method_missing/
#    puts "#{@node.name}.#{method_name}(#{args.map(&:inspect).join(',')})"
    case method_name.to_s
    when /^(.*)!$/
      @node['id'] = $1
    when /^(.*)=/
      _set_attributes ({$1 => args.join(' ')})
      args = []
    else
      _add_to_attribute 'class', method_name.to_s
    end

    _grow *args, &block
    self
  end

end
