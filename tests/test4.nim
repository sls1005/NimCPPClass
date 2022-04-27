#This file shows some advanced usage of this macro.
import cppclass

cppclass A:
  protected:
    a: cint = 1
  public:
    #If a member function is marked as {.virtual.}, it can be overridden.
    proc get(): cint {.virtual.} =
      this.a
    #If a member function is marked as {.static.}, it cannot use the pointer 'this'.
    proc greet() {.static.} =
      echo "Hello, world!"

cppclass B(A {.public.}):
  public:
    b: cint = 2
    #In this macro, the meaning of 'method' has changed.
    #It becomes a virtual member function.
    method store(b: cint) =
      this.b = b
    #If a virtual member function is marked as {.final.}, it cannot be overridden.
    proc get(): cint {.final.} =
      this.b

#A class marked as {.final.} cannot be inherited from.
cppclass C(B) {.final.}:
  public:
    #A member marked as {.static.} is shared by all instances of a class.
    c {.static.}: cint
    method store(c: cint) =
      this.c = c
    proc show() =
      echo (this[]).get()
      echo this.c

{.emit: "#include <iostream>".}

proc main =
  var
    a1: A
    c1: C
  a1.greet()
  echo a1.get()
  c1.store(3)
  c1.show()
  {.emit: """
  A a2;
  C c2;
  std::cout << a2.get() << std::endl;
  c2.show();
  """.}

main()
