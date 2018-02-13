#!/bin/bash
rm -rf c.txt
az vm get-instance-view --ids $(az vm list --query "[].id" -o tsv) --query "[].[ location,resourceGroup,name,instanceView.maintenanceRedeployStatus.maintenanceWindowStartTime ]" -o table | grep china > c.txt
while read Line
do
  rg=`echo $Line | awk '/ / {print $2}'`
  name=`echo $Line | awk '/ / {print $3}'`
  mt=`echo $Line | awk '/ / {print $4}' | awk -F '-' '{print $1}'`
  if [ "$mt" = "2018" ];
  then
    az vm redeploy -g $rg -n $name & 
  else
    echo $rg,$name,"already done"
  fi
done < c.txt
 
