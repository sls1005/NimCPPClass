import std/macros

type TypeList* = object
  types, names: seq[NimNode]

proc len*(self: TypeList): int {.compileTime.} =
  result = len(self.types)
  assert result == len(self.names)

proc identify*(self: var TypeList, typ: NimNode): NimNode {.compileTime.} =
  if typ.kind in [nnkIdent, nnkSym]:
    return typ
  for i, t in self.types:
    if t == typ:
      let name = self.names[i]
      return name
  let name = genSym(nskType)
  self.types.add(typ)
  self.names.add(name)
  return name

proc toNimNode*(self: sink TypeList): NimNode {.compileTime.} =
  result = newNimNode(nnkTypeSection)
  for i in 0 ..< len(self):
    result.add newTree(
      nnkTypeDef,
      self.names[i],
      newEmptyNode(),
      self.types[i]
    )

