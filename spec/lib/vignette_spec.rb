require 'spec_helper'

describe Vignette do

  context 'with simple session store' do
    let!(:session) { Hash.new }
    let(:array) { %w{a b c} }
    before { Vignette.set_repo(session) }

    it 'should have correct crc' do
      expect(array.crc).to eq(891568578)
      expect(array.crc.abs.to_s(16)).to eq('352441c2')
    end

    context 'when calling vignette' do
      context "for a single run" do
        before(:each) { expect(Kernel).to receive(:rand).and_return(1) }

        it 'should store tests in session' do
          expect(array.vignette).to eq('b'); line = __LINE__ # for tracking line number
          expect(Vignette.tests).to eq({:"(vignette_spec.rb:#{line})" => 'b'})
        end

        it 'should store tests even if we call on different lines' do
          expect(array.vignette).to eq('b'); line = __LINE__
          expect(Vignette.tests).to eq({:"(vignette_spec.rb:#{line})" => 'b'})

          expect(array.vignette).to eq('b'); new_line = __LINE__
          expect(Vignette.tests).to eq({:"(vignette_spec.rb:#{line})" => 'b'})
        end
      end

      context "for multiple runs" do
        before(:each) { expect(Kernel).to receive(:rand).and_return(1, 2, 0) }

        it 'should store tests in session by name' do
          expect(array.vignette(:cat)).to eq('b')
          
          original_time = Time.now
          second_time = original_time + 1
          third_time = original_time + 2
          fourth_time = original_time + 3

          Timecop.freeze(original_time) do
            expect(Vignette.tests).to eq(cat: 'b') # original choice
            expect(JSON(session[:v])).to eq( { '352441c2' => { 'n' => 'cat', 'v' => 'b', 't' => original_time.to_i } } )
          end

          Timecop.freeze(second_time) do
            expect(Vignette.tests).to eq(cat: 'b') # same value
            expect(JSON(session[:v])).to eq( { '352441c2' => { 'n' => 'cat', 'v' => 'b', 't' => original_time.to_i } } )
          end
          
          Timecop.freeze(third_time) do
            expect([11,22,33].vignette(:cat)).to eq(33) # new value
            expect(JSON(session[:v])).to eq(
              {
                '352441c2' => { 'n' => 'cat', 'v' => 'b', 't' => original_time.to_i },
                'd4d3e16f' => { 'n' => 'cat', 'v' => 33, 't' => third_time.to_i }
              }
            )
            expect(Vignette.tests).to eq(cat: 33)
          end

          Timecop.freeze(fourth_time) do
            expect(['mice', 'mooise'].vignette(:cat)).to eq('mice') # new value
            expect(JSON(session[:v])).to eq(
              {
                '2384053' => { 'n' => 'cat', 'v' => 'mice', 't' => fourth_time.to_i },
                '352441c2' => { 'n' => 'cat', 'v' => 'b', 't' => original_time.to_i },
                'd4d3e16f' => { 'n' => 'cat', 'v' => 33, 't' => third_time.to_i }
              }
            )
            expect(Vignette.tests).to eq(cat: 'mice')
          end
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

  context 'when threading' do
    before(:each) { expect(Kernel).to receive(:rand).and_return(1, 2) }

    context 'serially' do
      it 'should work like normal' do
        
        Thread.new do
          Vignette.with_repo(Hash.new) do
            expect(%w{a b c}.vignette(:name)).to eq('b')
            expect(Vignette.tests).to eq(name: 'b')
          end
        end.join

        Thread.new do
          Vignette.with_repo(Hash.new) do
            expect(%w{a b c}.vignette(:name)).to eq('c')
            expect(Vignette.tests).to eq(name: 'c')
          end
        end.join
      end

    end

    context 'with no delays' do
      it 'should work like normal' do
        threads = []

        threads << Thread.new do
          Vignette.with_repo(Hash.new) do
            expect(%w{a b c}.vignette(:name)).to eq('b')
            expect(Vignette.tests).to eq(name: 'b')
          end
        end

        threads << Thread.new do
          Vignette.with_repo(Hash.new) do
            expect(%w{a b c}.vignette(:name)).to eq('c')
            expect(Vignette.tests).to eq(name: 'c')
          end
        end

        threads.each(&:join)
      end
    end

    context 'with a one second delay' do
      it 'should work like normal' do
        threads = []

        threads << Thread.new do
          Vignette.with_repo(Hash.new) do
            sleep 0.1 # this is to cause a race condition
            expect(%w{a b c}.vignette(:name)).to eq('c')
            expect(Vignette.tests).to eq(name: 'c')

            sleep 0.2
            expect(%w{a b c}.vignette(:name)).to eq('c')
            expect(Vignette.tests).to eq(name: 'c')
          end
        end

        threads << Thread.new do
          Vignette.with_repo(Hash.new) do
            expect(%w{a b c}.vignette(:name)).to eq('b')
            expect(Vignette.tests).to eq(name: 'b')

            sleep 0.2

            expect(%w{a b c}.vignette(:name)).to eq('b')
            expect(Vignette.tests).to eq(name: 'b')            
          end
        end

        threads.each(&:join)
      end
    end
    
  end

end