#Included by cppclass.nim
var
  staticMember = false
  sizedInBits = false
  sizeInBits: int64
  field, fieldType, fieldWithPragma, value: NimNode

case def.kind:
of nnkAsgn:
  field = def[0]
  #A member can have a default value if it is of an AtomType (like int or float).
  value = valueList.identify(def[1])
  fieldType = newCall(bindSym("typeof"), value)
of nnkCall:
  expectKind(def[1], nnkStmtList)
  field = def[0]
  if (def[1][0]).kind == nnkAsgn:
    fieldType = def[1][0][0]
    value = valueList.identify(def[1][0][1])
  else:
    fieldType = def[1][0]
    value = newEmptyNode()
else:
  error("Invalid statement: " & repr(def), def)

if field.kind == nnkPragmaExpr:
  for p in field[1]:
    case p.kind:
    of nnkIdent:
      if p.strVal == "static":
        staticMember = true
      else:
        error("Unknown pragma: " & repr(p), field[1])
    of nnkExprColonExpr:
      expectKind(p[0], nnkIdent)
      expectKind(p[1], nnkIntLit)
      if (p[0]).strVal == "bitsize":
        sizedInBits = true
        sizeInBits = (p[1]).intVal
      else:
        error("Unknown pragma: " & repr(p), field[1])
    else:
      error("Unknown pragma: " & repr(p), field[1])
  if staticMember and sizedInBits:
    error("A static member with bit-size is invalid.", field[1])
  elif sizedInBits:
    fieldWithPragma = field
  field = field[0]

let
  member = field.strVal
  memberType = typeList.identify(fieldType)

if staticMember:
  let
    varName = genSym(nskVar)
    wholeName = newLit(typeNameStr & "::" & member)
    declaration = (
      if empty(value):
        quote do:
          var `varName` {.exportc: `wholeName`.}: `fieldType`
      else:
        quote do:
          var `varName` {.exportc: `wholeName`.}: `fieldType` = `value`
    )
  variables.add(declaration[0])
  code.add(
    newLit("static "),
    memberType,
    newLit(" " & member)
  )
else:
  code.add(
    memberType,
    newLit(" " & member)
  )
  if sizedInBits:
    code.add(
      newLit(" : " & $sizeInBits)
    )
  if not empty(value):
    code.add(
      newLit(" = "),
      value
    )

code.add newLit("; ")
if sizedInBits:
  fields.add newIdentDefs(
    fieldWithPragma,
    fieldType
  )
else:
  fields.add newIdentDefs(
    field,
    fieldType
  )
