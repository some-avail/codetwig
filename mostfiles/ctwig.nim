#[
Program to generate code-trees from a terminal window.

Firstly you must create a project.
- make a project-definition-file with at least the path to the project
- ctwig_make_project can add the source-files to the project-file
- user can prune the unneeded source-files

Then you can show trees.
For example for function myFunc you run:
ctwig myfunc

]#

import g_disk2nim, g_templates
#import std/[os, strutils, paths, dirs, tables, unicode]
import std/[os, strutils, paths, dirs, tables, parseopt]


var 
  versionfl: float = 0.32
  codetwigst: string = "CodeTwig"
  ct_projectsdirst: string = "projects"
  dec_list_suffikst: string = "dec_list.dat"

type 
  ViewType = enum
    viewBasic_OneLevel
    viewBasic_TwoLevels
    viewExtended_OneLevel
    viewExtended_TwoLevels
    viewAll


proc addSourceFilesToProject(proj_def_pathst: string): string = 
  #[
  Based on the project-path in the project-def-file, the source-files
  from that project are added to the project-def-file.

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
    blocklineit, source_file_posit, countit: int


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
            source_file_posit = fileob.getFilePos()
          blocklineit = 0
        elif linest != "":
        
          blocklineit += 1

          if blockphasest == "PROJECT_PATH":
            if linest != blockseparatorst:
              # read the project-path
              projectpathst = linest
              echo "Project-path of the source-files: " & projectpathst
              source_filesq = writeFilePatternToSeq2("*.nim", projectpathst)

          elif blockphasest == "SOURCE_FILES":
            if blocklineit == 1:
              if linest == blockseparatorst:
                # read the file-names of the source-files and write them to the files-section
                fileob.setFilePos(source_file_posit)
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
    nim_dec_typesq: seq[string] = @["proc", "template", "macro", "func"]
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
    excluded_declaresq: seq[string] = @["log", "l1", "else"]

    # to avoid doubles
    unique_decplusmodule2sq: seq[string]
    # must be unique
    dec_plus_modulest, previous_modulest: string


  try:

    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    source_filesq = extractFileSectionToSequence(proj_def_pathst, "SOURCE_FILES", ">----------------------------------<")

    # create a target-dir and -file, ie the dec-list
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    if not dirExists(reltargetprojectpathst):   
      createDir(reltargetprojectpathst)     # proc creates subdirs also
      echo "Creating target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst
    else:
      echo "Using target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst


    phase1_dec_list_filepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_phase1_" & dec_list_suffikst))
    phase2_dec_list_filepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_phase2_" & dec_list_suffikst))
    phase3_dec_list_filepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_phase3_" & dec_list_suffikst))


    # first phase; create first intermediate product phase1_dec_list_filepathst
    # per line: declaration, module, declaration-type, dec.line-start, col.start, col.end, dec.line-end
    echo "-------------first phase----------------"
    if phase1fileob.open(phase1_dec_list_filepathst, fmWrite):
      for filest in source_filesq:
        filepathst = string(Path(sourceprojectpathst) / Path(filest))
        modulenamest = filest[0 .. filest.len - 1 - langekst.len - 1]
        moduletitlest = moduledecorst & " " & modulenamest & " " & moduledecorst

        # below line no longer possible since addition of phase 2
        #phase1fileob.writeLine(moduletitlest)
        echo "-------- Processing file ----------- " & filest & "---------------"
        # open file for reading
        if fileob.open(filepathst, fmRead):
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

                      targlinest = dec_namest & sep1st & modulenamest & sep1st & dectypest & sep1st & "ls:" & $linecountit & sep1st & "cs:" & $dec_namear[0] & sep1st & "ce:" & $dec_namear[1]

                      phase1fileob.writeLine(targlinest)

                      echo "Line: " & $linecountit


                if not dectypefoundbo:      # other-type declares are relevant to determine declare-endings
                  if linest.endswith(":") and not linest.contains(" "):
                    # probably a macro-implementation - you want these..
                    decnamest = linest[0..linest.len - 2]
                    if decnamest notin excluded_declaresq:
                      targlinest = dec_namest & sep1st & modulenamest & sep1st & "implementation" & sep1st & "ls:" & $linecountit & sep1st & "cs:" & "0" & sep1st & "ce:" & $decnamest.len
                      phase1fileob.writeLine(targlinest)
                      echo "Line: " & $linecountit
                  else:
                    if linest.len > 15:
                      linepartst = linest[0..15]
                    else:
                      linepartst = linest[0..linest.len - 1]
                    targlinest = "other_declaration" & sep1st & modulenamest & sep1st  & linepartst & sep1st & "ls:" & $linecountit
                    phase1fileob.writeLine(targlinest)

          fileob.close()

        else:
          echo ">>>>>>>>>>>Could not open " & filepathst
    else: 
      echo ">>>>>>>>>>>Could not open " & phase1_dec_list_filepathst

    phase1fileob.close()    # close writable file


    # phase two; create new file and append declaration-endings to each line, called line-ends le, that is the last line of the declare
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
            newlinest = previous_linest & sep1st & line_endst
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

    if phase2fileob.open(phase2_dec_list_filepathst, fmRead) and phase2file2ob.open(phase2_dec_list_filepathst, fmRead) and phase3fileob.open(phase3_dec_list_filepathst, fmWrite):

      # for dec1 in dec-list:
      linecountit = 0
      for line1st in phase2fileob.lines:
        linecountit += 1
        # parse the line into data        
        line1sq = line1st.split(sep1st)
        #declarest = line1sq[0]
        modulest = line1sq[1]
        #declaretypest = line1sq[2]
        linestartit = parseInt(line1sq[3].split(":")[1])
        lineendit  = parseInt(line1sq[6].split(":")[1])
        appendst = ""
        unique_decplusmodule2sq = @[]

        # for dec2 in dec-list:
        phase2file2ob.setFilePos(0)
        for line2st in phase2file2ob.lines:          
          line2sq = line2st.split(sep1st)
          declare2st = line2sq[0]
          #echo declare2st
          module2st = line2sq[1]
          dec_plus_modulest = declare2st & "_" & module2st
          declaretype2st = line2sq[2]

          foundcountit = 0
          linecount3it = 0
          if not (declare2st in excluded_declaresq) and not (dec_plus_modulest in unique_decplusmodule2sq):
            # if the source-code-range of dec1 contains dec2:
            moduleta[modulest & ".nim"].setFilePos(0)
            for sline in moduleta[modulest & ".nim"].lines:
              linecount3it += 1
              if linecount3it > linestartit and linecount3it <= lineendit:

                commentclosingbo = false
                singlecommentbo = false
                if sline.contains("#["): incommentblockbo = true
                if sline.contains("]#"): 
                  commentclosingbo = true
                  incommentblockbo = false
                if sline.strip().startswith("#"): singlecommentbo = true

                if sline.len > 2 and not incommentblockbo and not commentclosingbo and not singlecommentbo:
                  if sline.contains(declare2st) and not sline.contains("\"" & declare2st & "\""):
                    foundcountit += 1
                    if not (dec_plus_modulest in unique_decplusmodule2sq):
                      unique_decplusmodule2sq.add(dec_plus_modulest)
                      usagest = declare2st & sep1st & module2st & sep1st & declaretype2st & sep1st & $linecount3it
                      appendst &= sep3st & usagest

        #append dec2-data to the line of dec1
        phase3fileob.writeLine(line1st & appendst)
        echo "Adding: ", $linecountit
        echo unique_decplusmodule2sq

    else:
      echo "Could not open one or three files"


    phase2fileob.close()
    phase2file2ob.close()
    phase3fileob.close()


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





