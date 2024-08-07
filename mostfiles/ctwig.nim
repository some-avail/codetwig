#[
Program to generate code-trees from a terminal window.

Firstly you must create a project.
- make a project-definition-file with at least the path to the project
- ctwig_make_project can add the source-files to the project-file
- user can prune the unneeded source-files

Then you can show trees.
For example you run:
ctwig projects/myproj.pro -ct


ADAP HIS
-CT version >= 1.5 will be multi-project and multi-level source-dirs


ADAP NOW


ADAP FUT
u-CT version x.y - implement the objects?? not soon because they only beautify the code..
  v-design objects
  -design conversions
-limit usages to imports

]#



import jolibs/generic/[g_disk2nim, g_templates, g_tools, g_stringdata, g_options]
import std/[os, strutils, paths, tables, parseopt]


var 
  versionfl: float = 1.701
  codetwigst: string = "CodeTwig"
  ct_projectsdirst: string = "projects"
  dec_list_suffikst: string = "dec_list.dat"

  excluded_declaresq: seq[string] = @["log", "else"]



type

  ViewType = enum
    viewBasic_OneLevel
    viewBasic_TwoLevels
    viewExtended_OneLevel
    viewExtended_TwoLevels
    viewAll

  ItemType = enum
    itemDeclaration
    itemSourceCode



  # below objects are drafted but NOT USED YET;
  # however they give a idea of the involved structures.
  # below pathI and pathE are usually resp. including or excluding a filename
  Project =  object of RootObj
    proName: string
    proDefPathI: Path            # where the def-file myproject.pro is located
    proSourcePathE: Path         # where the sourcecode-project is located
    proTargetPathE: Path         # where the codetwig-generated files are placed


  ModuleOfCode =  object of RootObj
    modName: string
    modPathE: Path
    modFileName: string
    modProject: string


  Declaration = object of RootObj
    dName: string
    dType: string
    dModule: string
    dModPathE: Path
    dProject: string
    dLineStart: int
    dLineEnd: int
    dColStart: int
    dColEnd: int



  UsageOfDecs = object of RootObj
    usingDec: string
    usedDec: string
    usedCallLine: int



# var debugbo: bool = true
var debugbo: bool = false


template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



proc extractFileExtension(filepathst: string): string = 

  # Extract the extension a file or filepath
  # Can be absent, zero-length or any length

  var 
    extst:string
    dotsq: seq[string]

  if filepathst.contains("."):
    dotsq = filepathst.split(".")
    extst = dotsq[dotsq.len - 1]
    
  else: 
    extst = ""

  result = extst



proc clipString(inputst: string, lengthit: int): string = 

  # maximize string at lengthit

  var 
    outputst: string

  if inputst.len > lengthit:
    outputst = inputst[0..lengthit - 1]
  else:
    outputst = inputst

  result = outputst



proc addSourceFilesToProject(proj_def_pathst: string): string = 
  #[
  Based on the project-path in the project-def-file, the source-files
  from that project are added to the project-def-file.

  ADAP NOW
  - add recursive sub-dir-addition of source-files


  ADAP FUT
  -add param overwritebo to overwrite / update the current sf-list
  -exclusion-list to auto-exclude certain files that are probably copies
  of originals, with numbers and words like bak or copy.
  ]#

  var
    fileob: File
    blockphasest: string
    blockheadar: array[0..1, string] = [
        "PROJECT_PATH",
        "SOURCE_FILES"]
    blockseparatorst = ">----------------------------------<"
    projectpathst: string
    source_filesq: seq[string]
    blocklineit, countit: int
    source_file_posit64: int64

  try:
    echo "Trying to open: " & proj_def_pathst
    # open the project-file for read-write access
    if open(fileob, proj_def_pathst, fmReadWriteExisting):
      for linest in fileob.lines:

        # check for block-header
        if linest in blockheadar:
          blockphasest = linest
          #echo "\p" & blockphasest
          if blockphasest == "SOURCE_FILES":
            source_file_posit64 = fileob.getFilePos()
          blocklineit = 0
        elif linest != "":
        
          blocklineit += 1

          if blockphasest == "PROJECT_PATH":
            if linest != blockseparatorst:
              # read the project-path
              projectpathst = linest
              echo "Project-path of the source-files: " & projectpathst
              writeFilePatternToSeqRec(source_filesq, "*.nim", Path(projectpathst), true)
            else:
              blockphasest = ""

          elif blockphasest == "SOURCE_FILES":
            if blocklineit == 1:
              if linest == blockseparatorst:
                # read the file-names of the source-files and write them to the files-section
                fileob.setFilePos(source_file_posit64)
                countit = 0
                for filenamest in source_filesq:
                  countit += 1
                  fileob.writeLine(filenamest)
                  echo filenamest
                echo "----------------------------------------------"
                fileob.writeLine(blockseparatorst)
                result =  $countit &  " source-file-names have been added to the project-file: " & proj_def_pathst
              else:
                result = "Source-files have been added previously; pre-clean section and try again.."
    else:
      echo "Could not open file; you may have misspelled the name.."
  
  
    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"
  finally:
    fileob.close()



proc extractFileSectionToSequence(filepathst, start_separst, end_separst: string): seq[string] = 
  #[
    Extract the lines of a file that are located between the starting and ending separator and 
    put them in a sequence.
  ]#

  var 
    in_phasebo: bool
    sectionsq: seq[string] = @[]

  result = sectionsq
  withFileAdvanced(fileob, filepathst, fmRead):
    for linest in fileob.lines:
      if linest == start_separst:
        in_phasebo = true
      elif linest == end_separst:
        in_phasebo = false
      else:
        if in_phasebo:
          sectionsq.add(linest)
    result = sectionsq


proc getSliceFromAnchor(tekst, anchorst: string, possib_endmarksq: seq[string], appendspacebo: bool): array[0..1, int] =
  #[
    Searching in the tekst, return a target-string indicated as slice [start,end] located after an anchor-string.
    If the target-string must be a separate word, then set appendspacebo = true
    The end of the target-string is the first one of the possible end-markers.

    if myarray != [-1, -1]:
      if myarray[1] != 99999999:
        echo mytekst[myarray[0]..myarray[1]]
      else:
        echo "no target-string or end-string found"
    else:
      echo "anchor not found"

    ADAP MAYBE
    -add orientation; target can be located next to an anchor-string with a certain orientation (before or after).
  ]#

  var 
    anchorposit, targ_startit, targ_endit: int
    new_anchorst: string
    possib_endpositsq: seq[int]
    smallit: int = 100000000

  try:
    if appendspacebo:
      new_anchorst = anchorst & " "
    else:
      new_anchorst = anchorst

    anchorposit = tekst.find(new_anchorst)
    if anchorposit != -1:
      #search first space and next word is what we want
      targ_startit = anchorposit + new_anchorst.len

      for endmarkst in possib_endmarksq:
        possib_endpositsq.add(tekst.find(endmarkst, targ_startit + 1))

      for posit in possib_endpositsq:
        if posit > targ_startit:
          if posit < smallit:
            smallit = posit

      targ_endit = smallit - 1
    else:
      targ_startit = -1
      targ_endit = -1


    result = [targ_startit, targ_endit]

  
  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "An index-error occurred.."
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo "Custom error information here"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"



proc countLinesOfFile(filepathst: string): int = 
  var 
    fileob: File
    countit: int = 0

  fileob = open(filepathst, fmRead)
  for linest in fileob.lines:
    countit += 1
  fileob.close()
  result = countit



proc getStandardLibsOfNim(filepathst: string): seq[string] = 
  #[
    All modules in the standard library of Nim.
    Current Nim version: 2.0.8
    Gotten from: https://nim-lang.org/docs/theindex.html
    Sub-section modules
  ]#
  var 
    onelinest, modulest: string
    linecountit: int = 0
    modulesq: seq[string] = @[]

  withFileAdvanced(fileob, filepathst, fmRead):
    for linest in fileob.lines:
      linecountit += 1
      if linecountit == 1:
        onelinest = linest

  for rawmodulest in onelinest.split(","):
    modulest = rawmodulest.strip
    modulesq.add(modulest)
  result = modulesq



proc getNimImports(filepathst: string; exclude_stdlibsbo: bool = true, include_selfbo: bool = true): seq[string] = 

  #[ 
    Open the file and read the relevant imports to a sequence.
    param exclude_stdlibsbo = false not yet fully implemented.
            usefull for analysing nimlang and its libs themselves
   ]#

  var 
    modules_stringst, modulest, relmodpathst, path_tailest: string
    stdlibsq: seq[string] = getStandardLibsOfNim("nim_std_lib.lst")

    # below resp: the resulting module-list, temp. module-list, split import-path-parts
    modulesq, temp_modulesq, modulepartsq: seq[string] = @[]
    fileob: File

  wispbo = false

  path_tailest = extractFilename(filepathst)
  if path_tailest.len > 4:
    if include_selfbo: modulesq.add(path_tailest[0..^5])

  fileob = open(filepathst, fmRead)

  #withFileAdvanced(fileob, filepathst, fmRead):

  if true:
    for linest in fileob.lines:
      if linest.startsWith("import "):
        wisp("linest = ", linest)
        modules_stringst = linest.split(" ", maxsplit = 1)[1]
        wisp("modules_stringst = ", modules_stringst)
        if modules_stringst.startsWith("std"):
          if not exclude_stdlibsbo:
            discard()
            # not yet implemented
        elif modules_stringst.contains("/"):
          if modules_stringst.contains("["):
            modulepartsq = modules_stringst.split("[")
            wisp("modulepartsq = ", $modulepartsq)
            relmodpathst = modulepartsq[0].strip()
            temp_modulesq = modulepartsq[1].split("]")[0].split(",")

            for rawmodulest in temp_modulesq:
              modulest = relmodpathst & rawmodulest.strip()
              modulesq.add(modulest)

          else:
            modulest = modules_stringst.strip()
            modulesq.add(modulest)

        else:   # list of modules either of stdlib or not
          for rawmodulest in modules_stringst.split(","):
            modulest = rawmodulest.strip()
            if not exclude_stdlibsbo or modulest notin stdlibsq: 
              modulesq.add(modulest)

  fileob.close()
  wispbo = true
  result = modulesq



