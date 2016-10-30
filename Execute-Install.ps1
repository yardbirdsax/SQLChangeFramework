[cmdletbinding()]
param
(
    [Parameter(mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [String]
    $InputFile = "BuildInput.txt"
)

$rgxInputFile = New-Object System.Text.RegularExpressions.Regex "([\w\\.]+)([ ]+[\w.]+)?"

# Get the current location of the script
$scriptPath = Split-Path $MyInvocation.MyCommand.Path;

# Set common variables
$logPath = "$scriptPath\log.txt";

# Load configuration variables
if (-not (Test-Path "$scriptPath\Config.txt"))
{
  Write-Warning "Configuration text file 'Config.txt' not found. Exiting."
  return
}

$Configs = Get-Content "$scriptPath\Config.txt" |
            Where-Object {-not ($_ -match "^#") -and ($_ -ne "")}

foreach ($config in $Configs)
{
  $splitConfig = $config.split("=")
  $expression = "`$env:$($splitConfig[0]) = `"$($splitConfig[1])`""
  Write-Verbose $expression
  Invoke-Expression $expression
}

# Instantiate process object
$sqlcmdProcess = New-Object System.Diagnostics.Process;
$sqlcmdProcess.StartInfo.FileName = "sqlcmd.exe";
$sqlcmdProcess.StartInfo.UseShellExecute = $false;
$sqlcmdProcess.StartInfo.RedirectStandardError = $true;
$sqlcmdProcess.StartInfo.RedirectStandardOutput = $true;
$sqlcmdProcess.StartInfo.WorkingDirectory = $scriptPath;
$sqlCmdProcess.StartInfo.RedirectStandardInput = $true;

# Instantiate process object
$bcpProcess = New-Object System.Diagnostics.Process;
$bcpProcess.StartInfo.FileName = "bcp.exe";
$bcpProcess.StartInfo.UseShellExecute = $false;
$bcpProcess.StartInfo.RedirectStandardError = $true;
$bcpProcess.StartInfo.RedirectStandardOutput = $true;
$bcpProcess.StartInfo.WorkingDirectory = $scriptPath;

# Check if log file exists, and if so, delete it
if (Test-Path $logPath) {Remove-Item $logPath -force;}

# Initialize log file
Add-Content $logPath "----------------------------------------------------------------------`n";
Add-Content $logPath " Beginning script execution.`n" -PassThru
Add-Content $logPath " Date: $(Get-Date)`n" -PassThru
Add-Content $logPath "----------------------------------------------------------------------`n";
Add-Content $logPath "`n";

# Get the list of files to execute
$filesToExecute = Get-Content "$scriptPath\$InputFile" |
                    Where-Object {-not ($_ -match "^#")}

# Loop over files and execute
foreach ($line in $filesToExecute)
{
  $match = $rgxInputFile.Match($line);
  $file = $match.Groups[1].Value;
 
  # Check if the file exists
  if (-not (Test-Path "$scriptPath\$file"))
  {
    Write-Warning "Script file '$scriptPath\$file' does not exist. Exiting."
    return
  }
  
  # Execute the file
  Add-Content $logPath "----------------------------------------------------------------------`n" -PassThru
  # if the script file is .SQL
  if ($file -match "\.sql")
  {
      Add-Content $logPath "Beginning execution of script '$scriptPath\$file'." -PassThru
      $sqlcmdArgs = "-i `"$scriptPath\$file`" -b -S $env:DBServer -d $env:DBName -E"
      cmd.exe /c "sqlcmd.exe $sqlcmdArgs >> `"$logPath`" 2>&1";
      #$sqlcmdProcess.Start() | Out-Null;
      #$sqlcmdProcess.StandardInput.WriteLine();
      #$sqlcmdProcess.WaitForExit();
      #Add-Content $logPath $sqlcmdProcess.StandardOutput.ReadToEnd()
      if ($LASTEXITCODE -ne 0) 
      { 
        #Add-Content $logPath $sqlcmdProcess.StandardError.ReadToEnd(); 
        Throw "Error occurred executing script '$scriptPath\$file', please check log.txt file for details."; 
      }
      Add-Content $logPath " Finished execution of script '$scriptPath\$file'." -PassThru
  }
  # if the script is .DAT
  elseif ($file -match "\.DAT")
  {
    $tableName = $match.Groups[2].Value;
    Add-Content $logPath "Beginning bulk insert of file '$scriptPath\$file'." -PassThru
    $bcpProcess.StartInfo.Arguments = "$($env:DBName).$($tableName.Trim()) in `"$($file)`" -S$($env:DBServer) -T -c -t`",`"";
    $bcpProcess.Start() | Out-Null;
    $bcpProcess.WaitForExit();
    Add-Content $logPath $bcpProcess.StandardOutput.ReadToEnd()
    if ($bcpProcess.ExitCode -ne 0) 
    { 
    Add-Content $logPath $bcpProcess.StandardError.ReadToEnd(); 
    Throw "Error occurred bulk inserting file '$scriptPath\$file', please check log.txt file for details."; 
    }
    Add-Content $logPath " Finished bulk insert of file '$scriptPath\$file'." -PassThru    
  }
}