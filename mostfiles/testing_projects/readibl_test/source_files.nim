#[ 
-implement source-files-module to:
  -be accessible from all modules
  -to limt file-access
 ]#

import strutils, sequtils
import tables
import os
import fr_tools
import algorithm


type
  DataFileType* = enum
    datFileLanguage
    datFileSummary
    datFileAll

  FileSpecs = object of RootObj
    fsName: string
    fsVersion: float

  FilePhase = object of FileSpecs
    phaNameFull: string   # block-header-name
    phaSequenceNum: int   # order-num in phase-list
    phaNameCount: int     # should be 1
    phaItemCount: int     # preferably > 0
    phaHasEmptyItem: bool    # = zero-length line; must be false
    phaEndMarkerFound: bool   # must be true


var
  versionfl:float = 0.25
  textsourcefilesq: seq[string] = @["outer_html.html",
                                  "flashread.html"]

  textsourcefileta* = initTable[string, string]()
  sourcefilestatust*: string = ""
  faultsfoundbo: bool = false

  parse_file_phasesq = @[
        "PUNCTUATION OF SENTENCES TO HANDLE",
        "PUNCTUATION OF SENTENCE-PARTS TO HANDLE",
        "PRONOUNS TO HANDLE",
        "VERBS TO HANDLE",
        "LINK-WORDS TO HANDLE",
        "PREPOSITIONS TO HANDLE",
        "NOUN-ANNOUNCERS TO HANDLE",
        "NOUN-REPLACERS TO HANDLE",
        "AMBIGUOUS WORD-FUNCTIONS TO HANDLE"]

  summary_file_phasesq = @["SIGNAL-WORDS TO HANDLE"]



var debugbo: bool = false
#var debugbo: bool = true


template l1(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



template withFile*(f, fn, mode, actions: untyped): untyped =
  var f: File
  if open(f, fn, mode):
    try:
      actions
    finally:
      close(f)
  else:
    quit("cannot open: " & fn)





proc allFilesExist*(filelisq: seq[string]): bool = 
  # return true if all files in the listsequence do exist, otherwise false
  var existingbo: bool = true
  for filest in filelisq:
    if not fileExists(filest):
      existingbo = false
      if filest.len == 0:
        echo "File cannot be an empty string!"
      else:
        echo "File not found: " & filest
      break

  result = existingbo




proc getSeqFromFileSection*(filepathst, startlinest, endlinest: string): seq[string] =

  #[
  Retrieve the lines between the startline and endline (not including), and
  put them into a sequence.
  ]#

  var
    filest: string
    sectionsq: seq[string] = @[]
    in_sectionbo: bool = false

  l1(getAppDir())
  l1(getCurrentDir())
  l1("filepathst" & " = " & filepathst)

  if fileExists(filepathst):
    l1("**********************************")
    filest = readFile(filepathst)
    for linest in filest.splitlines:

      l1(linest)

      if linest == startlinest:
        in_sectionbo = true
      elif linest == endlinest:
        in_sectionbo = false
      else:
        if in_sectionbo:
          sectionsq.add(linest)
          
          l1("added: " & linest)


  result = sectionsq




