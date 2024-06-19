#[ 
  This module contains the functions for the operation of 
  the cookie-tunnel called at the end of proj.startup.nim. 

]#


import strutils, json
import g_templates

var versionfl: float = 0.11

var debugbo: bool = true

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: echo messagest




#func split(s: string; sep: char; maxsplit: int = -1): seq[string] {.....}


proc split2*(st: string, sepst: string, maxsplit: int = -1): seq[string] =
  # As strutils.split, but liberalizing letter-case for the seperator sepst
  # Tested are: WORD, word and Word

  var sepsmallst, sepbigst, sepcapst: string
  
  sepsmallst = sepst.toLowerAscii()
  sepbigst = sepst.toUpperAscii()
  sepcapst = sepsmallst.capitalizeAscii()


  if st.contains(sepst):
    result = split(st, sepst, maxsplit)
  elif st.contains(sepsmallst):
    result = split(st, sepsmallst, maxsplit)
  elif st.contains(sepbigst):
    result = split(st, sepbigst, maxsplit)
  elif st.contains(sepcapst):
    result = split(st, sepcapst, maxsplit)

  


proc convertSequenceToFile*(filepathst: string, lisq: seq[string]) = 
  
  withFile(txtfl, filepathst, fmWrite):  # special colon
    for item in lisq:
      txtfl.writeLine(item)



proc convertSequenceToText(lisq: seq[string]): string = 
  # untested..
  var tekst: string = ""

  for filest in lisq:
    tekst &= filest & "\p"

  result = tekst
  


proc zipTwoSeqsToOne*(firstsq: seq[string], secondsq: seq[string] = @[]): seq[array[2, string]] = 
  var 
    newSeq: seq[array[2, string]]
    countit: int = 0

  if secondsq == @[]:
    for elemst in firstsq:
      newSeq.add([elemst, elemst])
  else:
    for elemst in firstsq:
      newSeq.add([elemst, secondsq[countit]])
      countit += 1

  result = newSeq



proc filterIsMatching*(tekst, searchtermst: string, testingbo: bool = false, itemnumberst: string = ""): string = 

  #[
  The searchterms form the filter.
  result types:
  - If filter matches the text: yes
  - if filter doesnt match: no
  - if filter is invalid: error-message

  currently supported operators:
  - a = and, o = or, n = (and) not
  - using no operators: will be treated as 'and'

  ADAP FUT:
  -add phrases
  -enable parentheses
  -enable alternative operators (more common ones)
  ]#


  var 
    termsq, splitallsq, operatorsq: seq[string]
    first_operator_missingbo: bool = true
    abortbo: bool = false
    foundsq: seq[bool] = @[]
    composbo: bool

  result = ""
  splitallsq = searchtermst.split()
  for it, elemst in splitallsq:
    if elemst.len > 1:
      termsq.add(elemst)
    elif elemst.len == 1:
      operatorsq.add(elemst)
      if it == 0:
        first_operator_missingbo = false

  if termsq.len == 0:
    result = "No search-terms entered.."
    abortbo = true
  elif termsq.len > 0:
    if termsq.len == operatorsq.len + 1:
      if first_operator_missingbo:
        operatorsq.insert("", 0)
      else:
        result = "Invalid search-terms; please re-enter"
        abortbo = true
    if operatorsq.len == 0:
      # suppose and-ops are meant and add them
      for thing in termsq:
        operatorsq.add("a")
      operatorsq.add("a")

  if testingbo:
    if result == "": result = "filter_ok"

  if not (abortbo or testingbo):
    #var operatorsq: seq[char] = @['a', 'n', 'a', 'o']

    # test if the search-terms are present in the text
    for termst in termsq:
      if tekst.contains(termst):
        foundsq.add(true)
      else:
        foundsq.add(false)


    # create the logical expression based on the found results
    for it, valbo in foundsq:
      if it < operatorsq.len:
        if it == 0:
          case operatorsq[it]
          of "n":
            composbo = not valbo
          else:
            composbo = valbo
        else:
          case operatorsq[it]
          of "a":      
            composbo = composbo and valbo
          of "o":
            composbo = composbo or valbo
          of "n":
            composbo = composbo and not valbo
          else:
            echo "invalid operator.."
      else:
        echo "cannot be bigger.."
      #echo it
    #echo composbo

    if composbo:
      result = "yes"
    else:
      echo "No match nr. " & itemnumberst
      result = "no"


proc countIsFactorOf*(countit, factorit: int): bool = 

  #[
    Use for intermittent messages like:
    if count is factor of 100:
      echo count
  ]#

  if (countit mod factorit) == 0:
    result = true
  else:
    result = false




proc concatenateFiles*(filelisq: seq[string], newfilepathst: string) = 

  #[
    Create a new file with the contents from all the files in filelisq
  ]#

  var 
    curfilest, allfilest: string
    fileob, newfileob: File

  echo $filelisq.len, " files found to concatenate.\p"

  # preclear the file
  if open(newfileob, newfilepathst, fmWrite):
    newfileob.close()

  # open the new file for appending
  if open(newfileob, newfilepathst, fmAppend):

    for filepathst in filelisq:
      if open(fileob, filepathst, fmRead):
        echo "...concatenating: " & filepathst
        curfilest = fileob.readAll()
        newfileob.write(curfilest)
        fileob.close()
      else:
        echo filepathst, " could not be found!"
    echo "\pWritten to: " & newfilepathst
    newfileob.close()

  else:
    echo newfilepathst,  " could not be opened!"




when isMainModule:

  #echo split2("do Select after this", "SELECT")


  #[ 
  var skiplistsq = @["through", "Through", "between", "because", "various", "against", 
                  "important", "something", "another", "themselves", "currently",
                  "particular", "possible", "without", "several", "certain"]

  convertSequenceToFile("fq_noise_word.dat", skiplistsq)
 ]#

 #echo zipTwoSeqsToOne(@["1","2","3"], @["a","b","c"])

  if false:
     var 
      tekst: string = "appel en een peer"
      searchtermst: string = "banaan n citroen"

     echo filterIsMatching(tekst, searchtermst)

  if true:
    concatenateFiles(@["test01.nim","test02.nim"], "testsamen.nim")

