
| Prep code repos for submitting to SGE
| (Script prototyping will take place in the corresponding project repos)
|

`[Parent Directory] <./>`_

.. contents:: **Table of Contents**
    :depth: 2

.. sectnum::    
    :start: 1    

####################
Gender classification using FA/TR volume (Aug3, 2015)
####################


####################
qsub helper
####################

********************
A 3 step receipe for matlab
********************


.. code:: bash

  tw_mcc myprog.m
  qsub-run -c ./myprog > myprog.sh  # <- don't forget to include "./"
  qsub myprog.sh

********************
``memrec`` (to evaluate appropriate ``h_vmem`` value
********************
.. code:: bash

  memrec -d 5 ./myprog & # "-d 5" makes recording every 5 sec

- Run above to make recordings every 5 sec, and output memory usage to ``memprofile.txt``
- ``memprofile.txt`` has 3 columns:

  (\1) **SecondsRunning** (2) **ProcessMemory** (3) **ChildMemory**
- Set ``h_vmem`` at 10~\15% above (2)+(3) above  


********************
``qstat``
********************
.. code:: bash

  qstat -r
  qstat -r | egrep -i "full jobname"
  qstat -j job-ID | grep usage
  qstat -u '*' # <- see all users

  # delete jobs
  qdel JOBID

********************
``/usr/bin/time`` to see multithreaded or not
********************
.. code:: bash

  /usr/bin/time -pv myprog

Or just simply run the program, and use ``top`` to evaluate cpu usage  
    