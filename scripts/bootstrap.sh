#!/bin/bash
###########
##
#	[dot]init bootstrap script
#	 version: 1.0.0
#	 project: https://github.com/vverdot/dotinit
#        author:  vverdot
##
###########

## VARS

PREP_SCRIPT_URL="https://raw.githubusercontent.com/vverdot/dotinit/master/scripts/prepare.sh"
TMP_DIR="/tmp/dotinit"
ACTION=""

## Utility functions

setColors() {
	ncolors=$(tput colors)

	if [ $ncolors -ge 8 ]; then
		bold="$(tput bold)"
		underline="$(tput smul)"
		standout="$(tput smso)"
		normal="$(tput sgr0)"
		black="$(tput setaf 0)"
		red="$(tput setaf 1)"
		green="$(tput setaf 2)"
		yellow="$(tput setaf 3)"
		blue="$(tput setaf 4)"
		magenta="$(tput setaf 5)"
		cyan="$(tput setaf 6)"
		white="$(tput setaf 7)"
	fi
}

msg() {
	echo "${bold}##  $1 ${normal}"
}

act() {
	ACTION="$1"
	echo
	echo "${bold}=> ${1} .. ${normal}"
}

cleanup() {
	if [ -d "$TMP_DIR" ]; then
		rm -r "$TMP_DIR"
	fi
}

failExit() {
	cleanup
	echo
	msg "Fatal Error. Aborting."
	msg
	exit $1
}

check() {
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		echo "${bold}#  ${ACTION} ${green}[OK]${normal}"
	else
		echo "${bold}#  ${ACTION} ${red}[!!] ERRCODE ${RESULT}${normal}"
		failExit $RESULT
	fi
}

## BEGIN SCRIPT

setColors

msg "Starting [dot]init"

act "Create temp dir ${TMP_DIR}"
mkdir -p "$TMP_DIR"
check

act "Download prepare.sh script from Github"
wget --no-cache -O "$TMP_DIR"/prepare.sh "$PREP_SCRIPT_URL"
check

act "Run > bash ${TMP_DIR}/prepare.sh"
bash "$TMP_DIR"/prepare.sh
check

cleanup
echo
msg "[dot]init over! Bye."
exit 0

## END SCRIPT
