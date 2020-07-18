
<#
    Modeled after a logger I've used for years; log4j.
#>
function Logger
{
    $obj = New-Object PSObject -Property @{
    
        className = $MyInvocation.MyCommand.Name;
        appenders = @();
        mainLogLevel = 0;
        level = @{DEBUG=0;INFO=1;WARN=2;ERROR=3;FATAL=4};
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name CallAppenders -Value {
    
        param($data,[int]$levelHeight,$levelType);
        
        if($levelHeight -ge $this.mainLogLevel)
        {
            foreach($appender in $this.appenders)
            {
                $appender.log($data,$levelType);
            }    
        }
    
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name debug -Value {
    
        param([string]$data);
        
        $this.CallAppenders($data,$this.level.DEBUG,"DEBUG");
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name info -Value {
    
        param([string]$data);
        
        $this.CallAppenders($data,$this.level.INFO,"INFO");
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name warn -Value {
    
        param([string]$data);
        
        $this.CallAppenders($data,$this.level.WARN,"WARN");
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name error -Value {
    
        param([string]$data);
        
        $this.CallAppenders($data,$this.level.ERROR,"ERROR");
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name fatal -Value {
    
        param([string]$data);
        
        $this.CallAppenders($data,$this.level.FATAL,"FATAL");

    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name load -Value {
    
        param($logFileConfigPath,$logFileName,$logFileChildFolder);
        
        [xml]$config = Get-Content $logFileConfigPath;
        $log4psNode = $config.LOG4PS;
        $defaultLevel = $log4psNode.getAttribute("level");
        $defaultLevel = $defaultLevel.ToUpper();
        
        switch($defaultLevel)
        {
            "DEBUG"{$this.mainLogLevel = $this.level.DEBUG;};
            "INFO"{$this.mainLogLevel = $this.level.INFO;};
            "WARN"{$this.mainLogLevel = $this.level.WARN;};
            "ERROR"{$this.mainLogLevel = $this.level.ERROR;};
            "FATAL"{$this.mainLogLevel = $this.level.FATAL;};            
        };
        
        $appenders = $log4psNode.selectNodes("APPENDER");
        foreach($appender in $appenders)
        {
            $type = $appender.getAttribute("type");
            $name = $appender.getAttribute("name");
            $maxFileSize = $appender.getAttribute("maxFileSize");
            $maxBackupFiles = $appender.getAttribute("maxBackupFiles");
            
            $appenderInstance = & (gi function:$type);
            
            $logFilePath = $logFileConfigPath.replace("\config\log4ps.xml","");
            $logFilePath = $logFilePath + "\logs\";
            
            $appenderInstance.logFileFolder = $logFilePath;            
            if(!$logFileName)
            {
                $appenderInstance.logFileName = $name;
            }
            else
            {
                $appenderInstance.logFileName = $logFileName;
            }
            
            if($logFileChildFolder)
            {
                $appenderInstance.logFileChildFolder = $logFileChildFolder;
            }
                        
            $appenderInstance.maxFileSize = $maxFileSize;
            $appenderInstance.maxBackupFiles = $maxBackupFiles;
            
            $layout = $appender.selectSingleNode("LAYOUT");
            $type = $layout.getAttribute("type");
            $pattern = $layout.getAttribute("pattern");
            
            $layoutInstance = & (gi function:$type);
            $layoutInstance.pattern = $pattern;
            
            $appenderInstance.layout = $layoutInstance;
            
            $appenderInstance.load();
            
            $this.appenders += $appenderInstance;          
        }
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name SendEmail -Value {
    
        param([string]$emailFrom,[string]$emailTo,[string]$smtpServer,[string]$subject,[string]$body);
     
        $smtp = new-object Net.Mail.SmtpClient($smtpServer);
        $smtp.Send($emailFrom, $emailTo, $subject, $body);

    };

    <#
        Function: Destroy
        Purpose: Destructor for the class
            
        Params: none
        Returns: none
    #>
    $obj | Add-Member -MemberType ScriptMethod -Name Destroy -Value {
        
        $this.appenders = $null;
        
    };
        
    <#
        Return object closure
    #>
    return $obj;
}
<#
#>
function PatternLayout
{
    $obj = New-Object PSObject -Property @{
    
        pattern = $null;
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name FormatData -Value {
    
        param($data,$levelType);
        
        $dateString = Get-Date -format dd/MM/yyyy;
        $timeString = Get-Date -format HH:mm:ss;
        $ret = $this.pattern.replace("%d",$dateString);
        $ret = $ret.replace("%t",$timeString);
        $ret = $ret.replace("%lvl",$levelType);
        $ret = $ret.replace("%log_data",$data);
        
        return $ret;
        
    };

    <#
        Function: Destroy
        Purpose: Destructor for the class
            
        Params: none
        Returns: none
    #>
    $obj | Add-Member -MemberType ScriptMethod -Name Destroy -Value {
        
        $this.pattern = $null;
        
    };
        
    <#
        Return object closure
    #>
    return $obj;
}
<#
#>
function RollingFileAppender
{
    $obj = New-Object PSObject -Property @{
    
        logFileName = $null;
        logFileChildFolder = $null;
        logFileFolder = $null;
        backupFolder = $null;
        logFileFullPath = $null;
        maxFileSize = 10000;
        maxBackupFiles = 0;
        layout = $null;
        currentCount = 0;
        currentFileName = $null;
        currentFileSize = 0;
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name load -Value {
    
        <#
            $dateString = Get-Date -format dd\_MM\_yyyy\_HH\_mm\_ss;
        #>
        
        if(!$this.logFileChildFolder)
        {
            $this.logFileFullPath = $this.logFileFolder + $this.logFileName;
        }
        else
        {
            $this.logFileFullPath = $this.logFileFolder + $this.logFileChildFolder + "\" + $this.logFileName;
        }
        
        if(!(Test-Path -path $this.logFileFolder))
        {
            New-Item -path $this.logFileFolder -type directory;
        }
        
        if($this.logFileChildFolder)
        {
            $p = $this.logFileFolder + "\" + $this.logFileChildFolder;
            if(!(Test-Path -path $p))
            {
                New-Item -path $p -type directory;
            }
        }
        
        $this.backupFolder = $this.logFileFolder + "backup";
        if(!(Test-Path -path $this.backupFolder))
        {
            New-Item -path $this.backupFolder -type directory;
        }
        
        if(!(Test-Path -path $this.logFileFullPath))
        {
            New-Item $this.logFileFullPath -type file
        }
        else
        {
            $this.currentFileSize = (Get-ChildItem -path $this.logFileFullPath | Select-Object Length).Length;
        }
        
        $this.currentCount = $this.DetermineCurrentLogCount();
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name DetermineCurrentLogCount -Value {
    
        $currentLogCount = 1;
        
        
        if((Test-Path $this.backupFolder))
        {
            $fileCount = (Get-ChildItem $this.backupFolder | Measure-Object).Count;
            if($fileCount -lt $this.maxBackupFiles)
            {
                $currentLogCount = $fileCount + 1;
            }
        }
        
        return $currentLogCount;
    
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name WeCanLog -Value {
    
        param([int]$dataToLogSize);
        
        $ret = $false;
        $this.currentFileSize = $this.currentFileSize + $dataToLogSize;
        
        if([int]$this.currentFileSize -lt ([int]$this.maxFileSize * 1024)) 
        {
            $ret = $true;
        }
        
        return $ret;
        
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name RollLogFile -Value {
            
        if($this.currentCount -le $this.maxBackupFiles)
        {      
            $ext = "_" + $this.currentCount + ".log";
            $dest = $this.backupFolder + "\" + $this.logFileName.replace(".log",$ext);
            Move-Item $this.logFileFullPath $dest -force;
            
            $this.currentCount++;
        }
        else
        {
            $ext = "_1" + ".log";
            $dest = $this.backupFolder + "\" + $this.logFileName.replace(".log",$ext);
            Move-Item $this.logFileFullPath $dest -force;
            $this.currentCount = 2;
        }
        
        $this.currentFileSize = 0;
    
    };
    
    $obj | Add-Member -MemberType ScriptMethod -Name log -Value {
    
        param($data,$levelType);
        
        $dataToLog = $this.layout.FormatData($data,$levelType);
        
        if(!$this.WeCanLog(($dataToLog.length + 2)))
        {
            $this.RollLogFile();
        }
        
        Add-Content -path $this.logFileFullPath -value $dataToLog;
    
    };
    
    <#
        Function: Destroy
        Purpose: Destructor for the class
            
        Params: none
        Returns: none
    #>
    $obj | Add-Member -MemberType ScriptMethod -Name Destroy -Value {
        
        $this.logFileName = $null;
        $this.logFileChildFolder = $null;
        $this.logFileFolder = $null;
        $this.backupFolder = $null;
        $this.logFileFullPath = $null;
        $this.layout = $null;
        $this.currentFileName = $null;
        
    };
        
    <#
        Return object closure
    #>
    return $obj;
}
