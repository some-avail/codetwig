#[
Load some definitions from webgui_def.nim with data 
from external sources, esp. the config-file:
settings_flashread.conf
]#


import webgui_def
import fr_tools
import strutils
import os
import tables
import algorithm


const versionfl = 0.2

var debugbo: bool = false
  
template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest


# [("calledname", "somelabel", @[["first-value", "first shown value"], ["second-value", "second shown value"]]), 
# ("text-language", "Text-language:", @[["dutch", "Dutch"], ["english", "English"]]), 
# ("taglist", "Pick taglist:", @[["paragraph-only", "Paragraph only"], ["full-list", "Full list"]])]


proc loadTextLangsFromConfig() =

# Load the processing-languages of the dropdown "dropdownsta" of 
# webgui_def.nim from the config-file

  var
    valuelist: string
    sourcelangsq: seq[string]
    langvaluelistsq: seq[array[2, string]]
    tbo: bool = false

  # get the processing-languages from the config-file
  valuelist = readOptionFromFile("text-language", "value-list")
  sourcelangsq = valuelist.split(",,")
  if tbo: echo sourcelangsq


  # generate the new valuelist
  for langst in sourcelangsq:
    if fileExists("parse_" & langst & ".dat"):
      langvaluelistsq.add([langst, capitalizeAscii(langst)])

  if tbo: echo langvaluelistsq
  if tbo: echo "=========="

  # locate and reset the languages from dropdownsta
  if tbo: echo dropdownsta[1]
  dropdownsta[1][2] = langvaluelistsq
  if tbo: echo dropdownsta[1]



proc loadComboFromDir_Old(combobokst, filenamepartst: string) =  
# proc loadComboFromDir() =  
  # Load the combo/dropdown-definition named combobokst in "dropdownsta"
  # of webgui_def.nim with the file-names with namepart filenamepartst 
  # from the current directory

  var
    combovaluelistsq: seq[array[2, string]]
    filenamest: string
    summary_namepartst: string


  # walk thru the file-iterator and sequence the right file(names)
  for kind, path in walkDir(getAppDir()):
    if kind == pcFile:
      filenamest = extractFileName(path)
      if len(filenamest) > 8:
        if filenamest[0..7] == filenamepartst:
          log(filenamest)
          summary_namepartst = "*" & filenamest[7..len(filenamest) - 1]
          combovaluelistsq.add([filenamest, summary_namepartst])
          log(summary_namepartst)


  # locate and reset the summaries from dropdownsta
  log($dropdownsta[3])
  dropdownsta[3][2] = combovaluelistsq
  log($dropdownsta[3])


proc loadComboFromDir(combobokst, filenamepartst: string) =  
# proc loadComboFromDir() =  
  # Load the combo/dropdown-definition named combobokst in "dropdownsta"
  # of webgui_def.nim with the file-names with namepart filenamepartst 
  # from the current directory

  var
    combovaluelistsq: seq[array[2, string]]
    filenamest, fnamest: string
    summary_namepartst: string
    filenamesq: seq[string]


  # walk thru the file-iterator and sequence the right file(names)
  for kind, path in walkDir(getAppDir()):
    if kind == pcFile:
      filenamest = extractFileName(path)

      if len(filenamest) > 8:
        if filenamest[0..7] == filenamepartst:
          log(filenamest)
          filenamesq.add(filenamest)

  filenamesq.sort()
  for fnamest in filenamesq:
    summary_namepartst = "*" & fnamest[7..len(fnamest) - 1]
    combovaluelistsq.add([fnamest, summary_namepartst])
    log(summary_namepartst)

  # locate and reset the summaries from dropdownsta
  log($dropdownsta[3])
  dropdownsta[3][2] = combovaluelistsq
  log($dropdownsta[3])



proc setCheckboxSetFromConfig(setnamest: string) = 
  # Copy the default-values from the config file for checkboxset "setnamest" of webgui_def.nim

  var buttonsq: seq[tuple[name:string, description: string, boolean_state: bool]] = checkboxesta[setnamest]
  # var buttonsq = checkboxesta[setnamest]

  var
    valuelist: string
    valuesq: seq[string]
    tbo: bool = false
    countit: int = 0

  if tbo: echo buttonsq

  # get default-values from config-file
  valuelist = readOptionFromFile(setnamest, "value-list")

  if tbo: echo valuelist

  valuesq = valuelist.split(",,")

  # set the checkbox-values
  for buttontu in buttonsq:
    # buttonsq[countit][2] = parseBool(valuesq[countit])
    checkboxesta[setnamest][countit][2] = parseBool(valuesq[countit])
    countit += 1

  if tbo: echo buttonsq


proc testWalkdir() = 
  for kind, path in walkDir(getAppDir()):
    case kind:
    of pcFile:
      echo "File: ", path
    of pcDir:
      echo "Dir: ", path
    of pcLinkToFile:
      echo "Link to file: ", path
    of pcLinkToDir:
      echo "Link to dir: ", path



loadTextLangsFromConfig()
setCheckboxSetFromConfig("fr_checkset1")
loadComboFromDir("summarylist", "summary_")

 
when isMainModule:
  discard