import cppclass

type A = object of RootObj
  a: cint

cppclass B(A {.public.}):
  private:
    b: cint
  public:
    proc `B`(a: cint = 1, b: cint = 2) =
      this.a = a
      this.b = b
    proc get(): cint =
      this.a + this.b

{.emit: "#include <iostream>".}

proc main =
  var foo: B
  echo foo.get()
  {.emit:"""
  B bar;
  std::cout << bar.get() << std::endl;
  """.}

main()