proc testNimImports(proj_def_pathst: string) = 
  #[
   test the proc getNimImports for a specific project-def
  ]#
  var 
    source_filesq: seq[string]
    filepathst: string
    sourceprojectpathst: string
    moduleta = initOrderedTable[string, File]()


  try:
    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    source_filesq = extractFileSectionToSequence(proj_def_pathst, "SOURCE_FILES", ">----------------------------------<")

    echo "\p**************************************"
    echo "sourceprojectpathst = ", sourceprojectpathst
    echo "**************************************"

    for filest in source_filesq:
      filepathst = string(Path(sourceprojectpathst) / Path(filest))
      moduleta[filest] = open(filepathst, fmRead)

      echo "Imported modules for: ", filest
      echo getNimImports(filepathst)
      echo ""



  #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo "Custom error information here"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"



proc substringInSequence(stringsq: seq[string]; substringst: string): bool = 
  #[
    Return true if the substring is in one of the elements.
  ]#

  var foundbo = false

  for st in stringsq:
    if substringst in st:
      foundbo = true
      break
  result = foundbo



proc containsWithValidBoundaries(tekst, subst: string; beforesq, aftersq: seq[string]; allowfirstbo, allowlastbo: bool): bool = 

  # subst within tekst has valid bounds if before and after strings are in seqs
  # allowfirstlastbo means that the subst is allowed as first or last part of tekst

  var 
    substartit, subendit, forstartit, aftendit: int
    forokbo, aftokbo, skipbo: bool
    forslicest, aftslicest: string

  try:

    wispbo = false

    forokbo = false
    aftokbo = false
    skipbo = false

    wisp("tekst = ", tekst)
    wisp("subst =", subst)
    wisp("beforesq = ", $beforesq)
    wisp("aftersq = ", $aftersq)
    wisp("tekst.len = ", tekst.len)
    wisp("allowfirstbo = ", allowfirstbo)
    wisp("allowlastbo = ", allowlastbo)


    substartit = tekst.find(subst)
    subendit = substartit + subst.len - 1

    wisp("substartit = ", substartit)
    wisp("subendit = ", subendit)


    if substartit >= 0:

      if allowfirstbo:
        if substartit == 0:
          forokbo = true
      else:
        if substartit == 0:
          skipbo = true

      if allowlastbo:
        if subendit == tekst.len - 1:
          aftokbo = true
      else:
        if subendit == tekst.len - 1:
          skipbo = true


      if not forokbo and not skipbo:
        wisp "in for"
        for forst in beforesq:
          forstartit = substartit - forst.len
          if forstartit >= 0:
            forslicest = tekst[forstartit .. substartit - 1]
            wisp("forslicest = ", forslicest)
            if forslicest == forst:
              forokbo = true
              break

      if not aftokbo and not skipbo:
        wisp "in aft"
        for aftst in aftersq:
          aftendit = subendit + aftst.len
          wisp("aftendit = ", aftendit)
          if aftendit < tekst.len:
            aftslicest = tekst[subendit + 1 .. aftendit]
            wisp("aftslicest = ", aftslicest)
            if aftslicest == aftst:
              aftokbo = true
              break

    wisp("forokbo =", forokbo)
    wisp("aftokbo = ", aftokbo)

    wispbo = false

    result = forokbo and aftokbo

  #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo "Custom error information here"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"





