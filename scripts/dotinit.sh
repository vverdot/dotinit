#!/bin/bash

#DOTINIT="$( cd "$( dirname "$( realpath "$0" )" )/.." && pwd )"

HOME_DIR="${DOTINIT:-"$HOME/.dotinit"}"
VERSION="1.0.0"


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
  scan <dotfiles|packages>
  	scan home directory dotfiles or installed packages

  install [what] [profile]
  	[what] = 'packages' or 'dotfiles' or 'all' or ''
  	 'packages' : install .deb listed in ./dots/[profile]/packages.lst
	 'dotfiles' : symlink dotfiles stored in ./dots/[profile]/*
	 'all'	    : install packages AND dotfiles
	 ''	    : list available profiles
  	[profile]='default' if omitted

Options:
  --help	: display command usage
  --unattended	: non-interactive mode (will answer "yes" if asked)
  --dry-run 	: only simulate
EOF
}


usage_error() {
	echo "dotinit: ${1:-'Unexpected Error'}"
	echo "Try 'dotinit --help' for more information."
	exit 1

}

installPackages() {
	if [ $# -eq 1 ]; then
		if [ -f "$1" ]; then
			sudo apt install $DRY_RUN $UNATTEND $(xargs <$1)
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
			"dotfiles") echo 'install dotfiles' ; return $? ;;
			"all") echo 'install both' ; return $? ;;
			*) usage_error ;;
		esac
	fi
}


setColors

if [ $# -lt 1 ]; then
	usage_error
fi

OPTS=$(getopt --shell bash --name dotinit --long unattended,dry-run,help --options f -- "$@")

eval set -- "$OPTS"

# Set Flags

F_FORCE=0
UNATTEND=''
DRY_RUN=''

# Extract options and argumrents
while true ; do
	case "$1" in
		--help) usage ; exit 0 ;;
		--) shift ; break ;;
		-f) F_FORCE=1 ; shift ;;
		--unattended) UNATTEND='--assume-yes' ; shift ;;
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
	*) usage_error ;;
esac

exit 0

