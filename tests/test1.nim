import cppclass

cppclass X:
  public:
    a: int
    proc `X`() =
      (this[]).a = 1
      (this[]).b = 2
      (this[]).c = 3
    proc get(): int =
      var
        a = (this[]).a
        b = (this[]).b
        c = (this[]).c
      return a + b + c
  protected:
    b: int
  private:
    c: int

var x: X
echo x.get()