from mcazurerm import *

def get_vm_instanceview(access_token, subscription_id, resource_group, vm_name):
    endpoint = ''.join([azure_rm_endpoint,
                        '/subscriptions/', subscription_id,
                        '/resourceGroups/', resource_group,
                        '/providers/Microsoft.Compute/virtualMachines/', vm_name,
                        '?$expand=instanceView'
                        '&api-version=', COMP_API])
    return do_get(endpoint, access_token)
