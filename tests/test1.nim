import cppclass

const
  arc = compileOption("gc", "arc")
  orc = compileOption("gc", "orc")

cppclass Foo:
  public:
    name: string
    payload: seq[cint]
    proc nameAs(s: cstring) =
      this.name = $(s)
    proc add(n: cint) =
      this.payload.add(n)
    proc `[]`(i: csize_t): cint =
      this.payload[int(i)]
    proc `Foo`() =
      #Initialization
      wasMoved(this.name)
      wasMoved(this.payload)
    proc `~Foo`() =
      let name = move(this.name)
      when arc or orc:
        `=destroy`(this.payload)
        wasMoved(this.payload)
      else:
        this.payload = @[]
      echo name & " has been destroyed."

when arc or orc:
  proc `=destroy`(self: var Foo) =
      #Prevent it from being destroyed twice.
      echo "Nothing happened."

{.emit: "#include <iostream>".}

proc main =
  var f: Foo
  f.nameAs("F")
  f.add(1)
  echo f[0]
  {.emit: """
  Foo x;
  x.nameAs("X");
  x.add(2);
  std::cout << x[0] << std::endl;
  """.}

main()