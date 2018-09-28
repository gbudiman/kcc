class Brainfuck
  def initialize input:, output:
    @input = input
    @output = output    
  end

  def interpret! script, trace: false, breakpoints: []
    @source_code = script.split('')
    @line_pointer = 0
    @output_buffer = ''
    @cells = Array.new
    @pointer = -1
    @stack = Stacktrace.new
    @output_buffer = Array.new

    pc = 0
    move_pointer :forward

    if trace
      puts 'step -   pc: opcode       | memory                           stack '
      puts '--------------------------------------------------------------------------'
    end

    loop do
      no_op = false
      in_position = @source_code[@line_pointer]

      debug_buffer = sprintf('%4d - %4d', pc, @line_pointer)
      pad_buffer = pad

      case in_position
      when '+' then at_pointer :+
      when '-' then at_pointer :-
      when '>' then move_pointer :forward
      when '<' then move_pointer :backward
      when '.' then buffer
      when ',' then set_at_pointer
      when '['
        if cell_is_zero?
          skip_to_next_closing_bracket
        else
          @stack.push({
            line_pointer: @line_pointer
          })
        end

        pad_buffer = pad(is_bracket: true)
      when ']'
        if cell_is_zero?
          @stack.pop
        else
          popped = @stack.peek
          @line_pointer = popped[:line_pointer]
        end

        pad_buffer = pad(is_bracket: true)
      when ' ' then no_op = true
      else raise Brainfuck::InvalidToken, "Invalid token #{in_position} at index #{@line_pointer}"
      end

      advance
      if not no_op
        puts "#{debug_buffer}: #{(pad_buffer + in_position).ljust(12)} | #{show_cells.ljust(32)} #{@stack.list}" if trace
        pc = pc + 1
      end

      break if @line_pointer >= @source_code.length
    end

    raise Brainfuck::UnbalancedBracket if not @stack.empty?
    return @output_buffer.join('')
  end

  def move_pointer direction
    @pointer = @pointer + (direction == :forward ? 1 : -1)

    raise Brainfuck::NegativeCellIndex if @pointer < 0 
    if @pointer >= @cells.length
      @cells.push(0)
    end
  end

  def at_pointer operation
    @cells[@pointer] = @cells[@pointer] + (operation == :+ ? 1 : -1)
  end

  def set_at_pointer
    print 'Enter one character then press enter: '
    @cells[@pointer] = $stdin.gets.strip[0].ord
  end

  def skip_to_next_closing_bracket
    advance
    loop do
      if @source_code[@line_pointer] == ']'
        break
      end
      advance
    end
  end

  def show_cells
    s = ''

    if @pointer > 0
      s += @cells[0..@pointer-1].join(' ') + ' '
    end

    s += "#{cell_value}*"
    s += ' ' + @cells[@pointer+1..-1].join(' ')

    return s
  end

  def cell_value
    return @cells[@pointer]
  end

  def cell_is_zero?
    return cell_value == 0
  end

  def pad is_bracket: false
    return "  " * ([@stack.list.length - (is_bracket ? 1 : 0), 0].max)
  end

  def advance
    @line_pointer = @line_pointer + 1
  end

  def memdump
    return @cells
  end

  def buffer
    @output_buffer.push(@cells[@pointer].chr)
  end

  def flush_buffer

  end
end

class Brainfuck::NegativeCellIndex < StandardError
end

class Brainfuck::InvalidToken < StandardError
end