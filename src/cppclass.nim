import std/[macros, random, strformat, strutils]
import ./cppclass/nameLists

when not defined(cpp):
  {.error: "This can only be used with the C++ backend.".}
elif defined(clang):
  {.passC: "-Wno-duplicate-decl-specifier".}

proc empty(node: NimNode): bool {.compileTime.} =
  node.kind == nnkEmpty

proc `kind=`(node: var NimNode, kind: NimNodeKind) =
  var res = newNimNode(kind)
  for child in node:
    res.add(child)
  node = res

macro cppclass*(className, definition: untyped): untyped =
  var
    typeName = className
    functionsToImport = newStmtList()
    functionsToExport = newStmtList()
    obj = newNimNode(nnkObjectTy)
    fields = newNimNode(nnkRecList)
    baseType = newEmptyNode()
    mode = "" #mode of inheritance, default to private
    final = false
    variables = newNimNode(nnkVarSection)
    typeList = initNameList(nskType)
    valueList = initNameList(nskConst)
    code = newTree(
      nnkBracket,
      newLit("class ") #C++ code to emit
    )
    r: Rand
  obj.add(newEmptyNode())
  if typeName.kind == nnkPragmaExpr:
    for p in typeName[1]:
      case p.kind:
      of nnkIdent:
        if p.strVal == "final":
          final = true
        else:
          error("Unknown pragma: " & repr(p), typeName[1])
      else:
        error("Unknown pragma: " & repr(p), typeName[1])
    typeName = typeName[0]
  if typeName.kind == nnkCall:
    #inheritance
    case (typeName[1]).kind:
    of nnkIdent, nnkDotExpr:
      baseType = copy(typeName[1])
    of nnkPragmaExpr:
      baseType = copy(typeName[1][0])
      mode = repr(typeName[1][1][0])
      if not(mode in ["private", "protected",  "public"]):
        error("Unknown mode: " & mode, typeName[1][1][0])
    else:
      error("$1 as base type is not supported." % repr(typeName[1]), typeName[1])
    typeName = typeName[0]

  case typeName.kind:
  of nnkIdent:
    code.add newLit(typeName.strVal)
  of nnkBracketExpr:
    error("Generic parameters are not supported", typeName)
  else:
    error("Invalid name: " & repr(typeName), typeName)

  if final:
    code.add(newLit(" final"))
  if empty(baseType):
    obj.add(newEmptyNode())
  else:
    obj.add newTree(
      nnkOfInherit,
      baseType
    )
    code.add(
      newLit(" : $1 " % mode),
      typeList.identify(baseType)
    )

  code.add newLit(" {")
  let typeNameStr = typeName.strVal
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
          of nnkProcDef, nnkFuncDef, nnkMethodDef:
            include ./cppclass/memberFunctions
          of nnkAsgn, nnkCall:
            include ./cppclass/members
          of nnkPragma:
            let pragmas = def
            include ./cppclass/pragmas
          of nnkDiscardStmt:
            discard
          else:
            error("Invalid statement: " & repr(def), def)
      of "cppclass":
        error("Nested classes are not supported.", node[0])
      else:
        let def = node
        include ./cppclass/members
    of nnkProcDef, nnkFuncDef, nnkMethodDef:
      let def = node
      include ./cppclass/memberFunctions
    of nnkAsgn:
      let def = node
      include ./cppclass/members
    of nnkPragma:
      let pragmas = node
      include ./cppclass/pragmas
    of nnkDiscardStmt:
      discard
    else:
      error("Invalid statement: " & repr(node), node)
  let form = (
    if final:
      ident("final")
    else:
      ident("inheritable")
  )
  code.add newLit("};")
  obj.add(fields)
  result = quote do:
    type `typeName` {.importcpp, cppNonPod, nodecl, `form`.} = `obj`
    {.emit: `code`.}
    `functionsToImport`
    `functionsToExport`
  if len(typeList) > 0:
    result.insert(1, typeList.toNimNode())
  if len(variables) > 0:
    result.insert(0, variables)
  if len(valueList) > 0:
    result.insert(0, valueList.toNimNode())
