import std/macros

type TypeList* = seq[array[2, NimNode]]

proc identify*(self: var TypeList, typ: NimNode): NimNode {.compileTime.} =
  if typ.kind in [nnkIdent, nnkSym]:
    return typ
  for record in self:
    if record[1] == typ:
      return record[0]
  let name = genSym(nskType)
  self.add([name, typ])
  return name

proc toNimNode*(self: TypeList): NimNode {.compileTime.} =
  result = newNimNode(nnkTypeSection)
  for record in self:
    result.add newTree(
      nnkTypeDef,
      record[0], #name
      newEmptyNode(),
      record[1] #type
    )