proc createCodeViewFile(proj_def_pathst: string, viewtypeeu: ViewType) = 
#[
  Create view-files of the enum-type

  ADAP FUT
  ??- sort second-level decs on line-nr.
]#


  var 
    decfilob, bofileob, btfileob: File 
    decfilepathst, boview_filepathst, btview_filepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    source_filesq, dlinesq, decdatasq, uselinesq: seq[string]
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = "___"
    sep3st = "==="
    decnamest, modulest, dectypest, linestartst, newmodulest, decdatalinest: string
    usedatalinest: string


  try:
    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    source_filesq = extractFileSectionToSequence(proj_def_pathst, "SOURCE_FILES", ">----------------------------------<")

    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    echo "--------------------------------------------------------"
    echo "Using target-directory for your " & codetwigst & "-project: " & reltargetprojectpathst

    decfilepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_phase3_" & dec_list_suffikst))
    boview_filepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_basic_one-level_view.txt"))
    btview_filepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_basic_two-level_view.txt"))


    decfilob = open(decfilepathst, fmRead)
    if viewtypeeu == viewBasic_OneLevel:
      bofileob = open(boview_filepathst, fmWrite)
      echo "Creating file: " & boview_filepathst
    elif viewtypeeu == viewBasic_TwoLevels:
      btfileob = open(btview_filepathst, fmWrite)
      echo "Creating file: " & btview_filepathst


    # create view-types
    if viewtypeeu == viewBasic_OneLevel or viewtypeeu == viewBasic_TwoLevels:
      newmodulest = ""
      # basic one level
      for dlinest in decfilob.lines:
        dlinesq = dlinest.split(sep3st)
        decdatasq = dlinesq[0].split(sep1st)
        decnamest = decdatasq[0]
        modulest = decdatasq[1]
        dectypest = decdatasq[2]
        linestartst = decdatasq[3]
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

        else:
          decdatalinest = "    " & decnamest.alignLeft(33) & dectypest.alignLeft(10) & "line: " & linestartst.split(":")[1]
          if viewtypeeu == viewBasic_OneLevel:
            bofileob.writeLine(decdatalinest)
          elif viewtypeeu == viewBasic_TwoLevels:
            btfileob.writeLine(decdatalinest)

            for it, uselinest in dlinesq:
              if it > 0:
                uselinesq = uselinest.split(sep1st)
                usedatalinest = uselinesq[0].alignLeft(33) & uselinesq[1].alignLeft(20) & uselinesq[2].alignLeft(10) & uselinesq[3]
                btfileob.writeLine("        " & usedatalinest)


    decfilob.close()

    if viewtypeeu == viewBasic_OneLevel:
      bofileob.close()
    elif viewtypeeu == viewBasic_TwoLevels:
      btfileob.close()



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



