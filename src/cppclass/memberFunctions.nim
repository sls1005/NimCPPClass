#Included by cppclass.nim
var
  func1 = copy(def)
  func2 = copy(func1)
  call = newLit("(#.$1(@))")
  constructor = false
  destructor = false
  operator = false
  star = false
  procName, typeName: NimNode
  funcName: string
let
  returnType = def.params[0]
  #static[T] and lent T are not supported
if (def[0]).kind == nnkPostfix:
  assert repr(def[0][0]) == "*"
  procName = copy(def[0][1])
  star = true
else:
  procName = copy(def[0])

if not empty(def[2]):
  error("Generic parameters are not supported.", def[2])

case procName.kind:
of nnkAccQuoted:
  if len(procName) == 2:
    if repr(procName[0]) == "~" and repr(procName[1]) == classNameStr:
      destructor = true
      funcName = "~" & classNameStr
  elif repr(procName[0]) == classNameStr:
    constructor = true
    funcName = classNameStr
  if not constructor and not destructor:
    operator = true
    include ./operators
of nnkIdent:
  funcName = repr(procName)
  if funcName == classNameStr:
    constructor = true
else:
  error("invalid name: " & repr(procName), def[0])

if not empty(returnType):
  if constructor:
    error("A constructor cannot have a return type.", returnType)
  if destructor:
    error("A destructor cannot have a return type.", returnType)

case returnType.kind:
of nnkEmpty:
  typeName = (
    if constructor or destructor:
      newLit("")
    else:
      newLit("void")
  )
of nnkIdent:
  if repr(returnType) == "void":
    typeName = newLit("void")
  else:
    typeName = returnType
else:
  if len(returnType) > 1:
    if repr(returnType[0]) in ["static", "lent"]:
      error("$1 is not supported." % repr(returnType), returnType)
  let t = repr(returnType)
  if t in typeList:
    typeName = typeList[t]
  else:
    typeName = genSym(nskType)
    types.add newTree(
      nnkTypeDef,
      typeName,
      newEmptyNode(),
      returnType
    )
    typeList[t] = typeName

code.add(typeName)
code.add newLit(" $1(" % funcName)

if len(def.params) > 1:
  var flag = true
  for parameter in def.params[1..^1]:
    let parameterType = parameter[^2]
    var parameterNames: seq[string]
    for p in parameter[0..^3]:
      parameterNames.add(repr(p))
    case parameterType.kind:
    of nnkEmpty:
      if len(parameterNames) > 1:
        error("$1 and $2 need a type.".format((parameterNames[0..^2]).join(", "), parameterNames[^1]), parameterType)
      else:
        error("$1 needs a type." % parameterNames[0], parameterType)
    of nnkIdent:
      if repr(parameterType) == "void":
        typeName = newLit("void")
      else:
        typeName = parameterType
    else:
      if len(parameterType) > 1:
        if repr(parameterType[0]) == "static":
          error("$1 is not supported." % repr(parameterType), parameterType)
      let t = repr(parameterType)
      if t in typeList:
        typeName = typeList[t]
      else:
        typeName = genSym(nskType)
        types.add newTree(
          nnkTypeDef,
          typeName,
          newEmptyNode(),
          parameterType
        )
        typeList[t] = typeName
    for n in parameterNames:
      if flag:
        flag = false
      else:
        code.add newLit(", ")
      code.add(
        typeName,
        newLit(" " & n)
      )

code.add newLit("); ")

if not constructor and not destructor: #import
  if operator:
    if star:
      func1[0][1] = procName
    else:
      func1[0] = procName
  (func1[3]).insert(
    1, newIdentDefs(
      genSym(nskParam),
      newTree(nnkVarTy, className)
    )
  )
  let importing = quote do:
    {.importcpp: `call`, nodecl, used.}
  for i in 0 .. 2:
    func1.addPragma(importing[i])
  func1[6] = newEmptyNode()
  functionsToImport.add(func1)

if not empty(def[^1]): #implement
  let
    wholeName = newLit(classNameStr & "::" & funcName)
    symbol = "_$1_$2$3".format(
      classNameStr, (
      if operator:
        "operator" & $(ord(funcName[^1]))
      elif destructor:
        $(ord('~')) & classNameStr
      else:
        funcName
      ),
      r.next()
    )
    declaration = (
      if constructor or destructor:
        "$2$3"
      else:
        "$1 $2$3"
    )
    preventDoubleDeclaration = newLit(fmt"""
#ifdef {symbol}
  {declaration}
  #undef {symbol}
#else
  #define {symbol}
#endif
""")
    exporting = quote do:
      {.exportcpp: `wholeName`, codegenDecl: `preventDoubleDeclaration`, used, cdecl.}
      #the undocumented pragma
    this = quote do:
      var this {.nodecl, used, importcpp: "this", inject, global.}: ptr `className`
      #Because {.nodecl.} doesn't work on local variables
  for i in 0 .. 3:
    func2.addPragma(exporting[i])
  (func2[6]).insert(0, this)
  func2[0] = genSym(nskProc)
  #The incomplete form is invisible from Nim.
  functionsToExport.add(func2)
