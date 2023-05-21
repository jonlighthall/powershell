#!/bin/bash
# print source name at start
echo "${TAB}running $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! $BASH_SOURCE = $src_name ]; then
    echo "${TAB}     -> $src_name"
fi
# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# set source and target directories
source_dir=$(dirname $src_name)
target_dir=$HOME/bin

# check directories
echo -n "source directory ${source_dir}... "
if [ -d $source_dir ]; then
    echo "exists"
else
    echo "does not exist"
    return 1
fi

echo -n "target directory ${target_dir}... "
if [ -d $target_dir ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $target_dir
fi

bar 38 "------ Start Linking Repo Files-------"

# list of files to be linked
ext=.sh
for my_link in blank clicker shutdown_wsl
do
    target=${source_dir}/${my_link}${ext}
    sub_dir=$(dirname "$my_link")
    if [ ! $sub_dir = "." ]; then
	my_link=$(basename "$my_link")
    fi
    link=${target_dir}/${my_link}

    echo -n "source file $target... "
    if [ -e $target ]; then
	echo -n "exists and is "
	if [ -x $target ]; then
	    echo "executable"
	    echo -n "${TAB}link $link... "
	    # first, backup existing copy
	    if [ -L $link ] || [ -f $link ] || [ -d $link ]; then
		echo -n "exists and "
		if [[ $target -ef $link ]]; then
		    echo -e "${GOOD}already points to ${my_link}${NORMAL}"
		    echo -n "${TAB}"
		    ls -lhG --color=auto $link
		    echo "${TAB}skipping..."
		    continue
		else
		    echo -n "will be backed up..."
		    mv -v $link ${link}_$(date +'%Y-%m-%d-t%H%M')
		fi
	    else
		echo "does not exist"
	    fi
	    # then link
	    echo -en "${TAB}${GRH}";hline 72;
	    echo "${TAB}making link... "
	    ln -sv $target $link | sed "s/^/${TAB}/"
	    echo -ne "${TAB}";hline 72;echo -en "${NORMAL}"
        else
            echo -e "${BAD}not executable${NORMAL}"
        fi
    else
        echo -e "${BAD}does not exist${NORMAL}"
    fi
    echo
done
bar 38 "--------- Done Making Links ----------"
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"