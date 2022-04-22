#Included by cppclass.nim
expectKind(def[1], nnkStmtList)
let
  field = def[0]
  fieldType = def[1][0]
  member = field.strVal
  memberType = typeList.identify(fieldType)

fields.add newIdentDefs(
  field,
  fieldType
)

code.add(
  memberType,
  newLit(" $1; " % member)
)
