Run with the bash function below

.. code:: bash

    tw_mcc2() { 
        mcc -m $1 -R -singleCompThread -R -nodisplay -R -nojvm;
        mv -f "${1%.*}" "${1%.*}.mcc"
        rm -f mccExcludedFiles.log
        rm -f "run_${1%.*}.sh"
        rm -f readme.txt
        qsub-run -c "./${1%.*}.mcc" > "${1%.*}.sh"
    }