import std/math
import cppclass

type A = object of RootObj
  a: cint

cppclass B(A {.public.}):
  public:
    b: cint = sqrt(17.0 ^ 5).cint

{.emit: "#include <iostream>".}

proc main =
  var foo: B
  foo.a = 1
  echo (foo.a, foo.b)
  {.emit:"""
  B bar;
  bar.a = 2;
  std::cout << bar.a << ", " << bar.b << std::endl;
  """.}

main()
