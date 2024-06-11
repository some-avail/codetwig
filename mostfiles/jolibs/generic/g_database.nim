#[ Abstraction-layer-module for the sqlite-db thru the lib db_sqlite.
    (there are also comparable libs like tiny_sqlite)
    This means that you can run SQL-statements without using SQL; instead 
    by using parametrized procs.

  Remarks:
  - sqlite has a system-table called "sqlite_master" in which 
  meta-information is stored.

  ADAP FUT:
  - optionalizing double quotes for names with spaces or hyphens in them
  -creating facilities to convert special characters
    * like converting single quote to double-single and vice versa
 ]#


import std/[strutils]
import db_connector/db_sqlite

import g_tools
# import g_templates


type 
  Comparetype* = enum
    compString
    compSub
    compNotString
    compNotSub

  IdGenerationType* = enum
    genIntegerByDb
    genIntegerByHand
    genStringByHand
    genIntegerByCode
    genStringByCode
    genUnknownByHand

  ViewFieldMethod* = enum
    viewFullNames       # like table.field01
    viewPrefixNames     # like ta.field01
    viewLastNames       # like field01
    viewAliases         # like alias01 if present, otherwise field01 (from: table.field01 as alias01)
    viewAuto            # = viewAliases


  #Row* = seq[string]


var
  debugbo: bool = true
  versionfl: float = 0.31
  double_quote_namesbo: bool


# Beware: variable debugbo might be used globally, modularly and procedurally
# whereby lower scopes override the higher ones?
# Maybe best to use modular vars to balance between an overload of 
# messages and the need set the var at different places.

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



proc getDb*: DbConn =
  ## Create a DbConn
  # let filepathst = "/home/bruik/Bureaublad/nimtest.db"
  let filepathst = "/media/OnsSpul/1klein/1joris/k1-onderwerpen/computer/Programmeren/nimtaal/jester/freekwensie/mostfiles/freek.db"
  #let filepathst = "/media/OnsSpul/1klein/1joris/k1-onderwerpen/computer/Programmeren/nimtaal/jester/kjx-srvpc-206.db"
  #let filepathst = "/home/bruik/.moonchild productions/pale moon/oq1i83z0.default/places.sqlite"
  open(filepathst, "", "", "")



template withDb*(body: untyped): untyped =
  # perform db-ops with automatic opening and closing of the db
  block:
    let db {.inject.} = getDb()
    try:
      body
    finally:
      close db


proc enquote(unquoted_namest: string): string = 
  # to be implemented
  discard

proc dequote(quoted_namest: string): string =
  # to be implemented
  discard

proc convertChars() = 
  # to be implemented
  # convert special characters, like apostrophe
  discard


proc old_getFieldAndTypeList*(tablenamest: string): seq[array[2, string]] = 
#[
  Get fields and types for the desired table from the system-table "sqlite_master"
  by means of the create-string (views not supported here).
  Limits till now: cannot yet handle spaces or hyphens in field-names

  ADAP NOW:
  -support parsing of bracketed fields

sample-create-string:
 CREATE TABLE mr_data 
(anID INTEGER CONSTRAINT auto_inc PRIMARY KEY ASC AUTOINCREMENT, Droidname TEXT UNIQUE, 
Type TEXT, Builder STRING, Date_of_build DATE, Weight REAL, Cost NUMERIC, 
Purpose STRING, Modelnr TEXT)
 ]#


  var
    create_stringst, fieldandtypest, fieldnamest: string
    fielddatasq, field_elemsq: seq[string]
    field_typesq: seq[array[2, string]]


  withDb:
    create_stringst = getValue(db, sql"SELECT sql FROM sqlite_master WHERE name = ?", tablenamest)
    #echo create_stringst
  
  fieldandtypest = create_stringst.split('(', 1)[1]
  #fieldandtypest = fieldandtypest.split(')')[0]
  fieldandtypest = fieldandtypest.strip(chars = {')'})
  fielddatasq = fieldandtypest.split(",")


  for fielddata in fielddatasq:
    # firstly strip surrounding spaces and then split on spaces
    field_elemsq = fielddata.strip().split(' ')
    fieldnamest = field_elemsq[0]

    # strip possible brackets
    fieldnamest = fieldnamest.strip(chars = {'[',']'})

    field_typesq.add([fieldnamest,field_elemsq[1]])

  result = field_typesq



proc getFieldAndTypeList*(tablenamest: string, 
                viewtype: ViewFieldMethod = viewAuto): seq[array[2, string]] = 

