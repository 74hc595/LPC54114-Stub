#!/bin/sh
#
# Starts the J-Link GDB server in the background,
# then starts gdb in the foreground.
#
# Usage:
#  ./jlink-gdb.sh "JLinkGDBServer-command-line" "gdb-command-line"

eval "$1 >/dev/null &"
eval "$2"