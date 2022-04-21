import std/[macros, random, strformat, strutils, tables]

when not defined(cpp):
  {.error: "This can only be used with the C++ backend.".}

proc empty(node: NimNode): bool {.compileTime.} =
  node.kind == nnkEmpty

macro cppclass*(className, definition: untyped): untyped =
  expectKind(className, nnkIdent)
  expectKind(definition, nnkStmtList)
  var
    classNameStr = repr(className)
    r = initRand(len(classNameStr) + ord(classNameStr[^1]))
    functionsToImport = newStmtList()
    functionsToExport = newStmtList()
    types = newNimNode(nnkTypeSection)
    fields = newNimNode(nnkRecList)
    code = newTree(
      nnkBracket,
      newLit("""
/*TYPESECTION*/
class $1 {
""" % classNameStr #C++ code to emit
      )
    )
    typeList: Table[string, NimNode]
  for node in definition:
    case node.kind:
    of nnkCall:
      case repr(node[0]):
      of "private", "protected",  "public":
        code.add newLit(repr(node[0]) & ": ")
        expectKind(node[1], nnkStmtList)
        for def in node[1]:
          case def.kind:
          of nnkProcDef, nnkFuncDef:
            include ./cppclass/memberFunctions
          of nnkCall:
            include ./cppclass/members
          of nnkDiscardStmt:
            discard
          else:
            error("Invalid statement: " & repr(def), def)
      of "cppclass":
        error("Nested classes are not supported.", node[0])
      else:
        let def = node
        include ./cppclass/members
    of nnkProcDef, nnkFuncDef:
      let def = node
      include ./cppclass/memberFunctions
    of nnkDiscardStmt:
      discard
    else:
      error("Invalid statement: " & repr(node), node)
  code.add newLit("};")
  let obj = newTree(
    nnkObjectTy,
    newEmptyNode(),
    newEmptyNode(),
    fields
  )
  result = quote do:
    type `className` {.importcpp, cppNonPod, nodecl.} = `obj`
    {.emit: `code`.}
    `functionsToImport`
    `functionsToExport`
  if len(types) > 0:
    result.insert(1, types)
