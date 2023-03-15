#!/bin/bash
mkdir -pv ~/bin
# list files to be linked in bin
for prog in clicker
do
    if [ ! -f $HOME/bin/$prog ]; then
	if [ -f $PWD/$prog.sh ]; then
	    ln -svf $PWD/$prog.sh $HOME/bin/$prog
	fi
    fi
done
