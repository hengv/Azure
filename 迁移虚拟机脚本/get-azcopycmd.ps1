function get-azcopycmd{
param(


[Parameter(Mandatory=$true)]
[String]$sub1id,

[Parameter(Mandatory=$true)]
[String]$sub1rg,

[Parameter(Mandatory=$true)]
[String]$vmname,

[Parameter(Mandatory=$true)]
[String]$filename
)   
    Select-AzureRmSubscription -Subscriptionid $sub1id

    $vms = get-azurermvm -ResourceGroupName $sub1rg -Name $vmname
    $dest_key = "xxxx"
    foreach($vm in $vms){
        Write-Output "" | Out-File -FilePath $filename -Append
        $tempos = $vm.StorageProfile.OsDisk.Vhd
        $tempsa = Get-AzureRmStorageAccount -Name $tempos.uri.Split('/')[2].split('.')[0] -ResourceGroupName $sub1rg
        $tempsakey =  Get-AzureRmStorageAccountKey -Name $tempos.uri.Split('/')[2].split('.')[0] -ResourceGroupName $sub1rg
        $key = $tempsakey[0].Value

        $source= $null
        $sourcetemp = $null
        $sourcekey = $null
        $dest = $null
        $destkey = $null
        $desttempkey = $null
        $pattern = $null

        $source = "/source:"+$tempos.uri.Split('/')[0]+'/'+$tempos.uri.Split('/')[1]+'/'+$tempos.uri.Split('/')[2]+'/'+$tempos.uri.Split('/')[3]
        $sourcekey = "/sourcekey:"+$key
        $desttempkey = "/destkey:"+$key
        $sourcetemp = "/source:"+$tempos.uri.Split('/')[0]+'/'+$tempos.uri.Split('/')[1]+'/'+$tempos.uri.Split('/')[2]+'/'+'vhd'
        $desttemp = "/dest:"+$tempos.uri.Split('/')[0]+'/'+$tempos.uri.Split('/')[1]+'/'+$tempos.uri.Split('/')[2]+'/'+'vhd'
        $dest = "/dest:https://bjchoice.blob.core.chinacloudapi.cn/"+$vmname
        $destkey = "/destkey:"+ $dest_key
        $pattern = "/pattern:" + $tempos.uri.Split('/')[4]
        $oscp1 = "azcopy "+$source+" " +$sourcekey+" " +$desttemp+" " +$desttempkey+" " +$pattern
        $oscp2 = "azcopy " +$sourcetemp+" "+ $sourcekey+" "+ $dest+" "+ $destkey+" "+ $pattern+" /synccopy"
        write-output $oscp1 | Out-File -filepath $filename -Append
        write-output $oscp2 | Out-File -filepath $filename -Append

        $tempdatas = $vm.StorageProfile.DataDisks
        foreach($data in $tempdatas){
        
            $tempdata = $data.vhd
            $tempdatasa = Get-AzureRmStorageAccount -Name $tempdata.uri.Split('/')[2].split('.')[0] -ResourceGroupName $sub1rg
            $tempdatasakey = Get-AzureRmStorageAccountKey -Name $tempdata.uri.Split('/')[2].split('.')[0] -ResourceGroupName $sub1rg
            $datakey = $tempdatasakey[0].Value

            $source= $null
            $sourcetemp = $null
            $desttempkey = $null
            $sourcekey = $null
            $dest = $null
            $destkey = $null
            $pattern = $null

            $source = "/source:"+$tempdata.uri.Split('/')[0]+'/'+$tempdata.uri.Split('/')[1]+'/'+$tempdata.uri.Split('/')[2]+'/'+$tempdata.uri.Split('/')[3]
            $sourcetemp = "/source:"+$tempdata.uri.Split('/')[0]+'/'+$tempdata.uri.Split('/')[1]+'/'+$tempdata.uri.Split('/')[2]+'/'+'vhd'
            $desttemp = "/dest:"+$tempdata.uri.Split('/')[0]+'/'+$tempdata.uri.Split('/')[1]+'/'+$tempdata.uri.Split('/')[2]+'/'+'vhd'
            $sourcekey = "/sourcekey:"+$datakey
            $desttempkey = "/destkey:"+$datakey
            $dest = "/dest:https://bjchoice.blob.core.chinacloudapi.cn/"+$vmname
            $destkey = "/destkey:"+ $dest_key
            $pattern = "/pattern:" + $tempdata.uri.Split('/')[4]
            $datacp1 = "azcopy "+$source+" " +$sourcekey+" " +$desttemp+" " +$desttempkey+" " +$pattern
            $datacp2 = "azcopy " +$sourcetemp+" "+ $sourcekey+" "+ $dest+" "+ $destkey+" "+ $pattern+" /synccopy"
            write-output $datacp1 | Out-File -filepath $filename -Append
            write-output $datacp2 | Out-File -filepath $filename -Append
        }
    }
}
$sub1id = "xxxx"
$sub1rg = "xxxx"
$vmname = "xxxx"
$filename = "d:\"+$vmname+".txt"

get-azcopycmd -sub1id $sub1id -sub1rg $sub1rg -vmname $vmname -filename $filename