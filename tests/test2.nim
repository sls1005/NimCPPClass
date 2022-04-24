import cppclass

cppclass A:
  private:
    a: cint
  public:
    proc get(): cint =
      this.a
    proc store(a: cint) =
      this.a = a

cppclass B(A):
  public:
    b: cint

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
