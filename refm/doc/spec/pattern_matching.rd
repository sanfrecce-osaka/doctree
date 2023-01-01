= Pattern matching

Pattern matching is a feature allowing deep matching of structured values: checking the structure and binding the matched parts to local variables.

Pattern matching in Ruby is implemented with the +case+/+in+ expression:

    case <expression>
    in <pattern1>
      ...
    in <pattern2>
      ...
    in <pattern3>
      ...
    else
      ...
    end

(Note that +in+ and +when+ branches can NOT be mixed in one +case+ expression.)

Or with the <code>=></code> operator and the +in+ operator, which can be used in a standalone expression:

    <expression> => <pattern>

    <expression> in <pattern>

The +case+/+in+ expression is _exhaustive_: if the value of the expression does not match any branch of the +case+ expression (and the +else+ branch is absent), +NoMatchingPatternError+ is raised.

Therefore, the +case+ expression might be used for conditional matching and unpacking:

#@samplecode
  config = {db: {user: 'admin', password: 'abc123'}}

  case config
  in db: {user:} # matches subhash and puts matched value in variable user
    puts "Connect with user '#{user}'"
  in connection: {username: }
    puts "Connect with user '#{username}'"
  else
    puts "Unrecognized structure of config"
  end
  # Prints: "Connect with user 'admin'"
#@end

whilst the <code>=></code> operator is most useful when the expected data structure is known beforehand, to just unpack parts of it:

#@samplecode
  config = {db: {user: 'admin', password: 'abc123'}}

  config => {db: {user:}} # will raise if the config's structure is unexpected

  puts "Connect with user '#{user}'"
  # Prints: "Connect with user 'admin'"
#@end

<code><expression> in <pattern></code> is the same as <code>case <expression>; in <pattern>; true; else false; end</code>.
You can use it when you only want to know if a pattern has been matched or not:

#@samplecode
  users = [{name: "Alice", age: 12}, {name: "Bob", age: 23}]
  users.any? {|user| user in {name: /B/, age: 20..} } #=> true
#@end

See below for more examples and explanations of the syntax.

== Patterns

Patterns can be:

* any Ruby object (matched by the <code>===</code> operator, like in +when+); (<em>Value pattern</em>)
* array pattern: <code>[<subpattern>, <subpattern>, <subpattern>, ...]</code>; (<em>Array pattern</em>)
* find pattern: <code>[*variable, <subpattern>, <subpattern>, <subpattern>, ..., *variable]</code>; (<em>Find pattern</em>)
* hash pattern: <code>{key: <subpattern>, key: <subpattern>, ...}</code>; (<em>Hash pattern</em>)
* combination of patterns with <code>|</code>; (<em>Alternative pattern</em>)
* variable capture: <code><pattern> => variable</code> or <code>variable</code>; (<em>As pattern</em>, <em>Variable pattern</em>)

Any pattern can be nested inside array/find/hash patterns where <code><subpattern></code> is specified.

Array patterns and find patterns match arrays, or objects that respond to +deconstruct+ (see below about the latter).
Hash patterns match hashes, or objects that respond to +deconstruct_keys+ (see below about the latter). Note that only symbol keys are supported for hash patterns.

An important difference between array and hash pattern behavior is that arrays match only a _whole_ array:

#@samplecode
  case [1, 2, 3]
  in [Integer, Integer]
    "matched"
  else
    "not matched"
  end
  #=> "not matched"
#@end

while the hash matches even if there are other keys besides the specified part:

#@samplecode
  case {a: 1, b: 2, c: 3}
  in {a: Integer}
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

<code>{}</code> is the only exclusion from this rule. It matches only if an empty hash is given:

#@samplecode
  case {a: 1, b: 2, c: 3}
  in {}
    "matched"
  else
    "not matched"
  end
  #=> "not matched"
#@end

#@samplecode
  case {}
  in {}
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

