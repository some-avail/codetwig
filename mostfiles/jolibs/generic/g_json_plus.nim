#[ Extra procs for json to easily retrieve and  write data from/to file 
-getDeepNodeFromKey() - get the node from anywhere in the json-exp by recursing
-calcDoubleKeys() - build a sequence of keys with multiple occurences,
                    so that they can be avoided.
]#


import json, tables

var versionfl: float = 0.2


when isMainModule:
  var filest: string
  # filest = "testedit.json"
  filest = "freek_gui.json"
  # filest = "test-freek_gui.json"
  var jnob = parseFile(filest)
  var arrjnob = %*[{"naam":"knakkie", "leeftijd": 89}]
  # var jnob = %*{"naam":"knakkie", "leeftijd": 89, "naam": "bizon"}
  var tempjnob: JsonNode = %*{}



proc testIter01(jnob:JsonNode)=
  # for testing only

  # walk thru keys
  #   check the kind of their values
  #   if their kind is JObject
  #     print that value
  #     recurse for that object (if recurbo = true)
  var it = 0
  var indentst = ""

  if jnob.kind == JObject:
    for key in jnob.keys:
      echo key
      # echo jnob[key].kind

      if jnob[key].kind == JObject:
        it += 1
        indentst = indentst & "  "
        testIter01(jnob[key])
      else:
        # echo indentst, $jnob[key]
        discard


proc testDeepNodeFromKey(keyst:string, depthcountit: int = 0, 
                  jnob:JsonNode, foundjnob:var JsonNode) = 

  # deprecated; for testing

  # Get the node from anywhere in the json-exp by recursing 
  # the jnob and finding the key.
  # The foundjnob must externally be existing and initilized,
  # and will be overwritten. If the key is not found nothing will 
  # be overwritten. If multiple are found the latest will 
  # written.

  var 
    tbo = false
    keycountit: int = 0
    depthit: int = depthcountit

  if tbo: echo "================================="
  if jnob.kind == JObject:
    # walk thru the keys
    for key in jnob.keys:
      keycountit += 1
      if tbo: echo keycountit
      if tbo: echo key
      if tbo: echo jnob[key].kind

      if key == keyst:
        foundjnob = jnob[key]

      if jnob[key].kind == JObject:
        depthit += 1
        if tbo: echo "depthit = ", $depthit
        testDeepNodeFromKey(keyst, depthit, jnob[key], foundjnob)
  else:
    echo "Original JsonNode is no JObject, but a ", $jnob.kind




proc getDeepNodeFromKey*(keyst:string, jnob:JsonNode, parfoundjnob:var JsonNode) = 

#[ 
   Get the node from anywhere in the json-exp of original 
   json-node-object jnob by recursing the jnob and finding the key.
   The original jnob must be of type / kind: JObject.
   The parfoundjnob must externally be existing and initilized,
   and will be overwritten. If the key is not found nothing will 
   be overwritten. If multiple keys are only the first one will 
   be used.

   ADAP HIS:
    - added a block structure to enable immediate breaks after find
    for better performance
 ]#

  var 
    tbo = false
    keycountit: int = 0

  if tbo: echo "================================="
  block myblock:
    if jnob.kind == JObject:
      # walk thru the keys
      for key in jnob.keys:
        keycountit += 1
        if tbo: echo keycountit
        if tbo: echo key
        if tbo: echo jnob[key].kind

        if key == keyst:
          parfoundjnob = jnob[key]
          break myblock
        if jnob[key].kind == JObject:
          getDeepNodeFromKey(keyst, jnob[key], parfoundjnob)
    else:
      echo "Error: original JsonNode is no JObject, but a ", $jnob.kind




proc listKeysFromNode(jnob:JsonNode, allkeyssq: var seq[string]) =

  # -walk thru all keys from a jnob, and put them in allkeyssq
  # -an empty seq must be pre-initalized externally and given as param.


  # walk thru keys
  #   check the kind of their values
  #   if their kind is JObject
  #     recurse for that object (if recurbo = true)

  if jnob.kind == JObject:
    for key in jnob.keys:
      # echo key
      # echo jnob[key].kind
      allkeyssq.add(key)
      if jnob[key].kind == JObject:
        listKeysFromNode(jnob[key], allkeyssq)




proc findDoubleKeys(keylistsq: seq[string]): seq[string] =

  # -find the non-unique keys in a keylist and return them as 
  # a (sub)sequence

  var countta = toCountTable(keylistsq)

  result = @[]
  for keyst,valit in countta.pairs:
    if valit > 1:
      result.add(keyst)
  


proc pruneJnodesFromTree*(treejnob: var JsonNode, pathtoparentsq, 
                                    siblings_to_prunesq: seq[string]) = 
  # Remove items (siblings_to_prunesq) from the treejnob that are located at 
  # pathtoparentsq
  for siblingst in siblings_to_prunesq:
    #echo siblingst
    if treejnob{pathtoparentsq}.hasKey(siblingst):
      #echo siblingst
      treejnob{pathtoparentsq}.delete(siblingst)




proc graftJObjectToTree*(newkeyst: string, pathtomountpointsq: seq[string], 
                          adoptivejnob: var JsonNode, orphanjnob: JsonNode) = 
  #[ Add a new (orphan) jsonnode to an adoptive jsonnode, both of type JObject.
      Set the path to mountpoint (where to attach) via pathtomountpointsq. 
      The orphan-jnob must look like: {newkeyst: some-jsonnode, blabla}
      The adoptive node must be preset outside of/before the procedure.
    ]#

  var temp_pathsq: seq[string]
  if not adoptivejnob.hasKey(newkeyst):
    adoptivejnob{pathtomountpointsq}.add(newkeyst,orphanjnob[newkeyst])
  else:     # overwrite existing subnode
    temp_pathsq = pathtomountpointsq
    temp_pathsq.add(newkeyst)
    adoptivejnob{temp_pathsq} = orphanjnob[newkeyst]
  #echo pretty (adoptivejnob)



proc replaceLastItemOfSeq*(sequencesq: seq[string], newtailest: string): seq[string] =

  var mysq: seq[string]
  mysq = sequencesq

  if mysq.len > 0:
    mysq = mysq[0..len(mysq) - 2]
  mysq.add(newtailest)

  result = mysq



when isMainModule:

  # echo tempjnob
  # getDeepNodeFromKey("web-elements fp", jnob, tempjnob)
  # echo tempjnob.kind
  # echo tempjnob

  # =============================================
  # var keylistsq: seq[string] = @[]
  # listKeysFromNode(jnob, keylistsq)
  # echo keylistsq
  # echo findDoubleKeys(keylistsq)
  # ===================================
  #testIter01(jnob)
  # ==========================================
  var mysq: seq[string] = @["all web-pages", "first web-page", "web-elements fp", "basic tables fp"]

  #echo replaceLastItemOfSeq(mysq, "d. duck")
  #graftJObjectToTree("new-table", mysq, true, jnob, %*{"new-table": "is nog klein"})


  echo pretty(jnob)
  pruneJnodesFromTree(jnob, mysq, @["table_01"])
  echo "----------------------------"
  echo pretty(jnob)
  echo "============"



