#Included by cppclass.nim
expectKind(def[1], nnkStmtList)
let
  field = def[0]
  fieldType = def[1][0]
  member = field.strVal
var 
  memberType: NimNode

case fieldType.kind:
of nnkIdent:
  memberType = fieldType
else:
  memberType = typeList.identify(fieldType)

fields.add newIdentDefs(
  field,
  fieldType
)

code.add(
  memberType,
  newLit(" $1; " % member)
)
