# Nim CPP Class

This module provides a macro that helps to define C++ classes from Nim.

### Example

```nim
import cppclass

cppclass X:
  public:
    a: int
    proc `X`() =
      (this[]).a = 1
      (this[]).b = 2
      (this[]).c = 3
    proc get(): int =
      var
        a = (this[]).a
        b = (this[]).b
        c = (this[]).c
      return a + b + c
  protected:
    b: int
  private:
    c: int

var x: X
echo x.get()
```

The class is emitted to the generated code by using `{.emit.}`. All the methods (or more exactly, member functions) are exported to C++ and imported back, so they can be used both in C++ and Nim. However, constructors and destructors are not imported, please import them by yourself.

```nim
import cppclass

cppclass Foo:
  protected:
    n: cint
  public:
   proc `Foo`(n: cint) =
     this.n = n
   proc get(): cint =
     this.n

proc initFoo(n: cint): Foo {.importcpp: "Foo(@)", constructor.}

{.emit: "#include <iostream>".}

proc main =
  var f1 = initFoo(10)
  echo f1.get()
  {.emit: """
  Foo f2(20);
  std::cout << f2.get() << std::endl;
  """.}

main()
```

Operators can also be defined, but only those valid in C++. Whether valid is checked by the C++ compiler. They will be transformed into C++ operators. Both `` `+` `` and `` `operator+` `` have the same meaning.

```nim
import cppclass

cppclass Bar:
  protected:
    v: uint8
  public:
    proc store(n: cint) =
      this.v = uint8(n)
    proc `+`(k: cint): cint =
      cint(this.v) + k

{.emit: "#include <iostream>".}

proc main =
  {.emit: """
  Bar b;
  b.store(4);
  std::cout << b + 5 << std::endl;
  """.}

main()
```

If a field (member) is an `AtomType` like `int` or `float`, it can have a default value. The value has to be something that can be evaluated at the compile time.

```nim
import std/math
import cppclass

cppclass Foo:
  public:
    a: float = sqrt(17.0 ^ 5)

var f: Foo
echo f.a
```

Inheritance is supported, but only from one parent.

```nim
import cppclass

cppclass A:
  private:
    a: int
  public:
    proc get(): int =
      this.a
    proc store(a: int) =
      this.a = a

cppclass B(A):
  public:
    b: int

var foo: B
foo.store(1)
echo foo.get()
```

In the above example, `B` inherits from `A`. The mode is default to `public`. This can be changed by using some pragma-like syntax.

```nim
import cppclass

cppclass A:
  protected:
    a: int

cppclass B(A {.private.}):
  public:
    b: int
    proc get(): int =
      this.a
    proc store(a: int) =
      this.a = a

var foo: B
foo.store(1)
echo foo.get()
```

### Note

* Generic parameters are not supported, as well as nested classes.

* Like in C++, the variable `this` is a `ptr` to the object that uses the member function.

* Do not use `static[T]` or `lent T` as parameter or return type.

* A class can have GC'd members (`ref`, `seq`, ...), but they must be `public` and initialized with `wasMoved`. They should be destroyed properly.

* If a field (member) is not initialized, its value is undefined.

* A class can not be exported because the emitted code is invisible from other modules. It has to be included.

* This module uses an undocumented pragma, `exportcpp`, so it might not be compatible with some versions of Nim compiler.
