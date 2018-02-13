$csvfilepath = "D:\201812sufile.csv"
$inputvalues = Import-Csv -Path $csvfilepath 
$inputvalues[0].ResourceGroup
foreach($input in $inputvalues){
   
     Restart-AzureRmVM -PerformMaintenance -ResourceGroupName $input.ResourceGroup -Name $input.name
     
}