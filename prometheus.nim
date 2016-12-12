import tables, lists, locks, strutils

type
  StatItem = ref object of RootObj

  Counter = ref object of StatItem
    name: string
    help: string
    value: int

  Histogram = ref object of StatItem
    name: string
    help: string
    bucketMargins: seq[float]

  Prometheus = ref object of RootObj
    statLock: Lock
    statList: SinglyLinkedList[StatItem]

method exportMetrics(item: StatItem): string {.base.} =
  result = ""

method exportMetrics(item: Counter): string =
  result = ""
  result = result & "# HELP " & item.name & " " & item.help & "\n"
  result = result & "# TYPE " & item.name & " counter\n"
  result = result & item.name & " " & formatFloat(toFloat(atomicInc(item.value, 0)), ffDecimal, 1) & "\n"

proc newPrometheus*(): Prometheus =
  result = Prometheus()
  initLock(result.statLock)

proc newCounter*(obj: Prometheus, name: string, help: string): Counter =
  result = Counter(name: name, help: help, value: 0)
  obj.statLock.acquire()
  obj.statList.prepend(result)
  obj.statLock.release()

proc increment*(obj: var Counter) =
  atomicInc(obj.value)

proc newHistogram*(obj: Prometheus, name: string, help: string, bucketMargins: openArray[float]): Histogram =
  result = Histogram(name: name, help: help, bucketMargins: @bucketMargins)
  obj.statLock.acquire()
  obj.statList.prepend(result)
  obj.statLock.release()

proc observe*(obj: var Histogram, value: float) =
  echo "Observing...\n"

method exportMetrics(item: Histogram): string =
  result = ""
  result = result & "# HELP " & item.name & " " & item.help & "\n"
  result = result & "# TYPE " & item.name & " histogram\n"

proc exportAllMetrics*(obj: Prometheus): string =
  result = ""
  obj.statLock.acquire()
  for statItem in items(obj.statList):
    result = result & statItem.exportMetrics()
  obj.statLock.release()
