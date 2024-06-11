#[
Some tools like:
-options (config-file: projectprefix_settings.conf) 
-localization / translation

Is a forth-development fr_tools.nim of readible
Expects global constant project_prefikst
]#



import strutils, times
import std/paths
import ../../app_globals


var debugbo: bool = false


var 
  interfacelanguagestatust*: string = ""
  # test: string
  versionfl: float = 0.4


# moved to: app_globals:
#const project_prefikst = "freek"

type  
  OptionType* = enum
    optValue
    optValueList
    optDescription



# Beware: variable debugbo might be used globally, modularly and procedurally
# whereby lower scopes override the higher ones?
# Maybe best to use modular vars to balance between an overload of 
# messages and the need set the var at different places.

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



proc readOptionFromFile_fut*[T:string|int](optnamest: string, optiontype: OptionType): T =
  #[
  Under construction...
  Read from the settings-file based on the option-data, which are ordered 
  per line containing:
  option-name___value___some description here___list-item1,,list-item2,,list-item3,,ect...

  The option-name is the first part of the line, the others are retrieved thru the 
  optiontype-enum.

  Expects settings-file as projectprefix_settings.conf"
 ]#

  var 
    filenamest: string = project_prefikst & "_settings.conf"
    clusterst: string
    optionsq: seq[string]
    optiondatast: string = ""
    myfile: File
    lastlinest: string
    tbo: bool = false


  if open(myfile, filenamest):    # try to open the file
    try:

      # walk thru the lines of the file
      if tbo: echo "\n=====Begin processing===="
      for line in myfile.lines:
        # echo line
        lastlinest = line
        if len(line) >= 5:        # exclude residual spaces
          if line[0 .. 0] != "#":     # exclude comments
            if line[0 .. 2] == ">>>":     # set cluster / subject
              # new cluster found
              clusterst = line[3 .. len(line) - 4]
              # echo clusterst
            else:                   # real options here
              optionsq = line.split("___")
              # echo optionsq
              if optionsq[0] == optnamest:    # option found
                if tbo: echo "------option found------"
                if tbo: echo optionsq
                if optiontype == optValue:
                  case optionsq[2]:
                  of "int":
                    result = parseInt(optionsq[1])
                  of "str":
                    result = optionsq[1]
                elif optiontype == optDescription:
                  optiondatast = optionsq[3]
                elif optiontype == optValueList:
                  optiondatast = optionsq[4]
                # exit loop when ready
                break

      if tbo: echo "\p===End of processing====\p"
    
    except IOError:
      echo "IO error!"
    
    except:
      let errob = getCurrentException()
      echo "\p******* Unanticipated error ******* \p" 
      echo "Last file-line read: " & lastlinest & "\p"
      echo repr(errob) & "\p****End exception****\p"

    finally:
      close(myfile)
  else:
    echo "File " & filenamest & " could not be opened."
    echo "Please check name and / or presence of file."



proc readOptionFromFile*(optnamest: string, optiontype: OptionType): string =
  #[
  Read from the settings-file based on the option-data, which are ordered 
  per line containing:
  option-name___value___some description here___list-item1,,list-item2,,list-item3,,ect...

  The option-name is the first part of the line, the others are retrieved thru the 
  optiontype-enum.
  Expects settings-file as projectprefix_settings.conf"
 ]#

  var 
    #filenamest: string = "../../" & project_prefikst & "_settings.conf"
    filenamest: string = project_prefikst & "_settings.conf"

    clusterst: string
    optionsq: seq[string]
    optiondatast: string = ""
    myfile: File
    lastlinest: string
    tbo: bool = false


  if open(myfile, filenamest):    # try to open the file
    try:

      # walk thru the lines of the file
      if tbo: echo "\n=====Begin processing===="
      for line in myfile.lines:
        # echo line
        lastlinest = line
        if len(line) >= 5:        # exclude residual spaces
          if line[0 .. 0] != "#":     # exclude comments
            if line[0 .. 2] == ">>>":     # set cluster / subject
              # new cluster found
              clusterst = line[3 .. len(line) - 4]
              # echo clusterst
            else:                   # real options here
              optionsq = line.split("___")
              # echo optionsq
              if optionsq[0] == optnamest:    # option found
                if tbo: echo "------option found------"
                if tbo: echo optionsq
                if optiontype == optValue:
                  optiondatast = optionsq[1]
                elif optiontype == optDescription:
                  optiondatast = optionsq[2]
                elif optiontype == optValueList:
                  optiondatast = optionsq[3]
                # exit loop when ready
                break

      if tbo: echo "\p===End of processing====\p"
    
    except IOError:
      echo "IO error!"
    
    except:
      let errob = getCurrentException()
      echo "\p******* Unanticipated error ******* \p" 
      echo "Last file-line read: " & lastlinest & "\p"
      echo repr(errob) & "\p****End exception****\p"

    finally:
      close(myfile)
  else:
    #echo string(getCurrentDir())
    echo "File " & filenamest & " could not be opened."
    echo "Please check name and / or presence of file."

  return optiondatast



proc getValList*(valuelist: string): seq[string] = 

  result = valuelist.split(",,")



proc newlang*(englishtekst:string):string =
  # Read from the language-translation-file (*.tra) the
  # appropriate translation for the target-language 
  # and return that.

  var 
    filenamest: string
    clusterst: string
    translationsq: seq[string]
    transdatast: string = ""
    myfile: File
    lastlinest: string
    targetlangst:string
    translationfoundbo:bool = false

  targetlangst = readOptionFromFile("interface-language", optValue)
  
  if targetlangst == "english":
    # no translation
    transdatast = englishtekst
  else:
    #filenamest = "../../" & targetlangst & "_translations.tra"
    filenamest = targetlangst & "_translations.tra"

    if open(myfile, filenamest):    # try to open the file
      try:

        # walk thru the lines of the file
        log("\n=====Begin processing====")
        for line in myfile.lines:
          # echo line
          lastlinest = line
          if len(line) >= 5:        # exclude residual spaces
            if line[0 .. 0] != "#":     # exclude comments
              if line[0 .. 2] == ">>>":     # set cluster / subject
                # new cluster found
                clusterst = line[3 .. len(line) - 4]
                # echo clusterst
              else:                   # real options here
                translationsq = line.split("___")
                # echo translationsq
                if translationsq[0] == englishtekst:    # option found
                  log("------translation found------")
                  log($translationsq)
                  translationfoundbo = true
                  transdatast = translationsq[1]
                  # elif typest == "description":
                  #   transdatast = translationsq[2]
                  # elif typest == "value-list":
                  #   transdatast = translationsq[3]

                  # exit loop when ready
                  break

        log("\p===End of processing====\p")
      
      except IOError:
        echo "IO error!"
      
      except:
        let errob = getCurrentException()
        echo "\p******* Unanticipated error ******* \p" 
        echo "Last file-line read: " & lastlinest & "\p"
        echo repr(errob) & "\p****End exception****\p"

      finally:
        close(myfile)
    else:
      echo "File " & filenamest & " could not be opened."
      interfacelanguagestatust = filenamest & " could not be found. "

  if not translationfoundbo:
    transdatast = englishtekst

  return transdatast



when isMainModule:

  
  #echo readOptionFromFile("freq-word-length", optValue)
  echo getValList(readOptionFromFile("subs-not-in-childlinks", optValueList))
  # echo newlang("not translated")
  #log("hallo yall")
  # discard
  #echo getValList("aa___bbb___cc")
  #echo getValList("")

