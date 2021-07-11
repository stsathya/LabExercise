param(
    [Parameter(Mandatory)]
    $sqlFileDir,
    [Parameter(Mandatory)]
    $username,
    [Parameter(Mandatory)]
    $dbName,
    [Parameter(Mandatory)]
    $password
)

$connString = "database=$dbName;server=localhost;Persist Security Info=false;user id=$username;pwd=$password"
New-Item -Path 'C:\Demo' -ItemType Directory

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
            return $sqlVersion
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
    sleep 10
    [Net.ServicePointManager]::SecurityProtocol =[Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest "https://downloads.mysql.com/archives/get/p/23/file/mysql-$verD3-winx64.zip" -OutFile "C:\Demo\mysql-$verD3.zip"
    Expand-Archive -LiteralPath "C:\Demo\mysql-$verD3.zip" -DestinationPath "C:\Demo"
    #Expand-Archive -LiteralPath "C:\MySQL\mysql-5.7.9.zip" -DestinationPath "C:\MySQL\mysql-5.7.9"
    if($sqlVersion -ge 5.6){
        $dest = "C:\Program Files\MySQL\MySQL Server 5.6"
    }elseif($sqlVersion -ge 5.7){
        $dest = "C:\Program Files\MySQL\MySQL Server 5.7"
    }
    Copy-Item -path "C:\Demo\mysql-$verD3-winx64\*" -destination $dest -Recurse -Force
    Start-Service -Name $sqlservice.Name
}

$content = "select version();"
$sqlVersion = sqlQuery($content)
$sqlVersionNum = ($sqlVersion -replace '\D+(\d+)\D+','$1').TrimStart('0')
Write-Host "SQl Version: " $sqlVersionNum
$verD1 = $sqlVersionNum.Insert(1,'.')
$verD2 = $verD1.Insert(3,'.')
$verD3 = $verD2.TrimEnd('.')

#Check .SQL file list and make list of versions to upgrade
$list = Get-ChildItem -Path $sqlFileDir -Recurse | `
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
        Write-Host "Higher version available and will continue with upgrade"
        $versionList += $nameNum
        $fileNameList += $name
        $i++
    }
}

#Upgrade loop

do{
    $min = ($versionList | measure -Minimum).Minimum.ToString()
    Write-host "minumum : " $min
    $index = [array]::indexof($versionList, $min)
    $fileIndex = $fileNameList[$index]
    $content = Get-Content $sqlFileDir\$fileIndex -Raw;
    sqlUpgrade($min)
    sqlQuery($content)
    $versionList = @($versionList | Where-Object { $_ -ne $min })
    $fileNameList = @($fileNameList | Where-Object { $_ -ne $fileIndex })
    Write-Host "Upgrade completed"
}Until($versionList.Count -eq 0)
