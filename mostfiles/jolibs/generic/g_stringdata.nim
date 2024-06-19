import strutils
import g_templates


var
  #datast = "errorline~~~hamer__duwings__schuur:kast2:plank3__3 kilo~~~zaag__verspanings__schuur:kast1__voor hout~~~combitang__klemmings__kelder:hoge-kast__rood"
  datast = "hamer__duwings__schuur:kast2:plank3__3 kilo~~~zaag__verspanings__schuur:kast1__voor hout~~~combitang__klemmings__kelder:hoge-kast__rood"
  
wispbo = false

type
  OperationOnString = enum
    opDelete
    opInsert
    opDeleteInsert      # = change

  ComparisonType* = enum
    cmExact
    cmSub
    cmExactInsens           # case-insensitive
    cmSubInsens

  #IgnoreType* = enum
  #  igSuperSensitive        # never ignore errors
  #  igBasicForgiveness      # forgive basic errors
  #  igManyErrors            # ignore many errors


proc zoomIntoFragments(inputst: string, separatorsq: seq[string], fragcoordsq: seq[int]): string = 

#[
  Zoom into and return a fragment of the inputst based on the separators and the 
  fragment-coordinates. The coords are zerobased ordinal numbers based on the corresponding 
  separator-separated fragments.

   @[2,1] looks in the third field (zerobased) and the second field-part.
  

  ADAP FUT
  -rewrite from fragcoordsq as starting-point
  Error-mitigation:
  -check if the number of elements is present


]#

  var 
    innerfragsq, curfragsq: seq[string] = @[]
    filtdepthit, sepdepthit, latestcoordcountit: int
    searchfieldvalst: string
    testsOKbo, coord_not_foundbo: bool


  try:
    wispbo = false
    filtdepthit = fragcoordsq.len
    sepdepthit = separatorsq.len
    #if separatorsq.len < fragcoordsq.len:
    #  testsOKbo = false

    coord_not_foundbo = false
    testsOKbo = true
    if testsOKbo:

      # set the filter-criteria
      wisp("filtdepthit = ", filtdepthit)

      # zoom in to the fragment we want compare which is put in searchfieldvalst
      for coordcountit, coordit in fragcoordsq:
        latestcoordcountit = coordcountit
        if coordcountit <= sepdepthit - 1:
          wisp("innerfragsq = ", repr(innerfragsq))

          if coordcountit == 0:
            curfragsq = inputst.split(separatorsq[coordcountit])

          elif coordcountit > 0:
            curfragsq = innerfragsq[coordcountit - 1].split(separatorsq[coordcountit])

          if curfragsq.len > coordit:
            innerfragsq.add(curfragsq[coordit])
          else:
            coord_not_foundbo = true
            break


      if not coord_not_foundbo:
        if sepdepthit > filtdepthit:
          searchfieldvalst = innerfragsq[filtdepthit - 1]
        else:
          searchfieldvalst = innerfragsq[sepdepthit - 1]
        result = searchfieldvalst
      else:
        echo "zoomIntoFragments: one or more coordinates could not be found;"
        echo "latestcoordcountit (zerobased) = ", latestcoordcountit
        echo "Adjust either the coordinates or the input-data."
        echo "inputst = ", inputst
        result = "_-_ERROR_-_"

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "\p****End exception****\p"


#[
proc zoomIntoFragments_old(inputst: string, separatorsq: seq[string], fragcoordsq: seq[int]): string = 

#[
  Zoom into and return a fragment of the inputst based on the separators and the 
  fragment-coordinates. The coords are zerobased ordinal numbers based on the corresponding 
  separator-separated fragments.

   @[2,1] looks in the third field (zerobased) and the second field-part.
  

  ADAP FUT
  -rewrite from fragcoordsq as starting-point
  Error-mitigation:
  -check if the number of elements is present


]#

  var 
    innerfragsq: seq[string] = @[]
    filtdepthit: int
    searchfieldvalst: string
    testsOKbo: bool


  try:
    wispbo = false
    filtdepthit = fragcoordsq.len

    if separatorsq.len < fragcoordsq.len:
      testsOKbo = false

    if testsOKbo:

      # set the filter-criteria
      wisp("filtdepthit = ", filtdepthit)

      # zoom in to the fragment we want compare which is put in searchfieldvalst
      for sepcountit, sepst in separatorsq:
        if sepcountit <= filtdepthit - 1:
          wisp(sepst)
          wisp("fragcoordsq[sepcountit] = ", fragcoordsq[sepcountit])
          if sepcountit == 0:
            innerfragsq.add(inputst.split(sepst)[fragcoordsq[sepcountit]])

          elif sepcountit > 0:
            innerfragsq.add(innerfragsq[sepcountit - 1].split(sepst)[fragcoordsq[sepcountit]])
          #wisp("innerfragsq = ", innerfragsq)
      searchfieldvalst = innerfragsq[filtdepthit - 1]
      result = searchfieldvalst
    else:
      echo "zoomIntoFragments: error because separatorsq.len < fragcoordsq.len"
      echo "inputst = ", inputst
      result = "__ERROR__"

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "\p****End exception****\p"


]#




