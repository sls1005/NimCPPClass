import std/[macros, random, strformat, strutils]
import ./cppclass/typeLists

when not defined(cpp):
  error("This can only be used with the C++ backend.")

proc empty(node: NimNode): bool {.compileTime.} =
  node.kind == nnkEmpty

macro cppclass*(className, definition: untyped): untyped =
  var
    functionsToImport = newStmtList()
    functionsToExport = newStmtList()
    obj = newNimNode(nnkObjectTy)
    fields = newNimNode(nnkRecList)
    code = newTree(
      nnkBracket,
      newLit("""
/*TYPESECTION*/
class """ #C++ code to emit
      )
    )
    r: Rand
    typeName: NimNode
    typeNameStr: string
    typeList: TypeList
  obj.add(newEmptyNode())
  case className.kind:
  of nnkIdent:
    typeName = className
    obj.add(newEmptyNode())
    code.add newLit(typeName.strVal)
  of nnkCall:
    #inheritance
    var
      baseType: NimNode
      mode = "public"
    case (className[0]).kind:
    of nnkIdent:
      typeName = className[0]
      code.add newLit(typeName.strVal)
    of nnkBracketExpr:
      error("Generic parameters are not supported", className[0])
    else:
      error("Invalid name: " & repr(className[0]), className[0])
    case (className[1]).kind:
    of nnkIdent, nnkDotExpr:
      baseType = className[1]
    of nnkPragmaExpr:
      baseType = className[1][0]
      mode = repr(className[1][1][0])
      if not(mode in ["private", "protected",  "public"]):
        error("Unknown mode: " & mode, className[1][1][0])
    else:
      error("$1 as base type is not supported." % repr(className[1]), className[1])
    obj.add newTree(
      nnkOfInherit,
      baseType
    )
    code.add(
      newLit(" : $1 " % mode),
      typeList.identify(baseType)
    )
  of nnkBracketExpr:
    error("Generic parameters are not supported", className)
  else:
    error("Invalid name: " & repr(className), className)

  code.add newLit(" {")
  typeNameStr = typeName.strVal
  r = initRand(len(typeNameStr) + ord(typeNameStr[^1]))
  expectKind(definition, nnkStmtList)

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
  obj.add(fields)
  result = quote do:
    type `typeName` {.importcpp, cppNonPod, inheritable, nodecl.} = `obj`
    {.emit: `code`.}
    `functionsToImport`
    `functionsToExport`
  if len(typeList) > 0:
    result.insert(1, typeList.toNimNode())
