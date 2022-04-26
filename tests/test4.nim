#This file shows some advanced usage of the macro.
import cppclass

cppclass A:
  protected:
    a: cint = 1
  public:
    #If a member function is marked as {.virtual.}, it can be overriden.
    proc get(): cint {.virtual.} =
      this.a
    #If a member function is marked as {.static.}, it cannot use the pointer 'this'.
    proc greet() {.static.} =
      echo "Hello, world!"

cppclass B(A {.public.}):
  public:
    b: cint = 2
    #If a virtual member function is marked as {.final.}, it cannot be overriden.
    proc get(): cint {.final.} =
      this.b

#If a class is marked as {.final.}, it cannot be inherit from.
cppclass C(B) {.final.}:
  public:
    c: float
    proc show() =
      echo (this[]).get()

{.emit: "#include <iostream>".}

proc main =
  var
    a1: A
    c1: C
  a1.greet()
  echo a1.get()
  c1.show()
  {.emit: """
  A a2;
  C c2;
  std::cout << a2.get() << std::endl;
  c2.show();
  """.}

main()