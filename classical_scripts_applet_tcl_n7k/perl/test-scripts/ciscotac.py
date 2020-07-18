#! /usr/bin/python
# Author: Florian Holzapfel
# Version: 0.1
# Purpose: SSH into loadbalancer and run list of commands for CiscoTAC

import getopt,sys,paramiko,time

def usage():
	print "\nOptions: \n-h: help \n-c: command list \n\nUsage: ciscotac.py -c command-list.txt\n"
	return

# This will error if unsupported parameters are received.
try:
	# This grabs input parameters. If the paramater requires an argument, it should have a colon ':' after. IE, -h does not require argument, -c do, so they get colons
	opts, args = getopt.getopt(sys.argv[1:], "hc:d:")
except getopt.GetoptError, err:
	# print help information and exit:
	print str(err) # will print something like "option -a not recognized"
	usage()
	sys.exit(2)

# This loops through the given parameters and sets the variables. The letters o and a are arbitrary, anything can be used.
# The logic is 'if paramater = x, set variable'.
for o, a in opts:
	if o == "-c":
                commandfile = a
	elif o in ("-h"):
		usage()
		sys.exit()
	else:
		assert False, "unhandled option"

#Set variables
#username = "ciscobackup"
username = "ciscotac"
#password = "7HrPdY!7VUEENQYx9etR2a=9"
password = "sJ9C4u5Rfm8YSc!"
device = "10.14.3.241"

# This prints the given arugments
print "Loadbalancer: ", device
print "Username: ", username
print "Command List: ", commandfile


# Opens files in read mode
file = open(commandfile,"r")

# Creates list based on file1 and file2
commands = file.readlines()

# This function loops through devices. No real need for a function here, just doing it.
def connect_to(x):
	# TimeIdentifier for Output-File
	time_id = time.strftime("%m_%d_%H:%M")
	# This opens an SSH session and loops for every command in the file
	for command in commands:
		# This strips \n from end of each command (line) in the commands list
		command = command.rstrip()
		ssh = paramiko.SSHClient()
		ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
		ssh.connect(device, username=username, password=password)
		stdin, stdout, stderr = ssh.exec_command(command)
		output = open("/tcpdump/hostname_"+time_id+".out", "a")
		output.write("\n\nCommand Issued: "+command+"\n")
		output.writelines(stdout)
		output.write("\n")
		print "Your file has been updated, it is hostname_"+time_id+".out"
		ssh.close()
connect_to(device)
file.close()
# END 

