import cppclass

type FuncPtr = proc(arg: pointer): cint {.cdecl.}

cppclass Caller:
  protected:
    f: FuncPtr
    arg: pointer
  public:
    proc `Caller`(f: FuncPtr, arg: pointer) =
      this.f = f
      this.arg = arg
    proc call(): cint =
      (this.f)(this.arg)

proc initCaller(f: FuncPtr, arg: pointer): Caller {.importcpp: "Caller(@)", constructor.}

proc foo(p: pointer): cint {.cdecl.} =
  cast[ptr cint](p)[] + 1

{.emit: """
#include <iostream>

int bar(void* p) {
  return *((int*)p) - 1;
}
""".}

proc main =
  var
    n: cint = 1
    c1 = initCaller(foo, cast[pointer](addr n))
  echo c1.call()
  {.emit: """
  int k = 10;
  Caller c2(&bar, (void*) &k);
  std::cout << c2.call() << std::endl;
  """.}

main()
