#!/bin/bash
###########
##
#	[dot]init prepare script
#	 version: 0.9.0
#	 project: https://github.com/vverdot/dotinit
#    	 author:  vverdot
##
###########


## VARS

DOT_DIR="${DOT_DIR:-.dotinit}"
GIT_REPO="https://github.com/vverdot/dotinit.git"
SCRIPT_NAME="[dot]init prepare"
INSTALL_DIR="${HOME}/${DOT_DIR}"
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

info() {
	echo "${bold}# ! $1 ${normal}"
}

act() {
	ACTION="$1"
	echo
	echo "${bold}=> ${1} .. ${normal}"
}

cleanup() {
	:
}

failExit() {
	cleanup
	echo
	msg "Fatal Error. Aborting ${SCRIPT_NAME}."
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

##
## BEGIN SCRIPT
##

setColors

msg "Starting ${SCRIPT_NAME}"

act "Create directory ${INSTALL_DIR}"
mkdir "$INSTALL_DIR"
check

act "Install git"
sudo apt update
sudo apt --assume-yes install git
check

act "Clone git repository"
cd "$INSTALL_DIR"
git clone "$GIT_REPO" "$INSTALL_DIR"
check

act "Add dotinit to path"
sudo ln -sf "${INSTALL_DIR}/scripts/dotinit.sh" "/usr/local/bin/dotinit"
check

echo
msg "[dot]init succesfully installed!"

act "Execute dotinit --help"
dotinit
check

cleanup
echo
msg "${SCRIPT_NAME} over! Bye."
exit 0

## END SCRIPT
