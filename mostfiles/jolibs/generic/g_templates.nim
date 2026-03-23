import std/[times, strutils]

var versionfl: float = 0.13


var wispbo* = true



template wisp_old*(wordsq: varargs[string, `$`]) =
  # works only for non-release-compilation; thats ok
  var
    filepathst, filenamest, modulest, procnamest: string
    pathsq: seq[string]

  if wispbo:
    let tob = getStackTraceEntries()      # a proc from the system-module

    if tob.len > 0:       # needed for release-compilation
      filepathst = $tob[tob.len - 1].filename
      pathsq = filepathst.split("/")
      filenamest = pathsq[pathsq.len - 1]
      modulest = filenamest[0..filenamest.len - 5]
      procnamest = $tob[tob.len - 1].procname
      echo "==>  ", modulest, "_", procnamest, "  echos: ",  wordsq



template getTrace*(wordsq: varargs[string, `$`]) =
  # works only for non-release-compilation; thats ok
  var
    filepathst, filenamest, modulest, procnamest: string
    pathsq: seq[string]
    lineit: int

  if wispbo:
    let tob = getStackTraceEntries()      # a proc from the system-module

    if tob.len > 0:       # needed for release-compilation
      echo "counting ", tob.len, " ", type(itemob)
      for itemob in tob:
        #echo itemob

        filepathst = $itemob.filename
        pathsq = filepathst.split("/")
        filenamest = pathsq[pathsq.len - 1]
        procnamest = $itemob.procname
        lineit = itemob.line
        echo filenamest.alignLeft(25) & ($lineit).alignLeft(10) & procnamest.alignLeft(25)



template wisp*(wordsq: varargs[string, `$`]) =
  # works only for non-release-compilation; thats ok
  var
    filepathst, filenamest, modulest, procnamest: string
    hfilepathst, hfilenamest, hmodulest, hprocnamest: string    
    pathsq, hpathsq: seq[string]
    messagest: string

  if wispbo:
    let tob = getStackTraceEntries()      # a proc from the system-module

    if tob.len > 0:       # needed for release-compilation
      filepathst = $tob[tob.len - 1].filename
      pathsq = filepathst.split("/")
      filenamest = pathsq[pathsq.len - 1]
      modulest = filenamest[0..filenamest.len - 5]
      procnamest = $tob[tob.len - 1].procname

      if tob.len > 1:
        hfilepathst = $tob[tob.len - 2].filename
        hpathsq = hfilepathst.split("/")
        hfilenamest = hpathsq[hpathsq.len - 1]
        hmodulest = hfilenamest[0..hfilenamest.len - 5]
        hprocnamest = $tob[tob.len - 2].procname

      messagest = wordsq.join(" ")
      #echo ""
      echo "==>  ", hprocnamest, "---", procnamest, "  echos:   ",  messagest




template withFile*(fileob, filenamest, mode, actions: untyped): untyped =
  var fileob: File
  if open(fileob, filenamest, mode):
    try:
      actions
    finally:
      close(fileob)
  else:
    echo("withFile cannot open: " & filenamest)



template withFileAdvanced*(fileob, filenamest, mode, actions: untyped): untyped =
  
  var fileob: File
  if open(fileob, filenamest, mode):
    try:
      actions

    except:
      let errob = getCurrentException()
      echo "\p******* Unanticipated error ******* \p" 
      echo repr(errob) & "\p****End exception****\p"
    finally:
      close(fileob)
  else:
    echo("withFileAdvanced cannot open: " & filenamest)




#[ 
Below are some timing-functions that may or may not
work. I find the cpuTime function unreliable, for example
it doesnt register a sleep-function. 
Finally in timeCop i revert to the now-function, which seems
accurate.
 ]#



proc doWork(x: int) =
  var n = 0
  for i in 0 .. 10000000 * x:
    n += i


template timeStuff*(statement: untyped): string =
  let t0 = cpuTime()
  statement
  formatFloat(cpuTime() - t0, ffDecimal, precision = 3)


template timeThings*(statement: untyped) =
  # easiest to use
  let t0 = cpuTime()
  statement
  echo formatFloat(cpuTime() - t0, ffDecimal, precision = 3), " s."



template timeNeatly(statement: untyped): float =
  let t0 = cpuTime()
  statement
  cpuTime() - t0


template timeCop*(statement: untyped) = 
  # measures real-time instead of cpu-time
  let t0 = now()
  statement
  let t1 = now()
  echo t1 - t0




when isMainModule:
  #[ 
  withFile(txt, "test_templ.txt", fmWrite):  # special colon
    txt.writeLine("line 1")
    txt.writeLine("line 2")
 ]#
  
  #echo "Time = ", timeStuff(doWork(100)), " s"
  #echo "Time = ", timeNeatly(sleep(2000)).formatFloat(ffDecimal, precision = 3), " s"

#[ 
  let t0 = cpuTime()
  echo t0
  #sleep(2000)
  doWork(10)
  let t1 = cpuTime()
  echo t1
  echo t1 - t0
  echo formatFloat(t1 - t0, ffDecimal, precision = 3), " s."
 ]#

#[ 
  let t0 = now()
  echo t0
  sleep(2000)
  #doWork(10)
  let t1 = now()
  echo t1
  echo t1 - t0
  #echo formatFloat(t1 - t0, ffDecimal, precision = 3), " s."
 ]#


  timeCop():
    #doWork(10)
    sleep(2000)
