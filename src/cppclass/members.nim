#Included by cppclass.nim
var
  staticMember = false
  field, fieldType, value: NimNode
#A member can have a default value if it is of an AtomType (like int or float).
case def.kind:
of nnkAsgn:
  field = def[0]
  value = valueList.identify(def[1])
  fieldType = newCall(ident("typeof"), value)
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
    else:
      error("Unknown pragma: " & repr(p), field[1])
  field = field[0]
if fieldType.kind == nnkPragmaExpr:
  for p in fieldType[1]:
    case p.kind:
    of nnkIdent:
      if p.strVal == "static":
          staticMember = true
      else:
        error("Unknown pragma: " & repr(p), fieldType[1])
    else:
      error("Unknown pragma: " & repr(p), fieldType[1])
  fieldType = fieldType[0]

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
  if not empty(value):
    code.add(
      newLit(" = "),
      value
    )

code.add newLit("; ")
fields.add newIdentDefs(
  field,
  fieldType
)
