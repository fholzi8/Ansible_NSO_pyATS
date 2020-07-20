from nornir import InitNornir
from nornir.plugins.functions.text import print_result, print_title
from nornir.plugins.tasks.networking import netmiko_send_command, netmiko_send_config

nr = InitNornir(config_file="config.yaml")


def cdp_map(task):
    r = task.run(task=netmiko_send_command, command_string = "show cdp neighbor", use_genie=True)
    task.host["facts"] = r.result
    outer = task.host["facts"]
    indexer = outer['cdp']['index']
    for idx in indexer:
        local_intf = indexer[idx]['local_interface']
        remote_port = indexer[idx]['port_id']
        remote_id = indexer[idx]['device_id']
        cdp_config = task.run(netmiko_send_config,name="Automating CDP Network Descriptions",config_commands=[
            "interface " + str(local_intf),
            "description Connected to " + str(remote_id) + " via its " + str(remote_port) + " interface"]
        )

def lldp_map(task):
    r = task.run(task=netmiko_send_command, command_string = "show lldp neighbors", use_genie=True)
    task.host["facts"] = r.result
    outer = task.host["facts"]
    interfaces = outer['interfaces']
    for intf in interfaces:
        local_intf = intf
        remote_keys = interfaces[intf]['port_id'].keys()
        for key in remote_keys:
            remote_port = key
            remote_id_keys = interfaces[intf]['port_id'][key]['neighbors'].keys()
            for key in remote_id_keys:
                remote_id = key

        lldp_config = task.run(netmiko_send_config,name="Automating LLDP Network Descriptions",config_commands=[
            "interface " + str(local_intf),
            "description Connected to " + str(remote_id) + " via its " + str(remote_port) + " interface"]
        )

results_lldp = nr.run(task=lldp_map)
results_cdp = nr.run(task=cdp_map)

#creating directory and merge lldp to cdp only overwrite if intf is empty

print_result(results_cdp)
print_result(results_lldp)
