#!/bin/bash
SRCDIR=$PWD
TGTDIR=$HOME/bin

# check target directory
echo -n "target directory $TGTDIR... "
if [ -d $TGTDIR ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $TGTDIR
fi

# list files to be linked in bin
for prog in clicker
do
    echo -n "program $SRCDIR/$prog.sh... "
    if [ -e $SRCDIR/$prog.sh ]; then
	echo -n "exists and is "
	if [ -x $SRCDIR/$prog.sh ]; then
	    echo "executable"

	    echo -n "$TGTDIR/${prog}... "
	    if [ -e $TGTDIR/${prog} ] ; then
		echo "already exists"

		if [[ $SRCDIR/$prog.sh -ef $TGTDIR/$prog ]]; then

		    echo " already points to ${prog}..."
		    echo "skipping ..."
		    break
		else
		    echo " Backing up ${prog}..."
		    mv -v $TGTDIR/${prog} $TGTDIR/${prog}_$(date +'%Y-%m-%d-t%H%M')
		fi
	    else
		echo "does not exist"
	    fi
	    echo "making link..."
	    ln -svf $SRCDIR/$prog.sh $TGTDIR/$prog
	else
	    echo "not executable"
	fi
    else
	echo "does not exist"
    fi
done