proc createDeclarationList(proj_def_pathst: string) = 
  #[
  proj_def_pathst = path to the file in which the codetwig-project for a source-project is defined

  Firstly scan all source-files to create a basic declaration-list
  (that is without the underlying declarations)
  Then, for each proc / declaration, one can scan for the used procs /decs and append them after earch dec-line.

  dec_module_dec-type_linestart_colstart_colend_line-end

  ADAP HIS
  -unificeren op dec_module, niet alleen op dec

  ADAP FUT
  -add special type of declarations like "route:""
  ]#


  var
    fileob, phase1fileob, phase2fileob, phase2file2ob, phase3fileob: File
    source_filesq: seq[string]
    # declaration-types
    nim_dec_typesq: seq[string] = @["proc", "template", "macro", "func", "iterator", "method", "converter"]
    langekst: string = "nim"
    filepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    linecountit, linecount2it, linecount3it, foundcountit: int
    phase1_dec_list_filepathst, phase2_dec_list_filepathst, phase3_dec_list_filepathst: string
    dec_namear: array[0..1, int]
    dec_namest: string
    targlinest: string
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = ":"
    sep3st = "==="
    moduledecorst = "----------"
    moduletitlest, modulenamest, linepartst: string
    startingtoken: string
    dectypefoundbo, incommentblockbo, commentclosingbo, singlecommentbo: bool
    previous_linest, line_endst, newlinest: string
    linesq, line1sq, line2sq: seq[string]
    moduleta = initOrderedTable[string, File]()
    declarest, modulest, declaretypest: string
    declare2st, module2st, declaretype2st: string
    linestartit, lineendit: int
    usagest, appendst: string

    # to avoid doubles
    unique_decplusmodule2sq: seq[string]
    # must be unique
    dec2_plus_module2st, previous_modulest: string

    projectnamest, fullmodpathst, modfilest, submodulest: string
    projectprefikst: string

  wispbo = false

  try:

    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    source_filesq = extractFileSectionToSequence(proj_def_pathst, "SOURCE_FILES", ">----------------------------------<")

    # create a target-dir and -file, ie the dec-list
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)
    projectnamest = string(pd_filebasepa)

    if not dirExists(reltargetprojectpathst):   
      createDir(reltargetprojectpathst)     # proc creates subdirs also
      echo "Creating target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst
    else:
      echo "Using target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst

    projectprefikst = clipString(string(pd_filebasepa), 7)
    phase1_dec_list_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase1_" & dec_list_suffikst))
    phase2_dec_list_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase2_" & dec_list_suffikst))
    phase3_dec_list_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase3_" & dec_list_suffikst))


    # first phase; create first intermediate product phase1_dec_list_filepathst
    # per line: declaration, module, declaration-type, dec.line-start, col.start, col.end, dec.line-end
    echo "-------------first phase----------------"
    if phase1fileob.open(phase1_dec_list_filepathst, fmWrite):
      for relmodpathst in source_filesq:
        fullmodpathst = string(Path(sourceprojectpathst) / Path(relmodpathst))
        modfilest = extractFilename(fullmodpathst)

        submodulest = relmodpathst[0 .. relmodpathst.len - 1 - langekst.len - 1]
        moduletitlest = moduledecorst & " " & submodulest & " " & moduledecorst

        # below line no longer possible since addition of phase 2
        #phase1fileob.writeLine(moduletitlest)
        echo "-------- Processing file ----------- " & relmodpathst & "---------------"
        # open file for reading
        if fileob.open(fullmodpathst, fmRead):
          linecountit = 0
          for linest in fileob.lines:
            linecountit += 1
            commentclosingbo = false
            singlecommentbo = false
            if linest.contains("#["): incommentblockbo = true
            if linest.contains("]#"): 
              commentclosingbo = true
              incommentblockbo = false
            if linest.strip().startswith("#"): singlecommentbo = true

            if linest.len > 2 and not incommentblockbo and not commentclosingbo and not singlecommentbo:

              startingtoken = linest[0..0]
              if not (startingtoken in [" "]):       # some sort of declaration found
                dectypefoundbo = false
                for dectypest in nim_dec_typesq:
                  #echo "Declaration-type: " & dectypest

                  dec_namear = getSliceFromAnchor(linest, dectypest, @["(", "[", "*", " "], true)

                  if dec_namear != [-1, -1]:      # we want only some declarations
                    if dec_namear[1] != 99999999:
                      dectypefoundbo = true
                      dec_namest = linest[dec_namear[0]..dec_namear[1]]
                      if decnamest notin excluded_declaresq:
                        targlinest = dec_namest & sep1st & submodulest & sep1st & dectypest & sep1st & "ls:" & $linecountit & sep1st & "cs:" & $dec_namear[0] & sep1st & "ce:" & $dec_namear[1]
                        phase1fileob.writeLine(targlinest)
                      echo "Line: " & $linecountit


                if not dectypefoundbo:      # other-type declares are relevant to determine declare-endings
                  if linest.endswith(":") and not linest.contains(" "):
                    # probably a macro-implementation - you want these..
                    decnamest = linest[0..linest.len - 2]
                    if decnamest notin excluded_declaresq:
                      targlinest = dec_namest & sep1st & submodulest & sep1st & "implement" & sep1st & "ls:" & $linecountit & sep1st & "cs:" & "0" & sep1st & "ce:" & $decnamest.len
                      phase1fileob.writeLine(targlinest)
                      echo "Line: " & $linecountit
                  else:
                    if linest.len > 15:
                      linepartst = linest[0..15]
                    else:
                      linepartst = linest[0..linest.len - 1]
                    targlinest = "other_declaration" & sep1st & submodulest & sep1st  & linepartst & sep1st & "ls:" & $linecountit
                    phase1fileob.writeLine(targlinest)

          fileob.close()

        else:
          echo ">>>>>>>>>>>Could not open " & fullmodpathst
    else: 
      echo ">>>>>>>>>>>Could not open " & phase1_dec_list_filepathst

    phase1fileob.close()    # close writable file


    # phase two; create new file and append declaration-endings to each line, called line-ends le, that is the last line of the declare;
    # after that append the project-name (for multi-project-functions)
    echo "-------------second phase----------------"

    # work with one file-object of phase one and one of phase two
    if phase1fileob.open(phase1_dec_list_filepathst, fmRead) and phase2fileob.open(phase2_dec_list_filepathst, fmWrite):
      linecountit = 0
      for linest in phase1fileob.lines:
        linecountit += 1
        if linecountit > 1:
          # line-end of the previous line is the line-start of the following minus 1
          linesq = linest.split(sep1st)
          modulest = linesq[1]
          previous_modulest = previous_linest.split(sep1st)[1]
          if previous_modulest == modulest:
            line_endst = "le:" & $(parseInt(linesq[3].split(":")[1]) - 1)
          else:       # use the total number of lines of the source-file
            filepathst = string(Path(sourceprojectpathst) / Path(previous_modulest & ".nim"))
            line_endst = "le:" & $(countLinesOfFile(filepathst))
          if previous_linest.split(sep1st)[0] != "other_declaration":
            newlinest = previous_linest & sep1st & line_endst & sep1st & projectnamest
            phase2fileob.writeLine(newlinest)
        previous_linest = linest
    else:
      echo "Could not open one or two files"

    phase1fileob.close()
    phase2fileob.close()



    # phase 3 uses a phase-2 dec-list and appends all used decs from the source-code-range..
    echo "-------------third phase----------------"


    
    # create the source-file-table
    for filest in source_filesq:
      filepathst = string(Path(sourceprojectpathst) / Path(filest))
      moduleta[filest] = open(filepathst, fmRead)
    

    var imported_modulesq: seq[string]
    var check_for_imported_modulesbo: bool = true
    var module2_tailest: string
    var exclude_stdlibsbo: bool = parseBool(readOptionFromFile("exclude_nim_standardlibs", optValue))

    if phase2fileob.open(phase2_dec_list_filepathst, fmRead) and phase2file2ob.open(phase2_dec_list_filepathst, fmRead) and phase3fileob.open(phase3_dec_list_filepathst, fmWrite):

      # for dec1 in dec-list:
      linecountit = 0
      for line1st in phase2fileob.lines:
        linecountit += 1
        # parse the line into data        
        line1sq = line1st.split(sep1st)
        declarest = line1sq[0]
        modulest = line1sq[1]
        #declaretypest = line1sq[2]
        linestartit = parseInt(line1sq[3].split(":")[1])
        lineendit  = parseInt(line1sq[6].split(":")[1])
        appendst = ""
        unique_decplusmodule2sq = @[]     # reset for every new dec1
        imported_modulesq = getNimImports(string(Path(sourceprojectpathst) / Path(modulest & ".nim")), exclude_stdlibsbo, true)


        # for dec2 in dec-list:
        phase2file2ob.setFilePos(0)
        for line2st in phase2file2ob.lines:          
          line2sq = line2st.split(sep1st)
          declare2st = line2sq[0]
          #echo declare2st
          module2st = line2sq[1]
          module2_tailest = string(extractFilename(Path(module2st)))
          dec2_plus_module2st = declare2st & "_" & module2st
          declaretype2st = line2sq[2]

          foundcountit = 0
          linecount3it = 0

          if not (declare2st in excluded_declaresq) and not (dec2_plus_module2st in unique_decplusmodule2sq):

            # if the source-code-range of dec1 contains dec2 (then append the used dec2):
            moduleta[modulest & ".nim"].setFilePos(0)
            for sline in moduleta[modulest & ".nim"].lines:
              linecount3it += 1
              if linecount3it > linestartit and linecount3it <= lineendit:
                # walk thru the lines of the source-code-range
                commentclosingbo = false
                singlecommentbo = false
                if sline.contains("#["): incommentblockbo = true
                if sline.contains("]#"): 
                  commentclosingbo = true
                  incommentblockbo = false
                if sline.strip().startswith("#"): singlecommentbo = true

                if sline.len > 2 and not incommentblockbo and not commentclosingbo and not singlecommentbo:
                  #if sline.contains(declare2st) and not sline.contains("\"" & declare2st & "\""):
                  if sline.containsWithValidBoundaries(declare2st, @[".", "(", " ", "=", "["], @["(", "=", " ", "."], false, true) :

                    foundcountit += 1

                    if not (dec2_plus_module2st in unique_decplusmodule2sq):

                      if not check_for_imported_modulesbo or imported_modulesq.substringInSequence(module2_tailest):

                        unique_decplusmodule2sq.add(dec2_plus_module2st)
                        usagest = declare2st & sep1st & module2st & sep1st & declaretype2st & sep1st & $linecount3it
                        appendst &= sep3st & usagest
                        wisp("dec2_plus_module2st = ", dec2_plus_module2st)
                        wisp("imported_modulesq = ", $imported_modulesq)
                        wisp("module2st = ", module2st)
                        wisp("module2_tailest = ", module2_tailest)
                      else:
                        wisp("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
                        wisp("declarest ++  modulest = ", declarest & " ++ " & modulest)
                        wisp("dec2_plus_module2st = ", dec2_plus_module2st)
                        wisp("imported_modulesq = ", $imported_modulesq)
                        wisp("module2st = ", module2st)
                        wisp("module2_tailest = ", module2_tailest)
                        wisp("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")


        #append dec2-data to the line of dec1
        phase3fileob.writeLine(line1st & appendst)

        if unique_decplusmodule2sq != @[]:
          echo "\pHandling nr. ", $linecountit,  " for dec ++ module:      ", declarest & " ++ " & modulest , "        adding usages:"
          echo unique_decplusmodule2sq

        else:
          echo "\pHandling nr. ", $linecountit, " - nothing found..."
        #echo "wispbo = ", wispbo

    else:
      echo "Could not open one or three files"


    phase2fileob.close()
    phase2file2ob.close()
    phase3fileob.close()


    for filest in source_filesq:
      moduleta[filest].close()

    wispbo = false

  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"



proc getSliceFromLines(fileob: var File, linestartit, lineendit: int, starttagst, endtagst: string, samelinebo: bool = false): array[0..1, int] = 
  #[
    Looping thru the lines, starting at linestart, retrieve the starting and ending point 
    as integers of the text between the startag and endtag, and put them in an array.
    
    samelinebo = true means that the starttag and endtag must be on the same line.
    Call like:
    interpointar = getSliceFromLines(fob, linestartit, lineendit, "(", ")")
  ]#

  var 
    fileposfromlineit, startit, endit, filestartit, fileendit, countit: int64
    startfoundbo, endfoundbo, stopsearchingbo: bool

  fileob.setFilePos(0)
  startfoundbo = false
  endfoundbo = false
  stopsearchingbo = false

  countit = 0
  for linest in fileob.lines:
    startit = 0
    endit = 0
    countit += 1
    if countit >= linestartit and countit <= lineendit:

      if not (startfoundbo and endfoundbo):
        fileposfromlineit = fileob.getFilePos()
        log($countit & " - " & $fileposfromlineit)
        if not startfoundbo:
          startit = linest.find(starttagst)
          if startit >= 0:
            startfoundbo = true
            filestartit = fileposfromlineit - linest.len + startit + starttagst.len - 1
            #echo "filestartit ", filestartit
            #echo "startit ", startit
            log($countit)
            log($fileposfromlineit)
            log($startit)
            log($filestartit)

        if not endfoundbo and not stopsearchingbo:
          # geval1: starttag is ) en eindtag is =
          # geval2: starttag is ( en eindtag is )

          endit = linest.find(endtagst)
          if endit >= 0: 
            fileendit = fileposfromlineit - linest.len + endit - 2

          if startfoundbo:
            while not endfoundbo:
              if fileendit >= filestartit - 1:
                  endfoundbo = true
                  #echo "fileendit ", fileendit
                  #echo "endit ", endit

              else:
                # search the next occurence of starttagst
                endit = linest.find(endtagst, endit + 1)
                if endit >= 0:
                  fileendit = fileposfromlineit - linest.len + endit - 2
                  #echo "fileendit ", fileendit
                  #echo "endit ", endit
                else:
                  if samelinebo:
                    stopsearchingbo = true
                  break
            log($countit)
            log($fileposfromlineit)
            log($endit)
            log($fileendit)


  fileob.setFilePos(0)
  if not startfoundbo:
    filestartit = -1
  if not endfoundbo:
    fileendit = -1        
  result = [filestartit.int, fileendit.int]


