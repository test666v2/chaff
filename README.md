chaff.sh

Purpose: Add additional pseudo-randomness to /dev/random from 5 sources : date, iostat, temperature (please verify that in the script), ping and ps

Please install sensors package or set variable GET_ENTROPY_FROM_TEMPERATURE to false

The terms "random", "randomized" and "randomness" are here loosely used and do not mean "true randomness"

It would be better to have a reliable hardware RNG or install haveged and be less happy, or both, or to be a tin-foil hat moron and run chaff.sh alongside haveged

In a terminal window: 

>user@computer:~$ **/your/path/here/chmod.sh +x /your/path/here/chaff.sh** to make the script executable

>user@computer:~$ **/your/path/here/chaff.sh** without arguments for a normal run

>user@computer:~$ **/your/path/here/chaff.sh --test** for building file _/dev/shm/.random.hex_ that can be tested against random number analysers (ent, rngtest, dieharder or any other tool)

>user@computer:~$ **/your/path/here/chaff.sh whatever** will produce a help message

run from cron as a local user: edit cron in a terminal window with "crontab -e" and add "@reboot /your/path/here/chaff.sh", save and exit and reboot

Adapt as needed (perhaps modifying the path where chaff.sh stores data, **/dev/shm/**, to **/tmp/** in the script and in the one-liner below)

EARLY ALPHA - YOU HAVE BEEN WARNED

PS: one-liner ugly hacks to check the "randomness" of chaff.sh for 5 runs. Test mostly fails with rngtest because of the small sample produced some of the times. Can be very slow with dieharder.

>user@computer:~$ **echo "chaff.sh output tested with ent (5 runs)" > /dev/shm/chaff_ent.txt; for (( i  = 1; i <= 5; i++ )) do printf "\n\n=====\n\n" >>/dev/shm/chaff_ent.txt; chaff.sh --test;ent /dev/shm/.random.hex >> /dev/shm/chaff_ent.txt 2>&1;done**

>user@computer:~$ **echo "chaff.sh output tested with rngtest (5 runs)" > /dev/shm/chaff_rngtest.txt; for (( i  = 1; i <= 5; i++ )) do printf "\n\n=====\n\n" >>/dev/shm/chaff_rngtest.txt; chaff.sh --test;rngtest < /dev/shm/.random.hex >> /dev/shm/chaff_rngtest.txt 2>&1;done**

>user@computer:~$ **echo "chaff.sh output tested with dieharder (5 runs)" > /dev/shm/chaff_dieharder.txt; for (( i  = 1; i <= 5; i++ )) do printf "\n\n=====\n\n" >>/dev/shm/chaff_dieharder.txt; chaff.sh --test;dieharder -a < /dev/shm/.random.hex >> /dev/shm/chaff_dieharder.txt 2>&1;done**
