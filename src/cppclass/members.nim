#Included by cppclass.nim
expectKind(def[1], nnkStmtList)
let
  member = repr(def[0])
  memberType = def[1][0]
var
  typeName: NimNode
case memberType.kind:
of nnkIdent:
  typeName = memberType
else:
  let t = repr(memberType)
  if t in typeList:
    typeName = typeList[t]
  else:
    typeName = genSym(nskType)
    types.add newTree(
      nnkTypeDef,
      typeName,
      newEmptyNode(),
      memberType
    )
    typeList[t] = typeName

fields.add newIdentDefs(
  ident(member),
  memberType
)

code.add(
  typeName,
  newLit(" $1; " % member)
)