proc getXLinesWithSubstring(fileob: var File, subst: string, linestartit, lineendit, numberit: int): seq[string] = 

  #[ Retrieve numberit lines from fileob based on the substring in them 
     starting from linestartit and put them in a sequence. Lines are prestripped for comparison
      
      Call like:
      commentlinesq = getXLinesWithSubstring(fob, "# ", linestartit, lineendit , 2)
]#
  var 
    countit, addcountit: int = 0
    outputsq: seq[string]
    strippedlinest: string

  fileob.setFilePos(0)
  for linest in fileob.lines:
    countit += 1
    strippedlinest = linest.strip()
    if countit >= linestartit and countit <= lineendit:
      if addcountit <= numberit:
        if strippedlinest.startsWith(subst):
          outputsq.add(linest)
          addcountit += 1
      else:
        break

  result = outputsq




proc createCodeViewFile(proj_def_pathst: string, viewtypeeu: ViewType) = 

#[
  Create view-files of the enum-type

  ADAP FUT
  ??- sort second-level decs on line-nr.
]#


  var 
    decfilob, bofileob, btfileob, eofileob, etfileob, fob: File 
    decfilepathst, boview_filepathst, btview_filepathst, eoview_filepathst, etview_filepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    source_filesq, dlinesq, decdatasq, uselinesq: seq[string]
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = "___"
    sep3st = "==="
    decnamest, modulest, dectypest, linestartst, lineendst, newmodulest, decdatalinest, decdata_ekst: string
    usedatalinest: string
    moduleta = initOrderedTable[string, File]()
    filestringta = initOrderedTable[string, string]()
    interpointar, betweenpointar: array[0..1, int]
    filepathst, modfilest, slicest, nextslicest: string
    linestartit, lineendit: int
    commentlinesq, doublehashsq, singlehashsq: seq[string]
    choppedmodulest, projectnamest, toptitlest: string
    projectprefikst: string


  try:
    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    source_filesq = extractFileSectionToSequence(proj_def_pathst, "SOURCE_FILES", ">----------------------------------<")

    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)
    projectnamest = string(pd_filebasepa)

    echo "--------------------------------------------------------"
    echo "Using target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst


    projectprefikst = clipString(string(pd_filebasepa), 7)

    decfilepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase3_" & dec_list_suffikst))
    boview_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_basic_one-level_view.txt"))
    btview_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_basic_two-level_view.txt"))
    eoview_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_extended_one-level_view.txt"))
    etview_filepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_extended_two-level_view.txt"))


    decfilob = open(decfilepathst, fmRead)
    if viewtypeeu == viewBasic_OneLevel:
      bofileob = open(boview_filepathst, fmWrite)
      echo "Creating file: " & boview_filepathst
    elif viewtypeeu == viewBasic_TwoLevels:
      btfileob = open(btview_filepathst, fmWrite)
      echo "Creating file: " & btview_filepathst
    elif viewtypeeu == viewExtended_OneLevel:
      eofileob = open(eoview_filepathst, fmWrite)
      echo "Creating file: " & eoview_filepathst
    elif viewtypeeu == viewExtended_TwoLevels:
      etfileob = open(etview_filepathst, fmWrite)
      echo "Creating file: " & etview_filepathst


    # create the source-file-table
    for filest in source_filesq:
      filepathst = string(Path(sourceprojectpathst) / Path(filest))
      moduleta[filest] = open(filepathst, fmRead)
      filestringta[filest] = readAll(moduleta[filest])


    # create view-types
    #if viewtypeeu == viewBasic_OneLevel or viewtypeeu == viewBasic_TwoLevels:
    if true:
      newmodulest = ""
      toptitlest = "\p ~~~~~~~~~~~~~~~~~  Project = " & projectnamest & "  ~~~~~~~~~~~~~~~~~~~~\p"
      if viewtypeeu == viewBasic_OneLevel:
        bofileob.writeLine(toptitlest)
      elif viewtypeeu == viewBasic_TwoLevels:
        btfileob.writeLine(toptitlest)
      elif viewtypeeu == viewExtended_OneLevel:
        eofileob.writeLine(toptitlest)
      elif viewtypeeu == viewExtended_TwoLevels:
        etfileob.writeLine(toptitlest)


      # walk thru the dec-list
      for dlinest in decfilob.lines:
        dlinesq = dlinest.split(sep3st)
        decdatasq = dlinesq[0].split(sep1st)
        decnamest = decdatasq[0]
        modulest = decdatasq[1]
        dectypest = decdatasq[2]
        linestartst = decdatasq[3]
        lineendst = decdatasq[6]
        #if modulest == "g_html_json":
        #  echo dlinesq

        if newmodulest != modulest:
          # write the new module
          newmodulest = modulest
          echo "Writing data from: " & newmodulest

          if viewtypeeu == viewBasic_OneLevel:
            bofileob.writeLine(newmodulest & "---------------------------------------------------")
          elif viewtypeeu == viewBasic_TwoLevels:
            btfileob.writeLine(newmodulest & "--------------------------------------------------------------------")
          elif viewtypeeu == viewExtended_OneLevel:
            eofileob.writeLine("\p\p****************    " & newmodulest & "   ***********************************************************************\p")
          elif viewtypeeu == viewExtended_TwoLevels:
            etfileob.writeLine("\p\p****************    " & newmodulest & "   ***********************************************************************\p")

        else:
          decdatalinest = "    " & decnamest.alignLeft(33) & dectypest.alignLeft(10) & "line: " & linestartst.split(":")[1]
          decdata_ekst = "    " & decnamest.alignLeft(33) & modulest.alignLeft(15) & dectypest.alignLeft(10) & "line: " & linestartst.split(":")[1]
      
          if viewtypeeu == viewBasic_OneLevel:
            bofileob.writeLine(decdatalinest)

          elif viewtypeeu == viewBasic_TwoLevels:
            btfileob.writeLine(decdatalinest)
            for it, uselinest in dlinesq:
              if it > 0:
                uselinesq = uselinest.split(sep1st)
                choppedmodulest = extractFilename(uselinesq[1])
                if choppedmodulest != uselinesq[1]:
                  choppedmodulest = ".../" & string(extractFilename(uselinesq[1]))
                usedatalinest = uselinesq[0].alignLeft(33) & choppedmodulest.alignLeft(23) & uselinesq[2].alignLeft(10) & uselinesq[3]
                btfileob.writeLine("        " & usedatalinest)


          elif viewtypeeu == viewExtended_OneLevel:
            eofileob.writeLine("----------------------------------------------------------------------")            
            eofileob.writeLine(decdata_ekst)          
          elif viewtypeeu == viewExtended_TwoLevels:
            etfileob.writeLine("----------------------------------------------------------------------")            
            etfileob.writeLine(decdata_ekst)


          if viewtypeeu == viewExtended_OneLevel or viewtypeeu == viewExtended_TwoLevels:
            linestartit = parseInt(linestartst.split(":")[1])
            lineendit = parseInt(lineendst.split(":")[1])
            modfilest = modulest & ".nim"
            fob = moduleta[modfilest]

            # add the parameter-declares (inputs)
            interpointar = getSliceFromLines(fob, linestartit, lineendit, "(", ")")
            #moduleta[modfilest].setFilePos(0)
            if interpointar[0] != -1 and interpointar[1] != -1 and interpointar[1] >= interpointar[0]:
              slicest = filestringta[modfilest][interpointar[0]..interpointar[1]]
            else:
              slicest = ""
              echo "    ", "missing input-params ", decnamest, " - ",  $interpointar, " - ", modulest

            # add the parameter-declares (output)
            betweenpointar = getSliceFromLines(fob, linestartit, lineendit, ")", "=")
            #moduleta[modfilest].setFilePos(0)
            if betweenpointar[0] != -1 and betweenpointar[1] != -1 and betweenpointar[1] >= betweenpointar[0]:
              nextslicest = filestringta[modfilest][betweenpointar[0]..betweenpointar[1]]
            else:
              nextslicest = ""
              echo  "    ", "missing output-params ", decnamest, " - ",  $betweenpointar, " - ", modulest


            if viewtypeeu == viewExtended_OneLevel:
              eofileob.writeLine("        (" & slicest & ")" & nextslicest)
            elif viewtypeeu == viewExtended_TwoLevels:
              etfileob.writeLine("        (" & slicest & ")" & nextslicest)


            # add the comment-blocks
            interpointar = getSliceFromLines(fob, linestartit, lineendit, "#[", "]#")
            #moduleta[modfilest].setFilePos(0)
            if interpointar[0] != -1 and interpointar[1] != -1 and interpointar[1] >= interpointar[0]:
              slicest = filestringta[modfilest][interpointar[0]..interpointar[1]]
              if viewtypeeu == viewExtended_OneLevel:
                eofileob.writeLine("        " & slicest)
              elif viewtypeeu == viewExtended_TwoLevels:
                etfileob.writeLine("        " & slicest)

            let num_double_commentit: int = parseInt(readOptionFromFile("number_double_hash_comments", optValue))
            let num_single_commentit: int = parseInt(readOptionFromFile("number_single_hash_comments", optValue))

            # add separate comment-lines if present
            doublehashsq = getXLinesWithSubstring(fob, "## ", linestartit, lineendit , num_double_commentit)
            singlehashsq = getXLinesWithSubstring(fob, "# ", linestartit, lineendit , num_single_commentit)

            commentlinesq = doublehashsq & singlehashsq

            if viewtypeeu == viewExtended_OneLevel:
              eofileob.writeLine("")
              for commentlinest in commentlinesq:
                eofileob.writeLine(commentlinest)
            elif viewtypeeu == viewExtended_TwoLevels:
              etfileob.writeLine("")
              for commentlinest in commentlinesq:
                etfileob.writeLine(commentlinest)


            if viewtypeeu == viewExtended_TwoLevels:
              etfileob.writeLine(" ")
              for it, uselinest in dlinesq:
                if it > 0:
                  uselinesq = uselinest.split(sep1st)
                  choppedmodulest = extractFilename(uselinesq[1])
                  if choppedmodulest != uselinesq[1]:
                    choppedmodulest = ".../" & string(extractFilename(uselinesq[1]))
                  usedatalinest = uselinesq[0].alignLeft(33) & choppedmodulest.alignLeft(23) & uselinesq[2].alignLeft(10) & uselinesq[3]
                  etfileob.writeLine("        " & usedatalinest)


    decfilob.close()

    if viewtypeeu == viewBasic_OneLevel:
      bofileob.close()
    elif viewtypeeu == viewBasic_TwoLevels:
      btfileob.close()
    elif viewtypeeu == viewExtended_OneLevel:
      eofileob.close()
    elif viewtypeeu == viewExtended_TwoLevels:
      etfileob.close()


    for filest in source_filesq:
      moduleta[filest].close()


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"




