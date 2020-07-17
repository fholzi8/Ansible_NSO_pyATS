Copyright (c) 2012 Scott Tudor <netc.project@gmail.com>
All rights reserved.



How to run this script
-----------------------

router# term len 0   (disable the --More-- prompt)
router# top



Description
------------

View Top Talkers in "real time" from CLI 

This experimental script is similar to the Unix 'top' command except it provides an updating list of Top Talkers. The script works by taking 7-second snapshots of the netflow cache table and calculates the byte/packet difference between snapshops. This calculation is used to find the Bit/sec and Pkt/sec for each flow. Flows with the highest Bits/sec are output to the screen in a 'Top Talker' table. The script output is a growing list so use 'term len 0' before running the script.



Options
----------

router#top -h
Usage:   top <arg1>
                -h                  HELP with options
                -f <flowMonName>    FLOW monitor name, default=Cfg first listed
                -r <sec>            REFRESH rate [1..30]; default 7



NOTES
------
* there is currently no way to interrupt script, script terminates after 30 seconds (5 interations)
* script currently uses 400 entries from the cache table to calculate top talkers