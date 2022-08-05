#!/bin/sh

#  Versioning.sh
#  Created by Matthew Watkins on 14/06/2022.

########## Add this file at the very top of your Xcode project
# Then:
# Edit Scheme... -> Build -> Pre-actions -> +
# Add script content below:
# "${WORKSPACE_PATH}"/../../Versioning.sh

# This will be the default version number for new projects
# Projects not using a three-part numbering scheme will be moved to one
VER_DEFAULT=0.1.0
EPOCH_TIME=`date +%s`
TMP_DIR=/tmp
EPOCH_FILE=$TMP_DIR/epoch.txt

### Shared functions

_setVersion() {
if [ $# -ne 1 ]; then
    echo "An argument is required to the setVersion function"; exit 1
fi

if [ $1 == "default" ]; then
    echo "Setting default/initial version value"
    echo ""
    _setVersion "$VER_DEFAULT"

elif [ $1 == "bump" ]; then
    echo "Bumping current version number"
    echo ""
    CURRENT=`echo $VERSION | awk -F "." {'print $3}'`
    TARGET="$(($CURRENT+1))"
    PREFIX=`echo $VERSION | cut -d. -f-2`
    _setVersion "$PREFIX.$TARGET"
else
    NEW_VERSION=$1
    echo "### Application Version ###"
    # Display/print build versioning
    echo "From: $VERSION"
    echo "To:   $NEW_VERSION"
    echo ""
    cp "$PROJECT_FILE" "$PROJECT_FILE".backup
    sed "s/MARKETING_VERSION = $VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" "$PROJECT_FILE" > /tmp/project.file
    mv /tmp/project.file "$PROJECT_FILE"
fi
}

### Pre-flight checks

# Check for presence of avgtool binary
AGVTOOL=`which agvtool`
if [ ! -x $AGVTOOL ]; then
    echo "Xcode command line tool not found: agvtool"; exit 1
fi

if [ -z ${WORKSPACE_PATH+x} ]; then
    echo "Script is NOT running in Xcode"
    echo ""

    PROJECT_PATH=`pwd`
    PROJECT_NAME=`echo ${PROJECT_PATH##*/}`
    WORKSPACE_PATH="$PROJECT_PATH/$PROJECT_NAME.xcodeproj/project.xcworkspace"
else
    echo "Script is running in Xcode"
    echo ""

    if [ -d "$WORKSPACE_PATH" ]; then
        # Set the current project root path
        PROJECT_PATH="${WORKSPACE_PATH}/../../"
        cd "${PROJECT_PATH}"
        PROJECT_PATH=`pwd`
        PROJECT_NAME=`echo ${PROJECT_PATH##*/}`
    else
        echo "Error: could not resolve workspace path"; exit 1
    fi
fi

# Old version; does not work where app directory != app name
#PROJECT_FILE="$PROJECT_PATH/$PROJECT_NAME.xcodeproj/project.pbxproj"
PROJECT_FILE="$PROJECT_PATH/$SCHEME_NAME.xcodeproj/project.pbxproj"

if [ ! -d "$PROJECT_PATH" ] || [ ! -d "$WORKSPACE_PATH" ]; then
    echo "One of the folder paths is invalid; check script operation"; exit 1
elif [ ! -f "$PROJECT_FILE" ]; then
    echo "The project file was not found; check script operation"
    echo "The path that failed was: ${PROJECT_FILE}"; exit 1
fi

if !(grep 'apple-generic' "$PROJECT_FILE" > /dev/null 2>&1)
then
    echo "Project versioning needs to be set to apple-generic"; exit 1
fi

echo "### Project Metadata ###"
echo "Project name:     ${PROJECT_NAME}"
echo "Project path:     ${PROJECT_PATH}"
echo "Project file:     ${PROJECT_FILE}"
echo "Workspace path:   ${WORKSPACE_PATH}"
echo ""

# Populate the date variable
DATE=`date +%Y-%m-%d`

# Exit the script when a command fails or if it tries to use an undeclared variable
set -o errexit
set -o nounset

# Temporarily enable script debugging output
#set -x

# Obtain the current application version
VERSION=$(agvtool what-marketing-version -terse1)

# If version number empty send warning, use alternate code path
if [ -z "$VERSION" ]; then
    # agvtool cannot enumerate versioning unless the option below is set
    # Build Settings -> Generate Info.plist File -> No
    echo "Warning: agvtool could not enumerate current application version string"
    echo ""

    # Example below of version stored in ${PROJECT_FILE}
    # MARKETING_VERSION = 0.1;

    # Alternate code path for recent Xcode versions
    VERSION=`grep MARKETING_VERSION "$PROJECT_FILE" | tail -n 1 | awk '{print $3}' | sed 's:;::'`
    if [ -z "$VERSION" ]; then
        echo "Unable to get version from project.pbxproj file"; exit 1
    else
        echo "Version retrieved from project.pbxproj file: $VERSION"
        echo ""
    fi
fi

if [ $# -eq 1 ] && [ $1 == "archive" ]; then
    echo "Script was triggered by Xcode archive generation"
    _setVersion bump
    exit 0
fi

if [ $VERSION == "1" ] || [ $VERSION == "1.0" ]
then
    _setVersion default
fi

# Get parameters from GIT repository
NUM_COMMITS=`git --git-dir="${PROJECT_PATH}/.git" --work-tree="${PROJECT_PATH}/" log | grep commit | wc -l`
LAST_COMMIT=`git --git-dir="${PROJECT_PATH}/.git" --work-tree="${PROJECT_PATH}/" log -n 1 | grep commit | awk '{print $2}'`

# Use only the last eight characters of last GIT commit
SHORT_COMMIT=`echo ${LAST_COMMIT} | tail -c 8`

OLD_BUILD=$(agvtool what-version -terse)
OLD_BUILD_NUMBER=`echo "$OLD_BUILD" | awk -F "." {'print $1'}`
# Set new value
NEW_BUILD_NUMBER="$(($OLD_BUILD_NUMBER+1))"
NEW_BUILD="${NEW_BUILD_NUMBER}.${SHORT_COMMIT}"

# Append git dirty flag, if necessary
if [[ `git status --porcelain` ]]; then
    NEW_BUILD="$NEW_BUILD.dirty"
else
    NEW_BUILD="$NEW_BUILD.clean"
fi

### Set new build version

# Performed conditionally, only if the last build was over sixty seconds ago
if [ -f $EPOCH_FILE ]; then
    LAST_RUN=`cat $EPOCH_FILE`
    ELAPSED=`expr $EPOCH_TIME - $LAST_RUN`
    echo "Invocation time since UNIX epoch: $EPOCH_TIME"
    echo "Time elapsed since last build attempt: $ELAPSED"
    echo ""
    if [ $ELAPSED -gt 60 ]; then
        echo $EPOCH_TIME > $EPOCH_FILE
        agvtool new-version -all ${NEW_BUILD} > /dev/null 2>&1
    fi
else
    echo $EPOCH_TIME > $EPOCH_FILE
    echo "Invocation time since UNIX epoch: $EPOCH_TIME"
    echo ""
    agvtool new-version -all ${NEW_BUILD} > /dev/null 2>&1
fi

# Display/print build versioning
echo "### Build Version ###"
echo "From: ${OLD_BUILD}"
echo "To:   ${NEW_BUILD}"
echo ""