proc readFromSeparatedString*(tablest: string, outersepst: string, innersepsq: seq[string], returnfragmentsq: seq[int], filtervaluesq: seq[string], comparisonsq: seq[ComparisonType], filtcoordsq: seq[seq[int]], skip_errorsbo: bool = true): seq[string] = 

  #[
    Generic way to read data from a textual table that match filter-criteria.
    It Walks thru the outer separated fragments  of tablest and retrieves fragments (or parts thereof) that match the filter-criteria.

    The easiest way to imagine is that the outer separator is a line-feed and that the inner seps 
    are the separator between fields, and possibly within fields.

    The filter can exist of multiple search-criteria and is using the and-operator.
    Every filter-coordinate can have a different length.
    
    Both the parameters returnfragmentsq and filtcoordsq are coordinate-based params. 
    returnfragmentsq expects coordinates to designate the field-value or field-value-part to return, 
    like @[2,1] looks in the third field (zerobased) and the second part.
    If returnfragmentsq == @[] then return the whole inner frag.

    filtcoordsq is a sequence of coordinates.

    filtervaluesq, comparisonsq and filtcoordsq are linked params in the sense that the n-th item 
    of each makes up a filter-criterion. Therefore all must have the same length.

    Currently skip-errors means skipping empty or whitespaced lines.


    ADAP NOW

    ADAP FUT
    Maybe later:
    You can retrieve a range of items [1, -10] or [3,5] from the second sep.
  ]#


  var 
    outputsq: seq[string] = @[]
    innerfragsq: seq[string] = @[]
    outerfragsq: seq[string]
    #sepdepthit: int = separatorsq.len
    filtdepthit: int
    coordinatesq: seq[int] = @[]
    testsOKbo: bool = false
    reportst, returnfragst, searchfieldvalst: string
    matchingbo, filtermatchbo: bool

  try:
    wispbo = false

    testsOKbo = true

    if filtervaluesq.len != comparisonsq.len or filtervaluesq.len != filtcoordsq.len or comparisonsq.len != filtcoordsq.len:
      testsOKbo = false
    

    #wisp(datast)


    if testsOKbo:

      # walk thru the outer (first sep) separated fragments
      outerfragsq = tablest.split(outersepst)
      for outercountit, fragst in outerfragsq:
        wisp("===============================================================")
        wisp(fragst)
        matchingbo = true
        searchfieldvalst = ""

        if not (skip_errorsbo and fragst.strip().len == 0): 

          for critcountit, filtvalst in filtervaluesq:
            wisp("***********************************")
            # set the filter-criteria
            wisp("filtvalst = ", filtvalst)

            searchfieldvalst = zoomIntoFragments(fragst, innersepsq, filtcoordsq[critcountit])

            wisp("searchfieldvalst = ", searchfieldvalst)

            case comparisonsq[critcountit]
            of cmExact:
              filtermatchbo = searchfieldvalst == filtvalst
            of cmSub:
              filtermatchbo = searchfieldvalst.contains(filtvalst)
            of cmExactInsens:
              filtermatchbo = searchfieldvalst.toLowerAscii == filtvalst.toLowerAscii
            of cmSubInsens:
              filtermatchbo = searchfieldvalst.toLowerAscii.contains(filtvalst.toLowerAscii)

            if not filtermatchbo:
              wisp("not matching...")
              matchingbo = false
              break
            else:
              wisp("matching!!!!!!!!")
        else:
          matchingbo = false


        if matchingbo:
          # zoom in to the return-fragment
          #returnfragst = fragst
          if returnfragmentsq == @[]:
            outputsq.add(fragst)
          else:
            returnfragst = zoomIntoFragments(fragst, innersepsq, returnfragmentsq)
            outputsq.add(returnfragst)

    else:
      echo "Filter-criteria have different lengths (should be equal)!"
      echo "[filtervaluesq.len, comparisonsq.len, filtcoordsq.len] = ", $[filtervaluesq.len,comparisonsq.len,filtcoordsq.len]

    result = outputsq

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "\p****End exception****\p"




proc writeToSeparatedString(tekst, insertst: string, operationeu: OperationOnString, separatorsq: seq[string], filtercoordinatesq: seq[seq[int]], filtervaluesq, comparisonsq: seq[string]): string = 
  discard()
  
  #[
    The filter can exist of multiple search-criteria using the and-operator.
    Every filter-coordinate can have a different length.

    Remarks:
    - you can update the char-position at each pass

  ]#


when isMainModule:

  if false:
    echo readFromSeparatedString(datast, "~~~", @["__", ":"], @[2,1],  
          @["schuur","duw"], @[cmExact, cmSub], @[@[2,0], @[1]])

  if true:
    var 
      filepathst, filecontentst: string
      fileob: File
      datasq: seq[string]

    #filepathst = "/home/bruik/logs/history_baks/bash_history_20240602"
    filepathst = "/media/OnsSpul/1klein/1joris/k1-onderwerpen/computer/Programmeren/nimtaal/codetwig/mostfiles/projects/codetwig/codetwi_phase3_dec_list.dat"

    if open(fileob, filepathst, fmRead):
      filecontentst = readAll(fileob)
      fileob.close()

    #readFromSeparatedString*(tablest: string, outersepst: string, innersepsq: seq[string], returnfragmentsq: seq[int], filtervaluesq: seq[string], comparisonsq: seq[ComparisonType], filtcoordsq: seq[seq[int]]): seq[string] = 

    #datasq = readFromSeparatedString(filecontentst, "\p", @[" "], @[], @["pdftohtml", ""], @[cmExact, cmSub], @[@[0], @[1]])
    #datasq = readFromSeparatedString(filecontentst, "\p" , @["===","~~~"], @[], @[""], @[cmSubInsens], @[@[0,0]])
    datasq = readFromSeparatedString(filecontentst, "\p" , @["===","~~~"], @[], @["", "", ""], @[cmSubInsens, cmSubInsens, cmSubInsens], @[@[0,0], @[0,1], @[0,7]])

    echo datasq
    echo datasq.len

  if false:
    #echo zoomIntoFragments(datast, @["~~~", "__", ":"], @[0,2,1])
    echo zoomIntoFragments(datast, @["~~~", "__"], @[0,2,1])