proc createCombinedSummaryFile*(combinationtypest, languagest: string): bool = 

  #[
   combine (concatenate or aggregate) the summaries from a list-file (if present) into 
   one new, overwritable file for use in multi-summary highlightings and extractions.
   combinationtypest: concatenate, aggregate, first or testing

    "combinationtypest = testing" means that only is checked if conditions are met.
  
  ADAP HIS
  -add an combinationstype "first" to only use the first summary for extraction
  (but all for highlighting)
    but this option is NOT used because not the first but the selected summary is used now.
  ]#


  var 
    summary_createdbo: bool = false
    listfilenamest: string = "data_files/list-of-summaries.lst"
    concat_filenamest: string = "data_files/summary_concatenated.dat"
    aggreg_filenamest: string = "data_files/summary_aggregated.dat"
    first_filenamest: string = "data_files/summary_first.dat"
    summarylisq, wordlisq: seq[string]
    sum_filest, concat_filest, aggreg_filest, first_filest : string
    headerst, footerst: string

  headerst = ">>>SUMMARIES_" & toUpperAscii(languagest) & "<<<"
  footerst = ">----------------------------------<"

  # read the sum-list-file
  summarylisq = getSeqFromFileSection(listfilenamest, headerst, footerst)
  if summarylisq.len > 0:
    if allFilesExist(summarylisq):
      # concatenate the summaries to one new file
      if combinationtypest == "concatenate":
        for sum_file_namest in summarylisq:
          sum_filest = readFile(sum_file_namest)
          concat_filest = concat_filest & sum_filest
        writeFile(concat_filenamest, concat_filest)
      if combinationtypest == "first":
        first_filest = readFile(summarylisq[0])
        writeFile(first_filenamest, first_filest)
      elif combinationtypest == "aggregate":
        let fileob = open(aggreg_filenamest, fmWrite)
        fileob.writeLine("SIGNAL-WORDS TO HANDLE")

        for sum_file_namest in summarylisq:
          # extract the relevant section
          wordlisq = getSeqFromFileSection(sum_file_namest, "SIGNAL-WORDS TO HANDLE", ">----------------------------------<")
          # add items to new file
          for linest in wordlisq:
            fileob.writeLine(linest)

        fileob.writeLine(">----------------------------------<")
        fileob.close()

      elif combinationtypest == "testing":
        discard

      summary_createdbo = true

  result = summary_createdbo




proc addLanguageFilesToList() =
  # Dynamicly add the parse_language.dat files from the config-file 
  # to the list textsourcefilesq

  var
    valuelist: string
    sourcelangsq:seq[string]
    tbo: bool = false


  # get the processing-languages from the config-file
  valuelist = readOptionFromFile("text-language", "value-list")
  sourcelangsq = valuelist.split(",,")
  if tbo: echo sourcelangsq


  # generate the new valuelist
  for langst in sourcelangsq:
    # textsourcefilesq.add(langst & ".dat")
    textsourcefilesq.add("parse_" & langst & ".dat")

  if tbo: echo textsourcefilesq


proc loadTextSourceFiles() =
  try:

    for keyst in textsourcefilesq:
      if fileExists(keyst):
        textsourcefileta[keyst] = readFile(keyst)
      else:
        if faultsfoundbo:   # previous faults found
          sourcefilestatust &= keyst & "  "
        else:   # first fault found
          faultsfoundbo = true
          sourcefilestatust = "The following files could not be found: "
          sourcefilestatust &= keyst & "  "

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"




proc writeFilePatternToSeq*(filestartwithst: string): seq[string] = 

#[ Write the files from pattern in the current dir to the sequence and
 return that]#

  var
    filelisq: seq[string]
    filenamest: string
  

  # walk thru the file-iterator and sequence the right file(names)
  for kind, path in walkDir(getAppDir()):
    if kind == pcFile:
      filenamest = extractFileName(path)
      if len(filenamest) > len(filestartwithst):
        if filenamest[0..len(filestartwithst) - 1] == filestartwithst:
          # log(filenamest)
          filelisq.add(filenamest)

  result = filelisq




