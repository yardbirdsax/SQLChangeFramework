# SQLChangeFramework

## LICENSE
-------------
The SQLChangeFramework is copyright 2016 Joshua Feierman, all rights reserved, and is released under the Apache 2.0 license.
  
## REQUIREMENTS
-------------

To run the installation process you must be logged in as a Windows user which is a member of the 'db_owner' database role in the database where the objects will be created.

## INSTALLATION
-------------

Follow these steps to install the Galaxy SQLChangeFramework database objects.

1. Open the Config.txt file in a text editor such as Notepad. The file contains a list of installation variables, listed as "variable"="value". These should be set before running the install.
   
   At a minimum, the following ones should be set:
   
   - DBServer - the name of the database server on which to install the database, including the instance name if a named instance.
   - DBName - the name of the database where the Galaxy ReportsPlus objects are created. This should be the name of your Galaxy database.
2. Open a command prompt at the location where the build resides. The prompt does not need to be opened with admin rights.
3. Run the following command: `powershell -file .\Execute-Install.ps1`. If you receive a warning about the script not being signed you need to set your Powershell execution policy to RemoteSigned or Unrestricted (the former is recommended).

   The build should execute and display a list of files being run. If an error occurs, a message will be printed to the screen directing the user to review the "log.txt" log file in the build directory. This will contain a more detailed error message.