There is also a way to specify there should be no other keys in the matched hash except those explicitly specified by the pattern, with <code>**nil</code>:

#@samplecode
  case {a: 1, b: 2}
  in {a: Integer, **nil} # this will not match the pattern having keys other than a:
    "matched a part"
  in {a: Integer, b: Integer, **nil}
    "matched a whole"
  else
    "not matched"
  end
  #=> "matched a whole"
#@end

Both array and hash patterns support "rest" specification:

#@samplecode
  case [1, 2, 3]
  in [Integer, *]
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

#@samplecode
  case {a: 1, b: 2, c: 3}
  in {a: Integer, **}
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

Parentheses around both kinds of patterns could be omitted:

#@samplecode
  case [1, 2]
  in Integer, Integer
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

#@samplecode
  case {a: 1, b: 2, c: 3}
  in a: Integer
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

#@samplecode
 [1, 2] => a, b
#@end

#@samplecode
 [1, 2] in a, b
#@end

#@samplecode
 {a: 1, b: 2, c: 3} => a:
#@end

#@# このコメントの前後のコードブロックを1つにまとめると
#@# {a: 1, b: 2, c: 3} => a: {a: 1, b: 2, c: 3} in a:
#@# と解釈されて duplicated key name で SyntaxError になってしまうのでやむを得ず別々のコードブロックにしている

#@samplecode
 {a: 1, b: 2, c: 3} in a:
#@end

Find pattern is similar to array pattern but it can be used to check if the given object has any elements that match the pattern:

#@samplecode
  case ["a", 1, "b", "c", 2]
  in [*, String, String, *]
    "matched"
  else
    "not matched"
  end
#@end

== Variable binding

Besides deep structural checks, one of the very important features of the pattern matching is the binding of the matched parts to local variables. The basic form of binding is just specifying <code>=> variable_name</code> after the matched (sub)pattern (one might find this similar to storing exceptions in local variables in a <code>rescue ExceptionClass => var</code> clause):

#@samplecode
  case [1, 2]
  in Integer => a, Integer
    "matched: #{a}"
  else
    "not matched"
  end
  #=> "matched: 1"
#@end

#@samplecode
  case {a: 1, b: 2, c: 3}
  in a: Integer => m
    "matched: #{m}"
  else
    "not matched"
  end
  #=> "matched: 1"
#@end

If no additional check is required, for only binding some part of the data to a variable, a simpler form could be used:

#@samplecode
  case [1, 2]
  in a, Integer
    "matched: #{a}"
  else
    "not matched"
  end
  #=> "matched: 1"
#@end

#@samplecode
  case {a: 1, b: 2, c: 3}
  in a: m
    "matched: #{m}"
  else
    "not matched"
  end
  #=> "matched: 1"
#@end

For hash patterns, even a simpler form exists: key-only specification (without any sub-pattern) binds the local variable with the key's name, too:

#@samplecode
  case {a: 1, b: 2, c: 3}
  in a:
    "matched: #{a}"
  else
    "not matched"
  end
  #=> "matched: 1"
#@end

Binding works for nested patterns as well:

#@samplecode
  case {name: 'John', friends: [{name: 'Jane'}, {name: 'Rajesh'}]}
  in name:, friends: [{name: first_friend}, *]
    "matched: #{first_friend}"
  else
    "not matched"
  end
  #=> "matched: Jane"
#@end

The "rest" part of a pattern also can be bound to a variable:

#@samplecode
  case [1, 2, 3]
  in a, *rest
    "matched: #{a}, #{rest}"
  else
    "not matched"
  end
  #=> "matched: 1, [2, 3]"
#@end

#@samplecode
  case {a: 1, b: 2, c: 3}
  in a:, **rest
    "matched: #{a}, #{rest}"
  else
    "not matched"
  end
  #=> "matched: 1, {:b=>2, :c=>3}"
#@end

Binding to variables currently does NOT work for alternative patterns joined with <code>|</code>:

