here = File.dirname __FILE__
require "#{here}/spec_helper"

module Nokorector
  describe Seed do
    before do
      @builder = Object.new
      class << @builder
        include Builder
      end
    end

    describe "method_missing magic" do
      describe "unknown underscore methods" do
        it "are reserved" do
          seed = Seed.new(@builder)._tag("a")
          rescuing { seed._oops }.should be_a(NoMethodError)
        end
      end

      describe "seed.name" do
        it "sets the class attribute on the underlying node" do
          seed = Seed.new(@builder)._tag("a")
          seed.name
          assert { seed._active_node["class"] == "name" }
          assert { seed.to_html == '<a class="name"></a>' }
        end

        it "returns the seed" do
          seed = Seed.new(@builder)._tag("a")
          assert { seed.name == seed }
        end

        it "appends to the class attribute if it's already got one" do
          seed = Seed.new(@builder)._tag("a")
          seed.foo.bar.baz
          assert { seed._active_node["class"] == "foo bar baz" }
          assert { seed.to_html == '<a class="foo bar baz"></a>' }
        end
      end

      describe "seed.name!" do
        it "sets the id attribute on the underlying node" do
          seed = Seed.new(@builder)._tag("a")
          seed.foo!
          assert { seed._active_node["id"] == "foo" }
          assert { seed.to_html == '<a id="foo"></a>' }
        end

        it "returns the seed" do
          seed = Seed.new(@builder)._tag("a")
          assert { seed.name == seed }
        end

        it "replaces the id attribute if it's already got one" do
          seed = Seed.new(@builder)._tag("a")
          seed.foo!.bar!
          assert { seed._active_node["id"] == "bar" }
          assert { seed.to_html == '<a id="bar"></a>' }
        end
      end

      describe "seed.att=" do
        it "is not supported, since Ruby always returns the value" do
          seed = Seed.new(@builder)._tag("a")
          rescuing {
            returned = seed.foo=("bar")
            assert { returned == seed }
          }.message.should include("undefined method `foo='")
        end
      end

      describe "seed[att]=" do
        it "is not supported, since Ruby always returns the value" do
          seed = Seed.new(@builder)._tag("a")
          rescuing {
            returned = seed["foo"]="bar"
            assert { returned == seed }
          }.message.should include("undefined method `[]='")
        end
      end

    end
  end
end
