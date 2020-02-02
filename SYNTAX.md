## function
```
<return type> <identifier>[: <argument type> <argument identifier>, ...;] =>
	<function body>
[; OR \nend]
```

e.g.
```
usize main: usize argc, char **argv =>
	# <snip>
;

usize another_function: usize x, usize y =>
	# <snip>
;

usize yet_another =>
	# <snip>
end
```

## variables
```
<type> <identifier> := <value>;
```

e.g.
```
usize x := 4;
```

### data types
**Integer***:
- u8
- u16
- u32
- u64
- usize
- f32
- f64
- fsize
- i8
- i16
- i32
- i64
- isize

an ASCII character is a `u8`.

Strings and booleans are defined in the standard library.

## conditionals
**if/elif/else**:
```
if (<expression>) =>
	# <snip>
; elif (<expressions>) =>
	# <snip>
; else =>
	# <snip>
;
```

e.g.
```
if (x == 10) =>
	write("x == 10\n");
end
```

**switch**:
```
switch (<identifier>) =>
	<value> => <expression>;
	<value> => <expression>;
	<value> => <expression1>
			<expression2>;
	_ => <expression that handles everything else>;
end
```
e.g.
```
switch (x) =>
	1 => write("x == 1\n");
	2 => write("x == 2\n");
	3 => write("x == 3\n");
	_ => write("x is of unknown value\n");
end
```

**conditional operators**:
- `-and` (logical and)
- `-or`  (logical or)
- `-eq`  (equal to)
- `-ne`  (not equal to)
- `-lt`  (less than)
- `-gt`  (greater than)
- `-lte` (less than or equal to)
- `-gte` (greater than or equal to)

## operators
- `:=` (shorthand assignment)
- `=>` (function body start/long variable assignment)
- `<<` (bitwise shift left)
- `>>` (bitwise shift right)
- `&`  (bitwise AND)
- `|`  (bitwise OR)
- `^`  (bitwise XOR)
- `~`  (bitwise NOT)
- `<<=`
- `>>=`
- `&=`
- `|=`
- `^=`
- `~=`

## foreign
The `foreign` keyword, similar to `extern` in C, informs
the compiler that a particular token will be linked to
the executable at runtime from another object file. For
identifiers declared as `foreign`, the compiler will not
produce an error.

```
foreign usize MY_CONSTANT;
```

`foreign` functions are also allowed:
```
foreign usize MY_FUNCTION: usize x, usize y;
```

the `include` keyword can be thought of as a shortcut to
`foreign`: it causes the compiler to go through the specified
file at treat each identifier as if it was declared with
`foreign`.

## loops
The only loop construct is `while`:
```
while: <expressions> =>
[; OR end]
```
e.g.
```
while: usize i := 0; i -lt 10; inc(i) =>
	# do stuff
end

usize i := 0;
while: i -lt 100 =>
	# do stuff
	blah();

	# increment
	inc(i);
end
```
