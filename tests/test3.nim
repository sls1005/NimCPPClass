import cppclass

type A = object of RootObj
  a {.bitsize: 4.}: cint

cppclass B(A {.public.}):
  private:
    b {.bitsize: 4.}: cint
  public:
    proc `B`(a: cint = 1, b: cint = 2) =
      assert a < 8 and b < 8
      assert a > -9 and b > -9
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
