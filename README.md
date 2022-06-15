# XCode Automatic Versioning Script

https://github.com/ModeSevenIndustrialSolutions/XCode-Versioning

Many of the scripts hosted on GitHub do not work with more recent Xcode releases. This script uses Apple's Xcode CLI tool, agvtool, to automatically bump build numbers and release versions. It uses a three part numbering scheme.

## Instructions

* Download the Versioning.sh script
* Add the shell script to the top level of your repository
* Navigate to the script in Terminal.app and mark it execuatable

e.g.	chmod a+x Versioning.sh

* Navigate to your projects build setting, find the versioning section
* Change the application versioning mode of your project to Apple Generic
* Add a new pre-build run script action

e.g.	Edit Scheme... -> Build -> Pre-actions -> + -> New Run Script Action

* For the script content, just add the path to the shell script (in your project folder)

"${WORKSPACE_PATH}"/../../Versioning.sh

e.g.	Edit Scheme... -> Archive -> Pre-actions -> + -> New Run Script Action

* For the script content, add the path to the script an add an argument "archive"

"${WORKSPACE_PATH}"/../../Versioning.sh archive

The first time the script runs, if the project version is set to "1.0" or "1" it will renumber your project to a three part versioning scheme

e.g.	0.1.0

Every time an archive is performed, the final number will be bumped

e.g.	0.1.0 -> 0.1.1

Every time a build is performed, the version will be created as follows:

12.4ba15baa.0

...where the first number is the number of builds, the second string is the last eight digits of the GIT commit, and the last number reflects whether the GIT repository is dirty, i.e. whether any code has not yet been commited. A zero represents all outstanding changes have been commited, and where the digit one represents a dirty repo with commits that have not been sent upstream.
