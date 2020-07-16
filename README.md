<h1>Section about Ansible and NSO and pyATS and why a combination is a good way to start with orchestration</h1>

Ansible is a great tool. Simply to learn and to start to automate tasks. But still it is a configuration management tool. 
Of course you can automate some tasks but there a good reason why not each operation is a good task for Ansible.

The problem with the Ansible services they exposed are things like the delete/modify playbooks. 
In this case it is pretty simple use cases but there are more complex things. Also, if the second task fails, what do you do? All the error logic is manual.
 
The point is that NSO is not a “script engine” as Ansible is. So, in Ansible, everything has to be explicitly coded.
 
For configuration, this means:
                1- southbound modules (ok in Ansible the vendors give you this, however every vendor does it differently)
                2- Business logic for Create / Delete and Modify.
                3- Error Handling
                4- Northbound WebUI, CLI, REST, NETCONF.
 
In Ansible, you get it (1) but all the rest is coding work. 
With NSO, you get (1) from the NEDs and with FASTMAP you only need to write the CREATE Business logic, all the rest is for free.

Here a link to NSO for-personal-use: <a href="https://developer.cisco.com/site/nso/"> NSO on DEVNET</a>

<a href="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/fastmap.png">
 <img class="aligncenter size-full wp-image-362" src="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/fastmap.png" alt="" width="1477" height="617" 
 srcset="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/fastmap.png 1477w, https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/fastmap.png 300w, 
 https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/fastmap.png 768w, https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/fastmap.png 1024w" 
 sizes="(max-width: 1477px) 100vw, 1477px" />
</a>

<h4>Ansible Playbook look-a-like</h4>

Configure ip helpers to interfaces

	- name: configure ip helpers on multiple interfaces
	ios_config:
	 lines:
		 - ip helper-address 172.26.1.10
 		- ip helper-address 172.26.3.8
	 parents: "{{ item }}"
	with_items:
		 - interface Ethernet1
 		- interface Ethernet2
		 - interface GigabitEthernet1
	
	- name: check the running-config against master config
	 ios_config:
 	  diff_against: intended
 	  intended_config: "{{ lookup('file', 'master.cfg') }}"

And how does it look if you do a little bit more intelligent task for example managing syslog?

First of all, what is to do to write an Ansible playbook?

<h5>Planning a Playbook</h5>

 * read configuration 
 * get networkdevice configuration
 * add logging level and severity
 * update terminal/buffered logging if needed
 * add logging server(s) and remove wrong ones
 * save configuration if necessary

Comfiguration file could look like this:

 
	# cat etc/logging_config.yaml
	archive: 
	- "archive"
	- "log config"
	- "logging enable"
	- "notify syslog contenttype plaintext"
	- "hidekeys"
	logging_source: "logging source-interface mgmt0"
	logging_servers:
	- "logging server 1.1.1.1"
	- "logging server 1.1.1.2"
	
	
	- name: "GET LOGGING CONFIGURATION"
	      register: get_logging_config
	      ios_command:
	        provider: "{{ provider }}"
	        commands:
	          - "show running-config | include log config"
	          - "show running-config | include logging source"
	          - "show running-config | include logging host"
	- name: "SET ARCHIVE"
		  !when: "(archive is defined) and (archive != get_logging_stdout_lines[0][0])"
		  register: set_archive
		  ios_config:
		  	provider: "{{ provider }}"
		  	lines:
		  	  * "{{ item }}"
	- name: "POSTPONE CONFIGURATION SAVE"
	      when: "(set_archive.changed == true)"
	      set_fact: configured=true
	- name: "SET Logging SERVER"
	      when: "(item not in get_logging_config.stdout_lines[2])"
	      with_items: "{{ logging_servers }}"
	      register: set_logging_server
	      ios_config:
	        provider: "{{ provider }}"
	        lines:
	          * "{{ item }}"
	- name: "POSTPONE CONFIGURATION SAVE"
	      when: "(set_logging_server.changed == true)"
	      set_fact: configured=true
	- name: "REMOVE LOGGING SERVER"
	      when: "(item not in logging_servers)"
	      with_items: "{{ get_logging_config.stdout_lines[2] }}"
	      register: remove_logging_server
	      ios_config:
	        provider: "{{ provider }}"
	        lines:
	          - "no {{ item }}"
	- name: "POSTPONE CONFIGURATION SAVE"
	      when: "(remove_logging_server.changed == true)"
	      set_fact: configured=true
	
Which configuration lines are missing to have a good baseline for a logging configuration
	
	logging level local7 
#(or other severity could be defined depending on device type[switch: local7; wireless: local5; security:local0; router:local1])

	logging source-interface mgmt0  
#(sometimes mgmt-intf not used nor available, InB using VLAN or a loopback interface is used)

	logging timestamp milliseconds  
#(default: seconds or on IOS-XE devices the command is not available)
	
	logging monitor (6|informational)
#depending on the OS of the devices

	logging origin-id hostname

Also a could explanation of how complex it could be to use only ansible tasks is here: <a href="http://www.routereflector.com/2017/02/managing-ntp-on-cisco-ios-with-ansible/">Managing NTP on Cisco IOS with Ansible</a>

<h1>What is pyATS</h1>

Here are some good videos about pyATS, XPresso and NetworkAutomation: <a href="https://www.ciscolive.com/global/on-demand-library.html?search=pyats&search.event=ciscoliveus2020#/session/1573153551586001Jsor">Everybody can NetDevOps</a>
