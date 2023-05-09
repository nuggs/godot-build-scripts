#!/bin/bash

HELP_STRING="-v - Run Godot with the --verbose option."
verbose=""
debug=""

while getopts dhv flag
do
        case "${flag}" in
                d) debug=--debug;;
		h) help=
			echo $HELP_STRING
			exit
		;;
                v) verbose=--verbose;;
        esac
done

export LD_LIBRARY_PATH="$PWD/bin/"
./bin/godot.x11.opt.tools.64 $verbose $debug