proc getSeqFromFileLines(filepathst, searchst, sep1st, sep2st: string, searchfieldar: array[0..1, int], substringbo: bool = true): seq[string] = 

  #[
    Add lines to the sequence which match the search-filter.
    Search with substring, string or wildcard * for search-value searchst on designated  search-field, which is indicated by the coordinates on the sep-divided line.
    
    Like so:
    part-a1~~~parta2===partb1~~~partb2
    part-b2 = [1,1]

    Call like:
    foundlinesq = getSeqFromFileLines(decfilepathst, declarationst, sep3st, sep1st, [0,0])

    extra separator and sortfieldar may come later    
  ]#

  var 
    fileob: File
    searchfieldvalst: string
    outputsq: seq[string] = @[]

  try:
    fileob = open(filepathst, fmRead)

    for linest in fileob.lines:
      searchfieldvalst = linest.split(sep1st)[searchfieldar[0]].split(sep2st)[searchfieldar[1]]
      if searchst == "*":     # get all decs
        outputsq.add(linest)
      else: 
        #echo searchfieldvalst & "-----" & searchst
        if substringbo:        
          if searchfieldvalst.toLowerAscii.contains(searchst.toLowerAscii):
            outputsq.add(linest)
        else:
          if searchfieldvalst.toLowerAscii == searchst.toLowerAscii:
            outputsq.add(linest)

    fileob.close()
    result = outputsq


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"



proc getSeqFromFileLines2(filepathst, fstsearchst, secsearchst, sep1st, sep2st: string, fstsearchfieldar, secsearchfieldar: array[0..1, int], substringbo: bool = true): seq[string] = 

  #[
    Add lines to the sequence which match the search-filter.
    In this extended proc first and second search-value and -field can be used.

    Search with substring, string or wildcard * for search-values fst/sec-searchst on designated  fst/sec-search-field, which is indicated by the coordinates on the sep-divided line.
    
    Like so:
    part-a1~~~parta2===partb1~~~partb2
    part-b2 = [1,1]

    extra separator and sortfieldar may come later
  ]#

  var 
    fileob: File
    fstsearchfieldvalst, secsearchfieldvalst: string
    outputsq: seq[string] = @[]

  try:
    fileob = open(filepathst, fmRead)

    for linest in fileob.lines:

      #echo linest
      fstsearchfieldvalst = linest.split(sep1st)[fstsearchfieldar[0]].split(sep2st)[fstsearchfieldar[1]]
      secsearchfieldvalst = linest.split(sep1st)[secsearchfieldar[0]].split(sep2st)[secsearchfieldar[1]]
      #echo fstsearchfieldvalst & "-----" & fstsearchst
      #echo secsearchfieldvalst & "-----" & secsearchst

      if fstsearchst == "*" and secsearchst == "*":     # get all decs
        outputsq.add(linest)
      elif fstsearchst == "*" and secsearchst != "*":
        if substringbo:        
          if secsearchfieldvalst.toLowerAscii.contains(secsearchst.toLowerAscii):
            outputsq.add(linest)
        else:
          if secsearchfieldvalst.toLowerAscii == secsearchst.toLowerAscii:
            outputsq.add(linest)
      elif fstsearchst != "*" and secsearchst == "*":
        if substringbo:        
          if fstsearchfieldvalst.toLowerAscii.contains(fstsearchst.toLowerAscii):
            outputsq.add(linest)
        else:
          if fstsearchfieldvalst.toLowerAscii == fstsearchst.toLowerAscii:
            outputsq.add(linest)
      else: 
        if substringbo:
          if fstsearchfieldvalst.toLowerAscii.contains(fstsearchst.toLowerAscii) and secsearchfieldvalst.toLowerAscii.contains(secsearchst.toLowerAscii):
            outputsq.add(linest)
        else:
          if fstsearchfieldvalst.toLowerAscii == fstsearchst.toLowerAscii and secsearchfieldvalst.toLowerAscii == secsearchst.toLowerAscii:
            outputsq.add(linest)

    fileob.close()
    result = outputsq


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"



proc getSeqFromLinesSpecial(filepathst, searchst, sep1st, sep2st: string, projectst = ""): seq[string] = 
  #[
    Search-function specific for the dec-list phase-3.
    It searches in all the used declarations for each line.
    It returns the line if one of the used declarations matches substringwise.

    MAYBE:
    extra separator and sortfieldar may come later
  ]#

  var 
    fileob: File
    searchfieldvalst: string
    outputsq, declaresq, sublinesq, fieldvalsq: seq[string] = @[]
    project_matchingbo: bool

  try:
    fileob = open(filepathst, fmRead)

    for linest in fileob.lines:
      project_matchingbo = false
      declaresq = linest.split(sep1st)
      for it, sublinest in declaresq:
        if it == 0:
          if projectst != "":
            fieldvalsq = sublinest.split(sep2st)
            if fieldvalsq[7] == projectst:
              project_matchingbo = true
        if it > 0:
          if projectst == "":
            fieldvalsq = sublinest.split(sep2st)
            if fieldvalsq[0].toLowerAscii == searchst.toLowerAscii:
              if linest notin outputsq:
                outputsq.add(linest)
          else:
            if project_matchingbo:
              fieldvalsq = sublinest.split(sep2st)
              if fieldvalsq[0].toLowerAscii == searchst.toLowerAscii:
                if linest notin outputsq:
                  outputsq.add(linest)


    fileob.close()
    result = outputsq


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"



#[
proc writeFamily_new(proj_def_pathst, declarationst, modulest, directionst: string, curdepthit, maxdepthit: int, projectst: string = "") = 

#[
  Recursive procedure to write / echo either used or used-by declarations, which can also be seen as children and parents.
]#


  var 
    decfileob: File 
    decfilepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    source_filesq, foundlinesq, wordsq, dlinesq, uselinesq: seq[string]
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = "___"
    sep3st = "==="
    inputst, outputst: string
    onelinest, declarest, usedatalinest, indentationst, decdatalinest: string
    choppedmodulest, decfilecontentst: string
    projectprefikst: string


  try:

    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    projectprefikst = clipString(string(pd_filebasepa), 7)
    decfilepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase3_" & dec_list_suffikst))
    decfileob = open(decfilepathst, fmRead)
    decfilecontentst = readAll(decfileob)


    var imported_modulesq: seq[string]
    var check_for_imported_modulesbo: bool = true
    #imported_modulesq = getNimImports(modulest & ".nim")


    if directionst == "usage":
      if curdepthit == 1:
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[declarationst, modulest, projectst], @[cmSub, cmSub, cmSub], @[@[0,0], @[0,1], @[0,7]])
      else:
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[declarationst, projectst], @[cmSub, cmExact], @[@[0,0], @[0,7]])


      onelinest = foundlinesq[0]
      dlinesq = onelinest.split(sep3st)

      for it, uselinest in dlinesq:
        if it > 0:
          uselinesq = uselinest.split(sep1st)
          choppedmodulest = extractFilename(uselinesq[1])

          if not check_for_imported_modulesbo or imported_modulesq.substringInSequence(choppedmodulest):

            if choppedmodulest != uselinesq[1]:
              choppedmodulest = ".../" & string(extractFilename(uselinesq[1]))
            usedatalinest = uselinesq[0].alignLeft(33) & choppedmodulest.alignLeft(23) & uselinesq[2].alignLeft(15) & uselinesq[3]
            indentationst = "    ".repeat(curdepthit)
            echo indentationst & usedatalinest
            if curdepthit <= maxdepthit:
              writeFamily(proj_def_pathst, uselinesq[0],"" ,directionst, curdepthit + 1 , maxdepthit, projectst)


    elif directionst == "used-by":

      foundlinesq = getSeqFromLinesSpecial(decfilepathst, declarationst, sep3st, sep1st, projectst)
      for linest in foundlinesq:
        dlinesq = linest.split(sep3st)[0].split(sep1st)
        choppedmodulest = extractFilename(dlinesq[1])
        if choppedmodulest != dlinesq[1]:
          choppedmodulest = ".../" & string(extractFilename(dlinesq[1]))
        decdatalinest = dlinesq[0].alignLeft(33) & choppedmodulest.alignLeft(23) & dlinesq[2].alignLeft(20) & dlinesq[3].alignLeft(15) & dlinesq[7].alignLeft(15) 
        indentationst = "    ".repeat(curdepthit)
        echo indentationst & decdatalinest
        if curdepthit <= maxdepthit:
          writeFamily(proj_def_pathst, dlinesq[0], "",directionst, curdepthit + 1 , maxdepthit, projectst)


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"
]#


