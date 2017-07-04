# [dot]init -- Work In Progress
.dotfiles manager tool (meant for personnal use).


## Requirements
*(was successfully tested with..)*
* Debian 9
* ca-certificates


## Install

Download and run the [prepare.sh](https://github.com/vverdot/dotinit/blob/master/scripts/prepare.sh) script.
```
./prepare.sh
```

**OR**

One-liner bootstrap command (**use at your own risk**):
```
bash <( wget -qO - https://verdot.fr/.init )

```

## Options

**[dot]init install directory** : set the env variable `DOTINIT_DIR` to change the installation directory (default is `.dotinit`)
