#[ Exchange nim-structs with json-structs
]#

import std/[json]

type
  PickList* = enum
    pickSelect
    pickDataList



proc createDropdownNodeFromSeq*(dropdownnamest, labelst: string, 
                                datalisq: seq[array[2, string]]): JsonNode = 

  #[ Create a json-object for the select-element (dropdown (dd) or picklist)
    From the datalisq, the first elem is the real-value, the second one the shown value.
   ]#

  var
    ddjnob: JsonNode = %*{}
    rowcountit: int = 0


  ddjnob.add(dropdownnamest, %*{})
  ddjnob[dropdownnamest].add("ddlab", %labelst)
  ddjnob[dropdownnamest].add("ddvalues", %*[])


  for ar in datalisq:
    ddjnob[dropdownnamest]["ddvalues"].add(%*{})
    ddjnob[dropdownnamest]["ddvalues"][rowcountit].add("real-value", %ar[0])
    ddjnob[dropdownnamest]["ddvalues"][rowcountit].add("show-value", %ar[1])
    rowcountit += 1

  result = ddjnob



proc createPicklistNodeFromSeq*(picklisttype: PickList, picklistnamest, labelst: string, 
                                datasq: seq[array[2, string]]): JsonNode = 

  #[ Create a json-object for the select-element (dropdown (dd) or picklist)
    From the datasq, the first elem is the real-value, the second one the shown value.
   ]#

  var
    pljnob: JsonNode = %*{}
    rowcountit: int = 0
    labnamest, valuenamest: string


  case picklisttype:
    of pickSelect:
      labnamest = "ddlab"
      valuenamest = "ddvalues"
    of pickDataList:
      labnamest = "dl_lab"
      valuenamest = "dl_values"



  pljnob.add(picklistnamest, %*{})
  pljnob[picklistnamest].add(labnamest, %labelst)
  pljnob[picklistnamest].add(valuenamest, %*[])


  for ar in datasq:
    pljnob[picklistnamest][valuenamest].add(%*{})
    pljnob[picklistnamest][valuenamest][rowcountit].add("real-value", %ar[0])
    pljnob[picklistnamest][valuenamest][rowcountit].add("show-value", %ar[1])
    rowcountit += 1

  result = pljnob



when isMainModule:
  # echo createDropdownNodeFromSeq("mydd", "labeltje", @[["aap", "toon-aap"], ["noot", "toon-noot"]])
  # echo createPicklistNodeFromSeq(pickSelect , "mydd", "labeltje", @[["aap", "toon-aap"], ["noot", "toon-noot"]])
  echo createPicklistNodeFromSeq(pickDataList , "mydali", "labeltje", @[["aap", "toon-aap"], ["noot", "toon-noot"]])
