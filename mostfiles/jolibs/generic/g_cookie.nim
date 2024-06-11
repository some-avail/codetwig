#[ 
  This module contains the functions for the operation of 
  the cookie-tunnel called at the end of proj.startup.nim. 
]#


# import g_templates
import tables, strutils, json
import g_json2html

var versionfl: float = 0.1

var debugbo: bool = true

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: echo messagest


# template getattr(procst: string): untyped = 
#   module.proc



proc dummyPass(paramst: string): string = 
  result = paramst


proc getFuncParts*(functionpartst: string): OrderedTable[string, string] =
  # parse the function-parts
  # sample: "funcname::g_cookie.dummyPass++location::inner++varname:statustext++param1::nieuwe statustekst"
  var 
    funcpartsq, keyvalsq: seq[string]
    functa =  initOrderedTable[string, string]()

  funcpartsq = functionpartst.split("++")
  log($funcpartsq)

  for item in funcpartsq:
    keyvalsq = item.split("::")
    functa[keyvalsq[0]] = keyvalsq[1]
  # log($functa)
  result = functa


proc runFunctionFromClient*(funcPartsta: OrderedTable[string, string], jnob: JsonNode): string = 

  # run the function
  if funcPartsta["funcname"] == "g_cookie.dummyPass":
    result = dummyPass(funcPartsta["newcontent"])
  elif funcPartsta["funcname"] == "setDropDown":
    result = setDropDown(jnob, funcPartsta["html-elem-name"], funcPartsta["selected-value"], 
      parseInt(funcPartsta["dd-size"]))
  elif funcPartsta["funcname"] == "setDropDown":
    result = setDropDown(jnob, funcPartsta["html-elem-name"], funcPartsta["selected-value"], 
      parseInt(funcPartsta["dd-size"]))


  

#     "funcname:setDropDown++location:inner++varname:dropdown1++param2:dropdownname_01++param3:third realvalue++param4:1", 60);
# proc setDropDown*(jnob: JsonNode, dropdownnamest, selected_valuest: string, 
#                     sizeit: int):string = 




when isMainModule:
  #var paramst: string = "funcname:g_cookie.dummyPass++location:inner++varname:statustext++param1:nieuwe statustekst"
  #echo getFuncParts(paramst)

  # echo getattr("g_cookie","dummyPass")("malle pietje")      #transformed into `day1.proc1(input)`

  discard
