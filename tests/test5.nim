import cppclass

cppclass Foo:
  {.emit: "friend class Bar;".}
  private:
    val: int

cppclass Bar:
  private:
    f: Foo
  public:
    proc store(v: int) =
      (this[]).f.val = v
    proc get(): int =
      (this[]).f.val

proc main =
  var x: Bar
  x.store(1)
  echo x.get()

main()
