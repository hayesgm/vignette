require 'spec_helper'

describe Vignette do

  context 'with simple session store' do
    let!(:session) { Hash.new }
    let(:array) { %w{a b c} }
    before { Vignette.session = session }

    it 'should have correct crc' do
      expect(array.crc).to eq(891568578)
      expect(array.crc.abs.to_s(16)).to eq('352441c2')
    end

    context 'when calling vignette' do
      context "for a single run" do
        before(:each) { expect(Kernel).to receive(:rand).and_return(1) }

        it 'should store tests in session' do
          expect(array.vignette).to eq('b'); line = __LINE__ # for tracking line number
          expect(Vignette.tests).to eq({"(vignette_spec.rb:#{line})" => 'b'})
        end

        it 'should store tests even if we call on different lines' do
          expect(array.vignette).to eq('b'); line = __LINE__
          expect(Vignette.tests).to eq({"(vignette_spec.rb:#{line})" => 'b'})

          expect(array.vignette).to eq('b'); new_line = __LINE__
          expect(Vignette.tests).to eq({"(vignette_spec.rb:#{line})" => 'b'})
        end
      end

      context "for multiple runs" do
        before(:each) { expect(Kernel).to receive(:rand).and_return(1, 2) }

        it 'should store tests in session by name' do
          expect(array.vignette('cat')).to eq('b')
          
          expect(Vignette.tests).to eq({'cat' => 'b'})
          expect(session).to eq( {'vignette_352441c2' => 1, v: {'cat' => 'b'}.to_json} )

          expect(array.vignette('cat')).to eq('b') # same value
          expect(session).to eq( {'vignette_352441c2' => 1, v: {'cat' => 'b'}.to_json} )

          expect([11,22,33].vignette('cat')).to eq(33) # new value
          expect(session).to eq( {'vignette_352441c2' => 1, 'vignette_d4d3e16f' => 2, v: {'cat' => 33}.to_json} )
        end
      end
    end
  end

  context 'when stripping paths' do
    let(:path) { '/a/b/c/d.ex' }

    context 'with rails defined' do
      before { stub_const('Rails', double('rails', root: '/a/b')) }
      
      it 'should properly gsub out rails root' do
        expect(Vignette.strip_path(path)).to eq('c/d.ex')
      end
    end

    context 'with rails undefined' do
      before { stub_const('Rails', nil) }

      it 'should just have final path' do
        expect(Vignette.strip_path(path)).to eq('d.ex')
      end
    end
  end

end