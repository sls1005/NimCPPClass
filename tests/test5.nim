import cppclass

type A = object of RootObj
  a: int

cppclass B(A):
  public:
    b: int

type C = object of B
  c: int

proc `$`(self: C): string =
  $((c: self.c, b: self.b, a: self.a))

var foo: C
foo.a = 1
foo.b = 2
foo.c = 3
echo foo