proc writeFamily(proj_def_pathst, declarationst, modulest, directionst: string, curdepthit, maxdepthit: int, projectst: string = "") = 

#[
  Recursive procedure to write / echo either used or used-by declarations, which can also be seen as children and parents.
]#


  var 
    decfileob: File 
    decfilepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    source_filesq, foundlinesq, wordsq, dlinesq, uselinesq: seq[string]
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = "___"
    sep3st = "==="
    inputst, outputst: string
    onelinest, declarest, usedatalinest, indentationst, decdatalinest: string
    choppedmodulest, decfilecontentst: string
    projectprefikst: string


  try:

    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    projectprefikst = clipString(string(pd_filebasepa), 7)
    decfilepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase3_" & dec_list_suffikst))
    decfileob = open(decfilepathst, fmRead)
    decfilecontentst = readAll(decfileob)


    if directionst == "usage":
      if curdepthit == 1:
        #foundlinesq = getSeqFromFileLines2(decfilepathst, declarationst, modulest, sep3st, sep1st, [0,0], [0,1])
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[declarationst, modulest, projectst], @[cmSub, cmSub, cmSub], @[@[0,0], @[0,1], @[0,7]])
      else:
        #foundlinesq = getSeqFromFileLines(decfilepathst, declarationst, sep3st, sep1st, [0,0])
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[declarationst, projectst], @[cmSub, cmExact], @[@[0,0], @[0,7]])


      onelinest = foundlinesq[0]
      dlinesq = onelinest.split(sep3st)

      for it, uselinest in dlinesq:
        if it > 0:
          uselinesq = uselinest.split(sep1st)
          choppedmodulest = extractFilename(uselinesq[1])
          if choppedmodulest != uselinesq[1]:
            choppedmodulest = ".../" & string(extractFilename(uselinesq[1]))
          usedatalinest = uselinesq[0].alignLeft(33) & choppedmodulest.alignLeft(23) & uselinesq[2].alignLeft(15) & uselinesq[3]
          indentationst = "    ".repeat(curdepthit)
          echo indentationst & usedatalinest
          if curdepthit <= maxdepthit:
            writeFamily(proj_def_pathst, uselinesq[0],"" ,directionst, curdepthit + 1 , maxdepthit, projectst)


    elif directionst == "used-by":

      foundlinesq = getSeqFromLinesSpecial(decfilepathst, declarationst, sep3st, sep1st, projectst)
      for linest in foundlinesq:
        dlinesq = linest.split(sep3st)[0].split(sep1st)
        choppedmodulest = extractFilename(dlinesq[1])
        if choppedmodulest != dlinesq[1]:
          choppedmodulest = ".../" & string(extractFilename(dlinesq[1]))
        decdatalinest = dlinesq[0].alignLeft(33) & choppedmodulest.alignLeft(23) & dlinesq[2].alignLeft(20) & dlinesq[3].alignLeft(15) & dlinesq[7].alignLeft(15) 
        indentationst = "    ".repeat(curdepthit)
        echo indentationst & decdatalinest
        if curdepthit <= maxdepthit:
          writeFamily(proj_def_pathst, dlinesq[0], "",directionst, curdepthit + 1 , maxdepthit, projectst)


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"



proc echoDeclarationData(proj_def_pathst, declarationst, modulest: string, projectst: string = "") = 

  #[
    Echo extra data of the declare like parameters and comment.
  ]#

  var 
    fob, modfileob, decfileob: File 
    decfilepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    dlinesq, decdatasq, singlelinesq: seq[string]

    sep1st = "~~~"
    sep3st = "==="
    decnamest, dectypest, linestartst, lineendst: string
    interpointar, betweenpointar: array[0..1, int]
    modfilest, slicest, nextslicest, modstringst, dlinest: string
    linestartit, lineendit: int
    commentlinesq, singlehashsq, doublehashsq: seq[string]
    reconstructed_project_def_pathst, decfilecontentst: string
    projectprefikst: string

  try:
    wispbo = false
    wisp("projectst = ", projectst)


    if proj_def_pathst.extractFileExtension() == "mul":
      reconstructed_project_def_pathst = string(Path(ct_projectsdirst) / Path(projectst & ".pro"))
      sourceprojectpathst = extractFileSectionToSequence(reconstructed_project_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    elif proj_def_pathst.extractFileExtension() == "pro":
      # retrieve project-data from project-def-file
      sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    else:
      echo "Your (multi-)project-definition \"" & proj_def_pathst & "\" has an invalid extension (must be .pro or .mul)"


    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    projectprefikst = clipString(string(pd_filebasepa), 7)
    decfilepathst = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase3_" & dec_list_suffikst))
    decfileob = open(decfilepathst, fmRead)
    decfilecontentst = readAll(decfileob)

    modfilest = string(Path(sourceprojectpathst) / Path(modulest & ".nim"))
    modfileob = open(modfilest, fmRead)
    modstringst = readAll(modfileob)

    #singlelinesq = getSeqFromFileLines2(decfilepathst, declarationst, modulest, sep3st, sep1st, [0,0], [0,1], false)
    singlelinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[declarationst, modulest, projectst], @[cmExact, cmSub, cmSub], @[@[0,0], @[0,1], @[0,7]])

    dlinest = singlelinesq[0]
    dlinesq = dlinest.split(sep3st)
    decdatasq = dlinesq[0].split(sep1st)
    #decnamest = decdatasq[0]
    #dectypest = decdatasq[2]
    linestartst = decdatasq[3]
    lineendst = decdatasq[6]


    linestartit = parseInt(linestartst.split(":")[1])
    lineendit = parseInt(lineendst.split(":")[1])
    fob = modfileob


    # add the parameter-declares (inputs)
    interpointar = getSliceFromLines(fob, linestartit, lineendit, "(", ")")
    if interpointar[0] != -1 and interpointar[1] != -1 and interpointar[1] >= interpointar[0]:
      slicest = modstringst[interpointar[0]..interpointar[1]]
    else:
      slicest = ""
      #echo "    ", "missing input-params ", decnamest, " - ",  $interpointar, " - ", modulest

    # add the parameter-declares (output)
    betweenpointar = getSliceFromLines(fob, linestartit, lineendit, ")", "=")
    if betweenpointar[0] != -1 and betweenpointar[1] != -1 and betweenpointar[1] >= betweenpointar[0]:
      nextslicest = modstringst[betweenpointar[0]..betweenpointar[1]]
    else:
      nextslicest = ""
      #echo  "    ", "missing output-params ", decnamest, " - ",  $betweenpointar, " - ", modulest

    echo("        (" & slicest & ")" & nextslicest & "\p")


    # add the comment-blocks
    interpointar = getSliceFromLines(fob, linestartit, lineendit, "#[", "]#")
    if interpointar[0] != -1 and interpointar[1] != -1 and interpointar[1] >= interpointar[0]:
      slicest = modstringst[interpointar[0]..interpointar[1]]
      echo("        " & slicest & "\p")

    let num_double_commentit: int = parseInt(readOptionFromFile("number_double_hash_comments", optValue))
    let num_single_commentit: int = parseInt(readOptionFromFile("number_single_hash_comments", optValue))

    # add separate comment-lines if present
    doublehashsq = getXLinesWithSubstring(fob, "## ", linestartit, lineendit , num_double_commentit)
    singlehashsq = getXLinesWithSubstring(fob, "# ", linestartit, lineendit , num_single_commentit)

    commentlinesq = doublehashsq & singlehashsq
    for commentlinest in commentlinesq:
      echo(commentlinest)
    echo()


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"






