Func APPISRUNNING ( $APPPATH )
	Local $EXE = StringRegExpReplace ( $APPPATH , ".*\\" , "" )
	Local $LIST = ProcessList ( $EXE )
	For $I = 1 To $LIST [ 0 ] [ 0 ]
		If StringInStr ( GETPROCPATH ( $LIST [ $I ] [ 1 ] ) , $APPPATH ) Then
			Return $LIST [ $I ] [ 1 ]
		EndIf
	Next
	Return 0
EndFunc
Func CHROMEISRUNNING ( $APPPATH = "chrome.exe" , $MSG = "Do you want to close Chrome？" )
	If Not APPISRUNNING ( $APPPATH ) Then Return 0
	$VAR = MsgBox ( 52 , "MyBrowser" , $MSG , 0 , $HSETTINGS )
	If $VAR <> 6 Then Return 1
	$EXE = StringRegExpReplace ( $APPPATH , ".*\\" , "" )
	For $J = 1 To 20
		$LIST = WinList ( "[REGEXPCLASS:(?i)Chrome; REGEXPTITLE:\S+]" )
		For $I = 1 To $LIST [ 0 ] [ 0 ]
			$PID = WinGetProcess ( $LIST [ $I ] [ 1 ] )
			If StringInStr ( GETPROCPATH ( $PID ) , $APPPATH ) Then
				WinClose ( $LIST [ $I ] [ 1 ] )
				WinWaitClose ( $LIST [ $I ] [ 1 ] , "" , 2 )
			EndIf
		Next
		Sleep ( 1000 )
		$LIST = ProcessList ( $EXE )
		For $I = 1 To $LIST [ 0 ] [ 0 ]
			If StringInStr ( GETPROCPATH ( $LIST [ $I ] [ 1 ] ) , $APPPATH ) Then
				ProcessClose ( $LIST [ $I ] [ 1 ] )
			EndIf
		Next
		If Not APPISRUNNING ( $APPPATH ) Then Return 0
	Next
	Return 1
EndFunc
Func HTTPPARSEURL ( $URL )
	Local $HOST , $PAGE , $PORT , $ARESULTS [ 3 ]
	Local $MATCH = StringRegExp ( $URL , "(?i)^https?://([^/]+)(/?.*)" , 1 )
	If @error Then Return SetError ( 1 , 0 , $ARESULTS )
	$ARESULTS [ 0 ] = $MATCH [ 0 ]
	$ARESULTS [ 1 ] = $MATCH [ 1 ]
	If $ARESULTS [ 1 ] = "" Then $ARESULTS [ 1 ] = "/"
	If StringLeft ( $URL , 5 ) = "https" Then
		$ARESULTS [ 2 ] = 443
	Else
		$ARESULTS [ 2 ] = 80
	EndIf
	Return SetError ( 0 , 0 , $ARESULTS )
EndFunc
Func TRAYTIPEXISTS ( $TRAYTEXT , $MATCHMODE = 0 )
	Local $AWINDOWS = WinList ( "[CLASS:tooltips_class32]" )
	Local $I , $HWND , $CLASS , $TEXT
	For $I = 1 To $AWINDOWS [ 0 ] [ 0 ]
		If Not BitAND ( WinGetState ( $AWINDOWS [ $I ] [ 1 ] ) , 2 ) Then ContinueLoop
		$HWND = DllCall ( "user32.dll" , "hwnd" , "GetParent" , "hwnd" , $AWINDOWS [ $I ] [ 1 ] )
		If @error Then Return SetError ( @error , @extended , 0 )
		$CLASS = DllCall ( "user32.dll" , "int" , "GetClassNameW" , "hwnd" , $HWND [ 0 ] , "wstr" , "" , "int" , 1024 )
		If @error Then Return SetError ( @error , @extended , 0 )
		If $CLASS [ 2 ] <> "Shell_TrayWnd" Then ContinueLoop
		$TEXT = WinGetTitle ( $AWINDOWS [ $I ] [ 1 ] )
		If $MATCHMODE = 1 Then
			If StringRegExp ( $TEXT , $TRAYTEXT ) Then Return $AWINDOWS [ $I ] [ 1 ]
		Else
			If StringInStr ( $TEXT , $TRAYTEXT ) Then Return $AWINDOWS [ $I ] [ 1 ]
		EndIf
	Next
