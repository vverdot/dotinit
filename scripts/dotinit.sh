#!/bin/bash
###########
##
#	[dot]init main script
#	 version: 0.12.0-alpha
#	 project: https://github.com/vverdot/dotinit
#    	 author:  vverdot
##
###########

#DOTINIT="$( cd "$( dirname "$( realpath "$0" )" )/.." && pwd )"

# TODO Store current profile in config
# switch between profiles manually

HOME_DIR="${DOTINIT:-"$HOME/.dotinit"}"
VERSION="0.10.1"


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

  uninstall [what] [profile]
  	[what] = 'dotfiles' or 'profile' or ''
	 'profile'  : entire remove links from provided profile (default: 'default')
	 'dotfiles' : remove links from provided files, restore files if applicable
	 ''	    : list available profiles
  	[profile]='default' if omitted

  update [profile] FILE [FILE]*
  	[profile] = the profile to update

  revert
  	uninstall all profiles and restore backups

Options:
  --help	: display command usage
  --assume-yes	: non-interactive mode (will answer "yes" if asked)
  --dry-run 	: only simulate
  --force	: will replace existing files (backups are created)
  --no-legend	: do not display legend
EOF
}


usage_error() {
	echo "dotinit: ${1:-'Unexpected Error'}"
	echo "Try 'dotinit --help' for more information."
	exit 1
}


## Backup functions

backupDotfile() {
	F_ORIG="$HOME/$1"
	BAK_HOME="$HOME_DIR/backup/H"
	if [ ! -f "$F_ORIG" ] ; then
		echo "Invalid file $F_ORIG for backup"
		return 1
	fi

	if [[ $DRY_RUN ]] ; then
		echo "$bold [would do]$normal cp $F_ORIG $BAK_HOME/$1"
	else
		cp "$F_ORIG" "$BAK_HOME/$1"
		if [ $? -eq 0 ] ; then
			echo "$bold [backup]$normal $1"
		else
			echo "Backup failed for $1"
			return 1
		fi
	fi

	return 0
}

uninstallDotfile() {
	FILENAME="$1"
	PROFILE="$2"

	# Is it a valid file to uninstall?
	if ! [ -e "$HOME/$FILENAME" -a -L "$HOME/$FILENAME" ] ; then
		#nothing to do (just notify for bad links)
		if [ -L "$HOME/$FILENAME" ] ; then
			echo "$bold [ignored]$normal $item"
		fi
		return 0
	fi

	# Test if it is handled by [dot]init
	FILE_ORIG="$(realpath $HOME/$FILENAME)"
	[[ "$FILE_ORIG" =~ ^"$HOME_DIR/dots/$PROFILE/H/" ]] || { echo "$bold [skipped]$normal $item" ; return 1 ; }

	if [[ $DRY_RUN ]] ; then
		echo "$bold [would do]$normal rm -f $HOME/$FILENAME"
	else
		rm -f "$HOME/$FILENAME"
		if ! [ "$?" -eq 0 ] ; then
			return 1
		fi
	fi

	restoreDotfile $FILENAME

	if ! [ $? -eq 0 ] ; then
		if ! [[ $DRY_RUN ]] ; then
			echo "$bold [removed]$normal $FILENAME "
	       	fi
	fi

	return 0
}

restoreDotfile() {
	FILENAME="$1"
	FILEBAK="$HOME_DIR/backup/H/$1"
	
	# Test if a backup exists
	test -f "$FILEBAK" ||  return 1 ;

	# Test if destination is empty
	if ! [ -e "$HOME/$FILENAME" ]; then
		
		if [[ $DRY_RUN ]] ; then
			echo "$bold [would do]$normal mv $FILEBAK $HOME/$FILENAME"
		else
			mv "$FILEBAK" "$HOME/$FILENAME"
			if ! [ $? -eq 0 ] ; then
			       return 1
		       	fi
			echo "$bold$green [restored]$normal $FILENAME"
		fi
	else
		echo "File $HOME/$FILENAME already exists."
		return 1
	fi

	return 0
}


revert() {
	:
}

uninstallDotfiles() {
	PROFILE=${1:-default}

	# Check if profile is valid
	if [ ! -d "$HOME_DIR/dots/$PROFILE" ]; then
		echo "Profile $PROFILE not found."
		return 1
	fi

	DOT_HOME="$HOME_DIR/dots/$PROFILE/H"
	# List potential dotfiles
	for dotitem in $(find $DOT_HOME -type f); do
		item=${dotitem#$DOT_HOME/}
		uninstallDotfile $item $PROFILE
	done

	return 0
}

uninstall() {
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
			"packages") echo "uninstall packages not yet implemented" ; return 0 ;;
			"dotfiles") shift ; uninstallDotfiles $@ ; return $? ;;
			"all") echo 'uninstall both not yet implemented' ; return 0 ;;
			*) usage_error ;;
		esac
	fi
}

## Install functions


