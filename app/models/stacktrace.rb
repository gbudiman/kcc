class Stacktrace
  def initialize
    @stack = Array.new
  end

  def push o
    @stack.push(o)
  end

  def pop
    return @stack.pop
  end

  def peek
    return @stack[-1]
  end

  def empty?
    return @stack.length == 0
  end
end