proc evaluateDataFiles*(verbosebo: bool = false): string = 
  #[
    Validate the file-sets parse_*.dat and summary_*.dat
    Deviations / complaints are reported.
    The results are show at startup.
    ]#

  var
    parse_lang_filesq, summary_filesq, all_filesq: seq[string]
    file_reportta = initOrderedTable[string, FilePhase]()
    tablekeyst: string
    reportst: string = "<b>Validation of the datafiles (no comment = OK):</b>\p<br>"
    phasecountit, itemcountit: int
    inphasebo: bool = false
    endmarkerst: string = ">----------------------------------<"
    phasesq: seq[string]


  parse_lang_filesq = writeFilePatternToSeq("parse_")
  summary_filesq = writeFilePatternToSeq("summary_")
  all_filesq = concat(parse_lang_filesq, summary_filesq)
  all_filesq.sort()

  # write the eval to a table (file_reportta) of objects (FilePhase)
  if true:
    for filest in all_filesq:
      phasecountit = 1
      # select correct phase-sequence
      case filest[0..4]
      of "parse":
        phasesq = parse_file_phasesq
      of "summa":
        phasesq = summary_file_phasesq

      for phasest in phasesq:
        tablekeyst = filest & "___" & phasest[0..phasest.len - 11]
        # preset objects for file
        file_reportta[tablekeyst] = FilePhase(
          fsName: filest,
          phaNameFull: phasest,
          phaNameCount: 0,
          phaSequenceNum: phasecountit,
          phaItemCount: 0,
          phaHasEmptyItem: false,
          phaEndMarkerFound: false
          )
        phasecountit += 1

      withFile(txt, filest, fmRead):
        for linest in txt.lines:
          if linest in phasesq:
            inphasebo = true
            itemcountit = 0
            # blockphase reached; update object
            tablekeyst = filest & "___" & linest[0..linest.len - 11]
            file_reportta[tablekeyst].phaNameCount += 1
          elif inphasebo:
            if linest == endmarkerst:
              file_reportta[tablekeyst].phaItemCount = itemcountit
              file_reportta[tablekeyst].phaEndMarkerFound = true
              inphasebo = false
            else:   # walking thru items
              if linest.len == 0:
                file_reportta[tablekeyst].phaHasEmptyItem = true
              file_reportta[tablekeyst].phaItemCount = itemcountit              
            itemcountit += 1


  # read the objects-table and create a basic html-report
  var 
    curfilest, formerfilest: string
    curphasest, formerphasest: string
    complaintst, endst, startst: string
    faultfoundbo: bool = false
    skip_othersbo: bool = false

  startst = "<br>\p"
  endst = "<br>\p"

  for keyst, valob in file_reportta:

    curfilest = valob.fsName
    curphasest = valob.phaNameFull
    if curfilest != formerfilest:
      reportst &= curfilest & endst

    complaintst = ""

    if valob.phaNameCount == 0:
      complaintst &= "---- This block-phase is not found (or mis-spelled)" & endst
      faultfoundbo = true
      skip_othersbo = true
    elif valob.phaNameCount > 1:
      complaintst &= "---- This block-phase occurs multiple times: " & $valob.phaNameCount & endst
      faultfoundbo = true
      skip_othersbo = true
    if not valob.phaEndMarkerFound:
      if not skip_othersbo:
        complaintst &= "---- This block-phase has no (valid) end-marker" & endst
        faultfoundbo = true
        skip_othersbo = true
    if valob.phaItemCount == 0:
      if not skip_othersbo:
        complaintst &= "---- This block-phase has NO items (no lines)" & endst
        faultfoundbo = true
    if valob.phaHasEmptyItem:
      if not skip_othersbo:
        complaintst &= "---- This block-phase has EMPTY items (zero-length lines)" & endst
        faultfoundbo = true

    formerfilest = valob.fsName

    if faultfoundbo or verbosebo:
      reportst &= "++ " & curphasest & endst
      reportst &= complaintst
      if verbosebo:
        reportst &= $valob & endst

    faultfoundbo = false
    skip_othersbo = false
  
  result = reportst