proc findLines(inputst, sep1st, sep3st, decfilecontentst, projecttypest: string): seq[string] = 

  var 
    inputsq: seq[string] = inputst.split(";")
    foundlinesq: seq[string]
    linestartst: string


  if inputsq.len == 1:

    if inputst.contains("~"):
      if inputst.startswith("~") or inputst.endswith("~"):
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputst.strip(chars = {'~'})], @[cmExactInsens], @[@[0,0]])
      else:       # linestart-num has been given
        linestartst = inputst.split("~")[1].strip()
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st, ":"], @[], @[inputst.split("~")[0], linestartst], @[cmExactInsens, cmExact], @[@[0,0], @[0,3,1]])
    else:
      foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputst], @[cmSubInsens], @[@[0,0]])


  elif inputsq.len == 2:

    if projecttypest == "single":
      if inputst.contains("~"):
        if inputsq[0].startswith("~") or inputsq[0].endswith("~"):
          foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputsq[0].strip(chars = {'~'}), inputsq[1]], @[cmExactInsens, cmSubInsens], @[@[0,0], @[0,1]])
        else:
          linestartst = inputsq[0].split("~")[1].strip()
          foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st, ":"], @[], @[inputsq[0].split("~")[0], inputsq[1], linestartst], @[cmExactInsens, cmSubInsens, cmExact], @[@[0,0], @[0,1], @[0,3,1]])
      else:
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputsq[0], inputsq[1]], @[cmSubInsens, cmSubInsens], @[@[0,0], @[0,1]])
    else:
      echo "For multi-projects: Enter one item (proc) or three items (declaration;module;project); it can be emtpy"


  elif inputsq.len == 3:

    if inputst.contains("~"):
      if inputsq[0].startswith("~") or inputsq[0].endswith("~"):
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputsq[0].strip(chars = {'~'}), inputsq[1], inputsq[2]], @[cmExactInsens, cmSubInsens, cmSubInsens], @[@[0,0], @[0,1], @[0,7]])
      else:
        linestartst = inputsq[0].split("~")[1].strip()
        foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st, ":"], @[], @[inputsq[0].split("~")[0], inputsq[1], inputsq[2], linestartst], @[cmExactInsens, cmSubInsens, cmSubInsens, cmExact], @[@[0,0], @[0,1], @[0,7], @[0,3,1]])
    else:
      foundlinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputsq[0], inputsq[1], inputsq[2]], @[cmSubInsens, cmSubInsens, cmSubInsens], @[@[0,0], @[0,1], @[0,7]])


  result = foundlinesq




proc echoDeclarationParts(linest, sep3st, sep1st, proj_def_pathst, directionst: string, maxdepthit: int) = 

  var 
    wordsq: seq[string]
    outputst: string
    declarest, modulest, dectypest, linestartst: string
    projectst: string

  echo "=============================================================================================================="
  #onelinest = foundlinesq[0]
  wordsq = linest.split(sep3st)[0].split(sep1st)
  declarest = wordsq[0]
  modulest = wordsq[1]
  dectypest = wordsq[2]
  linestartst = wordsq[3].split(":")[1]
  projectst = wordsq[7]
  outputst = declarest.alignLeft(33) & modulest.alignLeft(40) & dectypest.alignLeft(15) & linestartst.alignLeft(10) & projectst.alignLeft(12)
  echo declarest, " - ", modulest, "                   ", "show declaration-parts, direction: ", directionst, ", maxdepth: ", $maxdepthit, "\p"
  echoDeclarationData(proj_def_pathst, declarest, modulest, projectst)
  echo outputst
  echo "--------------------------------------------------------------------------------------------------------------"
  writeFamily(proj_def_pathst, declarest, modulest, directionst, 1, maxdepthit, projectst)
  echo "--------------------------------------------------------------------------------------------------------------"




proc getRangeOfFileLines(filepathst: string, linestartit, lineendit: int): seq[string] = 
  #[
    Write the lines of the range starting with linestartit and ending with lineendit 
    to an output-sequence and return it.
  ]#
  
  var 
    in_declarebo: bool = false
    outputsq: seq[string] = @[]
    linecountit: int = 0

  result = outputsq

  withFileAdvanced(fileob, filepathst, fmRead):
    for linest in fileob.lines:
      linecountit += 1
      if linecountit == linestartit:
        in_declarebo = true
      elif linecountit == lineendit + 1:
        in_declarebo = false

      if in_declarebo:
        outputsq.add(linest)

      result = outputsq



proc echoSequence(inputsq: seq[string]) = 
  for linest in inputsq:
    echo linest


proc echoRangeOfFileLines(filepathst: string, linestartit, lineendit: int) = 

  echoSequence(getRangeOfFileLines(filepathst, linestartit, lineendit))



proc getModulePath(proj_def_pathst, modulest, projectst: string): string = 

  var 
    reconstructed_project_def_pathst, sourceprojectpathst, modfilest: string

  if proj_def_pathst.extractFileExtension() == "mul":
    reconstructed_project_def_pathst = string(Path(ct_projectsdirst) / Path(projectst & ".pro"))
    sourceprojectpathst = extractFileSectionToSequence(reconstructed_project_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
  elif proj_def_pathst.extractFileExtension() == "pro":
    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
  else:
    echo "Your (multi-)project-definition \"" & proj_def_pathst & "\" has an invalid extension (must be .pro or .mul)"

  modfilest = string(Path(sourceprojectpathst) / Path(modulest & ".nim"))
  result = modfilest




proc echoSourceCode(linest, sep3st, sep1st, proj_def_pathst: string) = 



  var 
    wordsq: seq[string]
    outputst: string
    declarest, modulest, dectypest, linestartst, lineendst: string
    projectst: string


  echo "============================================================================================================"
  wordsq = linest.split(sep3st)[0].split(sep1st)
  declarest = wordsq[0]
  modulest = wordsq[1]
  linestartst = wordsq[3].split(":")[1]
  lineendst = wordsq[6].split(":")[1]
  projectst = wordsq[7]

  outputst = wordsq[0].alignLeft(33) & wordsq[1].alignLeft(40) & wordsq[2].alignLeft(15) & wordsq[3].split(":")[1].alignLeft(10) & wordsq[7].alignLeft(12)

  echo declarest, " - ", modulest, "                         show SourceCode\p"   
  echo outputst
  echo "--------------------------------------------------------------------------------------------------------------\p"
  echoRangeOfFileLines(getModulePath(proj_def_pathst, modulest, projectst), parseInt(linestartst), parseInt(lineendst))

  echo "--------------------------------------------------------------------------------------------------------------"





proc showItem(itemtypeu: ItemType, proj_def_pathst: string, directionst = "", maxdepthit = 0) = 

#[
  Show either declarational partial data or full source-code
]#


  try:

    var projecttypest: string
    if proj_def_pathst.extractFileExtension() == "mul":
      projecttypest = "multi"
    elif proj_def_pathst.extractFileExtension() == "pro":
      projecttypest = "single"
    else:
      echo "Your (multi-)project-definition \"" & proj_def_pathst & "\" has an invalid extension (must be .pro or .mul)"


    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    var reltargetprojectpathst: string = string(Path(ct_projectsdirst) / pd_filebasepa)


    var projectprefikst: string = clipString(string(pd_filebasepa), 7)
    var decfilepathst: string = string(Path(reltargetprojectpathst) / Path(projectprefikst & "_phase3_" & dec_list_suffikst))

    var decfilob: File = open(decfilepathst, fmRead)
    var decfilecontentst: string = decfilob.readAll()

    var inputst = ""
    while inputst notin ["exit","quit"]:

      echo "--------------------------------------------------------"
      if itemtypeu == itemDeclaration:
        echo "show declaration-parts;   Direction (tree-type) = ", directionst, ", Maxdepth = ", maxdepthit
      elif itemtypeu == itemSourceCode:
        echo "show the sourcecode of the declaration"
      echo "Enter:  declaration;module;project      to view specific items, emtpy for all items, or exit to exit: "

      inputst = readline(stdin)
      wisp(inputst)
    
      var 
        sep1st = "~~~"
        sep2st = "___"
        sep3st = "==="

      var foundlinesq: seq[string] = findLines(inputst, sep1st, sep3st, decfilecontentst, projecttypest)


      # if no exact match found or wildcard used (all found):
      if foundlinesq.len == 0 or foundlinesq.len > 1:

        var 
          foundsublinesq, wordsq: seq[string]
          outputst: string
          onelinest, declarest, modulest, dectypest, linestartst: string
          projectst: string


        if foundlinesq.len == 0:
          # maybe find something with substring-search
          foundsublinesq = readFromSeparatedString(decfilecontentst, "\p" , @[sep3st, sep1st], @[], @[inputst], @[cmSubInsens], @[@[0,0]])
        else:   # when wildcard has been entered (all found) proceed as if many are found
          foundsublinesq = foundlinesq

        if foundsublinesq.len > 1:
          #echo foundlinesq
          echo "=============================================================================================================="
          for linest in foundsublinesq:
            wordsq = linest.split(sep3st)[0].split(sep1st)
            outputst = wordsq[0].alignLeft(33) & wordsq[1].alignLeft(40) & wordsq[2].alignLeft(15) & wordsq[3].split(":")[1].alignLeft(10) & wordsq[7].alignLeft(12)
            echo outputst
          echo "--------------------------------------------------------------------------------------------------------------"
        elif foundsublinesq.len == 1:

          if itemtypeu == itemDeclaration:
            echoDeclarationParts(foundsublinesq[0], sep3st, sep1st, proj_def_pathst, directionst, maxdepthit)
          elif itemtypeu == itemSourceCode:
            echoSourceCode(foundsublinesq[0], sep3st, sep1st, proj_def_pathst)


        elif foundsublinesq.len == 0:
          echo "Item not found..."

      elif foundlinesq.len == 1:

        if itemtypeu == itemDeclaration:
          echoDeclarationParts(foundlinesq[0], sep3st, sep1st, proj_def_pathst, directionst, maxdepthit)
        elif itemtypeu == itemSourceCode:
          echoSourceCode(foundlinesq[0], sep3st, sep1st, proj_def_pathst)


    echo "Exiting..."


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"





proc showDeclarationBranch(proj_def_pathst, directionst: string, maxdepthit: int) = 

  #[
    Show a tree of declarations; either a usage-tree or a used-by-tree.
  ]#

  showItem(itemDeclaration, proj_def_pathst, directionst, maxdepthit)



proc showSourceCode(proj_def_pathst: string) = 

  #[
    Show the source-code of a declaration
  ]#

  showItem(itemSourceCode, proj_def_pathst)




