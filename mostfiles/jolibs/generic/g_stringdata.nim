import strutils
import g_templates


var
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
    cmExactInsens
    cmSubInsens



proc zoomIntoFragments(inputst: string, separatorsq: seq[string], fragcoordsq: seq[int]): string = 

#[
  Zoom into and return a fragment of the inputst based on the separators and the 
  fragment-coordinates. The coords are zerobased ordinal numbers based on the corresponding 
  separator-separated fragments.

   @[2,1] looks in the third field (zerobased) and the second field-part.
]#

  var 
    innerfragsq: seq[string] = @[]
    filtdepthit = fragcoordsq.len
    searchfieldvalst: string

  try:
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

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "\p****End exception****\p"



proc readFromSeparatedString*(tablest: string, outersepst: string, innersepsq: seq[string], returnfragmentsq: seq[int], filtervaluesq: seq[string], comparisonsq: seq[ComparisonType], filtcoordsq: seq[seq[int]]): seq[string] = 

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

    filtcoordsq is a sequence of coordinates.

    filtervaluesq, comparisonsq and filtcoordsq are linked params in the sense that the n-th item 
    of each makes up a filter-criterion. Therefore all must have the same length.

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
    #if sepdepthit != returnfragmentsq.len + 1:
    #  reportst = "separatorsq and returnfragmentsq have different length!"
    #  wisp(reportst
    #else:
    #  testsOKbo = true


    wisp(datast)

    testsOKbo = true

    if testsOKbo:

      # walk thru the outer (first sep) separated fragments
      outerfragsq = tablest.split(outersepst)
      for outercountit, fragst in outerfragsq:
        wisp("===============================================================")
        wisp(fragst)
        matchingbo = true
        searchfieldvalst = ""
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


        if matchingbo:
          # zoom in to the return-fragment
          #returnfragst = fragst
          if returnfragmentsq == @[]:
            outputsq.add(fragst)
          else:
            returnfragst = zoomIntoFragments(fragst, innersepsq, returnfragmentsq)
            outputsq.add(returnfragst)


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

  if true:
    echo readFromSeparatedString(datast, "~~~", @["__", ":"], @[2,1],  
          @["schuur","duw"], @[cmExact, cmSub], @[@[2,0], @[1]])

  if false:
    echo zoomIntoFragments(datast, @["~~~", "__", ":"], @[0,2,1])


