 
#The below command retrieves the path of the powershell script, splits it and extract the parent path into the variable
$appPath = Split-Path $MyInvocation.MyCommand.Path -Parent


#Read the properties file into a hashmap variable
$AppProps = convertfrom-stringdata (get-content $appPath\appdata.properties -raw)

$today = Get-Date -Format "yyyy.MM.dd hh:mm:ss PM"

$logPath = "$appPath\app.log"
Add-Content -Path $logPath -Value "The beginning of a fresh app running: $today"

#Extract each property into a variable
$source_path = $AppProps.source_path
$source_server = $AppProps.source_server

$dest_os = $AppProps.dest_os
$dest_path =  $AppProps.dest_path
$dest_server =  $AppProps.dest_server
$dest_server_username =  $AppProps.dest_server_username
$dest_server_pwd =  $AppProps.dest_server_pwd

# Removed the dynamic source server IP retrieval as it failed retrival for some servers and thus not a consistent behavior.
#$server_ip =  (Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias Ethernet0).IPAddress

#form the server-specific destination path that the files will be migrated to.
$server_specific_log_path = $dest_path + '/' + $source_server + '/'

#from the target variable that includes the destination server login details and destination path
$target = $dest_server_username + '@' + $dest_server + ':' + $server_specific_log_path


Add-Content -Path $logPath -Value "$target"
Add-Content -Path $logPath -Value "" 


#get all files with the .log extention in the source path and iterates through them
Get-ChildItem $source_path -Filter *.log | 
Foreach-Object {
    $content = $_.FullName
	$d = Get-Date -Format "yyyy.MM.dd"
	
	#check for only ssl-request log files and those files that are not for current date and pushes them to destination server
    if( ($content -like "*ssl_request*" ) -and ( $content -notlike "*$d*" ) )
	{	
		Add-Content -Path $logPath -Value "Attempting the push of the log file : $content"
		
		$migrator_command = '-v', '-r', '-pw', $dest_server_pwd , $content , $target
		
		# Check the destination OS to determine what tool to use for the migration
		if( $dest_os -like "*unix*" )
		{
			Add-Content -Path $logPath -Value "Push file to a unix server..."
			& $appPath\pscp.exe $migrator_command
		}
		else{
			Add-Content -Path $logPath -Value "Push file to a window server..."
		}
		
  
        #The if statement checks the status of the last command executed and uses it to determine deletion of the file
		if($?)
		{
			Add-Content -Path $logPath -Value $?
			Add-Content -Path $logPath -Value 'Push successful...'
            Remove-Item $content -Force
            Add-Content -Path $logPath -Value 'The pushed file is now successfully deleted.'
		}
		else{
			Add-Content -Path $logPath -Value $?
			Add-Content -Path $logPath -Value "Push failed for $content ..."
		}
		
	} 

}


  
