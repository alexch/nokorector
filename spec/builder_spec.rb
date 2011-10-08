here = File.dirname __FILE__
proj = "#{here}/.."
lib = "#{proj}/lib"
require "#{lib}/nokorector"
require "wrong/adapters/rspec"

puts "Ruby #{RUBY_VERSION}"

describe Nokorector::Builder do
  include Nokorector::Builder

  before do
    @_doc = nil  # todo: cleaner way to clear
  end

  it "doesn't know tags it doesn't know" do
    lambda { foo }.should raise_error(NameError)
  end

  tag :alpha

  it "knows tags it knows" do
    x = alpha
    x.to_html.should == "<alpha></alpha>"
  end

  it "can set attributes" do
    x = (alpha :foo => "bar")
    x.to_html.should == "<alpha foo=\"bar\"></alpha>"
  end

  it "can set a single attribute with =" do
    x = alpha
    x.foo = "bar"
    x.to_html.should == "<alpha foo=\"bar\"></alpha>"
  end    

  it "knows tags it knows with dot-class and dot-id-bang" do
    x = alpha.foo.bar!
    x.to_html.should == "<alpha class=\"foo\" id=\"bar\"></alpha>"
  end

  it "can set attributes along with classes and ids" do
    x = (alpha.foo.bar! baz: "baf")
    x.to_html.should == "<alpha class=\"foo\" id=\"bar\" baz=\"baf\"></alpha>"
  end

  it "sets inner text content" do
    alpha("foo").to_html.should == "<alpha>foo</alpha>"
  end

  it "includes text merely returned by the block" do
    x = 
      alpha do
        "beta"
      end
    x.to_html.should == "<alpha>beta</alpha>"
  end

  tag :beta
  tag :gamma

  it "sets inner block content" do
    x = 
    alpha do
      beta do
        gamma do
        end
      end
    end
    x.to_html.should == "<alpha><beta><gamma></gamma></beta></alpha>"
  end

  it "renders several tags in a row" do
    x = 
      alpha do
        beta
        gamma
      end
    x.to_html.should == 
      "<alpha>" + 
        "<beta></beta>" +
        "<gamma></gamma>" + 
      "</alpha>"
  end

  it "mixes and matches" do
    x = 
      alpha.foo do
        beta(hee: 'haw').bar!(baz: "baf") do
          gamma do
            "see"
          end
          gamma "saw"
          "plus some text"
        end
      end
    x.to_html.should == 
      "<alpha class=\"foo\">" + 
      "<beta hee=\"haw\" id=\"bar\" baz=\"baf\">" +
      "<gamma>see</gamma>" + 
      "<gamma>saw</gamma>" + 
      "plus some text" +
      "</beta></alpha>"
  end

  it "example 1" do
    pending  "weird bug with tag.att="
    alpha.foo("bar") do
      beta.src = "baf"
    end
    to_html.should == '<alpha class="foo">bar<beta src="baf"></beta></alpha>'
  end

  tag :a
  tag :b
  tag :img

  it "can pass a tag to a tag" do
    pending
    a(img(:src => "foo.jpg"), :href => "foo.html").to_html.should ==
    "<a href=\"foo.html\"><img src=\"foo.jpg\"></img></a>"
  end

  describe "to_html" do
    it "renders the seed" do
      alpha
      self.to_html.should == "<alpha></alpha>"
      self._seed.to_html.should == "<alpha></alpha>"
    end

# see http://nokogiri.org/Nokogiri/XML/Node/SaveOptions.html
# and http://nokogiri.org/Nokogiri/XML/Node.html#method-i-to_html
# and http://nokogiri.org/Nokogiri/XML/Node.html#method-i-write_to
    it "renders with options" do
      pending
      alpha {
        beta "foo"
        gamma {
          alpha
        }
      }
      self.to_html(:indent => 2).should == <<-HTML
<alpha>
  <beta>foo</beta>
  <gamma>
    <alpha>
    </alpha>
  </gamma>
</alpha>
      HTML
    end

  end

  describe "to_doc" do
    it "produces a Nokogiri Document" do
      alpha
      assert { self.to_doc.is_a? Nokogiri::HTML::Document }
    end

# see http://nokogiri.org/Nokogiri/XML/Node/SaveOptions.html
# and http://nokogiri.org/Nokogiri/XML/Node.html#method-i-to_html
# and http://nokogiri.org/Nokogiri/XML/Node.html#method-i-write_to
    it "keeps the DOCTYPE" do
      pending
      alpha {
        beta "foo"
        gamma {
          alpha
        }
      }
      self.to_doc.to_html(:indent => 2, :save_with => 
        Nokogiri::XML::Node::SaveOptions.new.to_i
      ).should =~ Regexp.new(Regexp.escape(<<-HTML))
<!DOCTYPE xhtml PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">
      HTML
    end

  end

  describe "put" do
    it "emits text" do
      put "foo"
      to_html.should == "foo"
    end

    it "emits a series of strings" do
      put "a", "b", "c"
      to_html.should == "abc"
    end

    it "emits a tag" do
      put alpha
      to_html.should == "<alpha></alpha>"
    end

    it "emits a tag snuck in as an argument" do
      put "a", alpha("b"), "c"
      to_html.should == "a<alpha>b</alpha>c"
    end

    it "emits a tag with children as an argument" do
      put "a", (alpha {beta; gamma;}), "c"
      to_html.should == "a<alpha><beta></beta><gamma></gamma></alpha>c"
    end

    it "emits a tag stored in a variable as an argument" do
      x = alpha {beta}
      put "a", x , "c"
      to_html.should == "a<alpha><beta></beta></alpha>c"
    end

    it "emits tags in weird orders" do
      pending "still impossible :-(" do
        x = alpha
        y = gamma
        put "a", y, beta, x, "c"
        to_html.should == "a" + 
          "<gamma></gamma>" +
          "<beta></beta>" +
          "<alpha></alpha>" + 
          "c"
      end
    end

    it "example 2" do
      put "a", b("c"), "d"
      to_html.should == 'a<b>c</b>d'
    end

    it "mixes" do
      pending
      put "a", img.src="foo.gif", b("c")
      to_html.should == 'a<img src="foo.gif"></img><b>c</b>'
    end

  end

end
