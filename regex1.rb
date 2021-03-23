# Inspiration from this blog post https://nickdrane.com/build-your-own-regex/
# file_name = "all"
# expression_file = "tests/#{file_name}-expressions.txt"
# target_file = "tests/#{file_name}-targets.txt"
# expected_file = target_file[0, target_file.length - 12] + "-expected.txt"

expression_file = ARGV[0]
target_file = ARGV[1]

parentheses_remainder = []
parentheses_content = []

expression_array = []
target_array = []
expected_array = []

File.open(expression_file).each do |line|
  expression_array.push(line.chomp)
end
File.open(target_file).each do |line|
  target_array.push(line.chomp)
end
# File.open(expected_file).each do |line|
#   expected_array.push(line.chomp)
# end

def run(expression_array, target_array)
  correct_count = 0
  wrong_count = 0
  expression_array.zip(target_array).each do |expression, target|
    begin
      target.match(expression)
      if match(expression.chars, target.chars)
        puts "YES: #{expression} with #{target}"
      else
        puts "NO:  #{expression} with #{target}"
      end
    rescue RegexpError => e
      puts "SYNTAX ERROR: #{expression} with #{target}"
    end
    # if result == expected
    #   correct_count += 1
    #   puts "CORRECT => " + result
    # else
    #   wrong_count += 1
    #   puts "WRONG => " + result
    # end
  end
  # puts correct_count.to_f/(correct_count.to_f+wrong_count.to_f)
end

def match(expression, target)
  if (expression.nil? || expression.empty?) && (target.nil? || target.empty?)
    true
  elsif expression[1] == '*'
    asterisk_match(expression, target)
  elsif expression[0] == '('
    bool = parentheses_match(expression, target)
    return bool
  elsif expression.include?('|')
    pipe_match(expression, target)
  else
    first_match(expression[0], target[0]) && match(expression.drop(1), target.drop(1))
  end
end

def first_match(expression, target)
  if target.nil? || target.empty?
    false
  elsif expression == '.'
    true
  elsif expression == target
    true
  else
    false
  end
end

def asterisk_match(expression, target)
  first_match(expression[0], target[0]) && match(expression, target.drop(1)) || match(expression.drop(2), target)
end

def pipe_match(expression, target)
  pipe_index = expression.index('|')
  before = expression[0, pipe_index]
  after = expression[pipe_index+1, expression.length]
  match(before, target) || match(after, target)
end

def parentheses_match (expression, target)
  closed_parentheses_index = find_closing_paren(expression)
  group = expression[1, closed_parentheses_index-1]
  if group.last == '*'
    return false
  end
  if expression[closed_parentheses_index + 1] == '*'
    remainder = expression.drop(closed_parentheses_index + 2)
    if group.include?('|') && find_outer_pipe(group) != 99
      pipe_index = find_outer_pipe(group)
      before = group[0, pipe_index]
      after = group[pipe_index+1, group.length]
      (match(before, target[0, before.length]) && match(expression, target.drop(before.length))) || match(remainder, target) ||
      (match(after, target[0, after.length]) && match(expression, target.drop(after.length))) || match(remainder, target)
    else
      (match(group, target[0, group.length]) && match(expression, target.drop(group.length))) || match(remainder, target)
    end
  elsif group.include?('|') && find_outer_pipe(group) != 99
    remainder = expression.drop(closed_parentheses_index + 1)
    pipe_index = find_outer_pipe(group)
    before = group[0, pipe_index]
    after = group[pipe_index+1, group.length]
    lits_before = before - ["("] - [")"]
    lits_after = after - ["("] - [")"]
    match(before, target[0, lits_before.length]) && match(remainder, target.drop(lits_before.length)) ||
    match(after, target[0, lits_after.length]) && match(remainder, target.drop(lits_after.length))
  else
    remainder = expression.drop(closed_parentheses_index + 1)
    lits = group - ["("] - [")"]
    match(group, target[0, lits.length]) && match(remainder, target.drop(lits.length))
  end
end

def find_closing_paren(array)
  close_pos = 0
  counter = 1
  while counter > 0
    close_pos += 1
    char = array[close_pos]
    if char == '('
      counter += 1
    elsif char == ')'
      counter -= 1
    elsif close_pos == 99
      break
    end
  end
  close_pos
end

def find_outer_pipe(array)
  pipe_pos = -1
  counter = 1
  while counter > 0
    pipe_pos += 1
    char = array[pipe_pos]
    if char == '('
      counter += 1
    elsif char == ')'
      counter -= 1
    elsif char == '|' && counter == 1
      return pipe_pos
    elsif pipe_pos == 99
      return pipe_pos
      break
    end
  end
end

run(expression_array, target_array)
