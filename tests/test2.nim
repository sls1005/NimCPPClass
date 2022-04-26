import std/math
import cppclass

cppclass A:
  protected:
    a: cint

cppclass B(A):
  public:
    b: cint = sqrt(17.0 ^ 5).cint
    proc get(): cint =
      this.a
    proc store(a: cint) =
      this.a = a

{.emit: "#include <iostream>".}

proc main =
  var foo: B
  foo.store(1)
  echo (foo.get(), foo.b)
  {.emit:"""
  B bar;
  bar.store(2);
  std::cout << bar.get() << std::endl;
  """.}

main()
