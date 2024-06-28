## CodeTwig - A code viewer and analyser

![01](mostfiles/pictures/codetwig_declarations_tree.png)

[See below for more screenshots](#more-screenshots)

[Go to downloadable releases](https://github.com/some-avail/codetwig/releases "Downloads for CodeTwig")

[Go to the user-manual](mostfiles/manual_codetwig.txt)


#### Forthcoming version: 1.62

### Description CodeTwig

CodeTwig (CT) is terminal-program to view the outline of the source-code and to show procedures as usage-trees or used-by-trees. Some features are still to be added. See future-plans below. Currently only meant for Nim.

#### Features
- CT scans the source-code-files on basis of the project you have defined and adds the files from all underlying directories (after which you can prune the list).
- It creates a declaration-list in which all declarations like procs and templates are listed 
- The declaration-list is used to generate 4 text-files that give specific views of the project.
- CT can also show (for a certain declaration / proc) the usage-trees and used-by trees on basis of the dec-list, and gives with it the arguments and the comment-section.
- a source-code-view option (-c:s); search and show the full source-code of the proc /declaration.
- flexible semicolumn-separated search: declaration;module;project
- multiproject-feature; CT can combine dec-list of multiple projects and thus show trees for multiple projects (multiproject-feature).
- all functions are called by entering terminal-commands, allthough the generated view-files can be watched by themselves of course.


### Installation by building
Since the program (at this stage) is for Nim only, users = programmers are assumed to be able to build the executable themselves.
Developers can download a release, or clone the code 
(CodeTwig has no external components) and do the following:

Run the command:
nim c -d:release ctwig.nim
which will compile the code to an executable for you local OS.


### Using CodeTwig
[Go to the user-manual](mostfiles/manual_codetwig.txt)


### What's new in x.y?
[Open the whats-new-file](mostfiles/whatsnew_codetwig.txt)

Or look at the commits.
[Commits-list](https://github.com/some-avail/codetwig/commits/main)




#### Completed from future plans
- 1.62
  - removed bug caused by short project-names
  - added declaration-types method, iterator and converter



### Remaining future plans:
- add an options-file (for example for customizing the number of comment-lines)
- within search do enable line-start-appending to be able to uniquify overloaded names
- limit decs in the usage-tree to the imported modules (optionize).
- multiproject-level regeneration of individual project-files.


### Maybe ever?
- command-history


<a name="more-screenshots">More screenshots:</a>
Forthcoming.

