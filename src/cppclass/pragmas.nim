for p in pragmas:
  case p.kind:
  of nnkExprColonExpr:
    expectKind(p[0], nnkIdent)
    if repr(p[0]) == "emit":
      case (p[1]).kind:
      of nnkStrLit, nnkTripleStrLit:
              code.add(p[1])
      of nnkBracket:
        for c in p[1]:
          code.add(c)
      else:
        error("Cannot emit: " & repr(p[1]), p[1])
    else:
      error(repr(p[0]) & " is not supported.", p[0])
  else:
    error(repr(p) & " is not supported.", p)
