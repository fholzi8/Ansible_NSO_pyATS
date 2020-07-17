<h1>Section about Ansible and NSO and pyATS and why a combination is one good way of network orchestration</h1>

<!--<a href="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg">
 <img class="aligncenter size-full wp-image-362" src="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg" alt="" width="1477" height="617" srcset="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg 1477w, https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg 300w, https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg 768w, https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg 1024w" sizes="(max-width: 1477px) 100vw, 1477px" />
</a>-->

<img src="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/Wanna_code_but.jpeg">

<h3>How to start with network automation/orchestration</h3>

How to start with baselining (so standard configurations) and automatation? One of the best open-source tool in my view is Ansible. It is simple to install (<b>pip install ansible</b> or <b>apt-get install ansible</b> and so on) further it is agentless (also puppet or chef or saltstack have really good use cases but in terms of 1000s network devices with a limitied OS - agentless makes more sense for me) and to start with the first playbooks is simple. In the last years I had several discussion and about if Ansible is an automation tool or a configuration management tool. So, put it this way if working trafficlights (switching from red to orange to green and back to red after a certain time) is for you automation then Ansible would be an automation tool but there is no intelligent behind it. And, nowadays we are always speaking from the smart-whatever. So, automation should be smart making decision based on specific and predicitive keys. So is Ansible capable of this task? Yes, it is definitely and I always start with Ansible in network orchestration/automation projects BUT in my view and experience it is limited due to limitation of the programmability of the playbooks, regex limitation, and performance of the ansible host and using still ssh. And yes, ssh is not a high performer protocol. Of course you can tune it (a little bit) using pubkey instead of user/password or doesn't reuse connections (which btw. could be a problem onto network devices). So, my next step is to add NSO for the "smart" part into automation projects. (You don't know NSO - you can read here: <a href="https://www.cisco.com/c/en/us/solutions/service-provider/solutions-cloud-providers/network-services-orchestrator-solutions.html#:~:text=Cisco%20Network%20Services%20Orchestrator%20(NSO)%20is%20industry%2Dleading%20software,are%20delivered%20in%20real%20time."> Cisco NSO </a> and using pyATS as configuration validation/verification. And please keep in mind NSO is not vendor-locked other 177 NED (Network Element Drivers) starting from Arista to Vmware can be managed and orchestrate. 

<h3>Ansible</h3>

The problem with the Ansible services they exposed are things like the delete/modify playbooks. 
In this case, it is pretty simple use cases but there are more complex things. 
Also, if the second task fails, what do you do? All the error logic is manual.
 
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

Configuration file could look like this:

 
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

<h3>NSO</h3>

Starting with a good use case as explained here: <a href="https://github.com/jmullool/Ansible-driven-NSO-service-automation">Ansible-driven-NSO-service-automation</a>

<img src="https://github.com/fholzi8/Ansible_NSO_pyATS/blob/master/UseCase1.png">

<h4>Advantages</h4>
* vendor-independent
* stateful
* agentless (but NED needed)
* fast and reliable due to Netconf
* YAML-based playbooks

<h4>Disadvantages</h4>
* not open-source
* training needed (but self-learning available <a href="https://developer.cisco.com/docs/nso/#!learning-nso/the-first-day"> Learning-NSO</a>

<h4>Typical Questions</h4>

<b>Question:</b>What means Stateful or Stateless regarding Ansible/NSO?

<b>Answer:</b>Ansible has no state of the configuration means it executes playbooks and then exists. And from NSO stateful convergence algorithm derives the minimum network changes required. (bandwidth reduction and faster)

<b>Question:</b>What is the benefit of NSO versus Ansible?

<b>Answer:</b>Ansible doesn‘t provide rollbacks, minimal diffs nor any operations on data sets. Furthermore NSO needs by using Netconf or RESTconf less bandwidth. 

<b>Question:</b>Why should I use Ansible if NSO is so much better?

<b>Answer:</b>Ansible tasks use modules to perform activities and NSO modules uses the JSON-RPC API to perform operations on NSO. Means with Ansible you define easier your tasks and NSO generates operations. 

<b>Question:</b>Does NSO or Ansible scale?

<b>Answer:</b>The answers is yes and no. NSO can be deployed as a hierachical cluster environment. Ansible has no cluster deployment but you can set up several independent instances. Furthermore Ansible has a high cpu consumption if you have more than 1000 devices so its scalability is limited.

When normally questions about pricing are raised, but I believe that is not the right platform here to discuss it because it depends. (typical consultant answer :) )And keep in mind that Ansible is not free it is owned by RedHat (which is good in my view) and of course open-source but money is generated by services. And also NSO doesn't fit to every use case (due to cost or complexity) but as mentioned <b>it depends</b>.

<h3>What is pyATS</h3>

Here are some good videos about pyATS, XPresso and NetworkAutomation: <a href="https://www.ciscolive.com/global/on-demand-library.html?search=pyats&search.event=ciscoliveus2020#/session/1573153551586001Jsor">Everybody can NetDevOps</a>
