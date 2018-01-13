Configuration SQLInstall
{
     Import-DscResource -ModuleName xSQLServer
     Import-DscResource -ModuleName xStorage

     node  $AllNodes.NodeName
     {
        
          WindowsFeature 'NetFramework45'
          {
              Name   = 'NET-Framework-45-Core'
              Ensure = 'Present'
          }

          xMountImage ISO
          {
              ImagePath   = $AllNodes.SqlIsoPath
              DriveLetter = 'S'
              Ensure = 'Present'
          }
      
          xWaitForVolume WaitForISO
          {
              DriveLetter      = 'S'
              RetryIntervalSec = 5
              RetryCount       = 10
          }

          xSQLServerSetup 'InstallSQLServer'
          {               
               InstanceName = 'MSSQLSERVER'
               Features = 'SQLENGINE'
               SourcePath = 's:\'
               SQLSysAdminAccounts = @("aesondev\gaetan")              
               DependsOn = @('[xWaitForVolume]WaitForISO','[WindowsFeature]NetFramework45')
          }         
        

          xSQLServerFirewall firewall {
              Ensure =  'Present'
              InstanceName =  "MSSQLSERVER"
              Features = "SQLENGINE"
              SourcePath = "s:\"
          }
     }
}

   
$path = 'C:\DevOps'
$mofPath = 'C:\DevOps\localhost.mof'
$DSCLogRoot = "$path\DSCLog"
$DscLog = "$DSCLogRoot\SQLServer.txt"
if(!(Test-Path "$DscLog"))
{
    New-Item -ItemType Directory -Path $DscLog
}
Remove-Item $DscLog -Force -ErrorAction Ignore
Start-Transcript -Path $DscLog -Force
if($false -eq (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path -Force
}

  $config = @{
    AllNodes =
    @(
        @{
            NodeName     = 'localhost'
            SqlIsoPath   = "C:\en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso"
        }       
    )
}
  
   SQLInstall -OutputPath $path -ConfigurationData $config
   
   Start-DscConfiguration -Wait -Force -Verbose -Path $path 
   Remove-Item -Path $mofPath -Force -ErrorAction Ignore 
   Stop-Transcript




