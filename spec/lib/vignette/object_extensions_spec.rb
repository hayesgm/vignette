require 'spec_helper'

describe ObjectExtensions do

  context "with a test controller" do
    class TestController
      @@filters = []

      def self.filters
        @@filters
      end

      def self.around_filter(filter)
        @@filters << filter
      end

      include ObjectExtensions::ActionControllerExtensions

      def session
        { session_id: "whatever" }
      end

      def run(&block)
        filter = @@filters.first # just make this easy

        self.send(filter, &block)
      end
    end

    it "should register an around_filter" do
      expect(TestController.filters.count).to eq(1)
    end

    it "should correctly run around_filter" do
      expect(Kernel).to receive(:rand).and_return(2)
      expect(Vignette.active?).to be(false)

      tc = TestController.new

      tc.run do
        expect(Vignette.repo).to eq(tc.session)
        expect(Vignette.active?).to be(true)
        expect([1,2,3].vignette(:number)).to eq(3)
        expect(Vignette.tests).to eq(number: 3)
      end
    end
  end
end