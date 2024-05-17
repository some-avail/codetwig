#[ 
html-functions and -definitions

ADAP HIS
-cheapening:
  +-seq to array
  v-vars to const
-implement tables and adapt setradio
-move definitions to external file and call to that


ADAP NOW

 ]#

import tables
import webgui_def
import fr_tools

# no longer used
# import process_text


var versionfl = 0.5

# below def-sample commented and moved to webgui_def.nim
# const radiobuttonsta = {
#           "aapnootmies": @[("aap", "grote aap", false),
#                       ("noot", "notenboom", true),
#                       ("mies", "mies-bouwman", false)]
#         }.toTable



proc setRadioButtons*(namest, value_selectst:string):string = 

#[ 
UNIT INFO:
Generate code for radio-buttons based on an external gui-def
for radio-buttons.

Returns for sample-def:
<input type="radio" id="id_aap" name="een-naam" value="aap">
<label for="id_aap">grote aap</label><br>
<input type="radio" id="id_noot" name="een-naam" value="noot">
<label for="id_noot">notenboom</label><br>
<input type="radio" id="id_mies" name="een-naam" value="mies" checked>
<label for="id_mies">mies-bouwman</label><br>
 ]#


  let buttonsq = radiobuttonsta[namest]
  var 
    htmlst, valuest, labelst, checkst:string
    selectbo: bool

  htmlst = ""
  for buttontu in buttonsq:
    valuest = buttontu[0]
    labelst = newlang(buttontu[1])
    selectbo = buttontu[2]

    checkst = ""    # reset checkst

    if value_selectst == "":
      if selectbo:
        checkst = " checked"
    else:
      if value_selectst == valuest:
        checkst = " checked"

    htmlst &= "<input type=\"radio\" id=\"id_" & valuest & 
       "\" name=\"" & namest & "\" value=\"" & valuest & "\"" & checkst & ">\p"
    htmlst &= "<label for=\"id_" & valuest & "\">" & labelst & "</label><br>\p"

  return htmlst


proc setCheckBoxSet*(setnamest:string, checked_onesq:seq[string]): string = 
#[ 
UNIT INFO:
Generate code for a set of checkboxes with setnamest,
based on an external gui-def (webgui_def.nim)
Fill in the checked ones (checked_onesq) with the names 
for checkboxes you want to check,
or fill in "default" to read the default-values from webgui_def.


Returns for sample-def (default):
<input type="checkbox" id="id_aap" name="aap">
<label for="id_aap">grote aap</label><br>
<input type="checkbox" id="id_noot" name="noot" checked>
<label for="id_noot">notenboom</label><br>
<input type="checkbox" id="id_mies" name="mies" checked>
<label for="id_mies">mies-bouwman</label><br>
 ]#



  let buttonsq = checkboxesta[setnamest]
  var 
    htmlst, boxnamest, labelst, checkst:string
    selectbo: bool

  htmlst = ""
  for buttontu in buttonsq:
    boxnamest = buttontu[0]
    labelst = newlang(buttontu[1])
    selectbo = buttontu[2]

    checkst = ""    # reset checkst

    if checked_onesq.len > 0:
      if "default" in checked_onesq:
        if selectbo:
          checkst = " checked"
      else:
        if boxnamest in checked_onesq:
          checkst = " checked"

    htmlst &= "<input type=\"checkbox\" id=\"id_" & boxnamest & 
       "\" name=\"" & boxnamest & "\" value=\"" & boxnamest & "\""  & checkst & ">\p"
    htmlst &= "<label for=\"id_" & boxnamest & "\">" & labelst & "</label><br>\p"

  return htmlst



proc setDropDown*(dropdownnamest, selected_valuest: string):string = 

#[ 
UNIT INFO:
Generate code for a dropdown-control/ select-element,
based on an external gui-def (webgui_def.nim).
In this procedure you can only set one control per call.
The first string-item of the def is dropdownnamest, and you must choose 
a selected value that is to be shown after loading.

Sample output:
<span style="font-size:small"><label for="language">Language</label></span>
<select id="language" name="language">
<option value="dutch">Dutch</option>
<option value="english" selected>English</option>
</select>
 ]#

  var
    dropdown_list, dropdown_html: string
    valIDst, valuest: string
    namest, labelst: string
    valuelistsq:seq[array[2, string]]

  for definition in dropdownsta:
    if definition[0] == dropdownnamest:
      namest = definition[0]    # invisible so not translated
      labelst = newlang(definition[1])  # translated
      valuelistsq = definition[2]   # values not translated for now


  for valuepairtu in valuelistsq:
    valIDst = valuepairtu[0]
    valuest = valuepairtu[1]

    if valIDst == selected_valuest:
      dropdown_list &= "<option value=\"" & valIDst & "\" selected>" & valuest & "</option>\p"
    else:
      dropdown_list &= "<option value=\"" & valIDst & "\">" & valuest & "</option>\p"


  dropdown_html = "<span ><label for=\"" & namest & "\">" & labelst & "</label></span>\p"
  dropdown_html &= "<select id=\"" & namest & "\" name=\"" & namest & "\">\p"
  dropdown_html &= dropdown_list
  dropdown_html &= "</select>\p"


  # <span style="font-size:small"><label for="language">Language</label></span>
  # <select id="language" name="language">
  # {{{text_language}}}
  # </select>

  return dropdown_html



when isMainModule:
  # echo setRadioButtons("orders", "")
  # echo setCheckBoxSet("fr_checkset1", @["default"])
  echo "---------"
  echo setDropDown("text-language", "english")
