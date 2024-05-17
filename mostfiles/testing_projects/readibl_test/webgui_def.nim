#[ 

Static definitions for html-gui called from jo_htmlgen.nim

Observations:
-you can nest all you want if you use constants,
  instead of variables.
-one can test the makeup of a composite constant by using echo,
  which indicates how you can parse it.
-tables only work with same-typed items
-some controls are served as set, some as single item.

ADAP NOW
-variablize the constant to enable updating from external source
by module loadgui.nim
  -see research at: test_01228_complexe_vars_declareren.nim
  -choose simplest option (and least elegant) to only 
  convert the const to var


 ]#



import tables

var versionfl = 0.8


# radio-button-sets (set is necessary for radio-buttons):
# name, and then sequence: value, label, startup-selection
const radiobuttonsta* = {
          "aapnootmies": @[("aap", "grote aap", false),
                      ("noot", "notenboom", true),
                      ("mies", "mies-bouwman", false)],
          "orders_old": @[("frequencies", "Calculate word-frequencies", true),
                      ("process_text", "Process pasted text", false),
                      ("process_link", "Process pasted link", false)],
          "orders": @[("pasteclip", "Paste from the clipboard", true),
                      ("transfer", "Transfer belonging text", false),
                      ("frequencies", "Calculate word-frequencies", false),
                      ("process_text", "Reformat transferred text", false)]
                      }.toTable


# checkbox-sets (may load defaults from config-file thru loadgui.nim)
var checkboxesta* = {
      "aapnootmies": @[("aap", "grote aap", false),
                      ("noot", "notenboom", true),
                      ("mies", "mies-bouwman", true)],
      "fr_checkset1": @[("jump_to_end", "Jump to end-step", false),
                        ("summarize", "Summarize (extract certain sentences)", false),
                        ("generate_contents","Generate contents (experimental)", false),
                        ("insite_reformating","Perform in-site reformating", false),
                        ("newtab", "Open result in new tab", false)],
      "fr_checkset2": @[("multisum", "Use multi-summary file", false)]
                      }.toTable



# dropdowns or in html-lingo: selects
#  -concerns single items aot sets
#  -updated in loadgui.nim
var dropdownsta* =    [("calledname", "somelabel",
                                @[
                                ["first-value", "first shown value"], 
                                ["second-value", "second shown value"]
                                ]
                        ),
                        ("text-language", "Text-language:",
                                @[["dutch", "Dutch"], 
                                ["english", "English"]
                                ]
                        ),
                        ("taglist", "Pick taglist:",
                                @[
                                ["paragraph-only", "Paragraph only"], 
                                ["paragraph-with-headings", "Paragraph with headings"], 
                                ["full-list", "Full list"],
                                ["full-list-with-headings", "Full list with headings"],
                                ["exotic-list", "Exotic list"],
                                ["exotic-list-with-headings", "Exotic list with headings"],
                                ["body-tag-only", "Body-tag only"],
                                ["body-tag-with-headings", "Body-tag with headings"]
                                ]
                        ),
                        ("summarylist", "Highlighting/ summary = *:",
                                @[
                                ["sumname", "summary_english_qual.dat"]
                                ]
                        )
                      ]


when isMainModule:
  echo checkboxesta
  # echo dropdownsta[0]
  # echo dropdownsta[0][0]
  # echo dropdownsta[0][1]

