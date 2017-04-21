#!/bin/bash
####################################################
#
# chaff.sh
#
# Purpose: Add additional pseudo-randomness to /dev/random from 4 sources : date, iostat, temperature (please read ahead) and ping
#
# please install sensors package or set variable GET_ENTROPY_FROM_TEMPERATURE to false
#
# the terms "random" and "randomness" are not used here as meaning "truely random" or "true randomness"
#
# better to have a reliable hardware RNG or install haveged and be less happy, or to be a tin-foil hat moron and run chaff.sh alongside haveged
#
# in a terminal window: "chmod +x /your/path/here/chaff.sh" to make the script executable
#
# run from cron: edit, as root, cron in a terminal window with "crontab -e" and add "@reboot /your/path/here/chaff.sh", save and exit and reboot
#
# EARLY ALPHA - YOU HAVE BEEN WARNED
#
####################################################
#
# DISCLAIMER
#
# Use this script at your own risk
# You, as a user, have no right to support even if implied
# Carefully read the script and then interpret, modify, correct, fork, disdain, whatever
#
####################################################
#
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
#
####################################################
#
# Starting values for some variables
#
CPU_DURESS_MAX=19 # 21 and more is way over the top # used to "disturb" possible predicatibility in temperature readings
CPU_DURESS_MIN=11 # 10 or less will probably be irrelevant # used to "disturb" possible predicatibliity in temperature readings
DELAY_MAX=20 # in seconds # MAX interval between script looping
DELAY_MIN=5 # in seconds # MIN interval between script looping
GET_ENTROPY_FROM_DATE=true
GET_ENTROPY_FROM_IOSTAT=true
GET_ENTROPY_FROM_PING=true
GET_ENTROPY_FROM_TEMPERATURE=true # controversial in this implementation, may lead to CPU instability because of random "spikiness" caused by bc # set to "false" to avoid this
IP_TO_PING=0 # 0 is 127.0.0.1 # any other IP will introduce possible unwanted delays, but will probably increase "randomness" # do not ping public IPs
NUMBER_OF_CORES=$(( $(grep -m 1 -i cores < /proc/cpuinfo | awk '{print $4}') -1 )) # for 4 cores the NUMBER_OF_CORES will be 3 # needed to create temperature increase while spiking CPUs
NUMBER_OF_PINGS=4
PING_INTERVAL=0.2 # 0.2 for interval between pings, have to be root for lower value
RANDOM_CHARS_FILE="/dev/shm/.random.hex" # or whatever you want, perhaps /tmp/.random.hex ?
RANDOM_ROUNDS_MAX=10 # number of loops for sequential checksums from date (time), iostat, sensors (temperature) and ping # perhaps their order should/could be randomized
RANDOM_ROUNDS_MIN=1 # 0 is poinless, but may introduce some "randomness"
#
#########################################################
#
entropy_from_date ()
{
### date (time) in nanoseconds
ALPHA_STRING+=$(/bin/date +%s%N | /usr/bin/shasum -a 512 | /usr/bin/awk '{print $1}') # get only shasum from column 1
}
#
#########################################################
#
entropy_from_iostat ()
{
ALPHA_STRING+=$(/usr/bin/iostat | /usr/bin/shasum -a 512 | /usr/bin/awk '{print $1}') # get only shasum from column 1
}
#
#########################################################
#
entropy_from_temperature () ### probably way over the top
{
   for (( CORE = 0; CORE <= NUMBER_OF_CORES; CORE++ )) # launch bc up to $NUMBER_OF_CORE + 1 threads, so for 4 cores we get 4 "simultaneous" threads
      do
         CPU_DURESS=$(( ( RANDOM % (( CPU_DURESS_MAX - CPU_DURESS_MIN + 1 )) )  + CPU_DURESS_MIN ))
         eval "taskset -c $CORE echo 2^2^$CPU_DURESS | /usr/bin/bc > /dev/null &"
      done
# wait for /usr/bin/bc to finish in all threads
      BC_IN_MEM=true
      while $BC_IN_MEM
         do
            TEST=$(pgrep -a bc | awk '{print $2}')
            [ "$TEST" == "/usr/bin/bc" ] || BC_IN_MEM=false
            sleep 0.2
         done
   ALPHA_STRING+=$(/usr/bin/sensors -u | /usr/bin/shasum -a 512 | /usr/bin/awk '{print $1}') # poll temperatures from sensors, get only shasum from column 1
}
#
#########################################################
#
entropy_from_ping ()
{
### pings to $IP_TO_PING
ALPHA_STRING+=$(/bin/ping -i $PING_INTERVAL -c $NUMBER_OF_PINGS $IP_TO_PING | /usr/bin/shasum -a 512 | /usr/bin/awk '{print $1}') # get only shasum from column 1
}
#
#########################################################
#
# MAIN
#
while true
   do
      ENTROPY_GATHERING_ROUNDS=$(( ( RANDOM % (( RANDOM_ROUNDS_MAX - RANDOM_ROUNDS_MIN + 1 )) )  + RANDOM_ROUNDS_MIN ))
      ALPHA_STRING=""
      for (( i  = 1; i <= ENTROPY_GATHERING_ROUNDS; i++ )) # generate up to 4 checksums from date (time), iostat, sensors (temperature) and ping
         do
            [ ! $GET_ENTROPY_FROM_DATE ] || entropy_from_date
            [ ! $GET_ENTROPY_FROM_IOSTAT ] || entropy_from_iostat
            [ ! $GET_ENTROPY_FROM_TEMPERATURE ] || entropy_from_temperature
            [ ! $GET_ENTROPY_FROM_PING ] || entropy_from_ping
         done
         BETA_STRING=$(echo -n "$ALPHA_STRING" | fold -w1 | shuf | shuf | tr -d '\n' | fold -w2) # break ALPHA_STRING string in 1 character lines, mix twice (shuf), remove line break, get a single line and break again but in 2 characters lines
         /bin/cat /dev/null > $RANDOM_CHARS_FILE # generate an empty $RANDOM_CHARS_FILE
         echo "$BETA_STRING" | \
            while read -r HEXOR
               do
                  /usr/bin/printf "\x$HEXOR" >> $RANDOM_CHARS_FILE # printf each line as hexadecimal coded characters to $RANDOM_CHARS_FILE
               done
      /bin/cat $RANDOM_CHARS_FILE > /dev/random # feed $RANDOM_CHARS_FILE to the /dev/random pool
      DELAY=$(( ( RANDOM % (( DELAY_MAX - DELAY_MIN + 1 )) )  + DELAY_MIN ))
      /bin/sleep $DELAY
   done