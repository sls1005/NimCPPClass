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

{.emit: "#include <iostream>".}

proc main =
  var foo: B
  foo.store(1)
  foo.b = 2
  echo [foo.get(), foo.b]
  {.emit:"""
  B bar;
  bar.store(3);
  std::cout << bar.get() << std::endl;
  """.}

main()