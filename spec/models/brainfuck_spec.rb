require 'rails_helper'

RSpec.describe Brainfuck, type: :model do
  before :each do
    @interpreter = Brainfuck.new(input: $stdin, output: $stdout)
  end

  it 'should raise InvalidToken exception on invalid token' do
    'g48&*!'.split('').each do |x|
      expect do
        @interpreter.interpret!(x)
      end.to raise_error(Brainfuck::InvalidToken, /Invalid token/)
    end
  end

  context 'linear operations' do
    it 'should do single print correctly' do
      out = @interpreter.interpret!('++++++++++.')
      expect(out).to eq(10.chr)
    end

    it 'should do combo print correctly' do
      out = @interpreter.interpret!('+++.>+++++.<--.')
      expect(out).to eq([3,5,1].map{|x| x.chr}.join(''))
    end

    it 'should have correct memory content' do
      @interpreter.interpret!('>>>>++')
      expect(@interpreter.memdump).to eq([0, 0, 0, 0, 2])
    end

    it 'should add 2 numbers correctly' do
      out = @interpreter.interpret!('++>+++++[<+>-] ++++ ++++ [< +++ +++ > -] <.')
      expect(@interpreter.memdump).to eq([55, 0])
      expect(out).to eq(55.chr)
    end
  end

  context 'basic loop' do
    it 'should execute loop correctly' do
      out = @interpreter.interpret!('++++++ [ > ++++++++++ < - ] > +++++ .')
      expect(out).to eq('A')
    end

    it 'should print Hello World correctly' do
      script = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
      out = @interpreter.interpret!(script) # prints "Hello World!\n"
      expect(out).to eq("Hello World!\n")
    end
  end
end
