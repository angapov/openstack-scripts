#!/usr/bin/env python
from neutronclient.v2_0 import client
from pprint import pprint
OS_USERNAME         = 'admin'
OS_PASSWORD         = 'sle3per1267'
OS_AUTH_URL         = 'http://slpeahhp:6000/v2.0'
OS_PROJECT_NAME     = 'iclcloud | dev'
neutron = client.Client(username=OS_USERNAME,
                          password=OS_PASSWORD,
                          tenant_name=OS_PROJECT_NAME,
                          auth_url=OS_AUTH_URL)
def create_router(name, tenant_id, ha=False, distributed=False):
    body = {'router': {'admin_state_up': True,
                       'name': name,
                       'tenant_id': tenant_id,
                       'ha': ha,
                       'distributed': distributed,
                       }}
    return neutron.create_router(body=body)

old_router = neutron.show_router('a9e0bec8-4664-45b4-888f-1bd25aa6089d')['router']
ports = [ port for port in neutron.list_ports(device_id=old_router['id'])['ports'] if port['device_owner']=='network:router_interface']
new_router = create_router(u'new_'+old_router['name'], 
                            old_router['tenant_id'],
                            ha = old_router['ha'],
                            distributed = old_router['distributed'])['router']

new_router = neutron.add_gateway_router(new_router['id'], 
                                        {'network_id': old_router['external_gateway_info']['network_id']})['router']
old_gateway_fixed_ips = old_router['external_gateway_info']['external_fixed_ips'][0]
new_gateway_fixed_ips = new_router['external_gateway_info']['external_fixed_ips'][0]
search_string = [ "subnet_id=%s", "ip_address=%s"] % (str(new_gateway_fixed_ips['subnet_id']), str(new_gateway_fixed_ips['ip_address']))
new_gateway_port = neutron.list_ports(fixed_ips = search_string)
print new_gateway_port
old_router = neutron.remove_gateway_router(old_router['id'])['router']
new_gateway_port = neutron.update_port(new_gateway_port['id'], body = { 'port': { 'fixed_ips': old_gateway_fixed_ips }})['port']

for port in ports:
    new_port = None
    neutron.remove_interface_router(old_router['id'], body = { 'port_id': port['id'] } )
    new_port = neutron.create_port(body = { 'port': { 'fixed_ips':  port['fixed_ips'], 
                                                      'network_id': port['network_id'],
                                                      'tenant_id':  port['tenant_id'] }})['port']
    neutron.add_interface_router(new_router['id'], body = { 'port_id': new_port['id'] } )
new_router = neutron.update_router(new_router['id'],
                                   body={ 'router': {
                                                'portforwardings': old_router['portforwardings'],
                                                'routes': old_router['routes'], 
                                   }})['router']
pprint(new_router)
print
#pprint(dir(neutron))
pprint(old_router)
