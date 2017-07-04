#!/bin/bash

usage() {
cat <<EOF
Usage: dotinit [options] command ...

Commands:
    scan <dotfiles|packages>
    	scan home directory dotfiles or installed packages

    install [package.lst]
    install packages from list (packages.lst by default)

Options:
    --help 	: display command usage
    --dry-run 	: only simulate

EOF
}

if [ $# -lt 1 ]; then
	echo "dotinit:" invalid number of arguments
	echo "Try 'dotinit --help' for more information."
	exit 1
fi

usage
