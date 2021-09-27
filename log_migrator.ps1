
Set-Location "E:\fix\_bio\sw\web_server_log_migrator"

$AppProps = convertfrom-stringdata (get-content ./appdata.properties -raw)

write-host $AppProps

$log_source_path = $AppProps.log_source_path
$log_dest_path =  $AppProps.log_dest_path
$log_server =  $AppProps.log_server
$log_server_username =  $AppProps.log_server_username
$log_server_pwd =  $AppProps.log_server_pwd

$server_ip =  (Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias Ethernet0).IPAddress
$server_specific_log_path = $log_dest_path + '/' + $server_ip + '/'
$target = $log_server_username + '@' + $log_server + ':' + $server_specific_log_path


write-host "$target"
write-host "" 


Get-ChildItem $log_source_path -Filter *.log | 
Foreach-Object {
    $content = $_.FullName
	$d = Get-Date -Format "yyyy.MM.dd"
	
	#check for only ssl-request log files and push to log server
    if( ($content -like "*ssl_request*" ) -and ( $content -notlike "*$d*" ) )
	{	
		write-host "Attempting the push of the log file : $content"
		write-host $target
		$migrator_command = '-v', '-r', '-pw', $log_server_pwd , $content , $target
		& .\pscp.exe $migrator_command
		write-host 'Push successful...'
	} 

}


#($content -like "*access*") -or ($content -like "*ssl_request*" )


pause
 