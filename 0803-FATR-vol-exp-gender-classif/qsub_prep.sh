#!/usr/bin/env bash

# area2=( zero one two three four )
# for mfile in "${area2[@]}"; do
#     echo "run this ${mfile}"
# done

tw_mcc() { 
    mcc -m $1 -R -singleCompThread -R -nodisplay -R -nojvm
}


# http://superuser.com/questions/31464/looping-through-ls-results-in-bash-shell-script
# http://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
# run all files beginning with "zscore"
for mfile in nozscore*\.m; do
    echo "==========================="
    echo "tw_mcc ${mfile}"
    tw_mcc "${mfile}"
    echo "qsub-run -c ./${mfile%.*} > ${mfile%.*}.sh"
    qsub-run -c "./${mfile%.*}" > "${mfile%.*}.sh"
done