proc compareDataFiles*(firstfilest, secfilest, formatst: string): string = 
    #[Compare files (for now only summary-files) and return 3 sorted lists:
    -equal words
    -words in first not second
    -words in second not first
    ]#

  var
    firstsq, secsq, bothsq, onlyfirstsq, onlysecsq: seq[string]
    blockphasebo: bool = false
    startmarkerst = "SIGNAL-WORDS TO HANDLE"
    endmarkerst = ">----------------------------------<"
    filear: array[0..1, string] = [firstfilest, secfilest]
    wordseqar: array[0..1, seq[string]] = [@[], @[]]
    lineseptst, outputst: string
    outputseqar: array[0..2, seq[string]]
    passit: int = 0
    empty_linebo: bool = false
    lengthit: int
    colorspacest: string = "<span style=background-color:#ffd280>" & "&nbsp" & "</span>"


  # create sorted seqs from the files
  for it in 0..1:
    withFile(txt, filear[it], fmRead):
      for linest in txt.lines:
        if linest == startmarkerst:
          blockphasebo = true
        elif linest == endmarkerst:
          blockphasebo = false
        else:
          if blockphasebo:
            wordseqar[it].add(linest)
    #sort(wordseqar[it])
    # echo wordseqar[it]


  firstsq = deduplicate(wordseqar[0])
  secsq = deduplicate(wordseqar[1])

  sort(firstsq)
  sort(secsq)

  # compare the seqs; create comparison-lists
  for wordst in firstsq:
    if wordst in secsq:
      bothsq.add(wordst)
    else:
      onlyfirstsq.add(wordst)
  for wordst in secsq:
    if not (wordst in firstsq):
      onlysecsq.add(wordst)


  # report the results
  if formatst == "text":
    lineseptst = "\p"
  elif formatst == "html":
    lineseptst = "<br>"


  outputst = lineseptst & "---------------------------------------" & lineseptst
  outputst &= "Comparison-result (sorted and uniquized):" & lineseptst & lineseptst
  outputst &= "First file: " & firstfilest & lineseptst
  outputst &= "Second file: " & secfilest & lineseptst

  outputseqar = [bothsq, onlyfirstsq, onlysecsq]
  
  for sq in outputseqar:
    if passit == 0:
      outputst &= lineseptst & "Words in both files:" & lineseptst
    elif passit == 1:
      outputst &= lineseptst & "Words only in FIRST file:" & lineseptst
    elif passit == 2:
      outputst &= lineseptst & "Words only in SECOND file:" & lineseptst

    #for wordst in outputseqar[passit]:
    for wordst in sq:
      if formatst == "text":
        outputst &= wordst & lineseptst
      elif formatst == "html":
        lengthit = wordst.len
        if lengthit > 0:
          if wordst == wordst.strip():
            outputst &= wordst & lineseptst
          elif wordst[0..0] == " " and wordst[lengthit - 1 .. lengthit - 1] == " ":
            outputst &= colorspacest & wordst.strip() & colorspacest & lineseptst
          elif wordst[0..0] == " ":
            outputst &= colorspacest & wordst.strip() & lineseptst
          elif wordst[lengthit - 1 .. lengthit - 1] == " ":
            outputst &= wordst.strip() & colorspacest & lineseptst
        else:
          empty_linebo = true
          #echo "Empty line in summary-comparison detected."
      else:
          outputst &= wordst & lineseptst
    passit += 1

  if empty_linebo:
    outputst &= lineseptst & lineseptst & "Empty lines have been detected in one or more files.."

  result = outputst




addLanguageFilesToList()
loadTextSourceFiles()



when isMainModule:
  # echo textsourcefileta["dutch.dat"]
  # echo sourcefilestatust

  # echo evaluateDataFiles(datFileAll)
  #echo compareDataFiles("summary_english_gen4_large.dat", "summary_english_causation.dat","text")

  #var filepathst: string = "/media/OnsSpul/1klein/1joris/k1-onderwerpen/computer/Programmeren/nimtaal/jester/readibl/mostfiles/data_files/list-of-summaries.lst"
  #echo getSeqFromFileSection(filepathst, ">>>SUMMARIES<<<", ">----------------------------------<")
  #echo createCombinedSummaryFile("concatenate")
  #echo createCombinedSummaryFile("aggregate")
  echo createCombinedSummaryFile("first")
  #echo getSeqFromFileSection("summary_english_computer.dat", "SIGNAL-WORDS TO HANDLE", ">----------------------------------<")

