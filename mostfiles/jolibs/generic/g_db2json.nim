#[ Generic module to transfer data from the
database to a json-object (jnob). 
This jnob is used loosely or integrated in 
(a copy of) the json-definition (jnob) ]#


# import std/[json, tables]
import std/[json]
import db_connector/db_sqlite
import g_database

var
  debugbo: bool = true
  versionfl: float = 0.21

const
  recordlimit*: int = 200



# Beware: variable debugbo might be used globally, modularly and procedurally
# whereby lower scopes override the higher ones?
# Maybe best to use modular vars to balance between an overload of 
# messages and the need set the var at different places.



template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



proc createHtmlTableNodeFromDB*(db_tablenamest: string, comparetype: Comparetype = compString, 
              fieldvaluesq: seq[array[2, string]] = @[], 
              ordersq: seq[string] = @[], ordertypest: string = ""): JsonNode =


  var
    rowsq: seq[Row]
    tablejnob: JsonNode = %*{}
    headersq:  seq[array[2, string]]
    rowcountit: int = 0

  
  tablejnob.add(db_tablenamest, %*{})
  #echo tablejnob

  tablejnob[db_tablenamest].add("theader", %*[])
  #echo tablejnob

  headersq = getFieldAndTypeList(db_tablenamest)

  for itemar in headersq:
    tablejnob[db_tablenamest]["theader"].add(%itemar[0])

  #echo tablejnob

  tablejnob[db_tablenamest].add("tdata", %*[])


  # retrieve the rows from the desired table  
  rowsq = readFromParams(db_tablenamest, @[], comparetype, fieldvaluesq, 
                        ordersq, ordertypest, limit = recordlimit)
  
  #echo rowsq

  for row in rowsq:
    tablejnob[db_tablenamest]["tdata"].add(%*[])
    for value in row:
      tablejnob[db_tablenamest]["tdata"][rowcountit].add(%value)
    rowcountit += 1
  
  #echo tablejnob
  echo "============"

  result = tablejnob



proc createDropdownNodeFromDb*(dropdownnamest, db_tablenamest: string, fieldpairsq: seq[string], 
      mycomparison: Comparetype = compString, fieldvaluesq: seq[array[2, string]] = @[],
      ordersq: seq[string] = @[], ordertypest: string = ""):JsonNode = 

  #[ Create a json-object for the select-element (dropdown (dd) or picklist)
    The fieldpairsq-param first elem is the real-value, the second one the shown value.
    If they the same put the same names in.
   ]#


  var
    rowsq: seq[Row]
    ddjnob: JsonNode = %*{}
    rowcountit: int = 0


  # get a table-query to provide the data for the select
  rowsq = readFromParams(db_tablenamest, fieldpairsq, mycomparison, fieldvaluesq, ordersq, ordertypest)
  #echo rowsq
  
  ddjnob.add(dropdownnamest, %*{})
  ddjnob[dropdownnamest].add("ddlab", %dropdownnamest)
  ddjnob[dropdownnamest].add("ddvalues", %*[])

  for row in rowsq:
    ddjnob[dropdownnamest]["ddvalues"].add(%*{})
    ddjnob[dropdownnamest]["ddvalues"][rowcountit].add("real-value", %row[0])
    ddjnob[dropdownnamest]["ddvalues"][rowcountit].add("show-value", %row[1])
    rowcountit += 1

  #echo ddjnob
  result = ddjnob


#[ 
readFromParams*(tablenamest: string, fieldsq: seq[string] = @[], 
      comparetype: Comparetype = compDoNot, fieldvaluesq: seq[array[2, string]] = @[],
      ordersq: seq[string] = @[], ordertypest: string = ""): seq[Row] = 
 ]#



when isMainModule:
  echo "-------------"
  #echo createHtmlTableNodeFromDB("mr_data")
  echo "-------------"
  #echo createHtmlTableNodeFromDB("mr_data")["mr_data"]

  echo createDropdownNodeFromDb("Droids", "mr_data", @["anID", "Droidname"], ordersq = @["anID"], ordertypest = "ASC")