#[
  Get fields and types for the desired table or view from the system-table "sqlite_master"
  by means of the create-string.
  Limits till now: cannot yet handle spaces or hyphens in field-names
  See the enum ViewFieldMethod on top of module.

  ADAP NOW:
  - enable the parsing of views

sample-create-string for a table:
 CREATE TABLE mr_data 
(anID INTEGER CONSTRAINT auto_inc PRIMARY KEY ASC AUTOINCREMENT, Droidname TEXT UNIQUE, 
Type TEXT, Builder STRING, Date_of_build DATE, Weight REAL, Cost NUMERIC, 
Purpose STRING, Modelnr TEXT)

sample for a view:
CREATE VIEW FDQ_RELATIONS_CHANGE AS
SELECT Relations.RelID, Relations.Change, Relations.Subject, Relations.Object1, Relations.Relation, Relations.Object2, Relations.Selected
FROM Relations
WHERE ((Not (Relations.Change) Is Null))
ORDER BY Relations.Change
 ]#


  var
    create_stringst, fieldandtypest, fieldnamest: string
    fielddatasq, field_elemsq, namesq: seq[string]
    field_typesq: seq[array[2, string]]
    myrow: Row
    itemtypest, itemnamest, item_tblnamest, itemrootpagest, itemsqlst: string
    producst, stuffst: string


  withDb:
    myrow = getRow(db, sql"SELECT * FROM sqlite_master WHERE name = ?", tablenamest)
    #echo myrow
  

  itemtypest = myrow[0]   # table, index or view
  itemnamest = myrow[1]
  item_tblnamest = myrow[2]   # table to which item belongs?
  itemrootpagest = myrow[3]   # ?
  itemsqlst = myrow[4]        # create-string for the item
  #echo itemsqlst

  case itemtypest
  of "table":

    fieldandtypest = itemsqlst.split('(', 1)[1]
    #fieldandtypest = fieldandtypest.split(')')[0]
    fieldandtypest = fieldandtypest.strip(chars = {')'})
    fielddatasq = fieldandtypest.split(',')


    for fielddata in fielddatasq:
      # firstly strip surrounding spaces and then split on spaces
      field_elemsq = fielddata.strip().split(' ')
      fieldnamest = field_elemsq[0]

      # strip possible brackets
      fieldnamest = fieldnamest.strip(chars = {'[',']'})

      field_typesq.add([fieldnamest,field_elemsq[1]])


  of "view":
    producst = itemsqlst.split2("SELECT ", 1)[1]
    producst = producst.split2("FROM ", 1)[0]
    producst = producst.strip()
    fielddatasq = producst.split(',')

    for fielddata in fielddatasq:
      # firstly strip surrounding spaces and then split on spaces
      stuffst = fielddata.strip()
      # echo stuffst
      case viewtype:
      of viewAuto, viewAliases:
          if " AS " in stuffst:
            stuffst = stuffst.split2(" AS ")[1]
          else:
            if '.' in stuffst:
              stuffst = stuffst.split('.')[1]
      of viewFullNames:
        discard     # allready present in stuffst
      of viewPrefixNames:
        if '.' in stuffst:
          namesq = stuffst.split('.')
          stuffst = namesq[0][0..1] & "." & namesq[1]
      of viewLastNames:
        if '.' in stuffst:
          stuffst = stuffst.split('.')[1]

      # only field, field-type is set as empty string
      field_typesq.add([stuffst, ""])

  result = field_typesq




