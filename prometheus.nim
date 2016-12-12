import tables, lists, locks, strutils

type
  StatItem = ref object of RootObj

  Counter* = ref object of StatItem
    name: string
    help: string
    value: int

var
  statLock: Lock
  statList: SinglyLinkedList[StatItem]

method exportMetrics(item: StatItem): string {.base.} =
  result = ""

method exportMetrics(item: Counter): string =
  result = ""
  result = result & "# HELP " & ((Counter)(item)).name & " " & ((Counter)item).help & "\n"
  result = result & "# TYPE " & ((Counter)(item)).name & " counter\n"
  result = result & ((Counter)(item)).name & " " & formatFloat(toFloat(item.value), ffDecimal, 1)

proc newCounter*(name: string, help: string): Counter =
  result = Counter(name: name, help: help, value: 0)
  statLock.acquire()
  statList.prepend(result)
  statLock.release()

proc increment*(obj: var Counter) =
  atomicInc(obj.value)

proc exportAllMetrics*(): string =
  result = ""
  for statItem in items(statList):
    result = result & statItem.exportMetrics()

initLock(statLock)
