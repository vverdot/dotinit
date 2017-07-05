#!/bin/bash

#DOTINIT="$( cd "$( dirname "$( realpath "$0" )" )/.." && pwd )"

HOME_DIR="${DOTINIT:-"$HOME/.dotinit"}"
VERSION="0.9.5"


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

usage() {
echo "[dot]init $VERSION - $HOME_DIR"
cat <<EOF
Usage: dotinit [options] command ...

Commands:
  scan [what] 
  	[what] = 'packages' or 'dotfiles' or 'all' or ''
	 'packages' : scan manually installed packages
	 'dotfiles' : scan home dotfiles
	 'all' | '' : scan both

  install [what] [profile]
  	[what] = 'packages' or 'dotfiles' or 'all' or ''
  	 'packages' : install .deb listed in ./dots/[profile]/packages.lst
	 'dotfiles' : symlink dotfiles stored in ./dots/[profile]/*
	 'all'	    : install packages AND dotfiles
	 ''	    : list available profiles
  	[profile]='default' if omitted

Options:
  --help	: display command usage
  --assume-yes	: non-interactive mode (will answer "yes" if asked)
  --dry-run 	: only simulate
EOF
}


usage_error() {
	echo "dotinit: ${1:-'Unexpected Error'}"
	echo "Try 'dotinit --help' for more information."
	exit 1
}


## Install functions

installPackages() {
	if [ $# -eq 1 ]; then
		if [ -f "$1" ]; then
			sudo apt install $DRY_RUN $UNATTEND $(xargs <$1)
			return $?
		else
			usage_error "file $1 not found"
		fi
	else
		usage_error "invalid number of arguments"
	fi
	return 0
}

install() {

	# Display existing profiles
	if [ $# -eq 0 ]; then
		echo "[dot]init profiles found:"
	
		profiles=$HOME_DIR/dots/*	

		for profile in $profiles ; do
			if [ -d "$profile" ]; then
				desc="$(head -2 < $profile/README.md | tail -1)" 
				echo "$bold  $( basename $profile ):${normal} $desc"
			fi
		done
		return 0
	fi

	# Single command
	if [ $# -ge 1 ]; then
		case "$1" in
			"packages") installPackages "$HOME_DIR/dots/${2:-default}/packages.lst" ; return $? ;;
			"dotfiles") echo 'install dotfiles not yet implemented' ; return $? ;;
			"all") echo 'install both not yet implemented' ; return $? ;;
			*) usage_error ;;
		esac
	fi

}


## Scan functions

showScan() {
	for dotitem in $1; do
		item=${dotitem#$HOME/}
		
		if [ -L $dotitem ] ; then
			if [ "$(realpath $dotitem)" = "$HOME_DIR/dots/$2/H/$item" ] ; then
				echo "${bold} [x] $item ${normal}"
			else
				echo "${bold}${red} [!] $item ${normal}"
			fi
			continue
		fi

		echo "${bold}${green} [+] $item ${normal}"
	done


	# List missing (installable) dotfiles
	for dotitem in $(find $HOME_DIR/dots/$2/H -type f | sort); do
		item=${dotitem#$HOME_DIR/dots/$2/H/}
		echo "$bold$cyan [-] $item $normal"
	done

	return 0
}


scan() {

	# Find files and links in $HOME starting with a dot and not ignored
	
	SCAN_CMD="find $HOME -maxdepth 1 \( -type l -o -type f \)  | egrep '^.*' " 
	EXCLUSIONS=''
	while read -r excl; do
		EXCLUSIONS="$EXCLUSIONS | egrep -v \"^${HOME}/${excl}$\""
    	done < "${HOME_DIR}/dotignore"
 
	FOUND=$(eval "$SCAN_CMD$EXCLUSIONS | sort")
	
	# Find
	


	#Show result	
	showScan "$FOUND" "${1:-default}"
	
	return 0
}

## BEGIN SCRIPT

setColors

if [ $# -lt 1 ]; then
	usage_error
fi

OPTS=$(getopt --shell bash --name dotinit --long assume-yes,dry-run,help,no-legend --options f -- "$@")

eval set -- "$OPTS"

# Set Flags

F_FORCE=0
UNATTEND=''
DRY_RUN=''
F_LEGEND=1

# Extract options and argumrents
while true ; do
	case "$1" in
		--help) usage ; exit 0 ;;
		--) shift ; break ;;
		-f) F_FORCE=1 ; shift ;;
		--no-legend) F_LEGEND=0 ; shift ;;
		--assume-yes) UNATTEND='--assume-yes' ; shift ;;
		--dry-run) DRY_RUN='--dry-run' ; shift ;;
		*) usage_error ;;
	esac
done

if [ $# -lt 1 ]; then
	usage_error
fi

CMD="$1"
shift

case "$CMD" in
	install) install "$@" ;;
	scan) scan "$@" ;;
	*) usage_error ;;
esac

if [ $? -ne 0 ]; then
	echo "[dot]init $CMD failed."
	exit 1
fi

exit 0

## END SCRIPT