installDotfiles() {

	PROFILE=${1:-default}

	# Check if profile is valid
	if [ ! -d "$HOME_DIR/dots/$PROFILE" ]; then
		echo "Profile $PROFILE not found."
		return 1
	fi

	DOT_HOME="$HOME_DIR/dots/$PROFILE/H"
	# List missing (installable) dotfiles
	for dotitem in $(find $DOT_HOME -type f); do
		item=${dotitem#$DOT_HOME/}

		if [ ! -e "$HOME/$item" -a ! -L "$HOME/$item" ] ; then
			DIRNAME=$(dirname "$item")
			
			if [ ! $DIRNAME = "." ] ; then
				if [[ $DRY_RUN ]] ; then
					echo "$bold [would do]$normal mkdir -p $HOME/$DIRNAME"
				else
					mkdir -p $HOME/$DIRNAME
				fi
			fi

			if [[ $DRY_RUN ]] ; then
				echo "$bold [would do]$normal ln -s $dotitem $HOME/$item"
			else
				ln -s $dotitem $HOME/$item
				if [ $? -eq 0 ] ; then
					echo "$bold$green [installed]$normal $item"
				else
					echo "$bold$red [failed]$normal ln -s $dotitem $HOME/$item"
					return 1
				fi
			fi
		else
			if [ ! -L "$HOME/$item" ] ; then
				# File exists already; need to force it
				if [[ $FORCE ]] ; then
					backupDotfile $item
					if [ ! $? -eq 0 ] ; then
						return 1
					else
						if [[ $DRY_RUN ]] ; then
							echo "$bold [would do]$normal ln -sf $dotitem $HOME/$item"
						else
							ln -sf $dotitem $HOME/$item
							if [ $? -eq 0 ] ; then
								echo "$bold$green [installed]$normal $item"
							else
								echo "$bold$red [failed]$normal ln -sf $dotitem $HOME/$item"
								return 1
							fi
						fi
					fi
				else
					echo "$bold [skipped]$normal $item"
				fi
			else
				# Link exists
				if ! [ "$(realpath $HOME/$item)" = "$dotitem" ] ; then
					echo "$bold [ignored]$normal $item"
				fi
			fi
		fi
	done

	return 0
}

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

	#TODO shouldn't list existing profiles
	# Display commands [what] or use only dotfiles
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
			"dotfiles") shift ; installDotfiles $@ ; return $? ;;
			"all") echo 'install both not yet implemented' ; return $? ;;
			*) usage_error ;;
		esac
	fi

}

## Profile functions

addDotfile() {
	FILENAME="$1"
	FILE="${1#$HOME/}"
	FILEH="$HOME_DIR/dots/$2/H/$FILE"

	if [ -e "$FILEH" ] ; then
		#
		if [ -f "$FILEH" ] ; then
			if [[ $FORCE ]] ; then
				if [[ $DRY_RUN ]] ; then
					echo "$bold [would do]$normal cp -f $FILENAME $FILEH"
				else
					cp -f "$FILENAME" "$FILEH"
					if ! [ $? -eq 0 ] ; then
						return 1
					fi
#					TODO:
					echo "$bold$green [added]$normal $FILE"
				fi
			else
				echo "$bold [skipped]$normal $FILE"
			fi
		else
			echo "$bold [ignored]$normal $FILE"
		fi
	else
		if [[ $DRY_RUN ]] ; then
			echo "$bold [would do]$normal cp $FILENAME $FILEH"
		else
			cp "$FILENAME" "$FILEH"
			echo "$bold$green [added]$normal $FILE"
		fi
	fi

	return 0	
}