EndFunc
Func REDUCEMEMORY ( )
	Local $AI_HANDLE = DllCall ( "kernel32.dll" , "int" , "OpenProcess" , "int" , 2035711 , "int" , False , "int" , @AutoItPID )
	Local $AI_RETURN = DllCall ( "psapi.dll" , "int" , "EmptyWorkingSet" , "long" , $AI_HANDLE [ 0 ] )
	DllCall ( "kernel32.dll" , "int" , "CloseHandle" , "int" , $AI_HANDLE [ 0 ] )
	Return $AI_RETURN [ 0 ]
EndFunc
Func GETPROCPATH ( $PID = @AutoItPID )
	If @OSArch <> "X86" And Not @AutoItX64 And Not _WINAPI_ISWOW64PROCESS ( $PID ) Then
		Local $COLITEMS = ""
		Local $OBJWMISERVICE = ObjGet ( "winmgmts:\\localhost\root\CIMV2" )
		$COLITEMS = $OBJWMISERVICE .ExecQuery ( "SELECT * FROM Win32_Process WHERE ProcessId = " & $PID , "WQL" , 16 + 32 )
		If IsObj ( $COLITEMS ) Then
			For $OBJITEM In $COLITEMS
				If $OBJITEM .ExecutablePath Then Return $OBJITEM .ExecutablePath
			Next
		EndIf
		Return ""
	Else
		Local $HPROCESS = DllCall ( "kernel32.dll" , "ptr" , "OpenProcess" , "dword" , BitOR ( 1024 , 16 ) , "int" , 0 , "dword" , $PID )
		If ( @error ) Or ( Not $HPROCESS [ 0 ] ) Then Return SetError ( 1 , 0 , "" )
		Local $RET = DllCall ( @SystemDir & "\psapi.dll" , "int" , "GetModuleFileNameExW" , "ptr" , $HPROCESS [ 0 ] , "ptr" , 0 , "wstr" , "" , "int" , 1024 )
		If ( @error ) Or ( Not $RET [ 0 ] ) Then Return SetError ( 1 , 0 , "" )
		Return $RET [ 3 ]
	EndIf
EndFunc
Func _ISUACADMIN ( )
	If StringRegExp ( @OSVersion , "_(XP|2003)" ) Or RegRead ( "HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" , "EnableLUA" ) <> 1 Then
		Return SetExtended ( 0 , IsAdmin ( ) )
	EndIf
	Local $HTOKEN = _SECURITY__OPENPROCESSTOKEN ( _WINAPI_GETCURRENTPROCESS ( ) , $TOKEN_QUERY )
	Local $TTI = _SECURITY__GETTOKENINFORMATION ( $HTOKEN , $TOKENGROUPS )
	_WINAPI_CLOSEHANDLE ( $HTOKEN )
	Local $PTI = DllStructGetPtr ( $TTI )
	Local $CBSIDATTR = DllStructGetSize ( DllStructCreate ( "ptr;dword" ) )
	Local $COUNT = DllStructGetData ( DllStructCreate ( "dword" , $PTI ) , 1 )
	Local $PGROUP1 = DllStructGetPtr ( DllStructCreate ( "dword;STRUCT;ptr;dword;ENDSTRUCT" , $PTI ) , 2 )
	Local $TGROUP , $SGROUP = ""
	Local $INADMINGRP = False , $DENYADMIN = False , $ELEVATEDADMIN = False , $SSID
	For $I = 0 To $COUNT - 1
		$TGROUP = DllStructCreate ( "ptr;dword" , $PGROUP1 + ( $CBSIDATTR * $I ) )
		$SSID = _SECURITY__SIDTOSTRINGSID ( DllStructGetData ( $TGROUP , 1 ) )
		If StringInStr ( $SSID , "S-1-5-32-544" ) Then
			$INADMINGRP = True
			If ( BitAND ( DllStructGetData ( $TGROUP , 2 ) , 16 ) = 16 ) Then $DENYADMIN = True
		ElseIf StringInStr ( $SSID , "S-1-16-12288" ) Then
			$ELEVATEDADMIN = True
		EndIf
	Next
	If $INADMINGRP Then
		If $ELEVATEDADMIN Then
			If $DENYADMIN Then
				Return SetExtended ( 0 , 0 )
			Else
				Return SetExtended ( 1 , 1 )
			EndIf
		Else
			Return SetExtended ( 1 , 0 )
		EndIf
	Else
		Return SetExtended ( 0 , 0 )
	EndIf
