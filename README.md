## CodeTwig - A code viewer and analyser

![01](mostfiles/pictures/codetwig_declarations_tree.png)

[See below for more screenshots](#more-screenshots)

[Go to downloadable releases - forthcoming](https://github.com/some-avail/codetwig/releases "Downloads for CodeTwig")

[Go to the user-manual](mostfiles/manual_codetwig.txt)



#### Description CodeTwig

CodeTwig is terminal-program to view the outline of the source-code and to show procedures as usage-trees or used-by-trees. Allthough the tree-function is working quite well, the program is still young. See future-plans below.
Currently only meant for Nim.


#### Installation by building
Since the program (at this stage) is for Nim only, users = programmers are assumed to be able to build the executable themselves.
Developers can download a release, or clone the code 
(CodeTwig has no external components) and do the following:

Run the command:
nim c -d:release ctwig.nim
which will compile the code to an executable for you local OS.


#### Using CodeTwig
[Go to the user-manual](mostfiles/manual_codetwig.txt)


### What's new in x.y?
[Open the whats-new-file - forthcoming]()
Or look at the commits.
[Commits-list](https://github.com/some-avail/codetwig/commits/main)



#### Future plans:
- Both in the views and in the tree-function the following information will be added:
  - procedural arguments
  - initial comments
- better automatic source-file-selection
  - check multiple dir-levels
  - filter out backups, copies and older versions of source-files.
- add an options-file.



<a name="more-screenshots">More screenshots:</a>
Forthcoming.