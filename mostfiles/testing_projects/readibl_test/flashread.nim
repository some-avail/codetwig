#[ 
UNIT INFO
Flashread is a browser-based program to format text
into a more readable format.
To use the clipboard extra installation is needed.

REQUIREMENTS
External components:
> nimclipboard-lib:
on linux mint 19 you need to install folowing packages:
libx11-xcb-dev and/or xcb
in either one of those exists xbc.h, which is needed.
> moustachu
> jester


VERSION-LINKS = CO-WORKING MODULES
flashread     process_text   webgui_def    jo_htmlgen    stringstuff  f*.css  source_files outer_html.h* flashread.h* settings*   fr_tools   loadgui
070           0.25            0.2           0.2           0.1
071           0.25/0.26       0.2           0.2           0.1           0.67
080           0.26            0.2           0.2           0.1           0.68
081           0.26            0.3           0.4           0.1           0.69
085           0.28            0.4           0.4           0.1           0.70    0.1           1.0             1.0         1.0
086           0.28            0.5           0.4           0.1           0.70    0.1           1.0             1.1         1.0
087           0.29
089           0.30            0.6           0.5           0.1           0.80    0.2           1.1             1.2         1.1         0.1       0.1
093           0.36            0.8           0.5           0.2           0.81    0.2           1.1             1.3         1.5         0.2       0.2

Further belonging files:
<language>.dat like english.dat
summary_<language>_default.dat for different langs and subject-areas
<language>_translations.tra like dutch_translations.tra




ADAP HIS
-improve reformating in-situ
-update titel
-talen-info verhuizen van de broncode naar de tekstbestanden


ADAP NOW


ADAP FUT
-check if additional sources can be loaded like css and pictures
-prevalidate language-dat-file before running
-javascript toevoegen
-koppelingen externe website aanhangen aan eigen website
-web-redo, mogn:
  -inhoudsopgave
 ]#


import jester
import strutils
import httpcore
import process_text
import os
import jo_htmlgen
import nimclipboard/libclipboard
import moustachu
import source_files
import fr_tools
import times
import g_mine

# not called but does needed work once
import loadgui


# set debugbo to false when creating a release!
var debugbo: bool = false

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest


const 
  versionfl: float = 0.9507
  minimal_word_lengthit = 7
  appnamebriefst:string = "RD"
  appnamenormalst = "Readibl"
  appnamesuffikst = "Text Reformatter"


settings:
  # port = Port(5003)   # personal
  port = Port(parseInt(readOptionFromFile("port-number", "value")))  # development




proc getWebTitle():string = 
  var 
    clipob = clipboard_new(nil)
    past, inter_tekst, test, parsestringit:string
    
  const 
    titlelenghit = 60
    parselenghtit = 500

  past = $clipob.clipboard_text()

  try:
    if past[0 .. 3] == "http":   # pasted text is a link
      inter_tekst = getTitleFromWebsite(past)
    else:
      if past.len > titlelenghit:
        inter_tekst = strip(past[0 .. titlelenghit])

    echo "\p\p===============READIBL==================="
    echo inter_tekst


    # Maybe future: advanced parsing to better strip
    # whitespace and/or line-endings

      # if past.len > parselenghtit:
      #   parsestringit = past[0 .. parselenghtit]
      # else:
      #   parsestringit = past

      # log(parsestringit)

      # inter_tekst = getStrippedText(parsestringit)
    
      # if inter_tekst.len > titlelenghit:
      #   inter_tekst = inter_tekst[0 .. titlelenghit]

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"

  result = appnamebriefst & "_" & inter_tekst




