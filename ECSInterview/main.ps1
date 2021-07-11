param(
    [Parameter(Mandatory)]
    $dbName,
    [Parameter(Mandatory)]
    $server,
    [Parameter(Mandatory)]
    $username,
    [Parameter(Mandatory)]
    [SecureString] $password
)

$connString = "database=$dbName;server=$server;Persist Security Info=false;user id=$username;pwd=$password"

function sqlQuery{
    param(
        [Parameter(Mandatory)]
        $query
    )
    $path = Get-ChildItem -Path 'C:\Program Files (x86)\MySQL' -Include MySql.Data.dll -File -Recurse -ErrorAction SilentlyContinue
    $sqlDataPath = "C:\Program Files (x86)\MySQL\"+$path.Directory.Name+"\MySql.Data.dll"
    [void][system.reflection.Assembly]::LoadFrom($sqlDataPath)
    [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
    $myconnection = New-Object MySql.Data.MySqlClient.MySqlConnection
    $myconnection.ConnectionString = $connString
    $myconnection.Open()
    $command = $myconnection.CreateCommand()
    $command.CommandText = $query
    $reader = $command.ExecuteReader()
    if($reader.Read()){
        $sqlVersion = $reader.GetValue(0).ToString()
        if ($sqlVersion){
            $sqlVersion | Out-File -FilePath "C:\temp\version.txt"
        }
    }
}

function sqlUpgrade{
    param(
        $ver
    )
    $verD1 = $ver.Insert(1,'.')
    $verD2 = $verD1.Insert(3,'.')
    $verD3 = $verD2.TrimEnd('.')
    $source = "https://downloads.mysql.com/archives/get/p/23/file/mysql-$verD3-winx64.zip"
    write-host ("Source Link : " + $source)
    $sqlservice = Get-Service -Name "mysql*"
    Stop-Service -Name $sqlservice.Name
    Start-Sleep 10
    [Net.ServicePointManager]::SecurityProtocol =[Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest "https://downloads.mysql.com/archives/get/p/23/file/mysql-$verD3-winx64.zip" -OutFile "C:\MySQL\mysql-$verD3.zip"
    Expand-Archive -LiteralPath "C:\MySQL\mysql-$verD3.zip" -DestinationPath "C:\MySQL"
    #Expand-Archive -LiteralPath "C:\MySQL\mysql-5.7.9.zip" -DestinationPath "C:\MySQL\mysql-5.7.9"
    if($sqlVersion -ge 5.6){
        $dest = "C:\Program Files\MySQL\MySQL Server 5.6"
    }elseif($sqlVersion -ge 5.7){
        $dest = "C:\Program Files\MySQL\MySQL Server 5.7"
    }
    Copy-Item -path "C:\MySQL\mysql-$verD3-winx64\*" -destination $dest -Recurse -Force
    Start-Service -Name $sqlservice.Name
}

$content = "select version();"
$sqlVersion = sqlQuery($content)
$sqlVersionNum = ($sqlVersion -replace '\D+(\d+)\D+','$1').TrimStart('0')
Write-Host "SQl Version: " $sqlVersionNum
$verD1 = $sqlVersionNum.Insert(1,'.')
$verD2 = $verD1.Insert(3,'.')
$verD3 = $verD2.TrimEnd('.')

$list = Get-ChildItem -Path 'C:\SQL' -Recurse | `
        Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -eq '.sql' }
write-host "`nTotal : "$list.Count "files `n"

$i=0
$versionList = @()
$fileNameList = @()

ForEach($n in $list){
    $name = $n.Name
    write-host $name
    $nameNum = ($name.TrimEnd('.')) -replace '\s',''
    $nameNum = ($nameNum -replace '\D+([0-9]*).*','$1').TrimStart('0')
    $numD1 = $nameNum.Insert(1,'.')
    $numD2 = $numD1.Insert(3,'.')
    $numD3 = $numD2.TrimEnd('.')

    if($verD3 -lt $numD3){
        $versionList += $nameNum#,@($nameNum.TrimStart('0'),$name)
        $fileNameList += $name
        $i++
    }
}


do{
    $min = ($versionList | Measure-Object -Minimum).Minimum.ToString()
    Write-host "minumum : " $min
    $index = [array]::indexof($versionList, $min)
    $fileIndex = $fileNameList[$index]
    $content = Get-Content C:\SQL\$fileIndex -Raw;
    sqlUpgrade($min)
    sqlQuery($content)
    $versionList = @($versionList | Where-Object { $_ -ne $min })
    $fileNameList = @($fileNameList | Where-Object { $_ -ne $fileIndex })
    Write-Host "deleted"
    $versionList.Count
    $fileNameList.Count
}Until($versionList.Count -eq 0)