proc readFromParams*(tablenamest: string, fieldsq: seq[string] = @[], 
      comparetype: Comparetype = compString, fieldvaluesq: seq[array[2, string]] = @[],
      ordersq: seq[string] = @[], ordertypest: string = "", limit: int = 0): seq[Row] = 


  #[ Retrieve a sequence of rows based on the entered parameters. 
    Comparetype-enum see top of file. 
    fieldsq = @[]  means empty sequence and return all fields
    fieldvaluesq = @[] means empty and thus all records are returned
    ordersq - creating ordered fields
    ordertypest - ASC or DESC, for ascending or descending

    You can either sequentially enter params without varnames, or when one param
    is omitted, you must use the varnames in the following ones (var = value).
    Generally, parameter-omission results in the defaults.


    Call like: 
      readFromParams("mr_data", @[], compString, @[["Weight", "58"]])     > no(=all) fields, one cond.
      readFromParams("mr_data", @["anID", "Droidname"], compSubstr, @[["Weight", "58"]])
      readFromParams("mr_data", @[], ordersq = @["Droidname"], ordertypest = "ASC")    > all fields, no conditions, do order

    ADAP HIS:
    - add substring-search
    - add an order-option

    ADAP FUT:
   ]#

  var
    sqlst, whereclausest, fieldlist, orderlist: string
    lengthit, countit: int

  # which fields to query
  if fieldsq.len == 0:
    sqlst = "SELECT * FROM " & tablenamest
  elif fieldsq.len == 1:
    sqlst = "SELECT " & fieldsq[0] & " FROM " & tablenamest
  else:
    fieldlist = fieldsq.join(", ")
    sqlst = "SELECT " & fieldlist & " FROM " & tablenamest

  # prepare the where-clause / row-filter
  lengthit = len(fieldvaluesq)
  countit = 0

  if fieldvaluesq.len > 0:
    sqlst &= " WHERE "

    if comparetype == compString:
      for fieldvalar in fieldvaluesq:
        countit += 1
        whereclausest &= fieldvalar[0] & " = '" & fieldvalar[1] & "'"
        if countit < lengthit:
          whereclausest &= " AND "
    elif comparetype == compSub:
      for fieldvalar in fieldvaluesq:
        countit += 1
        whereclausest &= fieldvalar[0] & " LIKE '%" & fieldvalar[1] & "%'"
        if countit < lengthit:
          whereclausest &= " AND "
    elif comparetype == compNotSub:
      for fieldvalar in fieldvaluesq:
        countit += 1
        whereclausest &= fieldvalar[0] & " NOT LIKE '%" & fieldvalar[1] & "%'"
        if countit < lengthit:
          whereclausest &= " AND "

    sqlst &= whereclausest
 
  
  # prep order-strings
  if ordersq.len == 1:
    orderlist = ordersq[0]
    sqlst &= " ORDER BY " & orderlist & " " & ordertypest
  elif ordersq.len > 1:
    orderlist = ordersq.join(", ")
    sqlst &= " ORDER BY " & orderlist & " " & ordertypest

  # maximize number of returned records
  if limit != 0:
    sqlst &= " LIMIT " & $limit

  echo sqlst

  # get the row-sequence
  withDb:
    result = db.getAllRows(sql(sqlst))




proc Old_readFromParams*(tablenamest: string, fieldsq: seq[string] = @[], 
      comparetype: Comparetype = compString, fieldvaluesq: seq[array[2, string]] = @[],
      ordersq: seq[string] = @[], ordertypest: string = ""): seq[Row] = 


  #[ Retrieve a sequence of rows based on the entered parameters. 
    Comparetype-enum see top of file. 
    fieldsq = @[]  means empty sequence and return all fields
    fieldvaluesq = @[] means empty and thus all records are returned
    ordersq - creating ordered fields
    ordertypest - ASC or DESC, for ascending or descending

    You can either sequentially enter params without varnames, or when one param
    is omitted, you must use the varnames in the following ones (var = value).
    Generally, parameter-omission results in the defaults.


    Call like: 
      readFromParams("mr_data", @[], compString, @[["Weight", "58"]])     > no(=all) fields, one cond.
      readFromParams("mr_data", @["anID", "Droidname"], compSubstr, @[["Weight", "58"]])
      readFromParams("mr_data", @[], ordersq = @["Droidname"], ordertypest = "ASC")    > all fields, no conditions, do order

    ADAP HIS:
    - add substring-search
    - add an order-option

    ADAP FUT:
   ]#

  var
    sqlst, whereclausest, fieldlist, orderlist: string
    lengthit, countit: int

  # which fields to query
  if fieldsq.len == 0:
    sqlst = "SELECT * FROM " & tablenamest
  elif fieldsq.len == 1:
    sqlst = "SELECT " & fieldsq[0] & " FROM " & tablenamest
  else:
    fieldlist = fieldsq.join(", ")
    sqlst = "SELECT " & fieldlist & " FROM " & tablenamest

  # prepare the where-clause / row-filter
  lengthit = len(fieldvaluesq)
  countit = 0

  if fieldvaluesq.len > 0:
    sqlst &= " WHERE "

    if comparetype == compString:
      for fieldvalar in fieldvaluesq:
        countit += 1
        whereclausest &= fieldvalar[0] & " = '" & fieldvalar[1] & "'"
        if countit < lengthit:
          whereclausest &= " AND "
    elif comparetype == compSub:
      for fieldvalar in fieldvaluesq:
        countit += 1
        whereclausest &= fieldvalar[0] & " LIKE '%" & fieldvalar[1] & "%'"
        if countit < lengthit:
          whereclausest &= " AND "
    elif comparetype == compNotSub:
      for fieldvalar in fieldvaluesq:
        countit += 1
        whereclausest &= fieldvalar[0] & " NOT LIKE '%" & fieldvalar[1] & "%'"
        if countit < lengthit:
          whereclausest &= " AND "

    sqlst &= whereclausest
 
  
  # prep order-strings
  if ordersq.len == 1:
    orderlist = ordersq[0]
    sqlst &= " ORDER BY " & orderlist & " " & ordertypest
  elif ordersq.len > 1:
    orderlist = ordersq.join(", ")
    sqlst &= " ORDER BY " & orderlist & " " & ordertypest

  echo sqlst

  # get the row-sequence
  withDb:
    result = db.getAllRows(sql(sqlst))