proc jump_to_end_step(languagest, preprocesst, taglist, typest, summaryfilest,
                          gencontentst: string, use_multi_summarybo: bool): string =
  # Skip the gradual steps from the radio-buttons and go to processing immediately
  # typest determines if text-extraction or insite text-replacement is done

  var 
    clipob = clipboard_new(nil)
    past, inter_tekst, resulttekst: string
    abbreviationsq: seq[string]

  past = $clipob.clipboard_text()
  abbreviationsq =  sequenceFromValueList(readOptionFromFile("abbreviations", "value-list"))

  if past[0 .. 3] == "http":   # pasted text is a link
    if typest == "":
      inter_tekst = handleTextPartsFromHtml(past, "extract", languagest, taglist, summaryfilest, gencontentst, abbreviationsq, use_multi_summarybo)
      result = formatText(inter_tekst, languagest, preprocesst, summaryfilest, gencontentst, use_multi_summarybo)
    elif typest == "insite_reformating":
      result = handleTextPartsFromHtml(past, "replace", languagest, taglist, summaryfilest, gencontentst, abbreviationsq, use_multi_summarybo)

  else:   # a text-block is pasted in this case
    inter_tekst = past
    resulttekst = replaceInPastedText(inter_tekst, gencontentst, abbreviationsq)
    result = formatText(resulttekst, languagest, preprocesst, summaryfilest, gencontentst, use_multi_summarybo)



proc showPage(par_innervarob, par_outervarob: var Context, 
                custominnerhtmlst:string=""): string = 
  
  var innerhtmlst:string
  {.gcsafe.}:
    if custominnerhtmlst == "":
      innerhtmlst = render(textsourcefileta["flashread.html"], par_innervarob)    
    else:
      innerhtmlst = custominnerhtmlst
    par_outervarob["flashread_form"] = innerhtmlst

    result = render(textsourcefileta["outer_html.html"], par_outervarob)




