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

    describe "as a linked list" do
      it "contains its node" do
        seed = Seed.new(@builder)._tag("a")
        assert { seed._nodes == [seed._node] }
      end

      it "points to its prior seed" do
        a = Seed.new(@builder)._tag("a")
        b = Seed.new(@builder, prior: a)._tag("b")
        assert { b._seeds == [a, b] }
      end

      it "has a fun method to plunk out a new seed" do
        a = Seed.new(@builder)._tag("a")
        b = a._sprout._tag("b")
        assert { b._seeds == [a, b] }
      end

      it "updates the builder's current seed" do
        a = Seed.new(@builder)._tag("a")
        assert { @builder._seed == a }
        b = a._sprout._tag("b")
        assert { @builder._seed == b }
      end

      # it "has two-way pointers as appropriate" do
      #   assert { @a._prior }
      # end

      describe "removes a seed from the list" do
        before do
          @a = Seed.new(@builder)._tag("a")
          @b = @a._sprout._tag("b")
          @c = @b._sprout._tag("c")
        end

        it "from the middle" do
          @b._detach
          assert {@c._seeds == [@a, @c]}
          assert {@b._prior.nil?}
          assert {@b._next.nil?}
        end

        it "from the beginning" do
          @a._detach
          assert {@c._seeds == [@b, @c]}
          assert {@a._prior.nil?}
          assert {@a._next.nil?}
        end

        it "from the end" do
          @c._detach
          assert {@c._prior.nil?}
          assert {@c._next.nil?}
        end

        it "switches the builder's seed if necessary" do
          assert { @builder._seed == @c }
          @c._detach
          assert { @builder._seed == @b }
        end
      end

      describe '<<' do
        it "inserts a seed at the end of the list" do
          a = Seed.new(@builder)._tag("a")
          b = Seed.new(@builder)._tag("b")
          returned = (a << b)
          assert { a._next == b }
          assert { b._prior == a }
          assert { returned == b }
        end

        it "detaches its argument"
        it "complains if it's in the middle"
      end
    end

    describe "_seeds" do
      it "returns a single seed" do
        a = Seed.new(@builder)._tag("a")
        a._seeds.should == [a]
      end

      it "returns two seeds" do
        a = Seed.new(@builder)._tag("a")
        b = a._sprout._tag("b")
        a._seeds.should == [a]
        b._seeds.should == [a, b]
      end

      it "works after a grow block" do
        b = c = nil
        a = Seed.new(@builder)._tag("a")
        returned_seed = a._grow do
          assert { @builder._seed == a._child }
          b = @builder._seed._tag("b")
          assert { @builder._seed == b }
          c = b._sprout
          c._tag("c")
          assert { @builder._seed == c }
        end
        returned_seed.should == a
        a._seeds.should == [a]
        d { a._child }
        a._child._seeds.should == [b, c]
      end

      it "works after another really complicated grow" do
        b = c = nil
        a = Seed.new(@builder)._tag("a")
        a.foo do
          b = a._child._tag("beta")
          b._grow do
            c = b._child._tag("gamma")._grow do
              "see"
            end
            c._sprout._tag("gamma")._grow "saw"
            "plus some text"
          end
        end
        a.to_html.should == "<a class=\"foo\"><beta><gamma>see</gamma><gamma>saw</gamma>plus some text</beta></a>"
      end

    end

    describe "_node" do
      it "adds the child's nodes as children of this seed's node" do
        a = Seed.new(@builder)._tag("a")
        b = Seed.new(@builder)._tag("b")
        a._add_child b
        assert {a._node.to_html == "<a><b></b></a>"}
        assert {a._node.children.first == b._node}
      end

      it "is idempotent" do
        a = Seed.new(@builder)._tag("a")
        b = Seed.new(@builder)._tag("b")
        a._add_child b
        assert {a._node.to_html == "<a><b></b></a>"}
        assert { a._node.to_html == a._node.to_html }
      end

    end

    describe "_grow" do
      before do
        @seed = Seed.new(@builder)._tag("a")
      end

      it "sets attributes when passed a hash" do
        @seed._grow(foo: "bar")
        assert { @seed._node["foo"] == "bar" }
      end

      it "sets contents when passed a string" do
        @seed._grow("foo")
        assert { @seed._node.to_html == "<a>foo</a>"}
        assert { @seed._child.to_html == "foo"}
      end

      it "sets contents when passed a few strings" do
        @seed._grow("foo", "bar")
        assert { @seed.to_html == "<a>foobar</a>"}
        assert { @seed._node.to_html == "<a>foobar</a>"}
        assert { @seed._child.to_html == "foobar"}
        # assert { @seed._child._seeds.length == 2}
      end

      it "sets contents when passed a seed" do
        b = Seed.new(@builder)._tag("b")
        @seed._grow(b)
        assert { @seed.to_html == "<a><b></b></a>"}
      end

      it "sets contents when passed a few strings and seeds and whatnot"
      it "sets child contents when passed a block"
      it "sets child contents when a block returns a string" do

      end

      it "can do all of the above and chew gum at the same time"
    end

    describe "_tag" do
      it "adds an element node" do       # so maybe it should be named _element, hm?
        seed = Seed.new(@builder)
        assert { seed._node.nil? }
        seed._tag("a")
        assert { seed._node.is_a? Nokogiri::XML::Element }
        assert { seed._node.name == "a" }
      end
    end

    describe "_text" do
      it "adds a text node" do
        seed = Seed.new(@builder)
        assert { seed._node.nil? }
        seed._text("abc")
        assert { seed._node.is_a? Nokogiri::XML::Text }
        assert { seed._node.to_s == "abc" }
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