proc addNewFromParams*(tablenamest: string, fieldvaluesq: seq[array[2, string]]) =
  #[ 
  Base on sql: "INSERT INTO my_table (id, name) VALUES (0, jack)"
  Apostrophes-possibs:
    *Apostrophes can be added by prefixing another apostrophe in sql, thus ''
    *replace apostrs by some sequence like _-_-_-_and then back for showing 
    purposes.
  Call like:
    addNewFromParams("mr_data", @[["Droidname", "Koid"], ["Type","neutronic"]])
    addNewFromParams("mr_data", @[["Weight", "63"]])
   ]#


  var
    sqlst, fieldlist, valuelist: string
    lengthit, countit: int

  sqlst = "INSERT INTO " & tablenamest & " ("

  lengthit = len(fieldvaluesq)
  countit = 0

  if lengthit == 1:
    fieldlist = fieldvaluesq[0][0]
    valuelist = "'" & fieldvaluesq[0][1] & "'"
  elif lengthit > 1:
    for fieldvalar in fieldvaluesq:
      countit += 1
      if countit < lengthit:
        fieldlist &= fieldvalar[0] & ", "
        valuelist &= "'" & fieldvalar[1] & "', "

      elif countit == lengthit:
        fieldlist &= fieldvalar[0]
        valuelist &= "'" & fieldvalar[1] & "'"
  
  sqlst &= fieldlist & ") VALUES (" & valuelist & ")"

  log("==================")
  log(sqlst)

  withDb:
    db.exec(sql(sqlst))



proc deleteFromParams*(tablenamest: string, comparetype: Comparetype = compString, 
                        fieldvaluesq: seq[array[2, string]] = @[]) =

  #[ Delete a sequence of rows based on the entered parameters. 
    Comparetype-enum see top of file. 
    fieldvaluesq = @[] must have at least one array-pair

   ]#

  var
    sqlst, whereclausest, fieldlist: string
    lengthit, countit: int

  sqlst = "DELETE FROM " & tablenamest


  # prepare the where-clause / row-filter
  lengthit = len(fieldvaluesq)
  countit = 0

  sqlst &= " WHERE "

  if comparetype == compString:
    for fieldvalar in fieldvaluesq:
      countit += 1
      whereclausest &= fieldvalar[0] & " = '" & fieldvalar[1] & "'"
      if countit < lengthit:
        whereclausest &= " AND "
  elif comparetype == compSub:
    for fieldvalar in fieldvaluesq:
      countit += 1
      whereclausest &= fieldvalar[0] & " LIKE '%" & fieldvalar[1] & "%'"
      if countit < lengthit:
        whereclausest &= " AND "

  sqlst &= whereclausest
 
  log("-------------------------") 
  log(sqlst)

  # get the row-sequence
  withDb:
    db.exec(sql(sqlst))




