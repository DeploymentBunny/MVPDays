<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
)
Get-NetFirewallRule -DisplayName "*File and Printer Sharing*" | Enable-NetFirewallRule -Verbose
Get-NetFirewallRule -Group "@FirewallAPI.dll,-28752" | Enable-NetFirewallRule -Verbose
Get-NetFirewallRule -DisplayName "*File and Printer Sharing*"
Get-NetFirewallRule -Group "@FirewallAPI.dll,-28752"