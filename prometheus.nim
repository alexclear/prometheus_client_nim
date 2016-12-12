import tables

type
  Counter* = object of RootObj
    name: string
    help: string
    value: int

proc newCounter*(name: string, help: string): Counter =
  result = Counter(name: name, help: help, value: 0)

proc increment*(obj: var Counter) =
  atomicInc(obj.value)
