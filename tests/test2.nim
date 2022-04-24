import cppclass

cppclass A:
  protected:
    a: cint

cppclass B(A):
  public:
    b: cint
    proc get(): cint =
      this.a
    proc store(a: cint) =
      this.a = a

{.emit: "#include <iostream>".}

proc main =
  var foo: B
  foo.store(1)
  foo.b = 2
  echo (foo.get(), foo.b)
  {.emit:"""
  B bar;
  bar.store(3);
  std::cout << bar.get() << std::endl;
  """.}

main()
