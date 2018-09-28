require_relative './brainfuck.rb'
require_relative './stacktrace.rb'
require 'awesome_print'

class BrainfuckTester
  def initialize
    @interpreter = Brainfuck.new(input: $stdin, output: $stdout)
    @breakpoints = {}
    @trace = false
    @input = nil
  end

  def test!
    print 'Type Brainf*ck script: '
    @input = $stdin.gets.strip

    execute
  end

  def execute
    begin
      out = @interpreter.interpret! @input, trace: @trace, breakpoints: @breakpoints
      puts "Output: #{out}"
    rescue Exception => e
      puts e
      test!
    end

    print_options
  end

  def set_breakpoints
    puts ' idx Token'
    @input.split('').each_with_index do |t, i|
      puts sprintf('%4d %s', i, t)
    end

    puts "Current breakpoints: #{@breakpoints}"
    print 'Enter breakpoint index separated by space: '
    binput = $stdin.gets.strip
    @breakpoints = binput.split(/\s+/).map{ |x| x.to_i }.sort
  end

  def print_options
    print 'set [b]reakpoint, '
    print (@trace ? 'disable' : 'enable') + ' [t]race, '
    print '[r]erun, '
    print '[q]uit: '

    option = $stdin.gets.strip
    ap option
    case option
    when 'b'
      set_breakpoints
      execute
    when 't'
      @trace = !@trace
      execute
    when 'r'
      execute
    end
  end
end

bft = BrainfuckTester.new
bft.test!
