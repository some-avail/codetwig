#[ Exchange disk- and file-structures with nim-structures 
]#

import strutils, algorithm
import os
import g_templates


var versionfl: float = 0.12
var 
  debugbo: bool = false
  wispbo: bool = true

  
template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



proc writeFilePatternToSeq*(filestartwithst: string): seq[string] = 

#[ Write the files from pattern in the current dir to the sequence and
 return that]#

  var
    filelisq: seq[string]
    filenamest: string
  
  # walk thru the file-iterator and sequence the right file(names)
  wisp("getAppDir = ", getAppDir())
  for kind, path in walkDir(getAppDir()):
    if kind == pcFile:
      filenamest = extractFileName(path)
      if len(filenamest) > len(filestartwithst):
        if filenamest[0..len(filestartwithst) - 1] == filestartwithst:
          #log(filenamest)
          #wisp(filenamest)
          filelisq.add(filenamest)

  result = filelisq



proc getPatternLocation(starred_patternst: string): string = 
  #[ 
  determine the location of the wordpattern with regard to 
  the location of the star
  ]#

  var locationit: int = 0

  if starred_patternst[0..0] == "*":
    locationit += 1
  
  if starred_patternst[starred_patternst.len-1..starred_patternst.len-1] == "*":
    locationit += 10

  case locationit
  of 1:
    result = "right"
  of 10:
    result = "left"
  of 11:
    result = "middle"
  else:
    result = "star_missing"



proc writeFilePatternToSeq2*(starred_patternst, source_dirst: string): seq[string] = 
#[ Write the files from a *-pattern in the current dir to the sequence and
 return that; options:
  -start with / left-part: pattern*
  -end with / right-part: *pattern
  -in the middle: *pattern*

  UNDER CONSTRUCTION
 ]#

  var
    filelisq: seq[string]
    filenamest, patternlocatst, strippedpatternst: string
    patlengthit: int
  
  patternlocatst = getPatternLocation(starred_patternst)
  strippedpatternst = starred_patternst.strip(chars = {'*'})
  patlengthit = strippedpatternst.len
  log(strippedpatternst)
  log(getAppDir())
  log(patternlocatst)

  # walk thru the file-iterator and sequence the right file(names)
  for kind, path in walkDir(source_dirst):
    if kind == pcFile:
      filenamest = extractFileName(path)
      if len(filenamest) > len(strippedpatternst):
        case patternlocatst:
        of "left":
          if filenamest.startswith(strippedpatternst):
            log(filenamest)
            filelisq.add(filenamest)
        of "right":
          if filenamest.endswith(strippedpatternst):
            log(filenamest)
            filelisq.add(filenamest)
        elif patternlocatst == "middle":
          if filenamest.contains(strippedpatternst):
            log(filenamest)
            filelisq.add(filenamest)

        else:
          log("else")
    sort(filelisq)
  result = filelisq



proc addShowValuesToSeq*(listsq: seq[string], startingclipst, substitutionst: string): 
                                        seq[array[2, string]] = 
  #[
  From the real file-names-seq create a second seq with adjusted names to show in the 
  select-control and zip them into a double array
  ]#

  var 
    valuelisq: seq[array[2, string]]
    shownamest: string

  for filest in listsq:
    shownamest = substitutionst & filest[len(startingclipst) .. len(filest) - 1]
    valuelisq.add([filest, shownamest])

  result = valuelisq




proc convertFileToSequence*(filepathst, skipst: string): seq[string] = 
#[ 
  Convert a file to a Nim-sequence.
  Skip lines with the value skipst.
 ]#

  var lisq: seq[string]

  withFile(txt, filepathst, fmRead):  # special colon
    for line in txt.lines:
      #echo line
      if line.len > 0:
        if line.len < skipst.len:
          lisq.add(line)
        else:
          if line[0..skipst.len - 1] != skipst:
            lisq.add(line)

  result = lisq




proc convertMultFilesToSeq*(filepathsq: seq[string], skipst: string): seq[string] = 

#[ 
  Convert a file to a Nim-sequence.
  Skip lines with the value skipst.
 ]#

  var lisq: seq[string]

  for filest in filepathsq:
    withFile(txt, filest, fmRead):  # special colon
      for line in txt.lines:
        #echo line
        if line.len > 0:
          if line.len < skipst.len:
            lisq.add(line)
          else:
            if line[0..skipst.len - 1] != skipst:
              lisq.add(line)

  result = lisq



when isMainModule:
  #echo writeFilePatternToSeq("freek")
  #echo "-------------------"
  #echo addShowValuesToSeq(writeFilePatternToSeq("freek"), "freek", "*")


  # echo convertFileToSequence("lists/parent_links.dat", "#")
  #echo convertMultFilesToSeq(@["noise_words_dutch_generic.dat", "noise_words_english_generic.dat"], ">>>")

  #echo getPatternLocation("*pietje*")
  echo writeFilePatternToSeq2("freek*", ".")
  echo writeFilePatternToSeq2("*.dat", ".")
  echo writeFilePatternToSeq2("*english*", ".")

