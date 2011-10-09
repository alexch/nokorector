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
      describe "seed.att=" do
        it "is not supported, since Ruby always returns the value" do
          seed = Seed.new(@builder)._tag("a")
          rescuing {
            returned = seed.foo=("bar")
            assert { returned == seed }
          }.message.should include("attribute assignment not supported")
        end
      end
    end
  end
end
