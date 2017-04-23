#!/bin/bash
# shellcheck disable=SC2059
###################################################
# info for shellcheck error SC2059
# this refers to shellcheck beeing too restrictive with msg "Don't use variables in the printf format string. (..)"; ignoring this is not an issue
###################################################
 chaff.sh

# Purpose: Add additional pseudo-randomness to /dev/random from 4 sources : date, iostat, temperature (please verify ahead in the script) and ping

# Please install bc, sensors and systat packages

# The terms "random", "randomized" and "randomness" are here loosely used and do not mean "true randomness"

# It would be better to have a reliable hardware RNG or install haveged and be less happy, or both, or to be a tin-foil hat moron and run chaff.sh alongside haveged

# In a terminal window: "chmod +x /your/path/here/chaff.sh" to make the script executable

# run from cron: edit, as root, cron (as a local user) in a terminal window with "crontab -e" and add "@reboot /your/path/here/chaff.sh", save and exit and reboot

# this script was tested in DEBIAN TESTING; this script is probably OK for JESSIE (stable) and SID (unstable); probably also OK for UBUNTU and derivatives

# EARLY ALPHA - YOU HAVE BEEN WARNED

###################################################

# DISCLAIMER

# Use this script at your own risk
# You, as a user, have no right to support even if implied
# Carefully read the script and then interpret, modify, correct, fork, disdain, whatever

###################################################

#Copyright (c) <2017> <test666v2>
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

###################################################

# Starting values for some variables

ALPHA_STRING_SAVE_FILE=/dev/shm/.ALPHA_STRING_SAVE_FILE
CPU_DURESS_MAX=18 # 21 and more is way over the top # used to "disturb" possible predictability in temperature readings
CPU_DURESS_MIN=11 # 10 or less will probably be irrelevant # used to "disturb" possible predictability in temperature readings
DELAY_MAX=20 # in seconds # MAX interval between script looping
DELAY_MIN=5 # in seconds # MIN interval between script looping
ENTROPY_ROUNDS_MAX=10 # number of loops for sequential checksums from date (time), iostat, sensors (temperature) and ping # randomized order of execution
ENTROPY_ROUNDS_MIN=2 # 0 is poinless, but may introduce some "randomness"
GET_ENTROPY_FROM_DATE=true
GET_ENTROPY_FROM_IOSTAT=true
GET_ENTROPY_FROM_PING=true
GET_ENTROPY_FROM_TEMPERATURE=true # controversial; may lead to CPU instability because of random "spikiness" caused by bc # set to "false" to avoid this
IP_TO_PING=192.168.1.254 # 0 is 127.0.0.1 # any other IP will introduce possible unwanted delays, but will probably increase "randomness" # do not ping public IPs
NUMBER_OF_CORES=$(( $(grep -m 1 -i cores < /proc/cpuinfo | awk '{print $4}') -1 )) # for 4 cores the NUMBER_OF_CORES will be 3 # needed to create temperature increase while spiking CPUs
NUMBER_OF_PINGS=4
PING_INTERVAL=0.2 # 0.2 for interval between pings, have to be root for lower value
RANDOM_CHARS_FILE="/dev/shm/.random.hex" # or whatever you want, perhaps /tmp/.random.hex ?

########################################################

entropy_from_date ()
{
   [ $GET_ENTROPY_FROM_DATE ] || return
#   ALPHA_STRING+=$(date +%s%N | shasum -a 512 | awk '{print $1}') # get only shasum from column 1
   ALPHA_STRING=$(date +%s%N | shasum -a 512 | awk '{print $1}') # get only shasum from column 1
   printf "$ALPHA_STRING" >> $ALPHA_STRING_SAVE_FILE
}

########################################################

entropy_from_iostat ()
{
   [ $GET_ENTROPY_FROM_IOSTAT ] || return
#   ALPHA_STRING+=$(iostat | shasum -a 512 | awk '{print $1}') # get only shasum from column 1
   ALPHA_STRING=$(iostat | shasum -a 512 | awk '{print $1}') # get only shasum from column 1
   printf "$ALPHA_STRING" >> $ALPHA_STRING_SAVE_FILE
}

########################################################

