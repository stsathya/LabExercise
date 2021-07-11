# LabExercise

# Test Case Assumption

Based on given test case, I assume to Run SQL upgradation Script directly within Windows/Linux Server. But I have chosen only Windows Server.
Not exactly sure what queries does your .sql files will contain. So I made list of files with version numbers to update the version table.

My script can only perform minor upgradation within MySql 5.6.x version. Main script will download


# Repo

Please download Repo files from Github. Below are the Files/Folders,

    1. ECSInterview\SQL Folder -> Contains .sql files
    2. ECSInterview\main.ps1 -> This is the main powershell script


# Prerequistics

    1. Windows Server 2016 pre installed with MySql server 5.6.x version. (My script tested only in Windows Server 2016)

    2. Clone Git repo from https://github.com/stsathya/LabExercise.git and copy to MySql installed Server under C:\ drive.

    3. Windows Server should have internet access as my script will download package from MySql product archives directly.

    4. Assuming MySql Database present with 'versionTable' Table with 'version' field. So please make sure its present in the database.


# Execution

Once Prerequistics are ready, execute below command from powershell

Syntax:

    .\main.ps1 -sqlFileDir <directory of .sql> -dbName <db name> -username <db username> -password <db password>

Example:

    .\main.ps1 -sqlFileDir C:\ECSInterview\SQL -dbName menagerie -username root -password test



# Other way through MS Azure

I can achieve the same through Azure services but I didn't get much time. 
This will be a complete automation.

    1. All repo files will be stored in Azure Storage

    2. Create DSC config

    3. Add VM node to DSC config (With the help of Runbook automation we can assign VM to DSC config based on Tag assgining to VM)

Once VM added to DSC then DSC script will copy all repo files to Azure VM and execute main.ps1 directly within VM. It works through internet and no need to provide vm username and password.

To achieve this, we require Azure Resource Group, Storage Account, Event Grid Subscription, Automation Account Runbook and Azure VMs. 

