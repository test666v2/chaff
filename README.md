chaff.sh

Purpose: Add additional pseudo-randomness to /dev/random from 4 sources : date, iostat, temperature (please verify ahead in the script) and ping

Please install sensors package or set variable GET_ENTROPY_FROM_TEMPERATURE to false

The terms "random", "randomized" and "randomness" are here loosely used and do not mean "true randomness"

It would be better to have a reliable hardware RNG or install haveged and be less happy, or both, or to be a tin-foil hat moron and run chaff.sh alongside haveged

In a terminal window: "chmod +x /your/path/here/chaff.sh" to make the script executable

run from cron: edit, as root, cron in a terminal window with "crontab -e" and add "@reboot /your/path/here/chaff.sh", save and exit and reboot

EARLY ALPHA - YOU HAVE BEEN WARNED
