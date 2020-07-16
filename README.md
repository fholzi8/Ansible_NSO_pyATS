#<h1>Section about Ansible and NSO and pyATS and why a combination is a good way to start with orchestration</h1>

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

 