EndFunc
Func VERSIONCOMPARE ( $V1 , $V2 )
	Local $I , $A1 , $A2 , $RET = 0
	$A1 = StringSplit ( $V1 , "." , 2 )
	$A2 = StringSplit ( $V2 , "." , 2 )
	If UBound ( $A1 ) > UBound ( $A2 ) Then
		ReDim $A2 [ UBound ( $A1 ) ]
	Else
		ReDim $A1 [ UBound ( $A2 ) ]
	EndIf
	For $I = 0 To UBound ( $A1 ) - 1
		$RET = $A1 [ $I ] - $A2 [ $I ]
		If $RET <> 0 Then ExitLoop
	Next
	Return $RET
EndFunc
Func CHECKPREFS ( )
	Local $VAR , $CFG
	Local $PREFS = FileRead ( $USERDATADIR & "\prefs.js" )
	If Not StringRegExp ( $PREFS , "(?i)(?m)^\Quser_pref(""browser.shell.checkDefaultBrowser"",\E *\Qfalse);\E" ) Then
		$CFG &= "pref(""browser.shell.checkDefaultBrowser"", false);" & @CRLF
	EndIf
	$CACHEDIR = FULLPATH ( $CACHEDIR )
	If $CACHEDIR = "" Or $CACHEDIR = $USERDATADIR Then
		If StringInStr ( $PREFS , "user_pref(""browser.cache.disk.parent_directory""," ) Then
			$CFG &= "clearPref(""browser.cache.disk.parent_directory"");" & @CRLF
		EndIf
	Else
		$VAR = StringReplace ( $CACHEDIR , "\" , "\\" )
		If Not StringRegExp ( $PREFS , "(?i)(?m)^\Quser_pref(""browser.cache.disk.parent_directory"",\E *\Q""" & $VAR & """);\E" ) Then
			$CFG &= "pref(""browser.cache.disk.parent_directory"", """ & $VAR & """);" & @CRLF
		EndIf
	EndIf
	If $CACHESIZE = "" Or $CACHESIZE = 250 Then
		If StringInStr ( $PREFS , "user_pref(""browser.cache.disk.capacity""," ) Then
			$CFG &= "clearPref(""browser.cache.disk.capacity"");" & @CRLF
		EndIf
	Else
		$VAR = $CACHESIZE * 1024
		If Not StringRegExp ( $PREFS , "(?i)(?m)^\Quser_pref(""browser.cache.disk.capacity"",\E *\Q" & $VAR & ");\E" ) Then
			$CFG &= "pref(""browser.cache.disk.capacity"", " & $VAR & ");" & @CRLF
		EndIf
	EndIf
	If $CACHESIZESMART = 1 Then
		If StringInStr ( $PREFS , "user_pref(""browser.cache.disk.smart_size.enabled""," ) Then
			$CFG &= "clearPref(""browser.cache.disk.smart_size.enabled"");" & @CRLF
		EndIf
	Else
		If Not StringRegExp ( $PREFS , "(?i)(?m)^\Quser_pref(""browser.cache.disk.smart_size.enabled"",\E *\Qfalse);\E" ) Then
			$CFG &= "pref(""browser.cache.disk.smart_size.enabled"", false);" & @CRLF
		EndIf
	EndIf
	If $CFG Then
		$CFG = "//" & @CRLF & $CFG
	EndIf
	$PREFS = ""
	Return $CFG
EndFunc
Func CHECKFIREFOXPINNEDPROGRAMS ( $BROWSER_PATH )
	If Not FileExists ( $TASKBARDIR ) Then
		Return
	EndIf
	Local $FTIME = FileGetTime ( $TASKBARDIR , 0 , 1 )
	If $FTIME = $TASKBARLASTCHANGE Then
		Return
	EndIf
	$TASKBARLASTCHANGE = $FTIME
	Local $SEARCH = FileFindFirstFile ( $TASKBARDIR & "\*.lnk" )
	If $SEARCH = - 1 Then Return
	Local $FILE , $SHELLOBJ , $OBJSHORTCUT , $SHORTCUT_APPID
	$SHELLOBJ = ObjCreate ( "WScript.Shell" )
	If Not @error Then
		While 1
			$FILE = $TASKBARDIR & "\" & FileFindNextFile ( $SEARCH )
			If @error Then ExitLoop
			$OBJSHORTCUT = $SHELLOBJ .CreateShortCut ( $FILE )
			$PATH = $OBJSHORTCUT .TargetPath
			If $PATH == $BROWSER_PATH Or $PATH == @ScriptFullPath Then
				If $PATH == $BROWSER_PATH Then
					$OBJSHORTCUT .TargetPath = @ScriptFullPath
					$OBJSHORTCUT .Save
					$TASKBARLASTCHANGE = FileGetTime ( $TASKBARDIR , 0 , 1 )
				EndIf
				$SHORTCUT_APPID = _SHORTCUTAPPID ( $FILE )
				If Not $APPUSERMODELID Then
					$APPUSERMODELID = _WINDOWAPPID ( $HWND_BROWSER )
					If Not $APPUSERMODELID Then
						$APPUSERMODELID = APPIDFROMREGISTRY ( )
						If Not $APPUSERMODELID Then
							Local $PID = Run ( $CHROMEDIR & "\uninstall\helper.exe /UpdateShortcutAppUserModelIds" )
							ProcessWaitClose ( $PID , 5 )
							$APPUSERMODELID = APPIDFROMREGISTRY ( )
						EndIf
						If Not $APPUSERMODELID Then
							If $SHORTCUT_APPID Then
								$APPUSERMODELID = $SHORTCUT_APPID
							Else
								$APPUSERMODELID = "MyFirefox." & StringTrimLeft ( _WINAPI_HASHSTRING ( @ScriptFullPath , 0 , 16 ) , 2 )
							EndIf
						EndIf
						_WINDOWAPPID ( $HWND_BROWSER , $APPUSERMODELID )
					EndIf
				EndIf
				If $SHORTCUT_APPID <> $APPUSERMODELID Then
					_SHORTCUTAPPID ( $FILE , $APPUSERMODELID )
					$TASKBARLASTCHANGE = FileGetTime ( $TASKBARDIR , 0 , 1 )
				EndIf
				ExitLoop
			EndIf
		WEnd
		$OBJSHORTCUT = ""
		$SHELLOBJ = ""
	EndIf
	FileClose ( $SEARCH )
EndFunc
Func APPIDFROMREGISTRY ( )
	Local $APPID
	If @OSArch = "X86" Then
		Local $AROOT [ 2 ] = [ "HKCU\SOFTWARE" , $HKLM_SOFTWARE_32 ]
	Else
		Local $AROOT [ 3 ] = [ "HKCU\SOFTWARE" , $HKLM_SOFTWARE_32 , $HKLM_SOFTWARE_64 ]
	EndIf
	For $I = 0 To UBound ( $AROOT ) - 1
		$APPID = RegRead ( $AROOT [ $I ] & "\Mozilla\Firefox\TaskBarIDs" , $CHROMEDIR )
		If $APPID Then ExitLoop
	Next
	Return $APPID
EndFunc
Func FIREFOXCHECKDEFAULTBROWSER ( $BROWSERPATH )
	Local $INTERNETCLIENT , $KEY , $I , $J , $VAR , $REGWRITEERROR = 0
	If Not $CLIENTKEY Then
		If @OSArch = "X86" Then
			Local $AROOT [ 2 ] = [ "HKCU\SOFTWARE" , $HKLM_SOFTWARE_32 ]
		Else
			Local $AROOT [ 3 ] = [ "HKCU\SOFTWARE" , $HKLM_SOFTWARE_32 , $HKLM_SOFTWARE_64 ]
		EndIf
		For $I = 0 To UBound ( $AROOT ) - 1
			$J = 1
			While 1
				$INTERNETCLIENT = RegEnumKey ( $AROOT [ $I ] & "\Clients\StartMenuInternet" , $J )
				If @error <> 0 Then ExitLoop
				$KEY = $AROOT [ $I ] & "\Clients\StartMenuInternet\" & $INTERNETCLIENT
				$VAR = RegRead ( $KEY & "\DefaultIcon" , "" )
				If StringInStr ( $VAR , $BROWSERPATH ) Then
					$CLIENTKEY = $KEY
					$FILEASSO = RegRead ( $CLIENTKEY & "\Capabilities\FileAssociations" , ".html" )
					$URLASSO = RegRead ( $CLIENTKEY & "\Capabilities\URLAssociations" , "http" )
					ExitLoop 2
				EndIf
				$J += 1
			WEnd
		Next
	EndIf
	If $CLIENTKEY Then
		$VAR = RegRead ( $CLIENTKEY & "\shell\open\command" , "" )
		If Not StringInStr ( $VAR , @ScriptFullPath ) Then
			$REGWRITEERROR += Not RegWrite ( $CLIENTKEY & "\shell\open\command" , "" , "REG_SZ" , """" & @ScriptFullPath & """" )
			RegWrite ( $CLIENTKEY & "\shell\properties\command" , "" , "REG_SZ" , """" & @ScriptFullPath & """ -preferences" )
			RegWrite ( $CLIENTKEY & "\shell\safemode\command" , "" , "REG_SZ" , """" & @ScriptFullPath & """ -safe-mode" )
		EndIf
	EndIf
	If Not $FILEASSO Then
		If StringInStr ( RegRead ( "HKCR\FirefoxHTML\DefaultIcon" , "" ) , $BROWSERPATH ) Then
			$FILEASSO = "FirefoxHTML"
		EndIf
	EndIf
	If Not $URLASSO Then
		If StringInStr ( RegRead ( "HKCR\FirefoxURL\DefaultIcon" , "" ) , $BROWSERPATH ) Then
			$URLASSO = "FirefoxURL"
		EndIf
	EndIf
	Local $AASSO [ 2 ] = [ $FILEASSO , $URLASSO ]
	For $I = 0 To 1
		If Not $AASSO [ $I ] Then ContinueLoop
		$VAR = RegRead ( "HKCR\" & $AASSO [ $I ] & "\shell\open\command" , "" )
		If Not StringInStr ( $VAR , @ScriptFullPath ) Then
			$REGWRITEERROR += Not RegWrite ( "HKCR\" & $AASSO [ $I ] & "\shell\open\command" , "" , "REG_SZ" , """" & @ScriptFullPath & """ -url ""%1""" )
			RegDelete ( "HKCR\" & $AASSO [ $I ] & "\shell\open\command" , "DelegateExecute" )
			RegWrite ( "HKCR\" & $AASSO [ $I ] & "\shell\open\ddeexec" , "" , "REG_SZ" , "" )
		EndIf
		If Not $AREG [ 5 + $I ] [ 1 ] Then
			$AREG [ 5 + $I ] [ 1 ] = $AASSO [ $I ]
			$AREG [ 5 + $I ] [ 2 ] = _WINAPI_REGOPENKEY ( $AREG [ 5 + $I ] [ 0 ] , $AREG [ 5 + $I ] [ 1 ] , $KEY_NOTIFY )
		EndIf
	Next
	Local $AURLASSO [ 3 ] = [ "ftp" , "http" , "https" ]
	For $I = 0 To 2
		$VAR = RegRead ( "HKCR\" & $AURLASSO [ $I ] & "\DefaultIcon" , "" )
		If StringInStr ( $VAR , $BROWSERPATH ) Then
			$VAR = RegRead ( "HKCR\" & $AURLASSO [ $I ] & "\shell\open\command" , "" )
			If Not StringInStr ( $VAR , @ScriptFullPath ) Then
				$REGWRITEERROR += Not RegWrite ( "HKCR\" & $AURLASSO [ $I ] & "\shell\open\command" , "" , "REG_SZ" , """" & @ScriptFullPath & """ -url ""%1""" )
				RegDelete ( "HKCR\" & $AURLASSO [ $I ] & "\shell\open\command" , "DelegateExecute" )
				RegWrite ( "HKCR\" & $AURLASSO [ $I ] & "\shell\open\ddeexec" , "" , "REG_SZ" , "" )
			EndIf
		EndIf
	Next
	If $REGWRITEERROR And Not _ISUACADMIN ( ) And @extended Then
		If @Compiled Then
			ShellExecute ( @ScriptName , "-SetDefaultGlobal" , @ScriptDir , "runas" )
		Else
			ShellExecute ( @AutoItExe , """" & @ScriptFullPath & """ -SetDefaultGlobal" , @ScriptDir , "runas" )
		EndIf
	EndIf
EndFunc
Func GETPLUGINSDIR ( )
	Local $DIR = FileSelectFolder ( LANG ( "GUI" , "SaveToPluginsDir" , "指定 Firefox 插件目录" ) , "" , 1 + 4 , @ScriptDir , $HSETTINGS )
	FileChangeDir ( @ScriptDir )
	If $DIR = "" Then Return
	$PLUGINSDIR = RELATIVEPATH ( $DIR )
	GUICtrlSetData ( $HPLUGINSDIR , $PLUGINSDIR )
EndFunc
Func PROFILEINUSE ( $PROFDIR )
	Return FileExists ( $PROFDIR & "\parent.lock" ) And Not FileDelete ( $PROFDIR & "\parent.lock" )
EndFunc
Func CREATECHROMESHORTCUT ( )
	If Not FileExists ( FULLPATH ( $CHROMEPATH ) ) Then
		If StringInStr ( $PLATFORM , "mac" ) Or StringInStr ( $PLATFORM , "linux" ) Or StringInStr ( $PLATFORM , "android" ) Then
		Else
			$LANGCHROMENOTEXISTSTIPS = LANG ( "GUI" , "ChromeNotExistsTips" , "找不到浏览器程序文件： \n%s\n\n请重新设置或者从网络下载！\n需要从网络下载浏览器的最新版本吗？" )
			Local $MSG = MsgBox ( 36 , "MyBrowser" , StringFormat ( $LANGCHROMENOTEXISTSTIPS , $CHROMEPATH ) , 0 , $HSETTINGS )
			If $MSG <> 6 Then
				GUICtrlSetState ( $HCHROMEPATH , $GUI_FOCUS )
				Return SetError ( 1 )
			Else
				GUI_START_END_CHROMEUPDATE ( )
			EndIf
		EndIf
		Return
	EndIf
	Local $TARGETPATH = @ScriptDir & "\" & $APPNAME & ".exe"
	Local $DESKTOPPATH = EnvGet ( "USERPROFILE" ) & "\Desktop\"
	$BROWSERTYPE1 = IniRead ( $INIFILE , "Settings" , "BrowserType" , "" )
	If StringInStr ( $BROWSERTYPE1 , "Chrome" ) Then
		$BROWSERTYPE = "Google Chrome"
	ElseIf StringInStr ( $BROWSERTYPE1 , "Edge" ) Then
		$BROWSERTYPE = "MicroSoft Edge"
	ElseIf StringInStr ( $BROWSERTYPE1 , "Cent" ) Then
		$BROWSERTYPE = "Cent Browser"
	ElseIf StringInStr ( $BROWSERTYPE1 , "Edge" ) Then
		$BROWSERTYPE = "MicroSoft Edge"
	Else
		$BROWSERTYPE = $BROWSERTYPE1
	EndIf
	Local $ICONPATH = FULLPATH ( $CHROMEPATH )
	Local $BATCONTENT = "@echo off" & @CRLF & "(echo Set WshShell=CreateObject(""WScript.Shell""^)" & @CRLF & "echo strDesKtop=WshShell.SpecialFolders(""Desktop""^)" & @CRLF & "echo Set oShellLink=WshShell.CreateShortcut(strDesKtop^&""\" & "" & $BROWSERTYPE & ".lnk""^)" & @CRLF & "echo oShellLink.TargetPath=""" & $TARGETPATH & """" & @CRLF & "echo oShellLink.IconLocation=""" & $ICONPATH & """" & @CRLF & "echo oShellLink.Save)>makelnk.vbs" & @CRLF & "makelnk.vbs" & @CRLF & "del /f /q makelnk.vbs"
	Local $BATFILE = @ScriptDir & "\createshortcut.bat"
	$BINARYDATA = StringToBinary ( $BATCONTENT , 1 )
	$FILEHANDLE = FileOpen ( $BATFILE , 2 )
	FileWrite ( $FILEHANDLE , $BINARYDATA )
	FileClose ( $FILEHANDLE )
	_RUNDOS ( "call " & $BATFILE )
	If @error Then
		MsgBox ( 0 , "Error" , "The batch file did not run successfully: Error code " & @error )
	Else
		FileDelete ( $BATFILE )
	EndIf
EndFunc
Func UPDATEADDONSTARUP ( )
	Local $MOZLZ4EXE , $ADDONSTARUP , $ADDONSTARUPLZ4
	If @OSArch = "X86" Then
		$MOZLZ4EXE = @ScriptDir & "\" & "mozlz4-win32.exe"
		FileInstall ( "mozlz4-win32.exe" , $MOZLZ4EXE )
	Else
		$MOZLZ4EXE = @ScriptDir & "\" & "mozlz4-win64.exe"
		FileInstall ( "mozlz4-win64.exe" , $MOZLZ4EXE )
	EndIf
	$ADDONSTARUPLZ4 = $USERDATADIR & "\addonStartup.json.lz4"
	$ADDONSTARUP = $USERDATADIR & "\addonStartup.json"
	If FileExists ( $ADDONSTARUPLZ4 ) Then
		FileDelete ( $ADDONSTARUP )
		RunWait ( $MOZLZ4EXE & " " & $ADDONSTARUPLZ4 & " " & $ADDONSTARUP , @ScriptDir , @SW_HIDE )
	EndIf
	If FileExists ( $ADDONSTARUP ) Then
		Local $FILEOPEN , $FILECONTENT , $MATCHES
		$FILEOPEN = FileOpen ( $ADDONSTARUP , $FO_READ )
		If $FILEOPEN <> - 1 Then
			$FILECONTENT = FileRead ( $FILEOPEN )
			FileClose ( $FILEOPEN )
			$FILECONTENT = REPLACEJARPATH ( $FILECONTENT )
			$FILEOPEN = FileOpen ( $ADDONSTARUP , $FO_OVERWRITE )
			If $FILEOPEN <> - 1 Then
				FileWrite ( $FILEOPEN , $FILECONTENT )
				FileClose ( $FILEOPEN )
				RunWait ( $MOZLZ4EXE & " -z " & $ADDONSTARUP & " " & $ADDONSTARUPLZ4 , @ScriptDir , @SW_HIDE )
			EndIf
		EndIf
		FileDelete ( $ADDONSTARUP )
	EndIf
	If FileExists ( @ScriptDir & "\" & "mozlz4-win32.exe" ) Then FileDelete ( @ScriptDir & "\" & "mozlz4-win32.exe" )
	If FileExists ( @ScriptDir & "\" & "mozlz4-win64.exe" ) Then FileDelete ( @ScriptDir & "\" & "mozlz4-win64.exe" )
EndFunc
Func REPLACEJARPATH ( $CONTENT )
	Local $MATCHES = StringRegExp ( $CONTENT , "jar:file[^""]+" , $STR_REGEXPARRAYGLOBALMATCH )
	For $I = 0 To UBound ( $MATCHES ) - 1
		Local $PREVPATH = $MATCHES [ $I ]
		Local $TEMPPATH = StringReplace ( $PREVPATH , "jar:file:///" , "" )
		$TEMPPATH = StringReplace ( $TEMPPATH , "!/" , "" )
		Local $DIR , $NAME , $NEWPATH = ""
		FIREFOXSPLITPATH ( $TEMPPATH , $DIR , $NAME , "/" )
		If ( _STRINGENDSWITH ( $DIR , "/browser/features" ) ) Then
			$NEWPATH = "jar:file:///" & $CHROMEPATH & "/browser/features/" & $NAME & "!/"
		EndIf
		If ( _STRINGENDSWITH ( $DIR , "/extensions" ) ) Then
			$NEWPATH = "jar:file:///" & $USERDATADIR & "/extensions/" & $NAME & "!/"
		EndIf
		If $NEWPATH <> "" Then
			$NEWPATH = StringReplace ( $NEWPATH , "\" , "/" )
			$CONTENT = StringReplace ( $CONTENT , $PREVPATH , $NEWPATH )
		EndIf
	Next
	Return $CONTENT
EndFunc
Func UPDATEEXTENSIONSJSON ( )
	Local $EXTENSIONS
	$EXTENSIONS = $USERDATADIR & "\extensions.json"
	If FileExists ( $EXTENSIONS ) Then
		Local $FILEOPEN , $FILECONTENT , $MATCHES
		$FILEOPEN = FileOpen ( $EXTENSIONS , $FO_READ )
		If $FILEOPEN <> - 1 Then
			$FILECONTENT = FileRead ( $FILEOPEN )
			FileClose ( $FILEOPEN )
			$FILECONTENT = REPLACELOCALPATH ( $FILECONTENT )
			$FILEOPEN = FileOpen ( $EXTENSIONS , $FO_OVERWRITE )
			If $FILEOPEN <> - 1 Then
				FileWrite ( $FILEOPEN , $FILECONTENT )
				FileClose ( $FILEOPEN )
			EndIf
		EndIf
	EndIf
EndFunc
Func REPLACELOCALPATH ( $CONTENT )
	Local $MATCHES = StringRegExp ( $CONTENT , """path"":""[^""]+" , $STR_REGEXPARRAYGLOBALMATCH )
	For $I = 0 To UBound ( $MATCHES ) - 1
		Local $PREVPATH = $MATCHES [ $I ]
		$PREVPATH = StringReplace ( $PREVPATH , """path"":""" , "" )
		$PREVPATH = StringReplace ( $PREVPATH , "\\" , "\" )
		Local $DIR , $NAME , $NEWPATH = ""
		FIREFOXSPLITPATH ( $PREVPATH , $DIR , $NAME , "\" )
		If ( _STRINGENDSWITH ( $DIR , "\browser\features" ) ) Then
			$NEWPATH = $CHROMEPATH & "\browser\features\" & $NAME
		EndIf
		If ( _STRINGENDSWITH ( $DIR , "\extensions" ) ) Then
			$NEWPATH = $USERDATADIR & "\extensions\" & $NAME
		EndIf
		If $NEWPATH <> "" Then
			$PREVPATH = StringReplace ( $PREVPATH , "\" , "\\" )
			$NEWPATH = StringReplace ( $NEWPATH , "\" , "\\" )
			$CONTENT = StringReplace ( $CONTENT , "\\\\" , "\\" )
			$CONTENT = StringReplace ( $CONTENT , $PREVPATH , $NEWPATH )
		EndIf
	Next
	Return $CONTENT
EndFunc
Func COUNTUNDERSCORES ( $SSTRING )
	Local $ICOUNT = 0
	Local $IPOS = StringInStr ( $SSTRING , "_" )
	While $IPOS > 0
		$ICOUNT += 1
		$SSTRING = StringTrimLeft ( $SSTRING , $IPOS + 1 )
		$IPOS = StringInStr ( $SSTRING , "_" )
	WEnd
	Return $ICOUNT
EndFunc
