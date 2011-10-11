module Nokorector::Builder
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
    Nokorector::Seed.new(self)
  end

  def put *args
    args.each do |value|
      _seed << value
    end
  end

  def to_doc
    dtd = _doc.children.first
    # _doc.add_child _seed._nodes
    _doc.children = _seed._nodeset
    _doc.children.first.add_previous_sibling dtd
    _doc
  end

  def to_html(*args)
    _seed.to_html(*args)
  end

  def self.included into
    class << into
      def tag tag_name
        define_method(tag_name) do |*args, &block|
          puts "#{tag_name}(#{args.map(&:inspect).join(',')})"

          sprout = _seed._sprout
          sprout._tag tag_name
          @_seed = sprout
          @_seed = _seed._grow *args, &block
        end
      end
    end
  end
end
