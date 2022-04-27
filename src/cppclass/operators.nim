#Included by memberFunctions.nim
var op: string
case len(procName):
of 1:
  op = repr(procName[0])
  funcName = "operator " & op
of 2:
  case repr(procName[0]):
  of "operator":
    op = repr(procName[1])
    funcName = "operator " & op
    procName = newTree(nnkAccQuoted, procName[1])
  of "new", "delete":
    op = repr(procName[0]) & repr(procName[1])
    funcName = "operator " & op
of 3:
  assert repr(procName[0]) == "operator"
  op = repr(procName[1]) & repr(procName[2])
  funcName = "operator " & op
  procName = newTree(nnkAccQuoted, procName[1], procName[2])
else:
  error("Not supported.")

case len(def.params):
of 1:
  call = newLit("($1(#))")
of 2:
  if op == "[]":
    call = newLit("(#[#])")
  else:
    call = newLit("((#)$1(#))")
else:
  error("Not supported.")