proc updateFromParams*(tablenamest: string, setfieldvaluesq: seq[array[2, string]],
                           comparetype: Comparetype = compString, 
                        wherefieldvaluesq: seq[array[2, string]] = @[]) =
  
  var
    sqlst, whereclausest, setclausest: string
    wlengthit, wcountit, slengthit, scountit: int


  # starting-sql-statement
  sqlst = "UPDATE " & tablenamest & " SET "

  # prepare the set-clause
  slengthit = len(setfieldvaluesq)
  scountit = 0
  
  for fieldvalar in setfieldvaluesq:
    scountit += 1
    setclausest &= fieldvalar[0] & " = '" & fieldvalar[1] & "'"
    if scountit < slengthit:
      setclausest &= ", "

  sqlst &= setclausest & " WHERE "

  # prepare the where-clause / row-filter
  wlengthit = len(wherefieldvaluesq)
  wcountit = 0

  if comparetype == compString:
    for fieldvalar in wherefieldvaluesq:
      wcountit += 1
      whereclausest &= fieldvalar[0] & " = '" & fieldvalar[1] & "'"
      if wcountit < wlengthit:
        whereclausest &= " AND "
  elif comparetype == compSub:
    for fieldvalar in wherefieldvaluesq:
      wcountit += 1
      whereclausest &= fieldvalar[0] & " LIKE '%" & fieldvalar[1] & "%'"
      if wcountit < wlengthit:
        whereclausest &= " AND "


  sqlst &= whereclausest
 
  log("-------------------------") 
  log(sqlst)

  withDb():
    db.exec(sql(sqlst))



proc getAllUserTables*(): seq[string] = 

  var
    rawtablesq: seq[Row]
    tablesq: seq[string] = @[]

  rawtablesq = readFromParams("sqlite_master", @["name"], compString, 
                                    @[["type", "table"]])
  #echo rawtablesq

  for namesq in rawtablesq:
    if not ("sqlite" in namesq[0]):
      tablesq.add(namesq[0])

  result = tablesq



proc rowCount*(tablenamest: string, comparetype: Comparetype = compString, 
                            fieldvaluesq: seq[array[2, string]] = @[]): int =

  # get the number of records in the record-set given the criteria
  var allrowsq: seq[Row]
  allrowsq = readFromParams(tablenamest, @[], comparetype, fieldvaluesq) 
  result = len(allrowsq)



proc getColumnCount*(tablenamest: string): int =
  # get the number of columns of the table
  result = len(getFieldAndTypeList(tablenamest))



  
proc getKeyFieldStatus*(tablenamest: string): IdGenerationType = 
  # Determine how the ID-field is generated culminating in the 
  # enum IdGenerationType (for now only two types supported)

  var 
    allrowsq: seq[Row]
    sqlstringst: string

  allrowsq = readFromParams("sqlite_master", comparetype = compString,
                                 fieldvaluesq = @[["name", tablenamest]]) 
  sqlstringst = allrowsq[0][4]
  if "AUTOINCREMENT" in sqlstringst:
    result = genIntegerByDb
  else:
    result = genUnknownByHand


proc idValueExists*(tablenamest, id_fieldst, id_valuest: string): bool =
  # Determine if the passed id-value exists for given table
  var countit: int
  countit = rowCount(tablenamest, compString, @[[id_fieldst, id_valuest]])
  if countit > 0:
    result = true
  else:
    result = false



when isMainModule:
  #echo readFromParams("mr_data")
  echo "--------------"
  #echo readFromParams("mr_data", comparetype = compNotSub, fieldvaluesq = @[["Builder", "sung"]])
  # echo readFromParams("mr_data", @["anID", "Droidname"], ordersq = @["anID"], ordertypest = "DESC")
  #echo readFromParams("mr_data", @["Droidname"], ordersq = @["anID"], ordertypest = "DESC")
  #echo readFromParams("mr_data", ordersq = @["Type", "Weight"], ordertypest = "ASC")
  #echo readFromParams("mr_data")
  #echo readFromParams("planten")

  #addNewFromParams("mr_data", @[["Droidname", "Koid"], ["Type","neutronic"]])
  #addNewFromParams("mr_data", @[["Weight", "63"]])
  #sleep(1000)
  #deleteFromParams("mr_data", compString, @[["Weight", "63"]])

  #addNewFromParams("mr_data", @[["Weight", "63"]])

  #updateFromParams("mr_data", @[["Date_of_build", "2428-03-25"]], compString, @[["Droidname", "Koid"]])

  #echo getAllUserTables()

  #[ 
  for item in getFieldAndTypeList("PARAMS"):
    echo item[0]
    echo item[1]
    echo "---"
 ]#

#[ 
  timeThings():
    var testsq: seq[array[2, string]]
    testsq = getFieldAndTypeList("PARAMS")
   ]#


  #echo getKeyFieldStatus("vacancies")

  #echo rowCount("mr_data")
  #echo idValueExists("vacancies", "vacID", "5")


  for item in getFieldAndTypeList("vacancies_high_paying", viewAuto):
    echo item[0]
    echo item[1]
    echo "---"

