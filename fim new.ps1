Import-Module "C:\Users\bmato\Documents\vscode\Mail.ps1"


#$Credentials=Get-Credential
#$Credentials | Export-Clixml -Path "C:\users\bmato\Documents\vscode\EmailCred.xml"
# ^ run this to enter credentials then # it out after entering credentials
$EmailCredentialsPath="C:\users\bmato\Documents\vscode\EmailCred.xml"
$EmailCredentials=Import-Clixml -Path $EmailCredentialsPath
$EmailServer="smtp-mail.outlook.com"
$EmailPort="587"



function Add-Baseline{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baseline
    )
    try{
        if((Test-Path -Path $baseline)){
            Write-Error -Message "$baseline already exists with this name" -ErrorAction Stop
        }
        if($baseline.Substring($baseline.Length-4,4) -ne ".csv"){
            Write-Error -Message "Baseline needs to be .csv file" -ErrorAction Stop
        }
        "path,hash" | Out-File -FilePath $baseline -Force

    }catch{
        Write-Error $_.Exception.Message
    }
}
$baseline=""

function Check-Baseline{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]$baseline,
        [Parameter()]$emailTo
    )

    try{
        if((Test-Path -Path $baseline) -eq $false){
            Write-Error -Message "$baseline does not exist" -ErrorAction Stop
        }
        if($baseline.Substring($baseline.Length-4,4) -ne ".csv"){
            Write-Error -message "$baseline needs to be .csv file" -ErrorAction Stop    
        }

        $baselineFiles=Import-Csv -Path $baseline -Delimiter ","

        foreach($file in $baselineFiles){
            if(Test-Path -Path $file.path){
                $currenthash=Get-FileHash -Path $file.path
                if($currenthash.Hash -eq $file.hash){
                    Write-Output "$($file.path) hash is still the same"
                }else{
                    Write-Output "$($file.path) hash is different, anomaly detected"
                    if($emailTo){
                        Send-MailKitMessage -To $emailTo -From $EmailCredentials.UserName -Subject
                    }
                }
            }else{
                Write-Output "$($file.path) is not found!"
            }
        }  
        }catch{
            Write-Error $_.Exception.Message
    }
}

Write-Host "File Integrity Monitor" 
do{
    Write-Host "Please Select one of the following options or enter quit to quit" 
    Write-Host "1. Set baseline. current baseline is $($baseline)" 
    Write-Host "2. Check file for deviations" 
    Write-Host "3. Check file with email" 
    $entry=Read-Host -Prompt "Please make a selection."

    Switch ($entry){
        "1"{
            $baseline=Read-Host -Prompt "Enter a file path for the baseline"
            if(Test-Path -Path $baseline){
                if($baseline.Substring($baseline.Length-4,4) -eq ".csv"){

                }else{
                    $baseline=""
                    Write-Host "Invalid file path" 
                }
            }else{
                $baseline=""
                Write-Host "invalid file path"
            }
        }
        "2"{
            Check-Baseline -baseline $baseline
        }
        "3"{
            $email=Read-Host -Prompt "Enter the recipetent email"
            Check-Baseline -baseline $baseline -emailTo $email
        }

        "q"{}
        "quit"{}
        default{
            Write-Host "Invalid Entry" 
        }
     }
}while($entry -notin @('q','quit'))