routes:

  get "/":
    resp "Hello user, to continue please type: http://localhost:5050/flashread-form"

  get "/flashread-form":

    var
      statustekst, statusdatast:string
      output_tekst:string
      filepathst: string
      newinnerhtmlst: string
      filestatusmessagest: string
      compare_filesq: seq[string]
      use_multi_summarybo: bool = false

      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions


    filepathst = "getappdir: " & getappdir() & " <br>" &
              "getcurrentdir: " & getcurrentdir() & " <br>"

    filestatusmessagest = sourcefilestatust & interfacelanguagestatust
    # check if thru source_files.nim if all files are loaded successfully
    if sourcefilestatust != "":  
      statustekst = filestatusmessagest  
    else:
      statustekst = newlang("Press button to paste the content of the clipboard.")

    compare_filesq = sequenceFromValueList(readOptionFromFile("files-to-compare", "value-list"))

    outervarob["version"] = versionfl.formatFloat(ffDecimal, 4)
    outervarob["loadtime"] = newlang("Started: ") & $now()
    outervarob["pagetitle"] = appnamenormalst
    outervarob["namesuffix"] = newlang(appnamesuffikst)


    # load initial form
    innervarob["statustext"] = newlang(statustekst)
    innervarob["statusdata"] = ""
    innervarob["pastedtext"] = ""

    if allFilesExist(compare_filesq):
      innervarob["processedtext"] = filepathst & "<br><br>" & compareDataFiles(compare_filesq[0], compare_filesq[1], "html")
    else:
      innervarob["processedtext"] = filepathst & "<br><br>" & evaluateDataFiles(false)

    innervarob["text_language"] = setDropDown("text-language", readOptionFromFile("text-language", "value"))
    innervarob["taglist"] = setDropDown("taglist", "paragraph-with-headings")
    innervarob["radiobuttons_1"] = setRadioButtons("orders","")
    innervarob["summarylist"] = setDropDown("summarylist", readOptionFromFile("summary-file", "value"))
    innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @["default"])

    innervarob["urltext"] = ""
    innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @["default"])
    innervarob["submit"] = newlang("Choose and run")
    innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
    innervarob["newtab"] = "_self"

    resp showPage(innervarob, outervarob)



  # get "/flashread-form/@errorst":
  #   # load error-form - not used
  #   innervarob["statustekst"] = @"errorst"
  #   innervarob["statusdata"] = ""
  #   innervarob["pastedtext"] = ""
  #   innervarob["processedtext"] = filepathst
  #   innervarob["text_language"] = setDropDown("text-language", readOptionFromFile("text-language", "value"))
  #   innervarob["taglist"] = setDropDown("taglist", "paragraph-only")    
  #   innervarob["radiobuttons_1"] = setRadioButtons("orders","")
  #   innervarob["urltext"] = ""
  #   innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @["default"])
  #   innervarob["submit"] = newlang("Choose and run")
  #   innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")

  #   resp showPage()


  post "/flashread-form":

    var
      clipob = clipboard_new(nil)
      past = $clipob.clipboard_text()
      converted_tekst: string

      statustekst, statusdatast:string
      output_tekst:string
      filepathst: string
      newinnerhtmlst: string
      filestatusmessagest: string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions
      use_multi_summarybo: bool = false


    # filepathst = "getappdir: " & getappdir() & " <br>" &
    #           "getcurrentdir: " & getcurrentdir() & " <br>"

    # filestatusmessagest = sourcefilestatust & interfacelanguagestatust
    # # check if thru source_files.nim if all files are loaded successfully
    # if sourcefilestatust != "":  
    #   statustekst = filestatusmessagest  
    # else:
    #   statustekst = newlang("Press button to paste the content of the clipboard.")

    outervarob["version"] = versionfl.formatFloat(ffDecimal, 4)
    outervarob["loadtime"] = newlang("Started: ") & $now()
    outervarob["pagetitle"] = appnamenormalst
    outervarob["namesuffix"] = newlang(appnamesuffikst)


    if past.len < 5:
      statustekst = """The clipboard is empty or holds a small string (<5); 
                please copy a web-address or a bigger text!"""

      redirect("/flashread-form")


    if request.params["orders"] == "pasteclip":

      if @"jump_to_end" == "":
        # copy the from clipboard to the textbox
        # move to next radiobutton transfer

        statustekst = "Pasted. Now transfer text from link or pasted text."
        statusdatast = @"jump_to_end"


        innervarob["statustext"] = newlang(statustekst)
        innervarob["statusdata"] = statusdatast
        innervarob["pastedtext"] = past
        innervarob["processedtext"] = ""
        innervarob["text_language"] = setDropDown("text-language", @"text-language")
        innervarob["taglist"] = setDropDown("taglist", @"taglist")
        innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
        innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])

        innervarob["radiobuttons_1"] = setRadioButtons("orders", "transfer")
        innervarob["urltext"] = ""
        innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                       @"generate_contents", @"insite_reformating", @"newtab"])
        innervarob["submit"] = newlang("Choose and run")
        innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
        if @"newtab" == "":
          innervarob["newtab"] = "_self"
        elif @"newtab" == "newtab":
          innervarob["newtab"] = "_blank"

        # resp showPage()
        resp showPage(innervarob, outervarob)


      elif @"jump_to_end" == "jump_to_end":
        if @"insite_reformating" == "":

          if @"newtab" == "":
            innervarob["newtab"] = "_self"
          elif @"newtab" == "newtab":
            innervarob["newtab"] = "_blank"
            outervarob["pagetitle"] = getWebTitle()

          if @"multisum" == "multisum":
            if createCombinedSummaryFile("testing", @"text-language"):
              use_multi_summarybo = true
          output_tekst = jump_to_end_step(@"text-language", @"summarize", @"taglist", "", @"summarylist", @"generate_contents", use_multi_summarybo)

          statustekst = "Output number of words:"
          if @"multisum" == "multisum":
            if createCombinedSummaryFile("testing", @"text-language"):
              statusdatast = $countWords(output_tekst) & " --- " & "Using a combined summary.."
            else:
              statusdatast = $countWords(output_tekst)  & " --- " & "Could not use multi-summary-list (invalid)"
          else:
            statusdatast = $countWords(output_tekst)

          innervarob["statustext"] = newlang(statustekst)
          innervarob["statusdata"] = statusdatast
          innervarob["pastedtext"] = past
          innervarob["processedtext"] = output_tekst
          innervarob["text_language"] = setDropDown("text-language", @"text-language")
          innervarob["taglist"] = setDropDown("taglist", @"taglist")
          innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
          innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])
          innervarob["radiobuttons_1"] = setRadioButtons("orders", "pasteclip")
          innervarob["urltext"] = ""
          innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                            @"generate_contents", @"insite_reformating", @"newtab"])
          innervarob["submit"] = newlang("Choose and run")
          innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")

          # resp showPage()
          resp showPage(innervarob, outervarob)

        elif @"insite_reformating" == "insite_reformating":
          # output_tekst = jump_to_end_step(@"text-language", @"summarize")

          if @"newtab" == "":
            innervarob["newtab"] = "_self"
          elif @"newtab" == "newtab":
            innervarob["newtab"] = "_blank"
            outervarob["pagetitle"] = getWebTitle()


          if @"multisum" == "multisum":
            if createCombinedSummaryFile("testing", @"text-language"):
              use_multi_summarybo = true
          newinnerhtmlst = jump_to_end_step(@"text-language", @"summarize", @"taglist", 
                                        @"insite_reformating", @"summarylist", @"generate_contents", use_multi_summarybo)

          statustekst = "Output number of words:"
          if @"multisum" == "multisum":
            if createCombinedSummaryFile("testing", @"text-language"):
              statusdatast = $countWords(newinnerhtmlst) & " --- " & "Using a combined summary.."
            else:
              statusdatast = $countWords(newinnerhtmlst)  & " --- " & "Could not use multi-summary-list (invalid)"
          else:
            statusdatast = $countWords(newinnerhtmlst)

          #newinnerhtmlst = jump_to_end_step(@"text-language", @"summarize", 
          #                      @"taglist", @"insite_reformating", 
          #                      @"summarylist", @"generate_contents")
          #statustekst = "Output number of words:"
          #statusdatast = $countWords(newinnerhtmlst)

          innervarob["statustext"] = newlang(statustekst)
          innervarob["statusdata"] = statusdatast
          innervarob["pastedtext"] = past
          innervarob["processedtext"] = newinnerhtmlst
          innervarob["text_language"] = setDropDown("text-language", @"text-language")
          innervarob["taglist"] = setDropDown("taglist", @"taglist")
          innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
          innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])
          innervarob["radiobuttons_1"] = setRadioButtons("orders", "pasteclip")
          innervarob["urltext"] = ""
          innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                      @"generate_contents", @"insite_reformating", @"newtab"])
          innervarob["submit"] = newlang("Choose and run")
          innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")

          # resp showPage(newinnerhtmlst)
          resp showPage(innervarob, outervarob, newinnerhtmlst)

    elif request.params["orders"] == "transfer":
      # transfer the text or link from input to the right column
      # but first prepare dedotting abbreviations
      var abbreviationsq: seq[string]
      abbreviationsq =  sequenceFromValueList(readOptionFromFile("abbreviations", "value-list"))

      # determine type of pasted_text (text or link)
      if @"pasted_text"[0..3] == "http":   # pasted text is a link

        output_tekst = handleTextPartsFromHtml(@"pasted_text", "extract", @"text-language", 
                                          @"taglist", @"summarylist", @"generate_contents", abbreviationsq, use_multi_summarybo)
        # echo output_tekst
        
        statustekst = "Output number of words:"
        statusdatast = $countWords(output_tekst)
        innervarob["statustext"] = newlang(statustekst)
        innervarob["statusdata"] = statusdatast
        innervarob["pastedtext"] = output_tekst
        innervarob["processedtext"] = output_tekst
        innervarob["text_language"] = setDropDown("text-language", @"text-language")
        innervarob["taglist"] = setDropDown("taglist", @"taglist")
        innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
        innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])
        innervarob["radiobuttons_1"] = setRadioButtons("orders", "frequencies")
        innervarob["urltext"] = @"pasted_text"
        innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                      @"generate_contents", @"insite_reformating", @"newtab"])
        innervarob["submit"] = newlang("Choose and run")
        innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
        if @"newtab" == "":
          innervarob["newtab"] = "_self"
        elif @"newtab" == "newtab":
          innervarob["newtab"] = "_blank"

        # resp showPage()
        resp showPage(innervarob, outervarob)

      else:
        converted_tekst = replaceInPastedText(@"pasted_text", @"generate_contents", abbreviationsq)
        statustekst = "Text transferred to right column"
        innervarob["statustext"] = newlang(statustekst)
        innervarob["statusdata"] = ""
        innervarob["pastedtext"] = converted_tekst
        innervarob["processedtext"] = converted_tekst
        innervarob["text_language"] = setDropDown("text-language", @"text-language")
        innervarob["taglist"] = setDropDown("taglist", @"taglist")    
        innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
        innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])
        innervarob["radiobuttons_1"] = setRadioButtons("orders", "frequencies")
        innervarob["urltext"] = ""
        innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                        @"generate_contents", @"insite_reformating", @"newtab"])
        innervarob["submit"] = newlang("Choose and run")
        innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
        if @"newtab" == "":
          innervarob["newtab"] = "_self"
        elif @"newtab" == "newtab":
          innervarob["newtab"] = "_blank"

        # resp showPage()
        resp showPage(innervarob, outervarob)


    elif request.params["orders"] == "frequencies":

      output_tekst = calculateWordFrequencies(@"pasted_text", minimal_word_lengthit, true)
      statustekst = "Calculated frequencies for minimal word-length:"
      statusdatast = $minimal_word_lengthit
      innervarob["statustext"] = newlang(statustekst)
      innervarob["statusdata"] = statusdatast

      innervarob["pastedtext"] = @"pasted_text"
      innervarob["processedtext"] = output_tekst
      innervarob["text_language"] = setDropDown("text-language", @"text-language")
      innervarob["taglist"] = setDropDown("taglist", @"taglist")
      innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
      innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])
      innervarob["radiobuttons_1"] = setRadioButtons("orders", "process_text")
      innervarob["urltext"] = @"url_text"
      innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                      @"generate_contents", @"insite_reformating", @"newtab"])
      innervarob["submit"] = newlang("Choose and run")
      innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
      if @"newtab" == "":
        innervarob["newtab"] = "_self"
      elif @"newtab" == "newtab":
        innervarob["newtab"] = "_blank"

      # resp showPage()
      resp showPage(innervarob, outervarob)

    if request.params["orders"] == "process_text":

      if @"newtab" == "":
        innervarob["newtab"] = "_self"
      elif @"newtab" == "newtab":
        innervarob["newtab"] = "_blank"
        outervarob["pagetitle"] = getWebTitle()

      if @"multisum" == "multisum":
        if createCombinedSummaryFile("testing", @"text-language"):
          use_multi_summarybo = true

      output_tekst = formatText(@"pasted_text", @"text-language", @"summarize", 
                              @"summarylist", @"generate_contents", use_multi_summarybo)

      statustekst = "Output number of words:"
      if @"multisum" == "multisum":
        if createCombinedSummaryFile("testing", @"text-language"):
          statusdatast = $countWords(output_tekst) & " --- " & "Using a combined summary.."
        else:
          statusdatast = $countWords(output_tekst)  & " --- " & "Could not use multi-summary-list (invalid)"
      else:
        statusdatast = $countWords(output_tekst)

      statustekst = "Output number of words:"
      statusdatast = $countWords(output_tekst)
      innervarob["statustext"] = newlang(statustekst)
      innervarob["statusdata"] = statusdatast

      innervarob["pastedtext"] = @"pasted_text"
      innervarob["processedtext"] = output_tekst
      innervarob["text_language"] = setDropDown("text-language", @"text-language")
      innervarob["taglist"] = setDropDown("taglist", @"taglist")
      innervarob["summarylist"] = setDropDown("summarylist", @"summarylist")
      innervarob["checkbox_multisum"] = setCheckBoxSet("fr_checkset2", @[@"multisum"])
      innervarob["radiobuttons_1"] = setRadioButtons("orders", "pasteclip")
      innervarob["urltext"] = @"url_text"
      innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                        @"generate_contents", @"insite_reformating", @"newtab"])
      innervarob["submit"] = newlang("Choose and run")
      innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")


      # resp showPage()
      resp showPage(innervarob, outervarob)      