entropy_from_temperature () ### probably way over the top
{
   [ $GET_ENTROPY_FROM_TEMPERATURE ] || return
   for (( CORE = 0; CORE <= NUMBER_OF_CORES; CORE++ )) # launch bc up to $NUMBER_OF_CORES + 1 threads, so for 4 cores we get 4 "simultaneous" threads
      do
         CPU_DURESS=$(( ( RANDOM % (( CPU_DURESS_MAX - CPU_DURESS_MIN + 1 )) )  + CPU_DURESS_MIN ))
         eval "taskset -c $CORE echo 2^2^$CPU_DURESS | bc > /dev/null &"
      done
# wait for bc to finish in all threads
      BC_IN_MEM=true
      while $BC_IN_MEM
         do
            TEST=$(pgrep -a bc | awk '{print $2}')
            [ "$TEST" == "bc" ] || BC_IN_MEM=false
            sleep 0.2
         done
   ALPHA_STRING=$(sensors -u | shasum -a 512 | awk '{print $1}') # poll temperatures from sensors, get only shasum from column 1
   printf "$ALPHA_STRING" >> $ALPHA_STRING_SAVE_FILE
}

########################################################

entropy_from_ping ()
{
   [ $GET_ENTROPY_FROM_PING ] || return
   ALPHA_STRING=$(ping -i $PING_INTERVAL -c $NUMBER_OF_PINGS $IP_TO_PING | shasum -a 512 | awk '{print $1}') # get only shasum from column 1
   printf "$ALPHA_STRING" >> $ALPHA_STRING_SAVE_FILE
}

########################################################

exit_with_help_message ()
{
   printf "\nchaff.sh without arguments for normal run\n\nchaff.sh --test for building file $RANDOM_CHARS_FILE that can be tested against random number analysers (ent, rngtest, dieharder or any other tool)\n\nchaff.sh whatever will produce this helps message\n\n"
   exit
}

########################################################

exit_with_test_message ()
{
   printf "\nOutputted file with random data: $RANDOM_CHARS_FILE\nTest this file against ent, rngtest and/or dieharder\n\n   ent $RANDOM_CHARS_FILE\n\n   rngtest< $RANDOM_CHARS_FILE\n   dieharder -a < $RANDOM_CHARS_FILE\n\n"
   exit
}

########################################################

# MAIN

cat /dev/null > $ALPHA_STRING_SAVE_FILE
cat /dev/null > $RANDOM_CHARS_FILE
while true
   do
      case $1 in
         "") ;;
         "--test") ;;
         *) exit_with_help_message
      esac
      ENTROPY_GATHERING_ROUNDS=$(( ( RANDOM % (( ENTROPY_ROUNDS_MAX - ENTROPY_ROUNDS_MIN + 1 )) )  + ENTROPY_ROUNDS_MIN ))
      for (( i  = 1; i <= ENTROPY_GATHERING_ROUNDS; i++ )) # generate up to $ENTROPY_ROUNDS_MAX checksums from date (time), iostat, sensors (temperature) and ping
         do
            WHAT_TO_DO=$(printf "1\n2\n3\n4" | shuf)
            echo "$WHAT_TO_DO" | \
               while read -r TO_DO
                  do
                    case "$TO_DO" in
                        1) entropy_from_date ;;
                        2) entropy_from_iostat ;;
                        3) entropy_from_temperature ;;
                        4) entropy_from_ping
                     esac
                  done
         done
      BETA_STRING=$(fold -w1 < $ALPHA_STRING_SAVE_FILE | shuf | tr -d '\n' | fold -w2 | shuf) # break output from $ALPHA_STRING_SAVE_FILE in 1 character lines, mix (shuf), remove line break, break again but in 2 characters lines, shuf
      printf "" > $ALPHA_STRING_SAVE_FILE
      echo "$BETA_STRING" | \
         while read -r HEXOR
            do
               printf "\x$HEXOR" >> $RANDOM_CHARS_FILE # printf each line as hexadecimal coded characters to $RANDOM_CHARS_FILE
            done
      cat $RANDOM_CHARS_FILE > /dev/random # feed $RANDOM_CHARS_FILE to the /dev/random pool
      [[ $1 != "--test" ]] || exit_with_test_message
      cat /dev/null > $RANDOM_CHARS_FILE
      DELAY=$(( ( RANDOM % (( DELAY_MAX - DELAY_MIN + 1 )) )  + DELAY_MIN ))
      sleep $DELAY
   done
