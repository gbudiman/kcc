class Brainfuck
  def initialize input:, output:
    @input = input
    @output = output

    
  end

  def interpret! script
    @source_code = script.split('')
    @line_pointer = 0
    @output_buffer = ''
    @cells = Array.new
    @pointer = -1
    @stack = Stacktrace.new
    @output_buffer = Array.new

    move_pointer :forward

    loop do
      in_position = @source_code[@line_pointer]

      case in_position
      when '+'
        at_pointer :+
        advance
      when '-'
        at_pointer :-
        advance
      when '>'
        move_pointer :forward
        advance
      when '<'
        move_pointer :backward
        advance
      when '.'
        buffer
        advance
      when ','
        advance
      when '['
        if cell_is_zero?
          skip_to_next_closing_bracket
        else
          @stack.push({
            line_pointer: @line_pointer + 1
          })
          advance
        end
      when ']'
        if cell_is_zero?
          @stack.pop
          advance
        else
          popped = @stack.peek
          @line_pointer = popped[:line_pointer]
        end
      when ' '
        advance
      else
        raise Brainfuck::InvalidToken, "Invalid token #{in_position} at index #{@line_pointer}"
      end

      puts "#{sprintf('%4d', @line_pointer)}: #{in_position} | [#{show_cells}]"
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

  def skip_to_next_closing_bracket
    advance
    loop do
      if @source_code[@line_pointer] == ']'
        advance
        break
      end
      advance
    end
  end

  def show_cells
    s = ''

    if @pointer > 0
      s += @cells[0..@pointer-1].join(' ')
    end

    s += " #{cell_value}* "
    s += @cells[@pointer+1..-1].join(' ')

    return s
  end

  def cell_value
    return @cells[@pointer]
  end

  def cell_is_zero?
    return cell_value == 0
  end

  def advance
    @line_pointer = @line_pointer + 1
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