proc getSeqFromLinesSpecial(filepathst, searchst, sep1st, sep2st: string): seq[string] = 
  #[
    extra separator and sortfieldar may come later
  ]#

  var 
    fileob: File
    searchfieldvalst: string
    outputsq, declaresq, uselinesq: seq[string] = @[]

  try:
    fileob = open(filepathst, fmRead)

    for linest in fileob.lines:
      declaresq = linest.split(sep1st)
      for it, uselinest in declaresq:
        if it > 0:
          uselinesq = uselinest.split(sep1st)
          if uselinesq[0].toLowerAscii.contains(searchst.toLowerAscii):
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




proc writeFamily(proj_def_pathst, declarationst, directionst: string, curdepthit, maxdepthit: int) = 

#[
  Recursive procedure to write / echo either used or used-by declarations, which can also be seen as children and parents.
]#


  var 
    decfilob: File 
    decfilepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    source_filesq, foundlinesq, wordsq, dlinesq, uselinesq: seq[string]
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = "___"
    sep3st = "==="
    inputst, outputst: string
    onelinest, declarest, usedatalinest, indentationst, decdatalinest: string

  try:
    
    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    decfilepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_phase3_" & dec_list_suffikst))

    if directionst == "usage":

      foundlinesq = getSeqFromFileLines(decfilepathst, declarationst, sep3st, sep1st, [0,0])
      onelinest = foundlinesq[0]
      dlinesq = onelinest.split(sep3st)

      for it, uselinest in dlinesq:
        if it > 0:
          uselinesq = uselinest.split(sep1st)
          usedatalinest = uselinesq[0].alignLeft(33) & uselinesq[1].alignLeft(20) & uselinesq[2].alignLeft(15) & uselinesq[3]
          indentationst = "    ".repeat(curdepthit)
          echo indentationst & usedatalinest
          if curdepthit <= maxdepthit:
            writeFamily(proj_def_pathst, uselinesq[0] ,directionst, curdepthit + 1 , maxdepthit)

    elif directionst == "used-by":

      foundlinesq = getSeqFromLinesSpecial(decfilepathst, declarationst, sep3st, sep1st)
      for linest in foundlinesq:
        dlinesq = linest.split(sep3st)[0].split(sep1st)
        decdatalinest = dlinesq[0].alignLeft(33) & dlinesq[1].alignLeft(20) & dlinesq[2].alignLeft(15) & dlinesq[3]
        indentationst = "    ".repeat(curdepthit)
        echo indentationst & decdatalinest
        if curdepthit <= maxdepthit:
          writeFamily(proj_def_pathst, dlinesq[0] ,directionst, curdepthit + 1 , maxdepthit)


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

  var 
    decfilob: File 
    decfilepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    source_filesq, foundlinesq, foundsublinesq, wordsq: seq[string]
    sep1st = "~~~"
    #sep1st = "___"
    sep2st = "___"
    sep3st = "==="
    #decnamest, modulest, dectypest, linestartst, newmodulest, decdatalinest: string
    inputst, outputst: string
    onelinest, declarest: string

    #  dlinesq, decdatasq

  try:
    # retrieve project-data from project-def-file
    sourceprojectpathst = extractFileSectionToSequence(proj_def_pathst, "PROJECT_PATH", ">----------------------------------<")[0]
    source_filesq = extractFileSectionToSequence(proj_def_pathst, "SOURCE_FILES", ">----------------------------------<")

    # set the target-dir and declaration-file
    var (pd_dirpa, pd_filebasepa, pd_extst) = splitFile(Path(proj_def_pathst))
    reltargetprojectpathst = string(Path(ct_projectsdirst) / pd_filebasepa)

    echo "--------------------------------------------------------"
    echo "Direction (tree-type) = ", directionst, ", Maxdepth = ", maxdepthit
    echo "Enter the declaration you want to view, * for all , or exit to exit: "
    decfilepathst = string(Path(reltargetprojectpathst) / Path(string(pd_filebasepa)[0..6] & "_phase3_" & dec_list_suffikst))

    decfilob = open(decfilepathst, fmRead)

    inputst = ""
    while not(inputst in ["exit","quit"]):
      inputst = readline(stdin)
      foundlinesq = getSeqFromFileLines(decfilepathst, inputst, sep3st, sep1st, [0,0], false)
      # if no match found or wildcard * used (all found):
      if foundlinesq.len == 0 or foundlinesq.len > 1:
        if foundlinesq.len == 0:
          # maybe find something with substring-search
          foundsublinesq = getSeqFromFileLines(decfilepathst, inputst, sep3st, sep1st, [0,0])
        else:
          foundsublinesq = foundlinesq
        if foundsublinesq.len > 1:
          #echo foundlinesq
          echo "========================================================================="
          for linest in foundsublinesq:
            wordsq = linest.split(sep3st)[0].split(sep1st)
            outputst = wordsq[0].alignLeft(33) & wordsq[1].alignLeft(20) & wordsq[2].alignLeft(15) & wordsq[3].split(":")[1].alignLeft(10)
            echo outputst
          echo "-------------------------------------------------------------------------"
        elif foundsublinesq.len == 1:
          echo "========================================================================="
          onelinest = foundsublinesq[0]
          wordsq = onelinest.split(sep3st)[0].split(sep1st)
          declarest = wordsq[0] 
          outputst = wordsq[0].alignLeft(33) & wordsq[1].alignLeft(20) & wordsq[2].alignLeft(15) & wordsq[3].split(":")[1].alignLeft(10)
          echo outputst
          writeFamily(proj_def_pathst, declarest, directionst, 1, maxdepthit)
          echo "-------------------------------------------------------------------------"

      elif foundlinesq.len == 1:
        echo "========================================================================="
        onelinest = foundlinesq[0]
        wordsq = onelinest.split(sep3st)[0].split(sep1st)
        declarest = wordsq[0] 
        outputst = wordsq[0].alignLeft(33) & wordsq[1].alignLeft(20) & wordsq[2].alignLeft(15) & wordsq[3].split(":")[1].alignLeft(10)
        echo outputst
        writeFamily(proj_def_pathst, declarest, directionst, 1, maxdepthit)
        echo "-------------------------------------------------------------------------"




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
      of cmdArgument:             # without hyphen(s); used here for project-definition-file-path
        projectpathst = key
      of cmdShortOption, cmdLongOption:
        case key:
        of "c", "command": 
          case val:
          of "a", "add_files":
            procst = "addSourceFilesToProject"
          of "d", "declarations":
            procst =  "createDeclarationList"
          of "v", "views":
            procst = "createAllViewFiles"
          of "g", "generate_all":
            procst = "generate_all"
          of "t", "tree":
            procst = "showDeclarationBranch"
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




