$serverName = "yourhadooponazurecluster.cloudapp.net"; $userName = "yourclusterusername";
$password = "{password}";
$fileToUpload = "t2.txt"; $destination = "/example/data/";
$Md5Hasher = [System.Security.Cryptography.MD5]::Create();
$hashBytes = $Md5Hasher.ComputeHash($([Char[]]$password))
foreach ($byte in $hashBytes) { $passwordHash += "{0:x2}" -f $byte }
$curlCmd = ".\curl -k --ftp-create-dirs -T $fileToUpload -u $userName"
$curlCmd += ":$passwordHash ftps://$serverName" + ":2226$destination"
invoke-expression $curlCmd