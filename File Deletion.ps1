<#
.SYNOPSIS
This script deletes defined files from targeted folders.

.DESCRIPTION
This script deletes defined files from targeted folders. File names are written by user in '.\File Names.txt' file, and target
folders are written by user in '.\Target Folders.txt' file. User can enter partial names of files in '.\File Names.txt' for example
"*.dat". Script generates detailed log file, '.\File Deletion Log.log', and report that is sent via email to system administrators.

.NOTES
	Version:        1.0
	Author:         Zoran Jankov
	Creation Date:  07.07.2020.
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set error action to silently continue
$ErrorActionPreference = "SilentlyContinue"

#Defining log files
$logfile = '.\File Deletion Log.log'
New-Item -Path '.\Report.log' -ItemType File
$report = '.\Report.txt'

#Defining log title
$logTitle = "=============================== File Deletion PowerShell Script Log ================================"

#Defining log separator
$logSeparator = "===================================================================================================="

#Loading files for deletion
$fileNames = Get-Content -Path '.\File Names.txt'

#Loading target folders for file deletion
$folderPaths = Get-Content -Path '.\Target Folders.txt'

#Mail settings (enter your on mail settings)
$smtp = "smtp.mail.com"
$port = 25
$receiverEmail = "system.administrators@company.com"
$senderEmail = "powershell@company.com"
$subject = "File Deletion Report"
$body = "This is an automated message sent from PowerShell script. File Deletion script has finished executing."

#-----------------------------------------------------------[Functions]------------------------------------------------------------

<#
.SYNOPSIS
Writes a log entry

.DESCRIPTION
Creates a log entry with timestamp and message passed thru a parameter $Massage, and saves the log entry to log file
".\File Deletion Log.log". Timestamp is not written if $Message parameter is defined $logSeparator or a.

.PARAMETER Message
String value to be writen in the log file alongside timestamp

.EXAMPLE
Write-Log -Message "File sorting started"

.NOTES
Format of the timestamp is "yyyy.MM.dd. HH:mm:ss:fff" and this function adds " - " after timestamp and before the main massage.
#>
function Write-Log
{
    param([String]$Message)

	if(($Message -eq $logSeparator) -or ($Message -eq $logTitle))
	{
		Add-content -Path $logfile -Value $$Message
		Add-content -Path $report -Value $$Message
		Write-Output - $Message
	}
	else
	{
		$timestamp = Get-Date -Format "yyyy.MM.dd. HH:mm:ss:fff"
    	$logEntry = $timestamp + " - " + $Message
		Add-content -Path $logfile -Value $logEntry
		Add-content -Path $report -Value $logEntry
		Write-Output - $logEntry
	}
}

<#
.SYNOPSIS
Sends a Report.log file to defined email address

.DESCRIPTION
This function sends a Report.log file as an attachment to defined email address
#>
function Send-Report
{
    Send-MailMessage -SmtpServer $smtp `
                     -Port $port `
                     -To $receiverEmail `
                     -From $senderEmail `
                     -Subject $subject `
                     -Body $body `
                     -Attachments $report

	Remove-Item -Path $report
}

function Remove-FilesInFolder
{
    param([string]$Path)

    $massage = "Attempting to delete files in " + $Path + " folder"
    Write-Log -Message $massage

    foreach($fileName in $fileNames)
    {
        $fullPath = Join-Path -Path $Path -ChildPath $fileName
        $fileList = Get-ChildItem -Path $fullPath
        Remove-Files -FileList $fileList
    }

    $massage = "Successfully finished file deletion in " + $Path + " folder"
    Write-Log -Message $massage
}

function Remove-Files
{
    param($FileList)

    foreach($file in $FileList)
    {
        $massage = "Attempting to delete " + $file.Name + " file"
        Write-Log -Message $massage
        Remove-Item -Path $file.FullName

        if((Test-Path -Path $file.FullName) -eq $true)
        {
            $massage = "Failed to delete " + $file.Name + " file"
			Write-Log -Message $massage
        }
        else
        {
            $massage = "Successfully deleted " + $file.Name + " file"
		    Write-Log -Message $massage
        }
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -Message $logTitle
Write-Log -Message $logSeparator
Write-Log -Message "Started file deletion"

foreach($folderPath in $folderPaths)
{
    $massage = "Attempting to access " + $folderPath + " folder"
    Write-Log -Message $massage

    if((Test-Path -Path $folderPath) -eq $true)
    {
        $massage = "Successfully accessed " + $folderPath + " folder"
        Write-Log -Message $massage
        Remove-FilesInFolder -Path $folderPath
    }
    else
    {
        $massage = "Failed to access " + $folderPath + " folder. It does not exist"
        Write-Log -Message $massage
    }
}

Write-Log -Message "Successfully finished -File Deletion- PowerShell script"
Write-Log -Message $logSeparator

#Sends email with detailed report and deletes temporary ".\Report.txt" file
Send-Report