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
echo foo.b