update() {
	if [ $# -lt 2 ] ; then
		usage_error "not enough arguments"
	fi
	
	PROFILE=${1:-default}
	if ! [ -d "$HOME_DIR/dots/$1" ] ; then
		echo "$1 is not a valid profile."
		return 1
	fi
	shift

	echo "Updating profile $bold$PROFILE$normal.." 
	for dotitem in $@ ; do

		if ! [ -r "$dotitem" ] ; then
			echo "$bold [ignored]$normal $dotitem -- cannot read"
		       	continue	
		fi

		#TODO use exclusions (do we?)
		item="$(realpath $dotitem)"
		hitem="$(realpath -s $dotitem)"

		#Test if dotfile path is well in $HOME (and not in $HOME_DIR)
		[[ "$hitem" =~ ^"$HOME/" ]] || { echo "$bold [ignored]$normal $hitem -- not in $HOME" ; continue ; }
		[[ "$hitem" =~ ^"$HOME_DIR/" ]] && { echo "$bold [ignored]$normal $hitem -- invalid dotfile location" ; continue ; }

		#Element valid iff regular file (or folder soon)
		#TODO allow adding folders
		if [ -f "$item" -a -r "$item" ] ; then
			# Test if within HOME and not in HOME_DIR
			[[ "$item" =~ ^"$HOME/" ]] || { echo "$bold [ignored]$normal $item -- not in $HOME" ; continue ; }
			[[ "$item" =~ ^"$HOME_DIR/dots/$PROFILE/" ]] && { echo "$bold [ignored]$normal $item -- already in profile" ; continue ; }
			if [[ "$item" =~ ^"$HOME_DIR/" ]] ; then
				if ! [[ "$item" =~ ^"$HOME_DIR/dots/".+"/H/" ]] ; then
					echo "$bold [ignored]$normal -- invalid dotfile location: $item"
					continue
				fi
			fi

			#Copy file and store in profile
			relative_hitem=${hitem#$HOME/}
			DIRNAME="$(dirname $relative_hitem)"

			#Test if file doesn't already exist
			if [ -e "$HOME_DIR/dots/$PROFILE/H/$relative_hitem" ] ; then
				if ! [[ $FORCE ]] ; then
					echo "$bold$yellow [skipped]$normal $hitem -- file already exists"
					continue
				fi
			fi
			
			#Create directory if required
			if [ $DIRNAME != "." ] ; then
				if [[ $DRY_RUN ]] ; then
					echo "$bold [would do]$normal mkdir -p $HOME_DIR/dots/$PROFILE/H/$DIRNAME"
				else
					mkdir -p "$HOME_DIR/dots/$PROFILE/H/$DIRNAME"
					if [ $? != 0 ] ; then
						echo "$bold$red [failed]$normal $hitem -- couldn't create directory in profile"
						continue
					fi
				fi
			fi

			#Copy file to profile
			if [[ $DRY_RUN ]] ; then
				echo "$bold [would do]$normal cp $item $HOME_DIR/dots/$PROFILE/H/$relative_hitem"
			else
				cp "$item" "$HOME_DIR/dots/$PROFILE/H/$relative_hitem"
				if [ $? != 0 ] ; then
					echo "$bold$red [failed]$normal $hitem -- couldn't copy to profile"
					continue
				fi
				echo "$bold$green [added]$normal $hitem"
			fi
		else
			echo "$bold [ignored]$normal $item -- invalid dotfile"
		fi
	done

	return 0
}

## Scan functions

showScan() {
	unset PROFILE
	if [ -d "$HOME_DIR/dots/$2" ] ; then
		PROFILE=$2
	fi
	
	if [ $F_LEGEND -eq 1 ] ; then
		echo "Comparing $bold$HOME$normal dotfiles with [dot]init profile $bold${PROFILE:-<new>}$normal:"
		echo "[x] installed, [+] new, [-] missing, [?] duplicate, [!] conflicted"
	fi

	for dotitem in $1; do
		item=${dotitem#$HOME/}

		if [ ! -r "$dotitem" ] ; then
			echo "${bold}${red} [!] $item ${normal} -- cannot read"
			continue
		fi

		if [ -L $dotitem ] ; then

			# if no profile, then all links are conflicts
			if ! [[ $PROFILE ]] ; then
				echo "${bold}${red} [!] $item ${normal}"
				continue
			fi

			if [ "$(realpath $dotitem)" = "$HOME_DIR/dots/$2/H/$item" ] ; then
				echo "${bold} [x] $item ${normal}"
			else
				# TODO display conflict reason
				echo "${bold}${red} [!] $item ${normal}"
			fi
			continue
		fi

		# if not a link, it is (almost) necessarily a regular file

		# if no profile to compare, all files are new
		if ! [[ $PROFILE ]] ; then
			echo "${bold}${green} [+] $item ${normal}"
			continue
		fi

		if [ ! -f $HOME_DIR/dots/$2/H/$item ] ; then
			echo "${bold}${green} [+] $item ${normal}"
		else
			echo "${bold}${yellow} [?] $item ${normal}"
		fi
	done

	# cannot be missing files if no valid profile
	if [[ $PROFILE ]] ; then
		# List missing (installable) dotfiles
		for dotitem in $(find $HOME_DIR/dots/$2/H -type f | sort); do
			item=${dotitem#$HOME_DIR/dots/$2/H/}
			if [ ! -e "$HOME/$item" -a ! -L "$HOME/$item" ] ; then
				echo "$bold$cyan [-] $item $normal"
			#TODO handle other cases
			# LIST installed not in $HOME
			fi
		done
	fi

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

OPTS=$(getopt --shell bash --name dotinit --long assume-yes,dry-run,help,no-legend,force --options f -- "$@")

eval set -- "$OPTS"

# Set Flags

FORCE=''
UNATTEND=''
DRY_RUN=''
F_LEGEND=1

# Extract options and argumrents
while true ; do
	case "$1" in
		--help) usage ; exit 0 ;;
		--) shift ; break ;;
		-f|--force) FORCE=1 ; shift ;;
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
	uninstall) uninstall "$@" ;;
	scan) scan "$@" ;;
	update) update "$@" ;;
	revert) revert "$@" ;;
	*) usage_error ;;
esac

if [ $? -ne 0 ]; then
	echo "[dot]init $CMD failed."
	exit 1
fi

exit 0

## END SCRIPT
