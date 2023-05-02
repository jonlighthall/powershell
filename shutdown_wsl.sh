# print script name at start
echo $BASH_SOURCE
src_name=$(readlink -f $BASH_SOURCE)
echo "$src_name"
src_dir=$(dirname $src_name)

cd $src_dir
powershell.exe -File ./shutdown_wsl.ps1

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
