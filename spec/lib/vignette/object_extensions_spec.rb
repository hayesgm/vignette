require 'spec_helper'

describe ObjectExtensions do

  context "with a test controller" do
    class TestController
      @@filters = []

      def self.filters
        @@filters
      end

      def self.prepend_around_filter(filter)
        @@filters << filter
      end

      include ObjectExtensions::ActionControllerExtensions

      def set_params(p)
        @params = p
      end

      def params
        @params || {}
      end

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

    context "with force choice" do
      around(:each) do |example|
        Vignette.force_choice_param = :v
        example.run
        Vignette.force_choice_param = nil
      end

      it "should correctly run forced choice" do
        expect(Kernel).to receive(:rand).never
        expect(Vignette.active?).to be(false)

        tc = TestController.new
        tc.set_params({v: 'dog'})

        tc.run do
          expect(Vignette.repo).to eq(tc.session)
          expect(Vignette.active?).to be(true)
          expect(%w{cat dog parrot turtle horse}.vignette).to eq('dog')
          expect(Vignette.tests).to eq({})
        end
      end
    end
  end
end