proc createAllViewFiles(filepathst: string) = 

    createCodeViewFile(filepathst, viewBasic_OneLevel)
    createCodeViewFile(filepathst, viewBasic_TwoLevels)



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
      of cmdArgument:
        projectpathst = key
      of cmdShortOption, cmdLongOption:
        case key:
        of "c", "command": 
          case val:
          of "a", "add_files":
            procst = "addSourceFilesToProject"
          of "d", "declarations":
            procst =  "createDeclarationList"
          of "v", "views":
            procst = "createAllViewFiles"
          of "g", "generate_all":
            procst = "generate_all"
          of "t", "tree":
            procst = "showDeclarationBranch"
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
        of "createAllViewFiles":
          createAllViewFiles(projectpathst)
        of "generate_all":
          generate_all(projectpathst)
        of "showDeclarationBranch":
          showDeclarationBranch(projectpathst, directionst, depthit)
        of "echoHelpInfo":
          echoHelpInfo()

      else:
        echo "A project-file was not provided (like: projects/someproject.pro)"
    else:
      echo "A command-option was not provided (like -c=a or -c=t)"


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
    #mytekst = "proc crazyname(var)"
    mytekst = "proc new("
    myarray: array[0..1, int]
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
    createDeclarationList(filepathst)
  if false:
    createCodeViewFile(filepathst, viewBasic_OneLevel)
    createCodeViewFile(filepathst, viewBasic_TwoLevels)
  if false:
    echo getSeqFromFileLines(filepathst, "*", "===" , "~~~", [0,0], true).len
  if false:
    showDeclarationBranch(filepathst, "usage", 3)
    #showDeclarationBranch(filepathst, "used-by", 5)