proc echoHelpInfo() = 

  echo "Help for CodeTwig:"
  echo "Command-structure long-style: ctwig projects/someproject.pro --command:somecommand --extrakey:somevalue" 
  echo "Command-structure short-style: ctwig projects/someproject.pro -c:s -k:v" 
  echo "Most commands require a project-path, but not help:"
  echo "ctwig -h or ctwig --help"
  echo "As option-separator one can use ':', '=' or none"
  echo "---------------------------------------------------"
  var allcommandst = """
    for kind, key, val in optob.getopt():
      case kind:
      of cmdArgument:                       # without hyphen(s); used here for project-definition-file-path
        projectpathst = key
      of cmdShortOption, cmdLongOption:
        case key:
        of "c", "command": 
          case val:
          of "a", "add_files":
            procst = "addSourceFilesToProject"
          of "d", "declarations":
            procst =  "createDeclarationList"
          of "c", "combine":                       # combine multiple projects / dec-lists (later more?)
            procst = "createMultiProjectFiles"
          of "v", "views":
            procst = "createAllViewFiles"
          of "g", "generate_all":                 # both dec-lists and view-files
            procst = "generate_all"
          of "t", "tree":
            procst = "showDeclarationBranch"
          of "s", "sourcecode":
            procst = "showSourceCode"
        of "r", "direction":
          case val:
          of "u", "usage":
            directionst = "usage"
          of "b", "used-by":
            directionst = "used-by"          
        of "d", "depth":
          depthit = parseInt(val)
        of "h", "help":
          procst = "echoHelpInfo"
      of cmdEnd: 
        assert(false) # cannot happen
  """
  echo allcommandst



proc createMultiProjectFiles(multiprojectdefst: string) = 

#[
  Currently:
  v-create a multi-project directory based on your .mul-file
  v-Concatenate the dec-lists from multiple projects as defined in your 
  multi-project-definition (.mul)

  (After you have defined some projects in project-files (.pro),
  you can create a multi-project-definition that enables you to show 
  more projects at once; for now that is trees of usage and used-by.)

]#
  
  var 
    reltargetprojectpathst, multiprojectnamest, projectst, declist: string
    project_filesq, dec_list_filepathsq: seq[string]
    newdeclist: string


  # create a target-dir and -file, ie the dec-list
  var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(multiprojectdefst))
  reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)
  multiprojectnamest = string(pd_filebasepa)

  if not dirExists(reltargetprojectpathst):   
    createDir(reltargetprojectpathst)     # proc creates subdirs also
    echo "Creating target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst
  else:
    echo "Using target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst
  
  # extract the project-file-names from the multiproj-file
  project_filesq = extractFileSectionToSequence(multiprojectdefst, "PROJECTS_LIST", ">----------------------------------<")


  # retrieve the phase3 dec-list for all projects and put them in a list-seq
  for pfilest in project_filesq:
    projectst = pfilest[0..pfilest.len - 5]

    declist = ct_projectsdirst & "/" & projectst  & "/" & clipString(projectst, 7) & "_phase3_dec_list.dat"
    dec_list_filepathsq.add(declist)

  newdeclist = reltargetprojectpathst & "/" & clipString(multiprojectnamest, 7) & "_phase3_dec_list.dat"

  concatenateFiles(dec_list_filepathsq, newdeclist)




proc createAllViewFiles(filepathst: string) = 

  createCodeViewFile(filepathst, viewBasic_OneLevel)
  createCodeViewFile(filepathst, viewBasic_TwoLevels)
  createCodeViewFile(filepathst, viewExtended_OneLevel)
  createCodeViewFile(filepathst, viewExtended_TwoLevels)



proc generate_all(projectpathst: string) = 

  createDeclarationList(projectpathst)
  createAllViewFiles(projectpathst)




proc processCommandLine() = 
#[
  firstly load the args from the commandline and set the needed vars 
  then run the chosen procedures.

  test: string
]#


  var 
    optob = initOptParser(shortNoVal = {'h'}, longNoVal = @["help"])
    #optob = initOptParser()
    projectpathst, procst: string = ""
    directionst = "usage"
    depthit: int = 3
  
  try:

    # firstly load the args from the commandline and set the needed vars 
    for kind, key, val in optob.getopt():
      case kind:
      of cmdArgument:                       # without hyphen(s); used here for project-definition-file-path
        projectpathst = key
      of cmdShortOption, cmdLongOption:
        case key:
        of "c", "command": 
          case val:
          of "a", "add_files":
            procst = "addSourceFilesToProject"
          of "d", "declarations":
            procst =  "createDeclarationList"
          of "c", "combine":                       # combine multiple projects / dec-lists (later more?)
            procst = "createMultiProjectFiles"
          of "v", "views":
            procst = "createAllViewFiles"
          of "g", "generate_all":                 # both dec-lists and view-files
            procst = "generate_all"
          of "t", "tree":
            procst = "showDeclarationBranch"
          of "s", "sourcecode":
            procst = "showSourceCode"
        of "r", "direction":
          case val:
          of "u", "usage":
            directionst = "usage"
          of "b", "used-by":
            directionst = "used-by"          
        of "d", "depth":
          if val != "":
            depthit = parseInt(val)
          else:
            echo "You entered the depth-key(-d), but not the value (like: -d:2)."
        of "h", "help":
          procst = "echoHelpInfo"
      of cmdEnd: 
        assert(false) # cannot happen



    echo "----------------------------------------------------"
    echo "Thanks for using CodeTwig " & $versionfl
    echo "Project-path = " & projectpathst
    echo "Chosen procedure = " & procst
    echo "For help type: ctwig -h or ctwig --help"
    echo "----------------------------------------------------"

    if procst != "":
      if projectpathst != "" or procst == "echoHelpInfo":

        case procst
        of "addSourceFilesToProject":
          echo addSourceFilesToProject(projectpathst)
        of "createDeclarationList":
          createDeclarationList(projectpathst)
        of "createMultiProjectFiles":
          createMultiProjectFiles(projectpathst)
        of "createAllViewFiles":
          createAllViewFiles(projectpathst)
        of "generate_all":
          generate_all(projectpathst)
        of "showDeclarationBranch":
          showDeclarationBranch(projectpathst, directionst, depthit)
        of "showSourceCode":
          showSourceCode(projectpathst)
        of "echoHelpInfo":
          echoHelpInfo()

      else:
        echo "A project-file was not provided (like: projects/someproject.pro)"
    else:
      echo "A command-option was not provided (like -c=a or -c=t); exiting..."


  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob)
    echo "\p****End exception****\p"






var for_realbo: bool = true
if for_realbo:

  processCommandLine()

else:
  var 
    filepathst: string = "projects/readibl_test.pro"
    #filepathst: string = "projects/readibl_test/readibl_phase3_dec_list.dat"
    #mytekst = "proc crazyname(var)"
    mytekst = "proc new("
    filest: string
    myarray: array[0..1, int]
    fileob: File
  if false:
    echo addSourceFilesToProject(filepathst)
  if false:
    echo extractFileSectionToSequence(filepathst, "SOURCE_FILES", ">----------------------------------<")
  if false:
    #myarray = getSliceFromAnchor(mytekst, "proc", @["(", "[", "*", " "], true)
    myarray = getSliceFromAnchor(mytekst, "proc", @["(", "[", "*", " "], true)

    echo myarray
    echo mytekst
    if myarray != [-1, -1]:
      if myarray[1] != 99999999:
        echo mytekst[myarray[0]..myarray[1]]
      else:
        echo "no target-string or end-string found"
    else:
      echo "anchor not found"
  if false:
    fileob = open(filepathst, fmRead)
    myarray = getSliceFromLines(fileob, 0, 40, "(", ")")
    echo myarray

    fileob.setFilePos(0)
    filest = readAll(fileob)
    fileob.close()
    echo filest.len
    echo filest[myarray[0]..myarray[1]]


  if false:
    createDeclarationList(filepathst)
  if false:
    createCodeViewFile(filepathst, viewBasic_OneLevel)
    createCodeViewFile(filepathst, viewBasic_TwoLevels)
    createCodeViewFile(filepathst, viewExtended_OneLevel)
    createCodeViewFile(filepathst, viewExtended_TwoLevels)

  if false:
    #echo "getSeqFromFileLines2"
    #echo getSeqFromFileLines(filepathst, "*", "===" , "~~~", [0,0], true).len
    echo getSeqFromFileLines2(filepathst, "log", "", "===" , "~~~", [0,0], [0,1], true).len

  if false:
    showDeclarationBranch(filepathst, "usage", 3)
    #showDeclarationBranch(filepathst, "used-by", 5)

  if false:
    echoDeclarationData(filepathst, "formatText", "process_text")

  if false:
    createMultiProjectFiles("projects/myprojects.mul")

  if false:
    echo extractFileExtension("opa.oma.txt")

  if false:
    echo getNimImports("jolibs/generic/g_cookie.nim")

  if false:
    echo getStandardLibsOfNim("nim_std_lib.lst")

  if false:
    #testNimImports("projects/freekwensie.pro")
    testNimImports("projects/codetwig.pro")

  if true:
    var tekst = "aapnootmies"

    echo "containsWithValidBoundaries = ", $containsWithValidBoundaries(tekst, "noot", @["p"], @["mi"], true, true)

