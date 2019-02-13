<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    $EventLogs,
    $MaxSize
)

foreach($EventLog in $EventLogs){
    try{
        Limit-EventLog -LogName $EventLog -MaximumSize $MaxSize
    }
    catch{
        Write-Warning "Could not set $EventLog to $MaxSize, sorry"
    }
}
