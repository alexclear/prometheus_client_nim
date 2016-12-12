import tables, lists, locks, strutils

type
  StatItem = ref object of RootObj

  Counter* = ref object of StatItem
    name: string
    help: string
    value: int

  Histogram* = ref object of StatItem
    name: string
    help: string
    bucketMargins: seq[float]

var
  statLock: Lock
  statList: SinglyLinkedList[StatItem]

method exportMetrics(item: StatItem): string {.base.} =
  result = ""

method exportMetrics(item: Counter): string =
  result = ""
  result = result & "# HELP " & item.name & " " & item.help & "\n"
  result = result & "# TYPE " & item.name & " counter\n"
  result = result & item.name & " " & formatFloat(toFloat(atomicInc(item.value, 0)), ffDecimal, 1) & "\n"

proc newCounter*(name: string, help: string): Counter =
  result = Counter(name: name, help: help, value: 0)
  statLock.acquire()
  statList.prepend(result)
  statLock.release()

proc increment*(obj: var Counter) =
  atomicInc(obj.value)

proc newHistogram*(name: string, help: string, bucketMargins: openArray[float]): Histogram =
  result = Histogram(name: name, help: help, bucketMargins: @bucketMargins)
  statLock.acquire()
  statList.prepend(result)
  statLock.release()

proc observe*(obj: var Histogram, value: float) =
  echo "Observing...\n"

method exportMetrics(item: Histogram): string =
  result = ""
  result = result & "# HELP " & item.name & " " & item.help & "\n"
  result = result & "# TYPE " & item.name & " histogram\n"

proc exportAllMetrics*(): string =
  result = ""
  for statItem in items(statList):
    result = result & statItem.exportMetrics()

initLock(statLock)
