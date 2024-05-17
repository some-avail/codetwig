#[ 
aangepaste zoek-en-vervang-functie
 ]#


import strutils

var debugbo: bool = false

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest

var
  versionfl:float = 0.4
  starttekst, searchst, insertst: string
  mystripextractbo: bool



proc stripSymbolsFromList*(inputtekst: string, listsq: seq[string], symbolst: string): string =
  #[ 
  For all the words in the list that are present in inputtekst 
  strip symbolst (like U.S. > US)
  ]#

  var 
    tekst: string = inputtekst
    strippedwordst: string

  for wordst in listsq:
    strippedwordst = wordst.replace(symbolst, "")
    tekst = tekst.replace(wordst, strippedwordst)

  result = tekst



proc countOccurencesInContext(stringst, subst, contexttypest:string, 
                               contextsizeit, positionit: int):int =
  
  #[ 
  Test how many occs of a substring are present in 
  the context of a string. Supported context-type is forward and 
  around, contextsize determines how many forward or around
  positions are tested.
   ]#

  var
    contekst: string
    cont_countit, endposit, startposit: int

  if contexttypest == "forward":
    if stringst.len - positionit > contextsizeit:
      endposit = positionit + contextsizeit
    else:
      endposit = stringst.len - 1

    contekst = stringst[positionit .. endposit]

    cont_countit = count(contekst, subst, false)

  elif contexttypest == "around":
    if stringst.len - positionit > contextsizeit:
      endposit = positionit + contextsizeit
    else:
      endposit = stringst.len - 1

    if contextsizeit < positionit:
      startposit = positionit - contextsizeit
    else:
      startposit = 0

    contekst = stringst[startposit .. endposit]
    cont_countit = count(contekst, subst, false)

  else:
    echo "Unsupported context-type!"
  
  return cont_countit




proc customReplace*(sourcetekst: string, searchst, insertst: string, stripextractbo: bool,
                  conditionst: string, cond_intsq:seq[int]): string =

  #[ 
  UNIT INFO
  Replace in a text by searching the string searchst, and after finding 
  inserting insertst as the new string. 
  When stripextractbo = true then only extract the string without 
  trailing spaces.
  Perform the replacement only when conditionst is met, based on the data
  in cond_datasq. 
  Supported condition:
  unique_occurrence = skip replacement when multiple 
  instances of searchst occur in a range around searchtst (in cond_intsq).
  Return the replaced tekst.
   ]#

  var
    posit: int = 0
    stringfoundbo: bool = true
    strippedst: string
    continubo: bool = false
    countit: int = 0
    tekst: string = sourcetekst


  while stringfoundbo:
    countit += 1
    #echo "countit = " & $countit
    if searchst == "(":
      if countit > 100: break
    else:
      if countit > 10000: break
  
    posit = find(tekst, searchst, posit)
    if posit >= 0:
      # echo "posit = " & $posit
      # echo tekst
      continubo = false
      if conditionst == "unique_occurrence":
        if countOccurencesInContext(tekst, searchst, 
                                "around", cond_intsq[0], posit) <= 1:
          continubo = true
        else:
          if posit + cond_intsq[0] < tekst.len - 1:
            posit += cond_intsq[0]

      elif conditionst == "":
        continubo = true

      if continubo:
        if not stripextractbo:
          tekst.delete(posit..posit + searchst.len - 1)
        else:
          strippedst = strip(searchst, true, true)
          if posit > 0:
            posit = find(tekst, strippedst, posit - 1)
          else:
            posit = find(tekst, strippedst, posit)
          tekst.delete(posit..posit + strippedst.len - 1)

        tekst.insert(insertst, posit)
        posit += insertst.len

    elif posit == -1:
      stringfoundbo = false

  result = tekst




proc test_customReplace()=

  echo "------------"
  echo starttekst
  echo searchst
  echo insertst
  echo "mystripextractbo = " & $mystripextractbo
  echo customReplace(starttekst, searchst, insertst, mystripextractbo, 
                      "unique_occurrence", @[7])


proc outer_test_customReplace()=

  mystripextractbo = false

  starttekst = "katkatkatkatkat"
  searchst = "kat"
  insertst = "x"
  test_customReplace()

  starttekst = "xxxxx"
  searchst = "x"
  insertst = "kat"
  test_customReplace()

  starttekst = "dekat is de kattigste kat van kat-wereld"
  searchst = " kat "
  insertst = "x kat x"
  test_customReplace()

  starttekst = "dekat is de kattigste kat van kat-wereld"
  searchst = "kat "
  insertst = "kat x"
  test_customReplace()

  starttekst = "dekat is de kattigste kat van kat-wereld"
  searchst = " kat"
  insertst = "x kat"
  test_customReplace()

  starttekst = "xxxxxaxxxxxaxxxxxx"
  searchst = "a"
  insertst = "b"
  test_customReplace()


proc test_countOccurencesInContext()=
  var
    stringst: string = "de aap, de kat, de hond en de mens"
    subst: string = ","
    sizeit: int = 5
    posit: int = 9

  echo stringst
  echo stringst.len
  echo subst
  echo sizeit
  echo posit
  echo countOccurencesInContext(stringst, subst, "around", 
                                sizeit, posit)



when isMainModule:

  # outer_test_customReplace()
  # test_countOccurencesInContext()
  var strengst = "The dr. from the U.S. has arrived"
  echo strengst
  echo stripSymbolsFromList(strengst, @["dr.", "U.S."], ".")