#@samplecode
  case {a: 1, b: 2}
  in {a: } | Array
    "matched: #{a}"
  else
    "not matched"
  end
  # SyntaxError (illegal variable in alternative pattern (a))
#@end

Variables that start with <code>_</code> are the only exclusions from this rule:

#@samplecode
  case {a: 1, b: 2}
  in {a: _, b: _foo} | Array
    "matched: #{_}, #{_foo}"
  else
    "not matched"
  end
  # => "matched: 1, 2"
#@end

It is, though, not advised to reuse the bound value, as this pattern's goal is to signify a discarded value.

== Variable pinning

Due to the variable binding feature, existing local variable can not be straightforwardly used as a sub-pattern:

#@samplecode
  expectation = 18

  case [1, 2]
  in expectation, *rest
    "matched. expectation was: #{expectation}"
  else
    "not matched. expectation was: #{expectation}"
  end
  # expected: "not matched. expectation was: 18"
  # real: "matched. expectation was: 1" -- local variable just rewritten
#@end

For this case, the pin operator <code>^</code> can be used, to tell Ruby "just use this value as part of the pattern":

#@samplecode
  expectation = 18
  case [1, 2]
  in ^expectation, *rest
    "matched. expectation was: #{expectation}"
  else
    "not matched. expectation was: #{expectation}"
  end
  #=> "not matched. expectation was: 18"
#@end

One important usage of variable pinning is specifying that the same value should occur in the pattern several times:

#@samplecode
  jane = {school: 'high', schools: [{id: 1, level: 'middle'}, {id: 2, level: 'high'}]}
  john = {school: 'high', schools: [{id: 1, level: 'middle'}]}

  case jane
  in school:, schools: [*, {id:, level: ^school}] # select the last school, level should match
    "matched. school: #{id}"
  else
    "not matched"
  end
  #=> "matched. school: 2"

  case john # the specified school level is "high", but last school does not match
  in school:, schools: [*, {id:, level: ^school}]
    "matched. school: #{id}"
  else
    "not matched"
  end
  #=> "not matched"
#@end

In addition to pinning local variables, you can also pin instance, global, and class variables:

#@samplecode
  $gvar = 1
  class A
    @ivar = 2
    @@cvar = 3
    case [1, 2, 3]
    in ^$gvar, ^@ivar, ^@@cvar
      "matched"
    else
      "not matched"
    end
    #=> "matched"
  end
#@end

You can also pin the result of arbitrary expressions using parentheses:

#@samplecode
  a = 1
  b = 2
  case 3
  in ^(a + b)
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

== Matching non-primitive objects: +deconstruct+ and +deconstruct_keys+

As already mentioned above, array, find, and hash patterns besides literal arrays and hashes will try to match any object implementing +deconstruct+ (for array/find patterns) or +deconstruct_keys+ (for hash patterns).

#@samplecode
  class Point
    def initialize(x, y)
      @x, @y = x, y
    end

    def deconstruct
      puts "deconstruct called"
      [@x, @y]
    end

    def deconstruct_keys(keys)
      puts "deconstruct_keys called with #{keys.inspect}"
      {x: @x, y: @y}
    end
  end

  case Point.new(1, -2)
  in px, Integer  # sub-patterns and variable binding works
    "matched: #{px}"
  else
    "not matched"
  end
  # prints "deconstruct called"
  "matched: 1"

  case Point.new(1, -2)
  in x: 0.. => px
    "matched: #{px}"
  else
    "not matched"
  end
  # prints: deconstruct_keys called with [:x]
  #=> "matched: 1"
#@end

+keys+ are passed to +deconstruct_keys+ to provide a room for optimization in the matched class: if calculating a full hash representation is expensive, one may calculate only the necessary subhash. When the <code>**rest</code> pattern is used, +nil+ is passed as a +keys+ value:

