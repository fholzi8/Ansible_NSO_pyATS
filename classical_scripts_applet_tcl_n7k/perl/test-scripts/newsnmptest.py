#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import argparse
import netsnmp
import urllib2,json
import MySQLdb as mdb
from collections import defaultdict


__author__ = 'fholzi8 (att) gmail.com (Florian Holzapfel)'

def main():
	# Collect for networt elements
	nagioshosts = collect_network_elements("Dot1x-Client-Switch")
	#nagioshosts = collect_network_elements("Switche-NDL")
	
	for networkElements in nagioshosts:
		host = networkElements[0]
		host.lstrip("('")
		host.rstrip("',)")
		# Process the CLI
		#print 'Network Element: ' + host
		(snmpdata) = process_cli(host)
		# Get sysID
		device_oid_id = get_sys_object_id(snmpdata)
	
		# Stop completely before creating new files if SNMP
		# isn't working
		if not device_oid_id:
			print ('ERROR: Cannot contact %s. Check connectivity or SNMP parameters') % (snmpdata['ipaddress'])
			sys.exit(2)
	
		collect_snmp_values(snmpdata)


"""
def main():
	host = "10.11.1.13"
	(snmpdata) = process_cli(host)
	# Get sysID
	device_oid_id = get_sys_object_id(snmpdata)
	
	# Stop completely before creating new files if SNMP
	# isn't working
	if not device_oid_id:
		print ('ERROR: Cannot contact %s. Check connectivity or SNMP parameters') % (snmpdata['ipaddress'])
		sys.exit(2)
	
	collect_snmp_values(snmpdata)
"""

