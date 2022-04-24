#Included by cppclass.nim
var field, fieldType, value: NimNode
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

let
  member = field.strVal
  memberType = typeList.identify(fieldType)

fields.add newIdentDefs(
  field,
  fieldType
)
code.add(
  memberType,
  newLit(" " & member)
)
if not empty(value):
  code.add(
    newLit(" = "),
    value
  )
code.add newLit(";")