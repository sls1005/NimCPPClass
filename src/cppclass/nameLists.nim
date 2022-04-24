import std/macros

type NameList* = object
  kind: NimSymKind
  data: seq[array[2, NimNode]]

proc initNameList*(kind: NimSymKind): NameList {.compileTime.} =
  result.kind = kind

proc len*(self: NameList): int =
  len(self.data)

proc identify*(self: var NameList, value: NimNode): NimNode {.compileTime.} =
  if value.kind in [nnkIdent, nnkSym]:
    case self.kind:
    of nskConst:
      return newLit(value.strVal)
    of nskType:
      return value
    else:
      error("Unknown kind: " & repr(self.kind))
  for record in self.data:
    if record[1] == value:
      return record[0]
  let name = genSym(self.kind)
  self.data.add([name, value])
  return name

proc toNimNode*(self: NameList): NimNode {.compileTime.} =
  var k1, k2: NimNodeKind
  case self.kind:
  of nskConst:
    k1 = nnkConstSection
    k2 = nnkConstDef
  of nskType:
    k1 = nnkTypeSection
    k2 = nnkTypeDef
  else:
    error("Unknown kind: " & repr(self.kind))
  result = newNimNode(k1)
  for record in self.data:
    result.add newTree(
      k2,
      record[0], #name
      newEmptyNode(),
      record[1] #value
    )