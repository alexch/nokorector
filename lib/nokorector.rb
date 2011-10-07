require 'nokogiri'

module Nokorector
  def erect &block
    builder = Nokogiri::HTML::Builder.new &block
    builder.doc.root
  end
end

module Widget
  def _doc
    @doc ||= Nokogiri::HTML::Document.new
  end

  def _reset!
    @doc = nil
  end

  def self.included into
    class << into
      def tag tag_name
        d { self }
        d { tag_name }
        define_method(tag_name) do |*args, &block|
          puts "#{tag_name}(#{args.join(', ')})"
          wrapper = NodeWrapper.new(_doc, tag_name, *args, &block)
          wrapper
        end
      end
    end
  end
end

class NodeWrapper
  def initialize(doc, tag_name, *args, &block)
    @doc = doc
    @node = @doc.create_element tag_name.to_s
    _set *args, &block
  end

  def _node
    @node
  end

  def _set *args, &block
    attributes = args.last.is_a?(Hash) ? args.pop : {}
    _set_attributes attributes unless attributes.nil?
    
    args.compact.each do |content|
      d { content }
      @node << content
    end

    unless block.nil?
      child = block.call 
      d { child }
      child = child._node if child.is_a? NodeWrapper
      @node << child if child
    end
    @node
  end

  def to_html
    @node.to_html
  end

  # todo: test
  # stolen from noko builder.rb
  def method_missing(method_name, *args, &block)
    puts "called #{method_name}(#{args.join(',')})"
    case method_name.to_s
    when /^(.*)!$/
      @node['id'] = $1
    when /^(.*)=/
      _set_attributes({$1 => args.join(' ')})
      args = []
    else
      _add_attribute 'class', method_name.to_s
    end

    _set *args, &block
    self
  end

  def _set_attributes attributes = {}
    attributes.each do |k,v|
      @node[k.to_s] = ((@node[k.to_s] || '').split(/\s/) + [v]).join(' ')
    end
    self
  end

  def _add_attribute name, value
    d { @node }
    @node[name] =
      ((@node[name] || '').split(/\s/) + [value]).join(' ')
  end
end