#@samplecode
  case Point.new(1, -2)
  in x: 0.. => px, **rest
    "matched: #{px}"
  else
    "not matched"
  end
  # prints: deconstruct_keys called with nil
  #=> "matched: 1"
#@end

Additionally, when matching custom classes, the expected class can be specified as part of the pattern and is checked with <code>===</code>

#@samplecode
  class SuperPoint < Point
  end

  case Point.new(1, -2)
  in SuperPoint(x: 0.. => px)
    "matched: #{px}"
  else
    "not matched"
  end
  #=> "not matched"

  case SuperPoint.new(1, -2)
  in SuperPoint[x: 0.. => px] # [] or () parentheses are allowed
    "matched: #{px}"
  else
    "not matched"
  end
  #=> "matched: 1"
#@end

== Guard clauses

+if+ can be used to attach an additional condition (guard clause) when the pattern matches. This condition may use bound variables:

#@samplecode
  case [1, 2]
  in a, b if b == a*2
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

#@samplecode
  case [1, 1]
  in a, b if b == a*2
    "matched"
  else
    "not matched"
  end
  #=> "not matched"
#@end

+unless+ works, too:

#@samplecode
  case [1, 1]
  in a, b unless b == a*2
    "matched"
  else
    "not matched"
  end
  #=> "matched"
#@end

== Current feature status

As of Ruby 3.1, find patterns are considered _experimental_: its syntax can change in the future. Every time you use these features in code, a warning will be printed:

#@samplecode
  [0] => [*, 0, *]
  # warning: Find pattern is experimental, and the behavior may change in future versions of Ruby!
  # warning: One-line pattern matching is experimental, and the behavior may change in future versions of Ruby!
#@end

To suppress this warning, one may use the Warning::[]= method:

#@samplecode
  Warning[:experimental] = false
  eval('[0] => [*, 0, *]')
  # ...no warning printed...
#@end

Note that pattern-matching warnings are raised at compile time, so this will not suppress the warning:

#@samplecode
  Warning[:experimental] = false # At the time this line is evaluated, the parsing happened and warning emitted
  [0] => [*, 0, *]
#@end

So, only subsequently loaded files or `eval`-ed code is affected by switching the flag.

Alternatively, the command line option <code>-W:no-experimental</code> can be used to turn off "experimental" feature warnings.

== Appendix A. Pattern syntax

Approximate syntax is:

  pattern: value_pattern
         | variable_pattern
         | alternative_pattern
         | as_pattern
         | array_pattern
         | find_pattern
         | hash_pattern

  value_pattern: literal
               | Constant
               | ^local_variable
               | ^instance_variable
               | ^class_variable
               | ^global_variable
               | ^(expression)

  variable_pattern: variable

  alternative_pattern: pattern | pattern | ...

  as_pattern: pattern => variable

  array_pattern: [pattern, ..., *variable]
               | Constant(pattern, ..., *variable)
               | Constant[pattern, ..., *variable]

  find_pattern: [*variable, pattern, ..., *variable]
              | Constant(*variable, pattern, ..., *variable)
              | Constant[*variable, pattern, ..., *variable]

  hash_pattern: {key: pattern, key:, ..., **variable}
              | Constant(key: pattern, key:, ..., **variable)
              | Constant[key: pattern, key:, ..., **variable]

== Appendix B. Some undefined behavior examples

To leave room for optimization in the future, the specification contains some undefined behavior.

Use of a variable in an unmatched pattern:

#@samplecode
  case [0, 1]
  in [a, 2]
    "not matched"
  in b
    "matched"
  in c
    "not matched"
  end
  a #=> undefined
  c #=> undefined
#@end

Number of +deconstruct+, +deconstruct_keys+ method calls:

#@samplecode
  $i = 0
  ary = [0]
  def ary.deconstruct
    $i += 1
    self
  end
  case ary
  in [0, 1]
    "not matched"
  in [0]
    "matched"
  end
  $i #=> undefined
#@end
