#!/bin/bash

HELP_STRING="-v - Run Godot with the --verbose option."
verbose=""

while getopts hv flag
do
        case "${flag}" in
		h) help=
			echo $HELP_STRING
			exit
		;;
                v) verbose=--verbose;;
        esac
done

export LD_LIBRARY_PATH="$PWD/bin/"
./bin/godot.linuxbsd.editor.x86_64 $verbose

