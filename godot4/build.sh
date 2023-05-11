#!/bin/bash

# Directories we need to know about.
base_dir=$(pwd)
wren_dir=/home/turncoat/godot/source/modules/godot_wren/vendor/wren

# Set some defaults
bits=64
cores=6
clean=""
exports="no"
platform="linuxbsd"
shared="no"
target="editor"
wren="no"
modules=""

usage='Usage: build [OPTIONS]... [ARGS]...
       Builds the godot editor and optionally exports custom build
       templates with cross-platform building support\n\n'

while getopts b:cC:ehp:st:wm flag
do
    case "${flag}" in
        b) bits=${OPTARG};;
        c) clean="-c";;
        C) cores=${OPTARG};;
        e) exports="yes";;
        h)
            printf '..%s..' "$usage"
            exit 0
        ;;
        m) modules="custom_modules=../modules4";;
        p) platform=${OPTARG};;
        s) shared="yes";;
        t) target=${OPTARG};;
        w) wren="yes";;
        *) return;;
    esac
done

case "$target" in
    template_debug|template_release|editor)
        # do nothing because we're gucci.
    ;;
    *)
        echo "Valid targets are release, release_debug and debug"
	exit 1
    ;;
esac

build_wren() {
    if [ "$wren" == "no" ]
    then
        return
    fi

    # we need to build only shared or static libraries for some reason
    # if we say to compile with static libraries, it likes to pick up
    # our third party libraries shared library before the static which
    # causes us to need to have the shared library to launch our
    # supposedly statically built executable.
    wren_shared="wren"

    if [ "$shared" == "yes" ]
    then
        wren_shared="wren_shared"
    fi

    # If we're building windows exports, we need to use mingw.
    if [ "$platform" == "windows" ]
    then
        cd $wren_dir/projects/make.mingw || return
    elif [ "$platform" == "x11" ]
    then
        cd $wren_dir/projects/make || return
    fi

    # Clean makes every times.  :D
    make clean
    if [ "$bits" -eq 32 ]
    then
        make config=release_32bit $wren_shared
        if [ "$wren_shared" == "wren_shared" ]
        then
            cp $wren_dir/lib32/libwren.so "$base_dir"/bin/
        fi
    else
        make config=release_64bit $wren_shared
        if [ "$wren_shared" == "wren_shared" ]
        then
            cp $wren_dir/lib/libwren.so "$base_dir"/bin/
        fi
    fi
    cd "$base_dir" || return
}

# Just checking if wren is already compiled, if it's not we'll need to do so.
# I really can't figure out what I'm doing here.  Well, I think originally
# I was going to just have this for me but now I'm thinking about cleaning
# this up and releasing it if people are interested.
if [ "$bits" -eq 64 ] && [ "$wren" == "yes" ]
then
    if [ "$shared" == "no" ]
    then
        if [ ! -f $wren_dir/lib/libwren.a ]
        then
            wren="yes"
        fi
    else
        if [ ! -f $wren_dir/lib/libwren.so ]
        then
            wren="yes"
        fi
    fi
elif [ "$bits" -eq 32 ] && [ "$wren" == "yes" ]
then
    if [ "$shared" == "no" ]
    then
        if [ ! -f $wren_dir/lib32/libwren.a ]
        then
            wren="yes"
        fi
    else
        if [ ! -f $wren_dir/lib32/libwren.so ]
        then
            wren="yes"
        fi
    fi
fi

# force building of Wren so we can know we have the library compiled for whatever we're targetting.
# We also note that we're not using shared libraries.  We want this for exported games so libraries
# get compiled into the executable instead of having to ship libraries with the game.
# shared is a custom variable used in our external modules.
if [ "$exports" == "yes" ]
then
    build_wren
    scons -j"$cores" platform="$platform" target=template_debug tools=no "$modules" modules_shared=no bits="$bits";
    scons -j"$cores" platform="$platform" target=template_release tools=no "$modules" modules_shared=no bits="$bits";
    exit 0
fi

if [ "$wren" == "yes" ]
then
    build_wren
fi

scons -j"$cores" platform="$platform" target="$target" "$modules" modules_shared="$shared" bits="$bits" "$clean"

