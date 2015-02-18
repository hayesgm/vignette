require 'spec_helper'

describe Haml::Filters::Vignette do

  context "when parsing a haml template" do
    let!(:session) { Hash.new }
    before(:each) { expect(Kernel).to receive(:rand).and_return(2) }

    context "with a rendered template and no file name" do
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
      let(:template) { "
%p
  :vignette
    [numbers]
    one
    two
    three
" }

      it "should correctly call vignette from render" do
        Vignette.with_settings(nil, session, nil) do
          html = Haml::Engine.new(template).render

          expect(html).to match(/\<p\>\s+three\s+\<\/p\>\n/)
          expect(Vignette.tests).to eq({:"numbers" => "three"})
        end
      end
    end

    context "with a template file" do
      let(:template_file) { File.join(File.dirname(__FILE__), '../../fixtures/ex.html.haml') }

      it "should correctly call vignette from render" do
        Vignette.with_settings(nil, session, nil) do
          template = File.read(template_file)

          html = Haml::Engine.new(template, filename: template_file).render

          expect(html).to match(/\<div\>\s+I like\s+scorpians\s+\<\/div\>/)
          expect(Vignette.tests).to eq({:"(ex.html.haml:3)" => "scorpians"})
        end
      end
    end
  end
end