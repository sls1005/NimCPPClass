import cppclass

type A = object of RootObj
  a: cint

cppclass B(A):
  public:
    b: cint

proc `$`(self: B): string =
  $((b: self.b, a: self.a))

{.emit: "#include <iostream>".}

proc main =
  var foo: B
  foo.a = 1
  foo.b = 2
  echo foo
  {.emit:"""
  B bar;
  bar.a = 3;
  bar.b = 4;
  std::cout << bar.a << ", " << bar.b << std::endl;
  """.}

main()
