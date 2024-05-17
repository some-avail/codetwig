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
import std/[os, strutils, paths, dirs]


var 
  versionfl: float = 0.1
  codetwigst: string = "CodeTwig"
  ct_projectsdirst: string = "projects"
  dec_list_suffikst: string = "dec_list.dat"

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
    blocklineit, source_file_posit: int


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
              source_filesq = writeFilePatternToSeq2("*.nim", projectpathst)

          elif blockphasest == "SOURCE_FILES":
            if blocklineit == 1:
              if linest == blockseparatorst:
                # read the file-names of the source-files and write them to the files-section
                fileob.setFilePos(source_file_posit)
                for filenamest in source_filesq:
                  fileob.writeLine(filenamest)
                fileob.writeLine(blockseparatorst)
                result = "Source-file-names have been added to the project-file: " & proj_def_pathst
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
    The end of the target-string is the first of the possible end-markers.

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




proc createDeclarationList(proj_def_pathst: string) = 
  #[
  proj_def_pathst = path to the file in which the codetwig-project for a source-project is defined

  Firstly scan all source-files to create a basic declaration-list
  (that is without the underlying declarations)
  Then, for each proc / declaration, one can scan for the used procs /decs and append them after earch dec-line.

  in pseudo-code:
  for dec1 in dec-list:
    for dec2 in dec-list:
      if the source-code-range of dec1 contains dec2:
        append dec2-data to the line of dec1

  dec_module_line_colstart_colend_dec-type
  ]#

  var
    fileob, phase1fileob, phase1file2ob, phase2fileob: File
    source_filesq: seq[string]
    # declaration-types
    nim_dec_typesq: seq[string] = @["proc", "template", "macro", "func"]
    langekst: string = "nim"
    filepathst: string
    sourceprojectpathst, reltargetprojectpathst: string
    linecountit: int
    phase1_dec_list_filepathst, phase2_dec_list_filepathst: string
    dec_namear: array[0..1, int]
    dec_namest: string
    targlinest: string
    #sep1st = "~~~"
    sep1st = "___"
    sep2st = ":"
    sep3st = "==="
    moduledecorst = "----------"
    moduletitlest, modulenamest, linepartst: string
    startingtoken: string
    dectypefoundbo, incommentblockbo, commentclosingbo, singlecommentbo: bool
    previous_linest, line_endst, newlinest: string
    linesq: seq[string]

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

    # first phase; create intermediate product phase1_dec_list_filepathst
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
              if not (startingtoken in [" "]):       # declaration found
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

                if not dectypefoundbo:      # other-type declares relevant to determine declare-endings
                  if linest.len > 15:
                    linepartst = linest[0..15]
                  else:
                    linepartst = linest[0..linest.len - 1]
                  targlinest = "other_declaration" & sep1st & linepartst & sep1st  & modulenamest & sep1st & "ls:" & $linecountit
                  phase1fileob.writeLine(targlinest)

          fileob.close()

        else:
          echo ">>>>>>>>>>>Could not open " & filepathst
    else: 
      echo ">>>>>>>>>>>Could not open " & phase1_dec_list_filepathst

    phase1fileob.close()    # close writable file


    # phase two; create new file and append declaration-endings to each line, called line-ends le, that is the last line of the declare
    
    # work with one file-object of phase one and one of phase two
    if phase1fileob.open(phase1_dec_list_filepathst, fmRead) and phase2fileob.open(phase2_dec_list_filepathst, fmWrite):
      linecountit = 0
      for linest in phase1fileob.lines:
        linecountit += 1
        if linecountit > 1:
          # line-end of the previous line is the line-start of the following minus 1
          linesq = linest.split(sep1st)
          line_endst = "le:" & $(parseInt(linesq[3].split(":")[1]) - 1)

          if previous_linest.split(sep1st)[0] != "other_declaration":
            newlinest = previous_linest & sep1st & line_endst
            phase2fileob.writeLine(newlinest)
        previous_linest = linest
    else:
      echo "Could not open one or two files"



  except IndexDefect:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Index-error caused by bug in program"
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"
  finally:
    phase1fileob.close()



var for_realbo: bool = false
if for_realbo:
  discard()
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
  if true:
    createDeclarationList(filepathst)

