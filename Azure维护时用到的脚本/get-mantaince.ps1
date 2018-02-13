$mycred = Get-Credential -UserName xxxxxxxx -Message hello
Login-AzureRmAccount -Environment AzureChinaCloud -Credential $mycred

$RMVMs=Get-AzurermVM
 
# Create array to contain all the VMs in the subscription
$RMVMsuArray = @()
$RMVMfaArray = @()
$RMVMother = @()
 
$i = 1
# Loop through VMs
foreach ($vm in $RMVMs)
  {
  write-host $i
  $i = $i + 1
  # Get VM Status (for Power State)
  $vmStatus = Get-AzurermVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status
  if($vmStatus.MaintenanceRedeployStatus){
      if($vmStatus.MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed){
          # Generate Array
          $RMVMsuArray += New-Object PSObject -Property @{`
 
            # Collect Properties
            Name = $vm.Name;;
            ResourceGroup = $vm.ResourceGroupName;
            PowerState = (get-culture).TextInfo.ToTitleCase(($vmStatus.statuses)[1].code.split("/")[1]);
            Location = $vm.Location;
            Size = $vm.HardwareProfile.VmSize;
            OSType = $vm.StorageProfile.OsDisk.OsType;
            MaintenanceAllowed = $vmStatus.MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed;
            PreMaintenanceWindowStartTime = $vmStatus.MaintenanceRedeployStatus.PreMaintenanceWindowStartTime;
            PreMaintenanceWindowEndTime = $vmStatus.MaintenanceRedeployStatus.PreMaintenanceWindowEndTime;
            MaintenanceWindowStartTime = $vmStatus.MaintenanceRedeployStatus.MaintenanceWindowStartTime;
            MaintenanceWindowEndTime = $vmStatus.MaintenanceRedeployStatus.MaintenanceWindowEndTime;
            LastCode = $vmStatus.MaintenanceRedeployStatus.LastOperationResultCode
            LastMessage = $vmStatus.MaintenanceRedeployStatus.LastOperationMessage
            Number = 1;
            }
        }
        else
        {
            $RMVMfaArray += New-Object PSObject -Property @{`
            Name = $vm.Name;
            ResourceGroup = $vm.ResourceGroupName;
            PowerState = (get-culture).TextInfo.ToTitleCase(($vmStatus.statuses)[1].code.split("/")[1]);
            Location = $vm.Location;
            Size = $vm.HardwareProfile.VmSize;
            OSType = $vm.StorageProfile.OsDisk.OsType;
            MaintenanceAllowed = $vmStatus.MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed;
            PreMaintenanceWindowStartTime = $vmStatus.MaintenanceRedeployStatus.PreMaintenanceWindowStartTime;
            PreMaintenanceWindowEndTime = $vmStatus.MaintenanceRedeployStatus.PreMaintenanceWindowEndTime;
            MaintenanceWindowStartTime = $vmStatus.MaintenanceRedeployStatus.MaintenanceWindowStartTime;
            MaintenanceWindowEndTime = $vmStatus.MaintenanceRedeployStatus.MaintenanceWindowEndTime;
            LastCode = $vmStatus.MaintenanceRedeployStatus.LastOperationResultCode
            LastMessage = $vmStatus.MaintenanceRedeployStatus.LastOperationMessage
            Number = 1;
            }
            
          }
      }
    else{
        $RMVMother += New-Object PSObject -Property @{`
            Name = $vm.Name;
            ResourceGroup = $vm.ResourceGroupName;
            PowerState = (get-culture).TextInfo.ToTitleCase(($vmStatus.statuses)[1].code.split("/")[1]);
            Location = $vm.Location;
            Size = $vm.HardwareProfile.VmSize;
            OSType = $vm.StorageProfile.OsDisk.OsType;
            Number = 1;
            }
    }
 }

$date = Get-Date
$mydate = $date.Year.ToString() + $date.Month.ToString() + $date.Day.ToString()
$su = "D:\" +$mydate +"sufile"+ ".csv"
$RMVMsuArray | export-csv $su
$fa = "D:\" +$mydate +"fafile"+ ".csv"
$RMVMfaArray | export-csv $fa
$fa = "D:\" +$mydate +"otherfile"+ ".csv"
$RMVMother | export-csv $fa




