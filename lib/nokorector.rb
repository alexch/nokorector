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
        define_method(tag_name) do |*args, &block|
          puts "#{tag_name}(#{args.map(&:inspect).join(',')})"
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
    set *args, &block
  end

  def node
    @node
  end

  def set *args, &block
    attributes = args.last.is_a?(Hash) ? args.pop : {}
    set_attributes attributes unless attributes.nil?
    
    args.compact.each do |content|
      @node << content
    end

    unless block.nil?
      child = block.call 
      child = child.node if child.is_a? NodeWrapper
      @node << child if child
    end
    @node
  end

  def to_html
    @node.to_html
  end

  def method_missing(method_name, *args, &block)
    puts "#{node.name}.#{method_name}(#{args.map(&:inspect).join(',')})"
    case method_name.to_s
    when /^(.*)!$/
      @node['id'] = $1
    when /^(.*)=/
      set_attributes({$1 => args.join(' ')})
      args = []
    else
      add_attribute 'class', method_name.to_s
    end

    set *args, &block
    self
  end

  def set_attributes attributes = {}
    attributes.each do |k,v|
      @node[k.to_s] = ((@node[k.to_s] || '').split(/\s/) + [v]).join(' ')
    end
    self
  end

  def add_attribute name, value
    @node[name] =
      ((@node[name] || '').split(/\s/) + [value]).join(' ')
  end
end
