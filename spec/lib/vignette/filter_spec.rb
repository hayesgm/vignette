require 'spec_helper'

describe Haml::Filters::Vignette do

  context "when parsing a haml template" do
    let!(:session) { Hash.new }

    context "with a rendered template and no file name" do
      before(:each) { expect(Kernel).to receive(:rand).and_return(2) }

      let(:template) { "
%p
  :vignette
    one
    two
    three
" }
    
      it "should raise error" do
        Vignette.with_settings(nil, session, nil) do
          html = Haml::Engine.new(template).render

          expect(html).to match(/\<p\>\s+three\s+\<\/p\>\n/)
          expect(Vignette.tests).to eq({:"(haml:3)" => "three"})
        end
      end
    end

    context "with a rendered template" do
      before(:each) { expect(Kernel).to receive(:rand).and_return(2) }

      let(:template) { "
%p
  :vignette_numbers
    one
    two
    three
" }

      it "should correctly call vignette from render" do
        Vignette.with_settings(nil, session, nil) do
          html = Haml::Engine.new(template).render

          expect(html).to eq("<p>\n  three\n</p>\n")
          expect(Vignette.tests).to eq({:"numbers" => "three"})
        end
      end
    end

    context "with a template file" do
      let(:template_file) { File.join(File.dirname(__FILE__), '../../fixtures/ex.html.haml') }

      before(:each) { expect(Kernel).to receive(:rand).and_return(2, 1) }

      it "should correctly call vignette from render" do
        Vignette.with_settings(nil, session, nil) do
          template = File.read(template_file)

          html = Haml::Engine.new(template, filename: template_file).render

          expect(html).to eq("<div>\n  I like\n  scorpians\n</div>\n")
          expect(Vignette.tests).to eq({:"(ex.html.haml:3)" => "scorpians"})

          # With a line number change
          template2 = "%p Hi mom\n" + template

          html2 = Haml::Engine.new(template2, filename: template_file).render

          expect(html2).to eq("<p>Hi mom</p>\n<div>\n  I like\n  scorpians\n</div>\n")
          expect(Vignette.tests).to eq({:"(ex.html.haml:3)" => "scorpians"})

          # With a vignette change
          template3 = template2.gsub('cats', 'rats')

          html3 = Haml::Engine.new(template3, filename: template_file).render

          expect(html3).to eq("<p>Hi mom</p>\n<div>\n  I like\n  rats\n</div>\n")
          expect(Vignette.tests).to eq({
            :"(ex.html.haml:3)" => "scorpians",
            :"(ex.html.haml:4)" => "rats"
          })
        end
      end
    end
  end
end