def collect_snmp_values(snmpdata):
	hostname = snmpdata['ipaddress']
	# Initialize dictionaries
	host_intf_mapping = defaultdict(lambda: defaultdict(dict))
	
	# Descriptions
	ifdesc_oid = '.1.3.6.1.2.1.31.1.1.1.1'
	ifdesc_results = do_snmpwalk(snmpdata, ifdesc_oid)
	for oid, val in sorted(ifdesc_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			#print '\n Description: %s' % str(val)
			host_intf_mapping[hostname][last_octet]['desc'] = str(val)
	# MAC-Address
	ifmac_oid = '.1.0.8802.1.1.1.1.2.2.1.12'
	ifmac_results = do_snmpwalk(snmpdata, ifmac_oid)
	for oid, val in sorted(ifmac_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			mac = format_mac(val)
			#print '\n MACaddress: %s' % mac
			host_intf_mapping[hostname][last_octet]['macaddress'] = mac
	# PortSec-MAC-Address
	ifp_mac_oid = '.1.3.6.1.4.1.9.9.315.1.2.1.1.10'
	ifp_mac_results = do_snmpwalk(snmpdata, ifp_mac_oid)
	for oid, val in sorted(ifp_mac_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			mac = format_mac(val)
			#print '\n MACaddress: %s' % mac
			host_intf_mapping[hostname][last_octet]['portsec-macaddress'] = mac
	# VLAN-ID
	ifvlan_oid = '.1.3.6.1.4.1.9.9.68.1.2.2.1.2'
	ifvlan_results = do_snmpwalk(snmpdata, ifvlan_oid)
	for oid, val in sorted(ifvlan_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			if int(val) == 1:
				trunk = "trunk"
				#print '\n Vlan-ID: %s' % trunk
				host_intf_mapping[hostname][last_octet]['vlanid'] = trunk
			else:
				#print '\n Vlan-ID: %d' % int(val)
				host_intf_mapping[hostname][last_octet]['vlanid'] = int(val)
	# Operationstatus
	ifoper_oid = '.1.3.6.1.2.1.2.2.1.8'
	ifoper_results = do_snmpwalk(snmpdata, ifoper_oid)
	for oid, val in sorted(ifoper_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			if int(val) == 1:
				oper = "up"
			elif int(val) == 2:
				oper = "down"
			else:
				oper = "testing"
			#print '\n Operationstatus: %s' % oper
			host_intf_mapping[hostname][last_octet]['oper'] = oper
	# EAP-Status
	ifeap_oid = '.1.3.6.1.2.1.2.2.1.8'
	ifeap_results = do_snmpwalk(snmpdata, ifeap_oid)
	for oid, val in sorted(ifeap_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			if int(val) == 1:
				eap = "initialize"
			elif int(val) == 2:
				eap = "disconnected"
			elif int(val) == 3:
				eap = "connecting"
			elif int(val) == 4:
				eap = "authenticating"
			elif int(val) == 5:
				eap = "authenticated"
			elif int(val) == 6:
				eap = "aborting"
			elif int(val) == 7:
				eap = "held"
			elif int(val) == 6:
				eap = "forceAuth"
			elif int(val) == 7:
				eap = "forceUnauth"
			else:
				eap = "unknown"
			#print '\n Operationstatus: %s' % eap
			host_intf_mapping[hostname][last_octet]['eap'] = eap
	# INTF-Speed
	ifspeed_oid = '.1.3.6.1.2.1.2.2.1.5'
	ifspeed_results = do_snmpwalk(snmpdata, ifspeed_oid)
	for oid, val in sorted(ifspeed_results.items()):
		last_octet = get_oid_last_octet(oid)
		if ((int(last_octet) > 10000) and (int(last_octet) < 12000)):
			#print '\n Index: ' + last_octet
			#print '\n OID: ' + oid
			if int(val) == 10000000:
				speed = 10
			elif int(val) == 100000000:
				speed = 100
			else:
				speed = 1000
			#print '\n IF-Speed: %d mbps' % speed
			host_intf_mapping[hostname][last_octet]['speed'] = speed
	
	# Print mapping
	#print json.dumps(host_intf_mapping)
	do_json_upload(host_intf_mapping)

def do_snmpwalk(snmpdata, oid):
	return do_snmpquery(snmpdata, oid, False)
 
def do_snmpget(snmpdata, oid):
	return do_snmpquery(snmpdata, oid, True)

def do_snmpquery(snmpdata, oid, snmpget):
	# Initialize variables
	return_results = {}
	results_objects = False
	session = False
	
	# Get OID
	try:
		session = netsnmp.Session(DestHost=snmpdata['ipaddress'],
			Version=snmpdata['version'], Community=snmpdata['community'],
			SecLevel='authPriv', AuthProto=snmpdata['authprotocol'],
			AuthPass=snmpdata['authpassword'], PrivProto=snmpdata['privprotocol'],
			PrivPass=snmpdata['privpassword'], SecName=snmpdata['secname'],
			UseNumeric=True)
		result_objects = netsnmp.VarList(netsnmp.Varbind(oid))
	
		if snmpget:
			session.get(result_objects)
		else:
			session.walk(result_objects)
	
	except Exception as exception_error:
	# Check for errors and print out results
		print ('ERROR: Occurred during SNMPget for OID %s from %s: '
				'(%s)') % (oid, snmpdata['ipaddress'], exception_error)
		sys.exit(2)
	
	# Crash on error
	if (session.ErrorStr):
		print ('ERROR: Occurred during SNMPget for OID %s from %s: '
				'(%s) ErrorNum: %s, ErrorInd: %s') % (
				oid, snmpdata['ipaddress'], session.ErrorStr,
					session.ErrorNum, session.ErrorInd)
		sys.exit(2)
	
	# Construct the results to return
	for result in result_objects:
		if is_number(result.val):
			return_results[('%s.%s') % (result.tag, result.iid)] = (
				float(result.val))
		elif is_string(result.val):
			return_results[('%s.%s') % (result.tag, result.iid)] = (
				str(result.val))
		elif is_unicode(result.val):
			return_results[('%s.%s') % (result.tag, result.iid)] = (
				unicode(result.val))
		else:
			return_results[('%s.%s') % (result.tag, result.iid)] = (
				result.val)
	
	return return_results

def do_json_upload(val):
	# Upload JSON
	req = urllib2.Request('https://adtools.company.local/sccm/add2db/switchports.aspx')
	# Adding Header
	req.add_header('Content-Type', 'application/json')
	response = urllib2.urlopen(req, json.dumps(val))

def get_sys_object_id(snmpdata):
	sysobjectid = '.1.3.6.1.2.1.1.2.0'
	snmp_results = do_snmpget(snmpdata, sysobjectid)
	for val in snmp_results.values():
		return val

def format_mac(val):
	if val == "":
		mac = '00:00:00:00:00:00'
		return str(mac)
	elif val == '\x00\x00\x00\x00\x00\x00':
		mac = '00:00:00:00:00:00'
		return str(mac)
	else:
		maca = " ".join(hex(ord(n)) for n in val)
		macb = maca.replace("0x", "")
		macc = macb.replace(" ", ":")
		if len(macc) > 17:
			macc = '00:00:00:00:00:00'
		#print 'MAC-address: %s' % str(macc)
		return str(macc)

def is_number(val):
	try:
		float(val)
		return True
	except ValueError:
		return False

def is_string(val):
	try:
		str(val)
		return True
	except ValueError:
		return False

def is_unicode(val):
	try:
		unicode(val)
		return True
	except ValueError:
		return False

def get_oid_last_octet(oid):
	octets = oid.split('.')
	return octets[-1]

def process_cli(host):
	# Initialize SNMP variables
	snmpdata = {}
	snmpdata['community'] = None
	snmpdata['ipaddress'] = host
	snmpdata['secname'] = "SNMPUser"
	snmpdata['version'] = 3
	snmpdata['authpassword'] = "SNMP_Passwd!"
	snmpdata['authprotocol'] = "MD5"
	snmpdata['privpassword'] = "SNMP_Secret"
	snmpdata['privprotocol'] = "DES"
	snmpdata['port'] = 161
	
	# Parse the CLI
	parser = argparse.ArgumentParser()
	parser.add_argument('-v', '--version', help='SNMP version',
		type=int)
	parser.add_argument('-c', '--community', help='SNMPv2 community string')
	parser.add_argument('-i', '--ipaddress',
		help='IP address of device to query')
	parser.add_argument('-u', '--secname', help='SNMPv3 secname')
	parser.add_argument('-A', '--authpassword', help='SNMPv3 authpassword')
	parser.add_argument('-a', '--authprotocol',
		help='SNMPv3 authprotocol (MD5, SHA)')
	parser.add_argument('-X', '--privpassword', help='SNMPv3 privpassword')
	parser.add_argument('-x', '--privprotocol',
		help='SNMPv3 privprotocol (DES, 3DES, AES128)')
	parser.add_argument('--port', help='SNMP UDP port', type=int)
	
	# Parse arguments and die if error
	try:
		args = parser.parse_args()
	except Exception:
		sys.exit(2)
	
	# Assign and verify SNMP arguments
	if args.version:
		snmpdata['version'] = args.version
	if args.community:
		snmpdata['community'] = args.community
	if args.ipaddress:
		snmpdata['ipaddress'] = args.ipaddress
	if (snmpdata['version'] != 2) and (snmpdata['version'] != 3):
		print 'ERROR: Only SNMPv2 and SNMPv3 are supported'
		sys.exit(2)
	if args.secname:
		snmpdata['secname'] = args.secname
	if (not snmpdata['secname']) and (snmpdata['version'] == 3):
		print 'ERROR: SNMPv3 must specify a secname'
		sys.exit(2)
	if args.authpassword:
		snmpdata['authpassword'] = args.authpassword
	if args.authprotocol:
		snmpdata['authprotocol'] = args.authprotocol.upper()
	if args.privpassword:
		snmpdata['privpassword'] = args.privpassword
	if args.privprotocol:
		snmpdata['privprotocol'] = args.privprotocol.upper()
	if args.port:
		snmpdata['port'] = args.port
	
	if not snmpdata['version']:
		print 'ERROR: SNMP version not specified'
		sys.exit(2)
	
	if (snmpdata['version'] == 2) and (not snmpdata['community']):
		print 'ERROR: SNMPv2 community string not defined'
		sys.exit(2)
	
	if (not snmpdata['ipaddress']):
		print 'ERROR: IP address of device to query is not defined'
		sys.exit(2)
	
	return (snmpdata)

def collect_network_elements(nagiosgroup):
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

if __name__ == "__main__":
    main()
