import std/[math, sequtils, stats]
import cppclass

cppclass Foo:
  protected:
    a: float = sqrt(17.0 ^ 5)
    b = (1 .. 100).toSeq().mean()
  public:
    proc get(): float =
      this.a + this.b

var f: Foo
echo f.get()
