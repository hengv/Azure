import json
import sys
import mcazurerm
import instanceview

try:
    with open('azurermconfig.json') as config_file:
            config_data = json.load(config_file)
except SystemError:
        sys.exit('Error: Expecting azurermconfig.json in current folder')

tenant_id = config_data['tenantId']
app_id = config_data['appId']
app_secret = config_data['appSecret']
subscription_id = config_data['subscriptionId']

access_token = mcazurerm.get_access_token(tenant_id, app_id, app_secret)

subscriptions = mcazurerm.list_subscriptions(access_token)
for sub in subscriptions['value']:
    print(sub['displayName'] + ': ' + sub['subscriptionId'])

#vminfo = mcazurerm.get_vm(access_token,sub['subscriptionId'],"test01","hwcent01")

vminstanceview =  instanceview.get_vm_instanceview(access_token,sub['subscriptionId'],"test01","hwcent01")
#print vminstanceview
print 'VM Name: ',vminstanceview['name']
print 'VM Resource Group: ',vminstanceview['id'].split('/')[4]
print 'VM Location: ',vminstanceview['location']
print "VM Status: ",vminstanceview['properties']['instanceView']['statuses'][1]['displayStatus']





