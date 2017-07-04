#!/bin/bash

DOTINIT_HOME="$( cd "$( dirname "$( realpath "$0" )" )/.." && pwd )"
VERSION="1.0.0"

usage() {
echo "[dot]init $VERSION - $DOTINIT_HOME"
cat <<EOF
Usage: dotinit [options] command ...

Commands:
  scan <dotfiles|packages>
  	scan home directory dotfiles or installed packages

  install [package.lst]
  	install packages from list (or default.lst)

Options:
  --help	: display command usage
  --unattended	: non-interactive mode (will answer "yes" if asked)
  --dry-run 	: only simulate
EOF
}


install() {
	echo "install $1"
}


if [ $# -lt 1 ]; then
	echo "dotinit: invalid number of arguments"
	echo "Try 'dotinit --help' for more information."
	exit 1
fi

OPTS=$(getopt --shell bash --name dotinit --long unattended,dry-run,help --options f -- "$@")

eval set -- "$OPTS"

# Set Flags

F_FORCE=0
F_UNATTEND=0
F_DRY_RUN=0

# Extract options and argumrents
while true ; do
	case "$1" in
		--help) usage ; exit 0 ;;
		--) shift ; break ;;
		-f) F_FORCE=1 ; shift ;;
		--unattended) F_UNATTEND=1 ; shift ;;
		--dry-run) F_DRY_RUN=1 ; shift ;;
		*) echo "Invalid parameter: $1" ; exit 1 ;;
	esac
done

if [ $# -lt 1 ]; then
	echo "dotinit: missing command"
	echo "Try 'dotinit --help' for more information."
	exit 1
fi

CMD="$1"
shift

case "$CMD" in
	install) install "$@" ;;
	*) echo "Unknown command: $CMD" ; exit 1 ;;
esac

exit 0

