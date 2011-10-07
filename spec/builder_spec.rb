here = File.dirname __FILE__
proj = "#{here}/.."
lib = "#{proj}/lib"
require "#{lib}/nokorector"
require "wrong/adapters/rspec"

puts "Ruby #{RUBY_VERSION}"

describe "erect" do
  include Nokorector
  it "works" do
    x = erect {
      foo
    }
    assert { x.to_html == "<foo></foo>" }
  end
  it "adds a class" do
    x = erect {
      foo.bar
    }
    assert { x.to_html.include? "<foo class=\"bar\"></foo>" }
  end

  it "returns a Nokogiri HTML Doc" do
    x = erect {
      foo
    }
    assert { x.is_a? Nokogiri::XML::Node }
  end

end

describe Widget do
  include Widget

  before do
    _reset!
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
    d { x }
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

  it "sets inner block text content" do
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

  it "mixes and matches" do
    x = 
      alpha.foo do
        beta(hee: 'haw').bar!(baz: "baf") do
          gamma do
            "see"
          end
        end
      end
    x.to_html.should == 
      "<alpha class=\"foo\">" + 
      "<beta hee=\"haw\" id=\"bar\" baz=\"baf\">" +
      "<gamma>see</gamma>" + 
      "</beta></alpha>"
  end


end
