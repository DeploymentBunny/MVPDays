<#
.SYNOPSIS
    Baseconfig for WS2019
.DESCRIPTION
    Baseconfig for WS2019
.EXAMPLE
    BaseconfigWS2019.ps1
.NOTES
        ScriptName: BaseconfigWS2019.ps1
        Author:     Mikael Nystrom
        Twitter:    @mikael_nystrom
        Email:      mikael.nystrom@truesec.se
        Blog:       https://deploymentbunny.com

    Version History
    1.0.0 - Script created [01/16/2019 13:12:16]

Copyright (c) 2019 Mikael Nystrom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

[cmdletbinding(SupportsShouldProcess=$True)]
Param(
)

$VerbosePreference = "continue"
$writetoscreen = $true

Function Get-VIAOSVersion([ref]$OSv){
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    Switch -Regex ($OS.Version)
    {
    "6.1"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 7 SP1"}
                Else
            {$OSv.value = "Windows Server 2008 R2"}
        }
    "6.2"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 8"}
                Else
            {$OSv.value = "Windows Server 2012"}
        }
    "6.3"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 8.1"}
                Else
            {$OSv.value = "Windows Server 2012 R2"}
        }
    "10"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 10"}
                Else
            {$OSv.value = "Windows Server 2016"}
        }
    DEFAULT { "Version not listed" }
    } 
}
Function Import-VIASMSTSENV{
    try{
        $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
        Write-Output "$ScriptName - tsenv is $tsenv "
        $MDTIntegration = $true
        
        #$tsenv.GetVariables() | % { Write-Output "$ScriptName - $_ = $($tsenv.Value($_))" }
    }
    catch{
        Write-Output "$ScriptName - Unable to load Microsoft.SMS.TSEnvironment"
        Write-Output "$ScriptName - Running in standalonemode"
        $MDTIntegration = $false
    }
    Finally{
        if ($MDTIntegration -eq $true){
            $Logpath = $tsenv.Value("LogPath")
            $LogFile = $Logpath + "\" + "$ScriptName.log"
        }
    Else{
            $Logpath = $env:TEMP
            $LogFile = $Logpath + "\" + "$ScriptName.log"
        }
    }
    Return $MDTIntegration
}
Function Invoke-VIAExe{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

    if($Arguments -eq "")
    {
        Write-Verbose "Running Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -NoNewWindow -Wait -Passthru
    }else{
        Write-Verbose "Running Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
    }
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
Function Start-Log
{
[CmdletBinding()]
    param (
    [ValidateScript({ Split-Path $_ -Parent | Test-Path })]
               [string]$FilePath
    )
               
    try
    {
        if (!(Test-Path $FilePath))
               {
                   ## Create the log file
                   New-Item $FilePath -Type File | Out-Null
               }
                              
               ## Set the global variable to be used as the FilePath for all subsequent Write-Log
               ## calls in this session
               $global:ScriptLogFilePath = $FilePath
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}
Function Write-Log
{
               param (
                              [Parameter(Mandatory = $true)]
                              [string]$Message,
                                             
                              [Parameter()]
                              [ValidateSet(1, 2, 3)]
                              [string]$LogLevel = 1
               )

    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
    #$LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf)", $LogLevel
    $Line = $Line -f $LineFormat
    Add-Content -Value $Line -Path $ScriptLogFilePath

    if($writetoscreen -eq $true){
        switch ($LogLevel)
        {
            '1'{
                Write-Host $Message -ForegroundColor Gray
                }
            '2'{
                Write-Host $Message -ForegroundColor Yellow
                }
            '3'{
                Write-Host $Message -ForegroundColor Red
                }
            Default {}
        }
    }

    if($writetolistbox -eq $true){
        $result1.Items.Add("$Message")
    }
}

# Set Vars
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
#[xml]$Settings = Get-Content "$ScriptDir\Settings.xml"
$ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE

#Try to Import SMSTSEnv
. Import-VIASMSTSENV

#Start logging
Start-Log -FilePath $LogFile

#Output more info
Write-Log "$ScriptName - ScriptDir: $ScriptDir"
Write-Log "$ScriptName - ScriptName: $ScriptName"
Write-Log "$ScriptName - Integration with TaskSequence(LTI/ZTI): $MDTIntegration"
Write-Log "$ScriptName - Log: $LogFile"

#Generate more info
if($MDTIntegration -eq "YES"){
    $TSMake = $tsenv.Value("Make")
    $TSModel = $tsenv.Value("Model")
    Write-Log "$ScriptName - Make:: $TSMake"
    Write-Log "$ScriptName - Model: $TSModel"
}
#Custom Code Starts--------------------------------------

#Action
$Action = "Enable Remote Desktop"
Write-Log "Action: $Action"
try
{
    cscript.exe /nologo C:\windows\system32\SCregEdit.wsf /AR 0
    Write-Log "Action: $Action - Sucess"
}
catch{
    Write-Log "Action: $Action - Fail"
}


#Action
$Action = "Set Remote Destop Security"
Write-Log "Action: $Action"
try
{
    cscript.exe /nologo C:\windows\system32\SCregEdit.wsf /CS 0
    Write-Log "Action: $Action - Sucess"
}
catch{
    Write-Log "Action: $Action - Fail"
}


#Configure global settings for all servers in the fabric
$Action = "Remove-WindowsFeature -Name FS-SMB1 -Norestart"
Write-Log "Action: $Action"
Remove-WindowsFeature -Name FS-SMB1

#Server Manager Performance Monitor
$Action = "Start-SMPerformanceCollector -CollectorName 'Server Manager Performance Monitor'"
Write-Log "Action: $Action"
Start-SMPerformanceCollector -CollectorName 'Server Manager Performance Monitor'

#Disable Show Welcome Tile for all users
$Action = "Disable Show Welcome Tile for all users"
Write-Log "Action: $Action"

$XMLBlock = @(
'<?xml version="1.0" encoding="utf-8"?>
  <configuration>
   <configSections>
    <sectionGroup name="userSettings" type="System.Configuration.UserSettingsGroup, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089">
    <section name="Microsoft.Windows.ServerManager.Common.Properties.Settings" type="System.Configuration.ClientSettingsSection, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" allowExeDefinition="MachineToLocalUser" requirePermission="false" />
    </sectionGroup>
   </configSections>
   <userSettings>
    <Microsoft.Windows.ServerManager.Common.Properties.Settings>
     <setting name="WelcomeTileVisibility" serializeAs="String">
      <value>Collapsed</value>
     </setting>
    </Microsoft.Windows.ServerManager.Common.Properties.Settings>
   </userSettings>
  </configuration>'
  )
$XMLBlock | Out-File -FilePath C:\Windows\System32\ServerManager.exe.config -Encoding ascii -Force

#Configure global settings for all servers in the fabric
$Action = "Enable SmartScreen"
Write-Log "Action: $Action"
$OptionType = 2
$KeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
New-ItemProperty -Path $KeyPath -Name EnableSmartScreen -Value $OptionType -PropertyType DWord -Force

#Set CrashControl
$Action = "Set CrashControl"
Write-Log "Action: $Action"
& $scriptdir\Configure-TSxCrashControl.ps1

#Firewall File/Printsharing
$Action = "Configure firewall rules"
Write-Log "Action: $Action"
& $scriptdir\Enable-TSxFirewallStandardRules.ps1

#Configure Eventlogs
$Action = "Configure Eventlogs"
Write-Log "Action: $Action"
$EventLogs = "Application","Security","System"
$MaxSize = 2GB
& $scriptdir\Configure-TSxEventLogs.ps1 -EventLogs $EventLogs -MaxSize $MaxSize

#Custom Code Ends--------------------------------------