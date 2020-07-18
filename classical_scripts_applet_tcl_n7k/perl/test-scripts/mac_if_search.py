#!/usr/bin/python
from snimpy.manager import Manager as M
from snimpy.manager import load
from netaddr import *
import MySQLdb as mdb
import sys



def Connect2Network(nethost):

        m = M(host=nethost,
        version=3,
        secname="SNMPUser",
        authprotocol="MD5",
        authpassword="SNMP_Passwd!",
        privprotocol="DES",
        privpassword="SNMP_Secret")

	return m


def CollectNetHost(nagiosgroup):

	query = ("SELECT h.alias from nagios_hostgroups g, nagios_hostgroup_members m, nagios_hosts h where g.alias = '"+nagiosgroup+"' and h.alias like 'de%swt%' and m.host_object_id = h.host_object_id and g.hostgroup_id = m.hostgroup_id order by h.alias")

	try:
		cnx = mdb.connect(host='dbserver.company.local',port=3310,user='nagiosread',passwd='xm!Es6c=nYE54ppbz8KX',db='nagios')
		cursor = cnx.cursor()
		cursor.execute(query)
		hosts = cursor.fetchall()
        	cursor.close()
		cnx.close()
        	return list(hosts)

	except mdb.Error as err:
		print '[-] Error '+err.args[0]+': '+err.args[1]
		sys.exit(1)


	

load("IF-MIB")
load("SNMPv2-MIB")
load("IP-FORWARD-MIB")
load("/usr/share/snmp/mibs/OLD-CISCO-INTERFACES-MIB.my")
#load("/usr/share/snmp/mibs/IEEE8021-PAE-MIB.txt")
load("/usr/share/snmp/mibs/CISCO-SMI.my")

nagioshosts = CollectNetHost("Dot1x-Client-Switch")

print '----Begin----'

x = len(nagioshosts)

print 'How many hosts are there: ' + str(x)

print '----Next Line----'

for index in nagioshosts:
	host = index[0]
	host.lstrip("('")
	host.rstrip("',)")
	#now you can ask the swithes

	net = Connect2Network(host)
	print net.sysName
	for i in net.locIfDescr:
		print i

	

print '----End----'

