Global Const $MEM_COMMIT = 4096
Global Const $MEM_RESERVE = 8192
Global Const $PAGE_READWRITE = 4
Global Const $MEM_RELEASE = 32768
Global Const $PROCESS_VM_OPERATION = 8
Global Const $PROCESS_VM_READ = 16
Global Const $PROCESS_VM_WRITE = 32
Global Const $SE_PRIVILEGE_ENABLED = 2
Global Enum $SECURITYANONYMOUS = 0 , $SECURITYIDENTIFICATION , $SECURITYIMPERSONATION , $SECURITYDELEGATION
Global Enum $TOKENUSER = 1 , $TOKENGROUPS , $TOKENPRIVILEGES , $TOKENOWNER , $TOKENPRIMARYGROUP , $TOKENDEFAULTDACL , $TOKENSOURCE , $TOKENTYPE , $TOKENIMPERSONATIONLEVEL , $TOKENSTATISTICS , $TOKENRESTRICTEDSIDS , $TOKENSESSIONID , $TOKENGROUPSANDPRIVILEGES , $TOKENSESSIONREFERENCE , $TOKENSANDBOXINERT , $TOKENAUDITPOLICY , $TOKENORIGIN , $TOKENELEVATIONTYPE , $TOKENLINKEDTOKEN , $TOKENELEVATION , $TOKENHASRESTRICTIONS , $TOKENACCESSINFORMATION , $TOKENVIRTUALIZATIONALLOWED , $TOKENVIRTUALIZATIONENABLED , $TOKENINTEGRITYLEVEL , $TOKENUIACCESS , $TOKENMANDATORYPOLICY , $TOKENLOGONSID
Global Const $TOKEN_QUERY = 8
Global Const $TOKEN_ADJUST_PRIVILEGES = 32
Func _WINAPI_GETLASTERROR ( Const $_ICURRENTERROR = @error , Const $_ICURRENTEXTENDED = @extended )
	Local $ARESULT = DllCall ( "kernel32.dll" , "dword" , "GetLastError" )
	Return SetError ( $_ICURRENTERROR , $_ICURRENTEXTENDED , $ARESULT [ 0 ] )
EndFunc
Func _WINAPI_SETLASTERROR ( $IERRORCODE , Const $_ICURRENTERROR = @error , Const $_ICURRENTEXTENDED = @extended )
	DllCall ( "kernel32.dll" , "none" , "SetLastError" , "dword" , $IERRORCODE )
	Return SetError ( $_ICURRENTERROR , $_ICURRENTEXTENDED , Null )
EndFunc
Func _SECURITY__ADJUSTTOKENPRIVILEGES ( $HTOKEN , $BDISABLEALL , $TNEWSTATE , $IBUFFERLEN , $TPREVSTATE = 0 , $PREQUIRED = 0 )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "AdjustTokenPrivileges" , "handle" , $HTOKEN , "bool" , $BDISABLEALL , "struct*" , $TNEWSTATE , "dword" , $IBUFFERLEN , "struct*" , $TPREVSTATE , "struct*" , $PREQUIRED )
	If @error Then Return SetError ( @error , @extended , False )
	Return Not ( $ACALL [ 0 ] = 0 )
EndFunc
Func _SECURITY__GETTOKENINFORMATION ( $HTOKEN , $ICLASS )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "GetTokenInformation" , "handle" , $HTOKEN , "int" , $ICLASS , "struct*" , 0 , "dword" , 0 , "dword*" , 0 )
	If @error Or Not $ACALL [ 5 ] Then Return SetError ( @error + 10 , @extended , 0 )
	Local $ILEN = $ACALL [ 5 ]
	Local $TBUFFER = DllStructCreate ( "byte[" & $ILEN & "]" )
	$ACALL = DllCall ( "advapi32.dll" , "bool" , "GetTokenInformation" , "handle" , $HTOKEN , "int" , $ICLASS , "struct*" , $TBUFFER , "dword" , DllStructGetSize ( $TBUFFER ) , "dword*" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( @error , @extended , 0 )
	Return $TBUFFER
EndFunc
Func _SECURITY__IMPERSONATESELF ( $ILEVEL = $SECURITYIMPERSONATION )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "ImpersonateSelf" , "int" , $ILEVEL )
	If @error Then Return SetError ( @error , @extended , False )
	Return Not ( $ACALL [ 0 ] = 0 )
EndFunc
Func _SECURITY__ISVALIDSID ( $PSID )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "IsValidSid" , "struct*" , $PSID )
	If @error Then Return SetError ( @error , @extended , False )
	Return Not ( $ACALL [ 0 ] = 0 )
EndFunc
Func _SECURITY__LOOKUPPRIVILEGEVALUE ( $SSYSTEM , $SNAME )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "LookupPrivilegeValueW" , "wstr" , $SSYSTEM , "wstr" , $SNAME , "int64*" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( @error , @extended , 0 )
	Return $ACALL [ 3 ]
EndFunc
Func _SECURITY__OPENPROCESSTOKEN ( $HPROCESS , $IACCESS )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "OpenProcessToken" , "handle" , $HPROCESS , "dword" , $IACCESS , "handle*" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( @error , @extended , 0 )
	Return $ACALL [ 3 ]
EndFunc
Func _SECURITY__OPENTHREADTOKEN ( $IACCESS , $HTHREAD = 0 , $BOPENASSELF = False )
	If $HTHREAD = 0 Then
		Local $ARESULT = DllCall ( "kernel32.dll" , "handle" , "GetCurrentThread" )
		If @error Then Return SetError ( @error + 10 , @extended , 0 )
		$HTHREAD = $ARESULT [ 0 ]
	EndIf
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "OpenThreadToken" , "handle" , $HTHREAD , "dword" , $IACCESS , "bool" , $BOPENASSELF , "handle*" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( @error , @extended , 0 )
	Return $ACALL [ 4 ]
EndFunc
Func _SECURITY__OPENTHREADTOKENEX ( $IACCESS , $HTHREAD = 0 , $BOPENASSELF = False )
	Local $HTOKEN = _SECURITY__OPENTHREADTOKEN ( $IACCESS , $HTHREAD , $BOPENASSELF )
	If $HTOKEN = 0 Then
		Local Const $ERROR_NO_TOKEN = 1008
		If _WINAPI_GETLASTERROR ( ) <> $ERROR_NO_TOKEN Then Return SetError ( 20 , _WINAPI_GETLASTERROR ( ) , 0 )
		If Not _SECURITY__IMPERSONATESELF ( ) Then Return SetError ( @error + 10 , _WINAPI_GETLASTERROR ( ) , 0 )
		$HTOKEN = _SECURITY__OPENTHREADTOKEN ( $IACCESS , $HTHREAD , $BOPENASSELF )
		If $HTOKEN = 0 Then Return SetError ( @error , _WINAPI_GETLASTERROR ( ) , 0 )
	EndIf
	Return $HTOKEN
EndFunc
Func _SECURITY__SETPRIVILEGE ( $HTOKEN , $SPRIVILEGE , $BENABLE )
	Local $ILUID = _SECURITY__LOOKUPPRIVILEGEVALUE ( "" , $SPRIVILEGE )
	If $ILUID = 0 Then Return SetError ( @error + 10 , @extended , False )
	Local Const $TAGTOKEN_PRIVILEGES = "dword Count;align 4;int64 LUID;dword Attributes"
	Local $TCURRSTATE = DllStructCreate ( $TAGTOKEN_PRIVILEGES )
	Local $ICURRSTATE = DllStructGetSize ( $TCURRSTATE )
	Local $TPREVSTATE = DllStructCreate ( $TAGTOKEN_PRIVILEGES )
	Local $IPREVSTATE = DllStructGetSize ( $TPREVSTATE )
	Local $TREQUIRED = DllStructCreate ( "int Data" )
	DllStructSetData ( $TCURRSTATE , "Count" , 1 )
	DllStructSetData ( $TCURRSTATE , "LUID" , $ILUID )
	If Not _SECURITY__ADJUSTTOKENPRIVILEGES ( $HTOKEN , False , $TCURRSTATE , $ICURRSTATE , $TPREVSTATE , $TREQUIRED ) Then Return SetError ( 2 , @error , False )
	DllStructSetData ( $TPREVSTATE , "Count" , 1 )
	DllStructSetData ( $TPREVSTATE , "LUID" , $ILUID )
	Local $IATTRIBUTES = DllStructGetData ( $TPREVSTATE , "Attributes" )
	If $BENABLE Then
		$IATTRIBUTES = BitOR ( $IATTRIBUTES , $SE_PRIVILEGE_ENABLED )
	Else
		$IATTRIBUTES = BitAND ( $IATTRIBUTES , BitNOT ( $SE_PRIVILEGE_ENABLED ) )
	EndIf
	DllStructSetData ( $TPREVSTATE , "Attributes" , $IATTRIBUTES )
	If Not _SECURITY__ADJUSTTOKENPRIVILEGES ( $HTOKEN , False , $TPREVSTATE , $IPREVSTATE , $TCURRSTATE , $TREQUIRED ) Then Return SetError ( 3 , @error , False )
	Return True
EndFunc
Func _SECURITY__SIDTOSTRINGSID ( $PSID )
	If Not _SECURITY__ISVALIDSID ( $PSID ) Then Return SetError ( @error + 10 , 0 , "" )
	Local $ACALL = DllCall ( "advapi32.dll" , "bool" , "ConvertSidToStringSidW" , "struct*" , $PSID , "ptr*" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( @error , @extended , "" )
	Local $PSTRINGSID = $ACALL [ 2 ]
	Local $ALEN = DllCall ( "kernel32.dll" , "int" , "lstrlenW" , "struct*" , $PSTRINGSID )
	Local $SSID = DllStructGetData ( DllStructCreate ( "wchar Text[" & $ALEN [ 0 ] + 1 & "]" , $PSTRINGSID ) , "Text" )
	DllCall ( "kernel32.dll" , "handle" , "LocalFree" , "handle" , $PSTRINGSID )
	Return $SSID
EndFunc
Global Const $TAGPOINT = "struct;long X;long Y;endstruct"
Global Const $TAGRECT = "struct;long Left;long Top;long Right;long Bottom;endstruct"
Global Const $TAGREBARBANDINFO = "uint cbSize;uint fMask;uint fStyle;dword clrFore;dword clrBack;ptr lpText;uint cch;" & "int iImage;hwnd hwndChild;uint cxMinChild;uint cyMinChild;uint cx;handle hbmBack;uint wID;uint cyChild;uint cyMaxChild;" & "uint cyIntegral;uint cxIdeal;lparam lParam;uint cxHeader" & ( ( @OSVersion = "WIN_XP" ) ? "" : ";" & $TAGRECT & ";uint uChevronState" )
Global Const $TAGGUID = "struct;ulong Data1;ushort Data2;ushort Data3;byte Data4[8];endstruct"
Global Const $TAGMEMMAP = "handle hProc;ulong_ptr Size;ptr Mem"
Func _MEMFREE ( ByRef $TMEMMAP )
	Local $PMEMORY = DllStructGetData ( $TMEMMAP , "Mem" )
	Local $HPROCESS = DllStructGetData ( $TMEMMAP , "hProc" )
	Local $BRESULT = _MEMVIRTUALFREEEX ( $HPROCESS , $PMEMORY , 0 , $MEM_RELEASE )
	DllCall ( "kernel32.dll" , "bool" , "CloseHandle" , "handle" , $HPROCESS )
	If @error Then Return SetError ( @error , @extended , False )
	Return $BRESULT
EndFunc
Func _MEMINIT ( $HWND , $ISIZE , ByRef $TMEMMAP )
	Local $ARESULT = DllCall ( "user32.dll" , "dword" , "GetWindowThreadProcessId" , "hwnd" , $HWND , "dword*" , 0 )
	If @error Then Return SetError ( @error + 10 , @extended , 0 )
	Local $IPROCESSID = $ARESULT [ 2 ]
	If $IPROCESSID = 0 Then Return SetError ( 1 , 0 , 0 )
	Local $IACCESS = BitOR ( $PROCESS_VM_OPERATION , $PROCESS_VM_READ , $PROCESS_VM_WRITE )
	Local $HPROCESS = __MEM_OPENPROCESS ( $IACCESS , False , $IPROCESSID , True )
	Local $IALLOC = BitOR ( $MEM_RESERVE , $MEM_COMMIT )
	Local $PMEMORY = _MEMVIRTUALALLOCEX ( $HPROCESS , 0 , $ISIZE , $IALLOC , $PAGE_READWRITE )
	If $PMEMORY = 0 Then Return SetError ( 2 , 0 , 0 )
	$TMEMMAP = DllStructCreate ( $TAGMEMMAP )
	DllStructSetData ( $TMEMMAP , "hProc" , $HPROCESS )
	DllStructSetData ( $TMEMMAP , "Size" , $ISIZE )
	DllStructSetData ( $TMEMMAP , "Mem" , $PMEMORY )
	Return $PMEMORY
EndFunc
Func _MEMWRITE ( ByRef $TMEMMAP , $PSRCE , $PDEST = 0 , $ISIZE = 0 , $SSRCE = "struct*" )
	If $PDEST = 0 Then $PDEST = DllStructGetData ( $TMEMMAP , "Mem" )
	If $ISIZE = 0 Then $ISIZE = DllStructGetData ( $TMEMMAP , "Size" )
	Local $ARESULT = DllCall ( "kernel32.dll" , "bool" , "WriteProcessMemory" , "handle" , DllStructGetData ( $TMEMMAP , "hProc" ) , "ptr" , $PDEST , $SSRCE , $PSRCE , "ulong_ptr" , $ISIZE , "ulong_ptr*" , 0 )
	If @error Then Return SetError ( @error , @extended , False )
	Return $ARESULT [ 0 ]
EndFunc
Func _MEMVIRTUALALLOCEX ( $HPROCESS , $PADDRESS , $ISIZE , $IALLOCATION , $IPROTECT )
	Local $ARESULT = DllCall ( "kernel32.dll" , "ptr" , "VirtualAllocEx" , "handle" , $HPROCESS , "ptr" , $PADDRESS , "ulong_ptr" , $ISIZE , "dword" , $IALLOCATION , "dword" , $IPROTECT )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _MEMVIRTUALFREEEX ( $HPROCESS , $PADDRESS , $ISIZE , $IFREETYPE )
	Local $ARESULT = DllCall ( "kernel32.dll" , "bool" , "VirtualFreeEx" , "handle" , $HPROCESS , "ptr" , $PADDRESS , "ulong_ptr" , $ISIZE , "dword" , $IFREETYPE )
	If @error Then Return SetError ( @error , @extended , False )
	Return $ARESULT [ 0 ]
EndFunc
Func __MEM_OPENPROCESS ( $IACCESS , $BINHERIT , $IPROCESSID , $BDEBUGPRIV = False )
	Local $ARESULT = DllCall ( "kernel32.dll" , "handle" , "OpenProcess" , "dword" , $IACCESS , "bool" , $BINHERIT , "dword" , $IPROCESSID )
	If @error Then Return SetError ( @error + 10 , @extended , 0 )
	If $ARESULT [ 0 ] Then Return $ARESULT [ 0 ]
	If Not $BDEBUGPRIV Then Return 0
	Local $HTOKEN = _SECURITY__OPENTHREADTOKENEX ( BitOR ( $TOKEN_ADJUST_PRIVILEGES , $TOKEN_QUERY ) )
	If @error Then Return SetError ( @error + 20 , @extended , 0 )
	_SECURITY__SETPRIVILEGE ( $HTOKEN , "SeDebugPrivilege" , True )
	Local $IERROR = @error
	Local $ILASTERROR = @extended
	Local $IRET = 0
	If Not @error Then
		$ARESULT = DllCall ( "kernel32.dll" , "handle" , "OpenProcess" , "dword" , $IACCESS , "bool" , $BINHERIT , "dword" , $IPROCESSID )
		$IERROR = @error
		$ILASTERROR = @extended
		If $ARESULT [ 0 ] Then $IRET = $ARESULT [ 0 ]
		_SECURITY__SETPRIVILEGE ( $HTOKEN , "SeDebugPrivilege" , False )
		If @error Then
			$IERROR = @error + 30
			$ILASTERROR = @extended
		EndIf
	Else
		$IERROR = @error + 40
	EndIf
	DllCall ( "kernel32.dll" , "bool" , "CloseHandle" , "handle" , $HTOKEN )
	Return SetError ( $IERROR , $ILASTERROR , $IRET )
EndFunc
Global Const $UBOUND_DIMENSIONS = 0
Global Const $UBOUND_COLUMNS = 2
Global Const $MOUSEEVENTF_XDOWN = 128
Global Const $MOUSEEVENTF_XUP = 256
Global Const $FO_READ = 0
Global Const $FO_OVERWRITE = 2
Func _SENDMESSAGE ( $HWND , $IMSG , $WPARAM = 0 , $LPARAM = 0 , $IRETURN = 0 , $WPARAMTYPE = "wparam" , $LPARAMTYPE = "lparam" , $SRETURNTYPE = "lresult" )
	Local $ARESULT = DllCall ( "user32.dll" , $SRETURNTYPE , "SendMessageW" , "hwnd" , $HWND , "uint" , $IMSG , $WPARAMTYPE , $WPARAM , $LPARAMTYPE , $LPARAM )
	If @error Then Return SetError ( @error , @extended , "" )
	If $IRETURN >= 0 And $IRETURN <= 4 Then Return $ARESULT [ $IRETURN ]
	Return $ARESULT
EndFunc
Global Const $STR_REGEXPARRAYGLOBALMATCH = 3
Global Const $HGDI_ERROR = Ptr ( - 1 )
Global Const $INVALID_HANDLE_VALUE = Ptr ( - 1 )
Global Const $WH_MOUSE = 7
Global Const $KF_EXTENDED = 256
Global Const $KF_ALTDOWN = 8192
Global Const $KF_UP = 32768
Global Const $LLKHF_EXTENDED = BitShift ( $KF_EXTENDED , 8 )
Global Const $LLKHF_ALTDOWN = BitShift ( $KF_ALTDOWN , 8 )
Global Const $LLKHF_UP = BitShift ( $KF_UP , 8 )
Global Const $GWL_WNDPROC = 4294967292
Global $__G_AINPROCESS_WINAPI [ 64 ] [ 2 ] = [ [ 0 , 0 ] ]
Func _WINAPI_CALLWINDOWPROC ( $PPREVWNDFUNC , $HWND , $IMSG , $WPARAM , $LPARAM )
	Local $ARESULT = DllCall ( "user32.dll" , "lresult" , "CallWindowProc" , "ptr" , $PPREVWNDFUNC , "hwnd" , $HWND , "uint" , $IMSG , "wparam" , $WPARAM , "lparam" , $LPARAM )
	If @error Then Return SetError ( @error , @extended , - 1 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_CLOSEHANDLE ( $HOBJECT )
	Local $ARESULT = DllCall ( "kernel32.dll" , "bool" , "CloseHandle" , "handle" , $HOBJECT )
	If @error Then Return SetError ( @error , @extended , False )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_CREATEEVENT ( $TATTRIBUTES = 0 , $BMANUALRESET = True , $BINITIALSTATE = True , $SNAME = "" )
	Local $SNAMETYPE = "wstr"
	If $SNAME = "" Then
		$SNAME = 0
		$SNAMETYPE = "ptr"
	EndIf
	Local $ARESULT = DllCall ( "kernel32.dll" , "handle" , "CreateEventW" , "struct*" , $TATTRIBUTES , "bool" , $BMANUALRESET , "bool" , $BINITIALSTATE , $SNAMETYPE , $SNAME )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_CREATEWINDOWEX ( $IEXSTYLE , $SCLASS , $SNAME , $ISTYLE , $IX , $IY , $IWIDTH , $IHEIGHT , $HPARENT , $HMENU = 0 , $HINSTANCE = 0 , $PPARAM = 0 )
	If $HINSTANCE = 0 Then $HINSTANCE = _WINAPI_GETMODULEHANDLE ( "" )
	Local $ARESULT = DllCall ( "user32.dll" , "hwnd" , "CreateWindowExW" , "dword" , $IEXSTYLE , "wstr" , $SCLASS , "wstr" , $SNAME , "dword" , $ISTYLE , "int" , $IX , "int" , $IY , "int" , $IWIDTH , "int" , $IHEIGHT , "hwnd" , $HPARENT , "handle" , $HMENU , "handle" , $HINSTANCE , "struct*" , $PPARAM )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_FREELIBRARY ( $HMODULE )
	Local $ARESULT = DllCall ( "kernel32.dll" , "bool" , "FreeLibrary" , "handle" , $HMODULE )
	If @error Then Return SetError ( @error , @extended , False )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_GETCLASSNAME ( $HWND )
	If Not IsHWnd ( $HWND ) Then $HWND = GUICtrlGetHandle ( $HWND )
	Local $ARESULT = DllCall ( "user32.dll" , "int" , "GetClassNameW" , "hwnd" , $HWND , "wstr" , "" , "int" , 4096 )
	If @error Or Not $ARESULT [ 0 ] Then Return SetError ( @error , @extended , "" )
	Return SetExtended ( $ARESULT [ 0 ] , $ARESULT [ 2 ] )
EndFunc
Func _WINAPI_GETCURRENTPROCESS ( )
	Local $ARESULT = DllCall ( "kernel32.dll" , "handle" , "GetCurrentProcess" )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_GETMODULEHANDLE ( $SMODULENAME )
	Local $SMODULENAMETYPE = "wstr"
	If $SMODULENAME = "" Then
		$SMODULENAME = 0
		$SMODULENAMETYPE = "ptr"
	EndIf
	Local $ARESULT = DllCall ( "kernel32.dll" , "handle" , "GetModuleHandleW" , $SMODULENAMETYPE , $SMODULENAME )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_GETPROCADDRESS ( $HMODULE , $VNAME )
	Local $STYPE = "str"
	If IsNumber ( $VNAME ) Then $STYPE = "word"
	Local $ARESULT = DllCall ( "kernel32.dll" , "ptr" , "GetProcAddress" , "handle" , $HMODULE , $STYPE , $VNAME )
	If @error Or Not $ARESULT [ 0 ] Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_GETWINDOWTHREADPROCESSID ( $HWND , ByRef $IPID )
	Local $ARESULT = DllCall ( "user32.dll" , "dword" , "GetWindowThreadProcessId" , "hwnd" , $HWND , "dword*" , 0 )
	If @error Then Return SetError ( @error , @extended , 0 )
	$IPID = $ARESULT [ 2 ]
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_GUIDFROMSTRING ( $SGUID )
	Local $TGUID = DllStructCreate ( $TAGGUID )
	_WINAPI_GUIDFROMSTRINGEX ( $SGUID , $TGUID )
	If @error Then Return SetError ( @error + 10 , @extended , 0 )
	Return $TGUID
EndFunc
Func _WINAPI_GUIDFROMSTRINGEX ( $SGUID , $TGUID )
	Local $ARESULT = DllCall ( "ole32.dll" , "long" , "CLSIDFromString" , "wstr" , $SGUID , "struct*" , $TGUID )
	If @error Then Return SetError ( @error , @extended , False )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_INPROCESS ( $HWND , ByRef $HLASTWND )
	If $HWND = $HLASTWND Then Return True
	For $II = $__G_AINPROCESS_WINAPI [ 0 ] [ 0 ] To 1 Step - 1
		If $HWND = $__G_AINPROCESS_WINAPI [ $II ] [ 0 ] Then
			If $__G_AINPROCESS_WINAPI [ $II ] [ 1 ] Then
				$HLASTWND = $HWND
				Return True
			Else
				Return False
			EndIf
		EndIf
	Next
	Local $IPID
	_WINAPI_GETWINDOWTHREADPROCESSID ( $HWND , $IPID )
	Local $ICOUNT = $__G_AINPROCESS_WINAPI [ 0 ] [ 0 ] + 1
	If $ICOUNT >= 64 Then $ICOUNT = 1
	$__G_AINPROCESS_WINAPI [ 0 ] [ 0 ] = $ICOUNT
	$__G_AINPROCESS_WINAPI [ $ICOUNT ] [ 0 ] = $HWND
	$__G_AINPROCESS_WINAPI [ $ICOUNT ] [ 1 ] = ( $IPID = @AutoItPID )
	Return $__G_AINPROCESS_WINAPI [ $ICOUNT ] [ 1 ]
EndFunc
Func _WINAPI_LOADLIBRARY ( $SFILENAME )
	Local $ARESULT = DllCall ( "kernel32.dll" , "handle" , "LoadLibraryW" , "wstr" , $SFILENAME )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_MAKELONG ( $ILO , $IHI )
	Return BitOR ( BitShift ( $IHI , - 16 ) , BitAND ( $ILO , 65535 ) )
EndFunc
Func _WINAPI_MOUSE_EVENT ( $IFLAGS , $IX = 0 , $IY = 0 , $IDATA = 0 , $IEXTRAINFO = 0 )
	DllCall ( "user32.dll" , "none" , "mouse_event" , "dword" , $IFLAGS , "dword" , $IX , "dword" , $IY , "dword" , $IDATA , "ulong_ptr" , $IEXTRAINFO )
	If @error Then Return SetError ( @error , @extended )
EndFunc
Func _WINAPI_SETWINDOWLONG ( $HWND , $IINDEX , $IVALUE )
	_WINAPI_SETLASTERROR ( 0 )
	Local $SFUNCNAME = "SetWindowLongW"
	If @AutoItX64 Then $SFUNCNAME = "SetWindowLongPtrW"
	Local $ARESULT = DllCall ( "user32.dll" , "long_ptr" , $SFUNCNAME , "hwnd" , $HWND , "int" , $IINDEX , "long_ptr" , $IVALUE )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_SETWINDOWSHOOKEX ( $IHOOK , $PPROC , $HDLL , $ITHREADID = 0 )
	Local $ARESULT = DllCall ( "user32.dll" , "handle" , "SetWindowsHookEx" , "int" , $IHOOK , "ptr" , $PPROC , "handle" , $HDLL , "dword" , $ITHREADID )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_STRINGLENW ( Const ByRef $TSTRING )
	Local $ARESULT = DllCall ( "kernel32.dll" , "int" , "lstrlenW" , "struct*" , $TSTRING )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_UNHOOKWINDOWSHOOKEX ( $HHOOK )
	Local $ARESULT = DllCall ( "user32.dll" , "bool" , "UnhookWindowsHookEx" , "handle" , $HHOOK )
	If @error Then Return SetError ( @error , @extended , False )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_WAITFORSINGLEOBJECT ( $HHANDLE , $ITIMEOUT = - 1 )
	Local $ARESULT = DllCall ( "kernel32.dll" , "INT" , "WaitForSingleObject" , "handle" , $HHANDLE , "dword" , $ITIMEOUT )
	If @error Then Return SetError ( @error , @extended , - 1 )
	Return $ARESULT [ 0 ]
EndFunc
Func _WINAPI_WINDOWFROMPOINT ( ByRef $TPOINT )
	Local $ARESULT = DllCall ( "user32.dll" , "hwnd" , "WindowFromPoint" , "struct" , $TPOINT )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $ARESULT [ 0 ]
EndFunc
Global Const $TAGOSVERSIONINFO = "struct;dword OSVersionInfoSize;dword MajorVersion;dword MinorVersion;dword BuildNumber;dword PlatformId;wchar CSDVersion[128];endstruct"
Global Const $__WINVER = __WINVER ( )
Func _WINAPI_ISWOW64PROCESS ( $IPID = 0 )
	If Not $IPID Then $IPID = @AutoItPID
	Local $HPROCESS = DllCall ( "kernel32.dll" , "handle" , "OpenProcess" , "dword" , __IIF ( $__WINVER < 1536 , 1024 , 4096 ) , "bool" , 0 , "dword" , $IPID )
	If @error Or Not $HPROCESS [ 0 ] Then Return SetError ( @error + 20 , @extended , False )
	Local $ARET = DllCall ( "kernel32.dll" , "bool" , "IsWow64Process" , "handle" , $HPROCESS [ 0 ] , "bool*" , 0 )
	If __CHECKERRORCLOSEHANDLE ( $ARET , $HPROCESS [ 0 ] ) Then Return SetError ( @error , @extended , False )
	Return $ARET [ 2 ]
EndFunc
Func __CHECKERRORCLOSEHANDLE ( $ARET , $HFILE , $BLASTERROR = 0 , $ICURERR = @error , $ICUREXT = @extended )
	If Not $ICURERR And Not $ARET [ 0 ] Then $ICURERR = 10
	Local $ILASTERROR = _WINAPI_GETLASTERROR ( )
	DllCall ( "kernel32.dll" , "bool" , "CloseHandle" , "handle" , $HFILE )
	If $ICURERR Then _WINAPI_SETLASTERROR ( $ILASTERROR )
	If $BLASTERROR Then $ICUREXT = $ILASTERROR
	Return SetError ( $ICURERR , $ICUREXT , $ICURERR )
EndFunc
Func __IIF ( $BTEST , $VTRUE , $VFALSE )
	Return $BTEST ? $VTRUE : $VFALSE
EndFunc
Func __WINVER ( )
	Local $TOSVI = DllStructCreate ( $TAGOSVERSIONINFO )
	DllStructSetData ( $TOSVI , 1 , DllStructGetSize ( $TOSVI ) )
	Local $ARET = DllCall ( "kernel32.dll" , "bool" , "GetVersionExW" , "struct*" , $TOSVI )
	If @error Or Not $ARET [ 0 ] Then Return SetError ( @error , @extended , 0 )
	Return BitOR ( BitShift ( DllStructGetData ( $TOSVI , 2 ) , - 8 ) , DllStructGetData ( $TOSVI , 3 ) )
EndFunc
Func _DATEDIFF ( $STYPE , $SSTARTDATE , $SENDDATE )
	$STYPE = StringLeft ( $STYPE , 1 )
	If StringInStr ( "d,m,y,w,h,n,s" , $STYPE ) = 0 Or $STYPE = "" Then
		Return SetError ( 1 , 0 , 0 )
	EndIf
	If Not _DATEISVALID ( $SSTARTDATE ) Then
		Return SetError ( 2 , 0 , 0 )
	EndIf
	If Not _DATEISVALID ( $SENDDATE ) Then
		Return SetError ( 3 , 0 , 0 )
	EndIf
	Local $ASSTARTDATEPART [ 4 ] , $ASSTARTTIMEPART [ 4 ] , $ASENDDATEPART [ 4 ] , $ASENDTIMEPART [ 4 ]
	_DATETIMESPLIT ( $SSTARTDATE , $ASSTARTDATEPART , $ASSTARTTIMEPART )
	_DATETIMESPLIT ( $SENDDATE , $ASENDDATEPART , $ASENDTIMEPART )
	Local $ADAYSDIFF = _DATETODAYVALUE ( $ASENDDATEPART [ 1 ] , $ASENDDATEPART [ 2 ] , $ASENDDATEPART [ 3 ] ) - _DATETODAYVALUE ( $ASSTARTDATEPART [ 1 ] , $ASSTARTDATEPART [ 2 ] , $ASSTARTDATEPART [ 3 ] )
	Local $ITIMEDIFF , $IYEARDIFF , $ISTARTTIMEINSECS , $IENDTIMEINSECS
	If $ASSTARTTIMEPART [ 0 ] > 1 And $ASENDTIMEPART [ 0 ] > 1 Then
		$ISTARTTIMEINSECS = $ASSTARTTIMEPART [ 1 ] * 3600 + $ASSTARTTIMEPART [ 2 ] * 60 + $ASSTARTTIMEPART [ 3 ]
		$IENDTIMEINSECS = $ASENDTIMEPART [ 1 ] * 3600 + $ASENDTIMEPART [ 2 ] * 60 + $ASENDTIMEPART [ 3 ]
		$ITIMEDIFF = $IENDTIMEINSECS - $ISTARTTIMEINSECS
		If $ITIMEDIFF < 0 Then
			$ADAYSDIFF = $ADAYSDIFF - 1
			$ITIMEDIFF = $ITIMEDIFF + 24 * 60 * 60
		EndIf
	Else
		$ITIMEDIFF = 0
	EndIf
	Select
	Case $STYPE = "d"
		Return $ADAYSDIFF
	Case $STYPE = "m"
		$IYEARDIFF = $ASENDDATEPART [ 1 ] - $ASSTARTDATEPART [ 1 ]
		Local $IMONTHDIFF = $ASENDDATEPART [ 2 ] - $ASSTARTDATEPART [ 2 ] + $IYEARDIFF * 12
		If $ASENDDATEPART [ 3 ] < $ASSTARTDATEPART [ 3 ] Then $IMONTHDIFF = $IMONTHDIFF - 1
		$ISTARTTIMEINSECS = $ASSTARTTIMEPART [ 1 ] * 3600 + $ASSTARTTIMEPART [ 2 ] * 60 + $ASSTARTTIMEPART [ 3 ]
		$IENDTIMEINSECS = $ASENDTIMEPART [ 1 ] * 3600 + $ASENDTIMEPART [ 2 ] * 60 + $ASENDTIMEPART [ 3 ]
		$ITIMEDIFF = $IENDTIMEINSECS - $ISTARTTIMEINSECS
		If $ASENDDATEPART [ 3 ] = $ASSTARTDATEPART [ 3 ] And $ITIMEDIFF < 0 Then $IMONTHDIFF = $IMONTHDIFF - 1
		Return $IMONTHDIFF
	Case $STYPE = "y"
		$IYEARDIFF = $ASENDDATEPART [ 1 ] - $ASSTARTDATEPART [ 1 ]
		If $ASENDDATEPART [ 2 ] < $ASSTARTDATEPART [ 2 ] Then $IYEARDIFF = $IYEARDIFF - 1
		If $ASENDDATEPART [ 2 ] = $ASSTARTDATEPART [ 2 ] And $ASENDDATEPART [ 3 ] < $ASSTARTDATEPART [ 3 ] Then $IYEARDIFF = $IYEARDIFF - 1
		$ISTARTTIMEINSECS = $ASSTARTTIMEPART [ 1 ] * 3600 + $ASSTARTTIMEPART [ 2 ] * 60 + $ASSTARTTIMEPART [ 3 ]
		$IENDTIMEINSECS = $ASENDTIMEPART [ 1 ] * 3600 + $ASENDTIMEPART [ 2 ] * 60 + $ASENDTIMEPART [ 3 ]
		$ITIMEDIFF = $IENDTIMEINSECS - $ISTARTTIMEINSECS
		If $ASENDDATEPART [ 2 ] = $ASSTARTDATEPART [ 2 ] And $ASENDDATEPART [ 3 ] = $ASSTARTDATEPART [ 3 ] And $ITIMEDIFF < 0 Then $IYEARDIFF = $IYEARDIFF - 1
		Return $IYEARDIFF
	Case $STYPE = "w"
		Return Int ( $ADAYSDIFF / 7 )
	Case $STYPE = "h"
		Return $ADAYSDIFF * 24 + Int ( $ITIMEDIFF / 3600 )
	Case $STYPE = "n"
		Return $ADAYSDIFF * 24 * 60 + Int ( $ITIMEDIFF / 60 )
	Case $STYPE = "s"
		Return $ADAYSDIFF * 24 * 60 * 60 + $ITIMEDIFF
	EndSelect
EndFunc
Func _DATEISLEAPYEAR ( $IYEAR )
	If StringIsInt ( $IYEAR ) Then
		Select
		Case Mod ( $IYEAR , 4 ) = 0 And Mod ( $IYEAR , 100 ) <> 0
			Return 1
		Case Mod ( $IYEAR , 400 ) = 0
			Return 1
	Case Else
			Return 0
		EndSelect
	EndIf
	Return SetError ( 1 , 0 , 0 )
EndFunc
Func _DATEISVALID ( $SDATE )
	Local $ASDATEPART [ 4 ] , $ASTIMEPART [ 4 ]
	_DATETIMESPLIT ( $SDATE , $ASDATEPART , $ASTIMEPART )
	If Not StringIsInt ( $ASDATEPART [ 1 ] ) Then Return 0
	If Not StringIsInt ( $ASDATEPART [ 2 ] ) Then Return 0
	If Not StringIsInt ( $ASDATEPART [ 3 ] ) Then Return 0
	$ASDATEPART [ 1 ] = Int ( $ASDATEPART [ 1 ] )
	$ASDATEPART [ 2 ] = Int ( $ASDATEPART [ 2 ] )
	$ASDATEPART [ 3 ] = Int ( $ASDATEPART [ 3 ] )
	Local $INUMDAYS = _DAYSINMONTH ( $ASDATEPART [ 1 ] )
	If $ASDATEPART [ 1 ] < 1000 Or $ASDATEPART [ 1 ] > 2999 Then Return 0
	If $ASDATEPART [ 2 ] < 1 Or $ASDATEPART [ 2 ] > 12 Then Return 0
	If $ASDATEPART [ 3 ] < 1 Or $ASDATEPART [ 3 ] > $INUMDAYS [ $ASDATEPART [ 2 ] ] Then Return 0
	If $ASTIMEPART [ 0 ] < 1 Then Return 1
	If $ASTIMEPART [ 0 ] < 2 Then Return 0
	If $ASTIMEPART [ 0 ] = 2 Then $ASTIMEPART [ 3 ] = "00"
	If Not StringIsInt ( $ASTIMEPART [ 1 ] ) Then Return 0
	If Not StringIsInt ( $ASTIMEPART [ 2 ] ) Then Return 0
	If Not StringIsInt ( $ASTIMEPART [ 3 ] ) Then Return 0
	$ASTIMEPART [ 1 ] = Int ( $ASTIMEPART [ 1 ] )
	$ASTIMEPART [ 2 ] = Int ( $ASTIMEPART [ 2 ] )
	$ASTIMEPART [ 3 ] = Int ( $ASTIMEPART [ 3 ] )
	If $ASTIMEPART [ 1 ] < 0 Or $ASTIMEPART [ 1 ] > 23 Then Return 0
	If $ASTIMEPART [ 2 ] < 0 Or $ASTIMEPART [ 2 ] > 59 Then Return 0
	If $ASTIMEPART [ 3 ] < 0 Or $ASTIMEPART [ 3 ] > 59 Then Return 0
	Return 1
EndFunc
Func _DATETIMESPLIT ( $SDATE , ByRef $ADATEPART , ByRef $ITIMEPART )
	Local $SDATETIME = StringSplit ( $SDATE , " T" )
	If $SDATETIME [ 0 ] > 0 Then $ADATEPART = StringSplit ( $SDATETIME [ 1 ] , "/-." )
	If $SDATETIME [ 0 ] > 1 Then
		$ITIMEPART = StringSplit ( $SDATETIME [ 2 ] , ":" )
		If UBound ( $ITIMEPART ) < 4 Then ReDim $ITIMEPART [ 4 ]
	Else
		Dim $ITIMEPART [ 4 ]
	EndIf
	If UBound ( $ADATEPART ) < 4 Then ReDim $ADATEPART [ 4 ]
	For $X = 1 To 3
		If StringIsInt ( $ADATEPART [ $X ] ) Then
			$ADATEPART [ $X ] = Int ( $ADATEPART [ $X ] )
		Else
			$ADATEPART [ $X ] = - 1
		EndIf
		If StringIsInt ( $ITIMEPART [ $X ] ) Then
			$ITIMEPART [ $X ] = Int ( $ITIMEPART [ $X ] )
		Else
			$ITIMEPART [ $X ] = 0
		EndIf
	Next
	Return 1
EndFunc
Func _DATETODAYVALUE ( $IYEAR , $IMONTH , $IDAY )
	If Not _DATEISVALID ( StringFormat ( "%04d/%02d/%02d" , $IYEAR , $IMONTH , $IDAY ) ) Then
		Return SetError ( 1 , 0 , "" )
	EndIf
	If $IMONTH < 3 Then
		$IMONTH = $IMONTH + 12
		$IYEAR = $IYEAR - 1
	EndIf
	Local $I_FACTORA = Int ( $IYEAR / 100 )
	Local $I_FACTORB = Int ( $I_FACTORA / 4 )
	Local $I_FACTORC = 2 - $I_FACTORA + $I_FACTORB
	Local $I_FACTORE = Int ( 1461 * ( $IYEAR + 4716 ) / 4 )
	Local $I_FACTORF = Int ( 153 * ( $IMONTH + 1 ) / 5 )
	Local $IJULIANDATE = $I_FACTORC + $IDAY + $I_FACTORE + $I_FACTORF - 1524.5
	Return $IJULIANDATE
EndFunc
Func _NOWCALC ( )
	Return @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
EndFunc
Func _DAYSINMONTH ( $IYEAR )
	Local $ADAYS = [ 12 , 31 , ( _DATEISLEAPYEAR ( $IYEAR ) ? 29 : 28 ) , 31 , 30 , 31 , 30 , 31 , 31 , 30 , 31 , 30 , 31 ]
	Return $ADAYS
EndFunc
Global Const $TRAY_EVENT_PRIMARYDOWN = - 7
Global Const $GUI_EVENT_CLOSE = - 3
Global Const $GUI_CHECKED = 1
Global Const $GUI_UNCHECKED = 4
Global Const $GUI_ENABLE = 64
Global Const $GUI_DISABLE = 128
Global Const $GUI_FOCUS = 256
Global Const $ES_AUTOVSCROLL = 64
Global Const $ES_AUTOHSCROLL = 128
Global Const $ES_WANTRETURN = 4096
Global Const $ES_NUMBER = 8192
Global Const $CBS_DROPDOWNLIST = 3
Global Const $CB_GETCOMBOBOXINFO = 356
Global Const $CB_SELECTSTRING = 333
Global Const $CB_SETEDITSEL = 322
Global Const $_UDF_GLOBALIDS_OFFSET = 2
Global Const $_UDF_GLOBALID_MAX_WIN = 16
Global Const $_UDF_STARTID = 10000
Global Const $_UDF_GLOBALID_MAX_IDS = 55535
Global Const $__UDFGUICONSTANT_WS_VISIBLE = 268435456
Global Const $__UDFGUICONSTANT_WS_CHILD = 1073741824
Global $__G_AUDF_GLOBALIDS_USED [ $_UDF_GLOBALID_MAX_WIN ] [ $_UDF_GLOBALID_MAX_IDS + $_UDF_GLOBALIDS_OFFSET + 1 ]
Func __UDF_GETNEXTGLOBALID ( $HWND )
	Local $NCTRLID , $IUSEDINDEX = - 1 , $BALLUSED = True
	If Not WinExists ( $HWND ) Then Return SetError ( - 1 , - 1 , 0 )
	For $IINDEX = 0 To $_UDF_GLOBALID_MAX_WIN - 1
		If $__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 0 ] <> 0 Then
			If Not WinExists ( $__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 0 ] ) Then
				For $X = 0 To UBound ( $__G_AUDF_GLOBALIDS_USED , $UBOUND_COLUMNS ) - 1
					$__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ $X ] = 0
				Next
				$__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 1 ] = $_UDF_STARTID
				$BALLUSED = False
			EndIf
		EndIf
	Next
	For $IINDEX = 0 To $_UDF_GLOBALID_MAX_WIN - 1
		If $__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 0 ] = $HWND Then
			$IUSEDINDEX = $IINDEX
			ExitLoop
		EndIf
	Next
	If $IUSEDINDEX = - 1 Then
		For $IINDEX = 0 To $_UDF_GLOBALID_MAX_WIN - 1
			If $__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 0 ] = 0 Then
				$__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 0 ] = $HWND
				$__G_AUDF_GLOBALIDS_USED [ $IINDEX ] [ 1 ] = $_UDF_STARTID
				$BALLUSED = False
				$IUSEDINDEX = $IINDEX
				ExitLoop
			EndIf
		Next
	EndIf
	If $IUSEDINDEX = - 1 And $BALLUSED Then Return SetError ( 16 , 0 , 0 )
	If $__G_AUDF_GLOBALIDS_USED [ $IUSEDINDEX ] [ 1 ] = $_UDF_STARTID + $_UDF_GLOBALID_MAX_IDS Then
		For $IIDINDEX = $_UDF_GLOBALIDS_OFFSET To UBound ( $__G_AUDF_GLOBALIDS_USED , $UBOUND_COLUMNS ) - 1
			If $__G_AUDF_GLOBALIDS_USED [ $IUSEDINDEX ] [ $IIDINDEX ] = 0 Then
				$NCTRLID = ( $IIDINDEX - $_UDF_GLOBALIDS_OFFSET ) + 10000
				$__G_AUDF_GLOBALIDS_USED [ $IUSEDINDEX ] [ $IIDINDEX ] = $NCTRLID
				Return $NCTRLID
			EndIf
		Next
		Return SetError ( - 1 , $_UDF_GLOBALID_MAX_IDS , 0 )
	EndIf
	$NCTRLID = $__G_AUDF_GLOBALIDS_USED [ $IUSEDINDEX ] [ 1 ]
	$__G_AUDF_GLOBALIDS_USED [ $IUSEDINDEX ] [ 1 ] += 1
	$__G_AUDF_GLOBALIDS_USED [ $IUSEDINDEX ] [ ( $NCTRLID - 10000 ) + $_UDF_GLOBALIDS_OFFSET ] = $NCTRLID
	Return $NCTRLID
EndFunc
Global Const $__COMBOBOXCONSTANT_EM_REPLACESEL = 194
Global Const $TAGCOMBOBOXINFO = "dword Size;struct;long EditLeft;long EditTop;long EditRight;long EditBottom;endstruct;" & "struct;long BtnLeft;long BtnTop;long BtnRight;long BtnBottom;endstruct;dword BtnState;hwnd hCombo;hwnd hEdit;hwnd hList"
Func _GUICTRLCOMBOBOX_GETCOMBOBOXINFO ( $HWND , ByRef $TINFO )
	If Not IsHWnd ( $HWND ) Then $HWND = GUICtrlGetHandle ( $HWND )
	$TINFO = DllStructCreate ( $TAGCOMBOBOXINFO )
	Local $IINFO = DllStructGetSize ( $TINFO )
	DllStructSetData ( $TINFO , "Size" , $IINFO )
	Return _SENDMESSAGE ( $HWND , $CB_GETCOMBOBOXINFO , 0 , $TINFO , 0 , "wparam" , "struct*" ) <> 0
EndFunc
Func _GUICTRLCOMBOBOX_REPLACEEDITSEL ( $HWND , $STEXT )
	If Not IsHWnd ( $HWND ) Then $HWND = GUICtrlGetHandle ( $HWND )
	Local $TINFO
	If _GUICTRLCOMBOBOX_GETCOMBOBOXINFO ( $HWND , $TINFO ) Then
		Local $HEDIT = DllStructGetData ( $TINFO , "hEdit" )
		_SENDMESSAGE ( $HEDIT , $__COMBOBOXCONSTANT_EM_REPLACESEL , True , $STEXT , 0 , "wparam" , "wstr" )
	EndIf
EndFunc
Func _GUICTRLCOMBOBOX_SELECTSTRING ( $HWND , $STEXT , $IINDEX = - 1 )
	If Not IsHWnd ( $HWND ) Then $HWND = GUICtrlGetHandle ( $HWND )
	Return _SENDMESSAGE ( $HWND , $CB_SELECTSTRING , $IINDEX , $STEXT , 0 , "wparam" , "wstr" )
EndFunc
Func _GUICTRLCOMBOBOX_SETEDITSEL ( $HWND , $ISTART , $ISTOP )
	If Not HWnd ( $HWND ) Then $HWND = GUICtrlGetHandle ( $HWND )
	Return _SENDMESSAGE ( $HWND , $CB_SETEDITSEL , 0 , _WINAPI_MAKELONG ( $ISTART , $ISTOP ) ) <> - 1
EndFunc
Func _GUICTRLCOMBOBOX_SETEDITTEXT ( $HWND , $STEXT )
	If Not IsHWnd ( $HWND ) Then $HWND = GUICtrlGetHandle ( $HWND )
	_GUICTRLCOMBOBOX_SETEDITSEL ( $HWND , 0 , - 1 )
	_GUICTRLCOMBOBOX_REPLACEEDITSEL ( $HWND , $STEXT )
EndFunc
Global Const $__STATUSBARCONSTANT_WM_USER = 1024
Global Const $SB_GETUNICODEFORMAT = 8192 + 6
Global Const $SB_ISSIMPLE = ( $__STATUSBARCONSTANT_WM_USER + 14 )
Global Const $SB_SETPARTS = ( $__STATUSBARCONSTANT_WM_USER + 4 )
Global Const $SB_SETTEXTA = ( $__STATUSBARCONSTANT_WM_USER + 1 )
Global Const $SB_SETTEXTW = ( $__STATUSBARCONSTANT_WM_USER + 11 )
Global Const $SB_SETTEXT = $SB_SETTEXTA
Global Const $SB_SIMPLEID = 255
Global $__G_HSBLASTWND
Global Const $__STATUSBARCONSTANT_CLASSNAME = "msctls_statusbar32"
Global Const $__STATUSBARCONSTANT_WM_SIZE = 5
Func _GUICTRLSTATUSBAR_CREATE ( $HWND , $VPARTEDGE = - 1 , $VPARTTEXT = "" , $ISTYLES = - 1 , $IEXSTYLES = 0 )
	If Not IsHWnd ( $HWND ) Then Return SetError ( 1 , 0 , 0 )
	Local $ISTYLE = BitOR ( $__UDFGUICONSTANT_WS_CHILD , $__UDFGUICONSTANT_WS_VISIBLE )
	If $ISTYLES = - 1 Then $ISTYLES = 0
	If $IEXSTYLES = - 1 Then $IEXSTYLES = 0
	Local $APARTWIDTH [ 1 ] , $APARTTEXT [ 1 ]
	If @NumParams > 1 Then
		If IsArray ( $VPARTEDGE ) Then
			$APARTWIDTH = $VPARTEDGE
		Else
			$APARTWIDTH [ 0 ] = $VPARTEDGE
		EndIf
		If @NumParams = 2 Then
			ReDim $APARTTEXT [ UBound ( $APARTWIDTH ) ]
		Else
			If IsArray ( $VPARTTEXT ) Then
				$APARTTEXT = $VPARTTEXT
			Else
				$APARTTEXT [ 0 ] = $VPARTTEXT
			EndIf
			If UBound ( $APARTWIDTH ) <> UBound ( $APARTTEXT ) Then
				Local $ILAST
				If UBound ( $APARTWIDTH ) > UBound ( $APARTTEXT ) Then
					$ILAST = UBound ( $APARTTEXT )
					ReDim $APARTTEXT [ UBound ( $APARTWIDTH ) ]
				Else
					$ILAST = UBound ( $APARTWIDTH )
					ReDim $APARTWIDTH [ UBound ( $APARTTEXT ) ]
					For $X = $ILAST To UBound ( $APARTWIDTH ) - 1
						$APARTWIDTH [ $X ] = $APARTWIDTH [ $X - 1 ] + 75
					Next
					$APARTWIDTH [ UBound ( $APARTTEXT ) - 1 ] = - 1
				EndIf
			EndIf
		EndIf
		If Not IsHWnd ( $HWND ) Then $HWND = HWnd ( $HWND )
		If @NumParams > 3 Then $ISTYLE = BitOR ( $ISTYLE , $ISTYLES )
	EndIf
	Local $NCTRLID = __UDF_GETNEXTGLOBALID ( $HWND )
	If @error Then Return SetError ( @error , @extended , 0 )
	Local $HWNDSBAR = _WINAPI_CREATEWINDOWEX ( $IEXSTYLES , $__STATUSBARCONSTANT_CLASSNAME , "" , $ISTYLE , 0 , 0 , 0 , 0 , $HWND , $NCTRLID )
	If @error Then Return SetError ( @error , @extended , 0 )
	If @NumParams > 1 Then
		_GUICTRLSTATUSBAR_SETPARTS ( $HWNDSBAR , UBound ( $APARTWIDTH ) , $APARTWIDTH )
		For $X = 0 To UBound ( $APARTTEXT ) - 1
			_GUICTRLSTATUSBAR_SETTEXT ( $HWNDSBAR , $APARTTEXT [ $X ] , $X )
		Next
	EndIf
	Return $HWNDSBAR
EndFunc
Func _GUICTRLSTATUSBAR_GETUNICODEFORMAT ( $HWND )
	Return _SENDMESSAGE ( $HWND , $SB_GETUNICODEFORMAT ) <> 0
EndFunc
Func _GUICTRLSTATUSBAR_ISSIMPLE ( $HWND )
	Return _SENDMESSAGE ( $HWND , $SB_ISSIMPLE ) <> 0
EndFunc
Func _GUICTRLSTATUSBAR_RESIZE ( $HWND )
	_SENDMESSAGE ( $HWND , $__STATUSBARCONSTANT_WM_SIZE )
EndFunc
Func _GUICTRLSTATUSBAR_SETPARTS ( $HWND , $APARTS = - 1 , $APARTWIDTH = 25 )
	Local $TPARTS , $IPARTS = 1
	If IsArray ( $APARTS ) <> 0 Then
		$APARTS [ UBound ( $APARTS ) - 1 ] = - 1
		$IPARTS = UBound ( $APARTS )
		$TPARTS = DllStructCreate ( "int[" & $IPARTS & "]" )
		For $X = 0 To $IPARTS - 2
			DllStructSetData ( $TPARTS , 1 , $APARTS [ $X ] , $X + 1 )
		Next
		DllStructSetData ( $TPARTS , 1 , - 1 , $IPARTS )
	ElseIf IsArray ( $APARTWIDTH ) <> 0 Then
		$IPARTS = UBound ( $APARTWIDTH )
		$TPARTS = DllStructCreate ( "int[" & $IPARTS & "]" )
		For $X = 0 To $IPARTS - 2
			DllStructSetData ( $TPARTS , 1 , $APARTWIDTH [ $X ] , $X + 1 )
		Next
		DllStructSetData ( $TPARTS , 1 , - 1 , $IPARTS )
	ElseIf $APARTS > 1 Then
		$IPARTS = $APARTS
		$TPARTS = DllStructCreate ( "int[" & $IPARTS & "]" )
		For $X = 1 To $IPARTS - 1
			DllStructSetData ( $TPARTS , 1 , $APARTWIDTH * $X , $X )
		Next
		DllStructSetData ( $TPARTS , 1 , - 1 , $IPARTS )
	Else
		$TPARTS = DllStructCreate ( "int" )
		DllStructSetData ( $TPARTS , $IPARTS , - 1 )
	EndIf
	If _WINAPI_INPROCESS ( $HWND , $__G_HSBLASTWND ) Then
		_SENDMESSAGE ( $HWND , $SB_SETPARTS , $IPARTS , $TPARTS , 0 , "wparam" , "struct*" )
	Else
		Local $ISIZE = DllStructGetSize ( $TPARTS )
		Local $TMEMMAP
		Local $PMEMORY = _MEMINIT ( $HWND , $ISIZE , $TMEMMAP )
		_MEMWRITE ( $TMEMMAP , $TPARTS )
		_SENDMESSAGE ( $HWND , $SB_SETPARTS , $IPARTS , $PMEMORY , 0 , "wparam" , "ptr" )
		_MEMFREE ( $TMEMMAP )
	EndIf
	_GUICTRLSTATUSBAR_RESIZE ( $HWND )
	Return True
EndFunc
Func _GUICTRLSTATUSBAR_SETTEXT ( $HWND , $STEXT = "" , $IPART = 0 , $IUFLAG = 0 )
	Local $BUNICODE = _GUICTRLSTATUSBAR_GETUNICODEFORMAT ( $HWND )
	Local $IBUFFER = StringLen ( $STEXT ) + 1
	Local $TTEXT
	If $BUNICODE Then
		$TTEXT = DllStructCreate ( "wchar Text[" & $IBUFFER & "]" )
		$IBUFFER *= 2
	Else
		$TTEXT = DllStructCreate ( "char Text[" & $IBUFFER & "]" )
	EndIf
	DllStructSetData ( $TTEXT , "Text" , $STEXT )
	If _GUICTRLSTATUSBAR_ISSIMPLE ( $HWND ) Then $IPART = $SB_SIMPLEID
	Local $IRET
	If _WINAPI_INPROCESS ( $HWND , $__G_HSBLASTWND ) Then
		$IRET = _SENDMESSAGE ( $HWND , $SB_SETTEXTW , BitOR ( $IPART , $IUFLAG ) , $TTEXT , 0 , "wparam" , "struct*" )
	Else
		Local $TMEMMAP
		Local $PMEMORY = _MEMINIT ( $HWND , $IBUFFER , $TMEMMAP )
		_MEMWRITE ( $TMEMMAP , $TTEXT )
		If $BUNICODE Then
			$IRET = _SENDMESSAGE ( $HWND , $SB_SETTEXTW , BitOR ( $IPART , $IUFLAG ) , $PMEMORY , 0 , "wparam" , "ptr" )
		Else
			$IRET = _SENDMESSAGE ( $HWND , $SB_SETTEXT , BitOR ( $IPART , $IUFLAG ) , $PMEMORY , 0 , "wparam" , "ptr" )
		EndIf
		_MEMFREE ( $TMEMMAP )
	EndIf
	Return $IRET <> 0
EndFunc
Global Const $WS_VSCROLL = 2097152
Global Const $WS_BORDER = 8388608
Global Const $WM_KEYDOWN = 256
Global Const $WM_CHAR = 258
Global Const $WM_SYSKEYDOWN = 260
Global Const $WM_SYSCHAR = 262
Func _ARRAYPUSH ( ByRef $AARRAY , $VVALUE , $IDIRECTION = 0 )
	If $IDIRECTION = Default Then $IDIRECTION = 0
	If ( Not IsArray ( $AARRAY ) ) Then Return SetError ( 1 , 0 , 0 )
	If UBound ( $AARRAY , $UBOUND_DIMENSIONS ) <> 1 Then Return SetError ( 3 , 0 , 0 )
	Local $IUBOUND = UBound ( $AARRAY ) - 1
	If IsArray ( $VVALUE ) Then
		Local $IUBOUNDS = UBound ( $VVALUE )
		If ( $IUBOUNDS - 1 ) > $IUBOUND Then Return SetError ( 2 , 0 , 0 )
		If $IDIRECTION Then
			For $I = $IUBOUND To $IUBOUNDS Step - 1
				$AARRAY [ $I ] = $AARRAY [ $I - $IUBOUNDS ]
			Next
			For $I = 0 To $IUBOUNDS - 1
				$AARRAY [ $I ] = $VVALUE [ $I ]
			Next
		Else
			For $I = 0 To $IUBOUND - $IUBOUNDS
				$AARRAY [ $I ] = $AARRAY [ $I + $IUBOUNDS ]
			Next
			For $I = 0 To $IUBOUNDS - 1
				$AARRAY [ $I + $IUBOUND - $IUBOUNDS + 1 ] = $VVALUE [ $I ]
			Next
		EndIf
	Else
		If $IUBOUND > - 1 Then
			If $IDIRECTION Then
				For $I = $IUBOUND To 1 Step - 1
					$AARRAY [ $I ] = $AARRAY [ $I - 1 ]
				Next
				$AARRAY [ 0 ] = $VVALUE
			Else
				For $I = 0 To $IUBOUND - 1
					$AARRAY [ $I ] = $AARRAY [ $I + 1 ]
				Next
				$AARRAY [ $IUBOUND ] = $VVALUE
			EndIf
		EndIf
	EndIf
	Return 1
EndFunc
Global Const $HKEY_CLASSES_ROOT = 2147483648
Global Const $HKEY_CURRENT_USER = 2147483649
Global Const $HKEY_LOCAL_MACHINE = 2147483650
Global Const $KEY_NOTIFY = 16
Global Const $REG_NOTIFY_CHANGE_LAST_SET = 4
Func _WINAPI_REGCLOSEKEY ( $HKEY , $BFLUSH = False )
	If $BFLUSH Then
		If Not _WINAPI_REGFLUSHKEY ( $HKEY ) Then
			Return SetError ( @error + 10 , @extended , 0 )
		EndIf
	EndIf
	Local $ARET = DllCall ( "advapi32.dll" , "long" , "RegCloseKey" , "handle" , $HKEY )
	If @error Then Return SetError ( @error , @extended , 0 )
	If $ARET [ 0 ] Then Return SetError ( 10 , $ARET [ 0 ] , 0 )
	Return 1
EndFunc
Func _WINAPI_REGFLUSHKEY ( $HKEY )
	Local $ARET = DllCall ( "advapi32.dll" , "long" , "RegFlushKey" , "handle" , $HKEY )
	If @error Then Return SetError ( @error , @extended , 0 )
	If $ARET [ 0 ] Then Return SetError ( 10 , $ARET [ 0 ] , 0 )
	Return 1
EndFunc
Func _WINAPI_REGNOTIFYCHANGEKEYVALUE ( $HKEY , $IFILTER , $BSUBTREE = False , $BASYNC = False , $HEVENT = 0 )
	Local $ARET = DllCall ( "advapi32.dll" , "long" , "RegNotifyChangeKeyValue" , "handle" , $HKEY , "bool" , $BSUBTREE , "dword" , $IFILTER , "handle" , $HEVENT , "bool" , $BASYNC )
	If @error Then Return SetError ( @error , @extended , 0 )
	If $ARET [ 0 ] Then Return SetError ( 10 , $ARET [ 0 ] , 0 )
	Return 1
EndFunc
Func _WINAPI_REGOPENKEY ( $HKEY , $SSUBKEY = "" , $IACCESS = 983103 )
	Local $SSUBKEYTYPE = "wstr"
	If Not IsString ( $SSUBKEY ) Then $SSUBKEYTYPE = "ptr"
	Local $ARET = DllCall ( "advapi32.dll" , "long" , "RegOpenKeyExW" , "handle" , $HKEY , $SSUBKEYTYPE , $SSUBKEY , "dword" , 0 , "dword" , $IACCESS , "ulong_ptr*" , 0 )
	If @error Then Return SetError ( @error , @extended , 0 )
	If $ARET [ 0 ] Then Return SetError ( 10 , $ARET [ 0 ] , 0 )
	Return $ARET [ 5 ]
EndFunc
Func _WINAPI_HASHDATA ( $PMEMORY , $ISIZE , $ILENGTH = 32 )
	If ( $ILENGTH <= 0 ) Or ( $ILENGTH > 256 ) Then Return SetError ( 11 , 0 , 0 )
	Local $TDATA = DllStructCreate ( "byte[" & $ILENGTH & "]" )
	Local $ARET = DllCall ( "shlwapi.dll" , "uint" , "HashData" , "struct*" , $PMEMORY , "dword" , $ISIZE , "struct*" , $TDATA , "dword" , $ILENGTH )
	If @error Then Return SetError ( @error , @extended , 0 )
	If $ARET [ 0 ] Then Return SetError ( 10 , $ARET [ 0 ] , 0 )
	Return DllStructGetData ( $TDATA , 1 )
EndFunc
Func _WINAPI_HASHSTRING ( $SSTRING , $BCASESENSITIVE = True , $ILENGTH = 32 )
	Local $ILENGTHS = StringLen ( $SSTRING )
	If Not $ILENGTHS Or ( $ILENGTH > 256 ) Then Return SetError ( 12 , 0 , 0 )
	Local $TSTRING = DllStructCreate ( "wchar[" & ( $ILENGTHS + 1 ) & "]" )
	If Not $BCASESENSITIVE Then
		$SSTRING = StringLower ( $SSTRING )
	EndIf
	DllStructSetData ( $TSTRING , 1 , $SSTRING )
	Local $SHASH = _WINAPI_HASHDATA ( $TSTRING , 2 * $ILENGTHS , $ILENGTH )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $SHASH
EndFunc
Func _WINAPI_GETKEYNAMETEXT ( $LPARAM )
	Local $ARET = DllCall ( "user32.dll" , "int" , "GetKeyNameTextW" , "long" , $LPARAM , "wstr" , "" , "int" , 128 )
	If @error Or Not $ARET [ 0 ] Then Return SetError ( @error , @extended , "" )
	Return $ARET [ 2 ]
EndFunc
Func _WINAPI_GETVERSION ( )
	Return BitAND ( BitShift ( $__WINVER , 8 ) , 255 ) & "." & BitAND ( $__WINVER , 255 )
EndFunc
Func _ISPRESSED ( $SHEXKEY , $VDLL = "user32.dll" )
	Local $A_R = DllCall ( $VDLL , "short" , "GetAsyncKeyState" , "int" , "0x" & $SHEXKEY )
	If @error Then Return SetError ( @error , @extended , False )
	Return BitAND ( $A_R [ 0 ] , 32768 ) <> 0
EndFunc
Global Const $INET_DOWNLOADREAD = 0
Global Const $INET_DOWNLOADCOMPLETE = 2
Global Const $INTERNET_DEFAULT_PORT = 0
Global Const $ICU_ESCAPE = 2147483648
Global Const $WINHTTP_FLAG_ASYNC = 268435456
Global Const $WINHTTP_FLAG_ESCAPE_DISABLE = 64
Global Const $WINHTTP_FLAG_SECURE = 8388608
Global Const $WINHTTP_ACCESS_TYPE_NO_PROXY = 1
Global Const $WINHTTP_ACCESS_TYPE_NAMED_PROXY = 3
Global Const $WINHTTP_NO_PROXY_NAME = ""
Global Const $WINHTTP_NO_PROXY_BYPASS = ""
Global Const $WINHTTP_NO_REFERER = ""
Global Const $WINHTTP_DEFAULT_ACCEPT_TYPES = 0
Global Const $WINHTTP_NO_ADDITIONAL_HEADERS = ""
Global Const $WINHTTP_NO_REQUEST_DATA = ""
Global Const $WINHTTP_HEADER_NAME_BY_INDEX = ""
Global Const $WINHTTP_NO_HEADER_INDEX = 0
Global Const $WINHTTP_OPTION_CALLBACK = 1
Global Const $WINHTTP_OPTION_RESOLVE_TIMEOUT = 2
Global Const $WINHTTP_OPTION_CONNECT_TIMEOUT = 3
Global Const $WINHTTP_OPTION_CONNECT_RETRIES = 4
Global Const $WINHTTP_OPTION_SEND_TIMEOUT = 5
Global Const $WINHTTP_OPTION_RECEIVE_TIMEOUT = 6
Global Const $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT = 7
Global Const $WINHTTP_OPTION_HANDLE_TYPE = 9
Global Const $WINHTTP_OPTION_READ_BUFFER_SIZE = 12
Global Const $WINHTTP_OPTION_WRITE_BUFFER_SIZE = 13
Global Const $WINHTTP_OPTION_PARENT_HANDLE = 21
Global Const $WINHTTP_OPTION_EXTENDED_ERROR = 24
Global Const $WINHTTP_OPTION_SECURITY_FLAGS = 31
Global Const $WINHTTP_OPTION_URL = 34
Global Const $WINHTTP_OPTION_SECURITY_KEY_BITNESS = 36
Global Const $WINHTTP_OPTION_PROXY = 38
Global Const $WINHTTP_OPTION_USER_AGENT = 41
Global Const $WINHTTP_OPTION_CONTEXT_VALUE = 45
Global Const $WINHTTP_OPTION_CLIENT_CERT_CONTEXT = 47
Global Const $WINHTTP_OPTION_REQUEST_PRIORITY = 58
Global Const $WINHTTP_OPTION_HTTP_VERSION = 59
Global Const $WINHTTP_OPTION_DISABLE_FEATURE = 63
Global Const $WINHTTP_OPTION_CODEPAGE = 68
Global Const $WINHTTP_OPTION_MAX_CONNS_PER_SERVER = 73
Global Const $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER = 74
Global Const $WINHTTP_OPTION_AUTOLOGON_POLICY = 77
Global Const $WINHTTP_OPTION_ENABLE_FEATURE = 79
Global Const $WINHTTP_OPTION_WORKER_THREAD_COUNT = 80
Global Const $WINHTTP_OPTION_PASSPORT_COBRANDING_TEXT = 81
Global Const $WINHTTP_OPTION_PASSPORT_COBRANDING_URL = 82
Global Const $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH = 83
Global Const $WINHTTP_OPTION_SECURE_PROTOCOLS = 84
Global Const $WINHTTP_OPTION_ENABLETRACING = 85
Global Const $WINHTTP_OPTION_PASSPORT_SIGN_OUT = 86
Global Const $WINHTTP_OPTION_REDIRECT_POLICY = 88
Global Const $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS = 89
Global Const $WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE = 90
Global Const $WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE = 91
Global Const $WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE = 92
Global Const $WINHTTP_OPTION_CONNECTION_INFO = 93
Global Const $WINHTTP_OPTION_SPN = 96
Global Const $WINHTTP_OPTION_GLOBAL_PROXY_CREDS = 97
Global Const $WINHTTP_OPTION_GLOBAL_SERVER_CREDS = 98
Global Const $WINHTTP_OPTION_REJECT_USERPWD_IN_URL = 100
Global Const $WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS = 101
Global Const $WINHTTP_OPTION_USERNAME = 4096
Global Const $WINHTTP_OPTION_PASSWORD = 4097
Global Const $WINHTTP_OPTION_PROXY_USERNAME = 4098
Global Const $WINHTTP_OPTION_PROXY_PASSWORD = 4099
Global Const $WINHTTP_AUTOLOGON_SECURITY_LEVEL_MEDIUM = 0
Global Const $WINHTTP_AUTOLOGON_SECURITY_LEVEL_LOW = 1
Global Const $WINHTTP_AUTOLOGON_SECURITY_LEVEL_HIGH = 2
Global Const $WINHTTP_ENABLE_PASSPORT_AUTH = 268435456
Global Const $HTTP_STATUS_DENIED = 401
Global Const $HTTP_STATUS_PROXY_AUTH_REQ = 407
Global Const $WINHTTP_QUERY_CONTENT_TYPE = 1
Global Const $WINHTTP_QUERY_STATUS_CODE = 19
Global Const $WINHTTP_QUERY_RAW_HEADERS_CRLF = 22
Global Const $WINHTTP_AUTH_SCHEME_PASSPORT = 4
Global Const $WINHTTP_AUTOPROXY_CONFIG_URL = 2
Global Const $WINHTTP_AUTO_DETECT_TYPE_DHCP = 1
Global Const $WINHTTP_AUTO_DETECT_TYPE_DNS_A = 2
Global Const $HWINHTTPDLL__WINHTTP = DllOpen ( "winhttp.dll" )
DllOpen ( "winhttp.dll" )
Func _WINHTTPCLOSEHANDLE ( $HINTERNET )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpCloseHandle" , "handle" , $HINTERNET )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return 1
EndFunc
Func _WINHTTPCONNECT ( $HSESSION , $SSERVERNAME , $ISERVERPORT = Default )
	Local $AURL = _WINHTTPCRACKURL ( $SSERVERNAME )
	If @error Then
		__WINHTTPDEFAULT ( $ISERVERPORT , $INTERNET_DEFAULT_PORT )
	Else
		$SSERVERNAME = $AURL [ 2 ]
		$ISERVERPORT = $AURL [ 3 ]
	EndIf
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "handle" , "WinHttpConnect" , "handle" , $HSESSION , "wstr" , $SSERVERNAME , "dword" , $ISERVERPORT , "dword" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return $ACALL [ 0 ]
EndFunc
Func _WINHTTPCRACKURL ( $SURL , $IFLAG = Default )
	__WINHTTPDEFAULT ( $IFLAG , $ICU_ESCAPE )
	Local $TURL_COMPONENTS = DllStructCreate ( "dword StructSize;" & "ptr SchemeName;" & "dword SchemeNameLength;" & "int Scheme;" & "ptr HostName;" & "dword HostNameLength;" & "word Port;" & "ptr UserName;" & "dword UserNameLength;" & "ptr Password;" & "dword PasswordLength;" & "ptr UrlPath;" & "dword UrlPathLength;" & "ptr ExtraInfo;" & "dword ExtraInfoLength" )
	DllStructSetData ( $TURL_COMPONENTS , 1 , DllStructGetSize ( $TURL_COMPONENTS ) )
	Local $TBUFFERS [ 6 ]
	Local $IURLLEN = StringLen ( $SURL )
	For $I = 0 To 5
		$TBUFFERS [ $I ] = DllStructCreate ( "wchar[" & $IURLLEN + 1 & "]" )
	Next
	DllStructSetData ( $TURL_COMPONENTS , "SchemeNameLength" , $IURLLEN )
	DllStructSetData ( $TURL_COMPONENTS , "SchemeName" , DllStructGetPtr ( $TBUFFERS [ 0 ] ) )
	DllStructSetData ( $TURL_COMPONENTS , "HostNameLength" , $IURLLEN )
	DllStructSetData ( $TURL_COMPONENTS , "HostName" , DllStructGetPtr ( $TBUFFERS [ 1 ] ) )
	DllStructSetData ( $TURL_COMPONENTS , "UserNameLength" , $IURLLEN )
	DllStructSetData ( $TURL_COMPONENTS , "UserName" , DllStructGetPtr ( $TBUFFERS [ 2 ] ) )
	DllStructSetData ( $TURL_COMPONENTS , "PasswordLength" , $IURLLEN )
	DllStructSetData ( $TURL_COMPONENTS , "Password" , DllStructGetPtr ( $TBUFFERS [ 3 ] ) )
	DllStructSetData ( $TURL_COMPONENTS , "UrlPathLength" , $IURLLEN )
	DllStructSetData ( $TURL_COMPONENTS , "UrlPath" , DllStructGetPtr ( $TBUFFERS [ 4 ] ) )
	DllStructSetData ( $TURL_COMPONENTS , "ExtraInfoLength" , $IURLLEN )
	DllStructSetData ( $TURL_COMPONENTS , "ExtraInfo" , DllStructGetPtr ( $TBUFFERS [ 5 ] ) )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpCrackUrl" , "wstr" , $SURL , "dword" , $IURLLEN , "dword" , $IFLAG , "struct*" , $TURL_COMPONENTS )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Local $ARET [ 8 ] = [ DllStructGetData ( $TBUFFERS [ 0 ] , 1 ) , DllStructGetData ( $TURL_COMPONENTS , "Scheme" ) , DllStructGetData ( $TBUFFERS [ 1 ] , 1 ) , DllStructGetData ( $TURL_COMPONENTS , "Port" ) , DllStructGetData ( $TBUFFERS [ 2 ] , 1 ) , DllStructGetData ( $TBUFFERS [ 3 ] , 1 ) , DllStructGetData ( $TBUFFERS [ 4 ] , 1 ) , DllStructGetData ( $TBUFFERS [ 5 ] , 1 ) ]
	Return $ARET
EndFunc
Func _WINHTTPGETIEPROXYCONFIGFORCURRENTUSER ( )
	Local $TWINHTTP_CURRENT_USER_IE_PROXY_CONFIG = DllStructCreate ( "int AutoDetect;" & "ptr AutoConfigUrl;" & "ptr Proxy;" & "ptr ProxyBypass;" )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpGetIEProxyConfigForCurrentUser" , "struct*" , $TWINHTTP_CURRENT_USER_IE_PROXY_CONFIG )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Local $IAUTODETECT = DllStructGetData ( $TWINHTTP_CURRENT_USER_IE_PROXY_CONFIG , "AutoDetect" )
	Local $PAUTOCONFIGURL = DllStructGetData ( $TWINHTTP_CURRENT_USER_IE_PROXY_CONFIG , "AutoConfigUrl" )
	Local $PPROXY = DllStructGetData ( $TWINHTTP_CURRENT_USER_IE_PROXY_CONFIG , "Proxy" )
	Local $PPROXYBYPASS = DllStructGetData ( $TWINHTTP_CURRENT_USER_IE_PROXY_CONFIG , "ProxyBypass" )
	Local $SAUTOCONFIGURL
	If $PAUTOCONFIGURL Then
		Local $IAUTOCONFIGURLLEN = __WINHTTPPTRSTRINGLENW ( $PAUTOCONFIGURL )
		If Not @error Then
			Local $TAUTOCONFIGURL = DllStructCreate ( "wchar[" & $IAUTOCONFIGURLLEN + 1 & "]" , $PAUTOCONFIGURL )
			$SAUTOCONFIGURL = DllStructGetData ( $TAUTOCONFIGURL , 1 )
			__WINHTTPMEMGLOBALFREE ( $PAUTOCONFIGURL )
		EndIf
	EndIf
	Local $SPROXY
	If $PPROXY Then
		Local $IPROXYLEN = __WINHTTPPTRSTRINGLENW ( $PPROXY )
		If Not @error Then
			Local $TPROXY = DllStructCreate ( "wchar[" & $IPROXYLEN + 1 & "]" , $PPROXY )
			$SPROXY = DllStructGetData ( $TPROXY , 1 )
			__WINHTTPMEMGLOBALFREE ( $PPROXY )
		EndIf
	EndIf
	Local $SPROXYBYPASS
	If $PPROXYBYPASS Then
		Local $IPROXYBYPASSLEN = __WINHTTPPTRSTRINGLENW ( $PPROXYBYPASS )
		If Not @error Then
			Local $TPROXYBYPASS = DllStructCreate ( "wchar[" & $IPROXYBYPASSLEN + 1 & "]" , $PPROXYBYPASS )
			$SPROXYBYPASS = DllStructGetData ( $TPROXYBYPASS , 1 )
			__WINHTTPMEMGLOBALFREE ( $PPROXYBYPASS )
		EndIf
	EndIf
	Local $AOUTPUT [ 4 ] = [ $IAUTODETECT , $SAUTOCONFIGURL , $SPROXY , $SPROXYBYPASS ]
	Return $AOUTPUT
EndFunc
Func _WINHTTPOPEN ( $SUSERAGENT = Default , $IACCESSTYPE = Default , $SPROXYNAME = Default , $SPROXYBYPASS = Default , $IFLAG = Default )
	__WINHTTPDEFAULT ( $SUSERAGENT , "AutoIt/3.3 WinHTTP/5.1" )
	__WINHTTPDEFAULT ( $IACCESSTYPE , $WINHTTP_ACCESS_TYPE_NO_PROXY )
	__WINHTTPDEFAULT ( $SPROXYNAME , $WINHTTP_NO_PROXY_NAME )
	__WINHTTPDEFAULT ( $SPROXYBYPASS , $WINHTTP_NO_PROXY_BYPASS )
	__WINHTTPDEFAULT ( $IFLAG , 0 )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "handle" , "WinHttpOpen" , "wstr" , $SUSERAGENT , "dword" , $IACCESSTYPE , "wstr" , $SPROXYNAME , "wstr" , $SPROXYBYPASS , "dword" , $IFLAG )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	If $IFLAG = $WINHTTP_FLAG_ASYNC Then _WINHTTPSETOPTION ( $ACALL [ 0 ] , $WINHTTP_OPTION_CONTEXT_VALUE , $WINHTTP_FLAG_ASYNC )
	; WinHTTP on Windows 7 and 8.1 defaults to TLS 1.0, which every modern vendor feed
	; refuses. Ask for TLS 1.2 explicitly; fall back to TLS 1.2 only if the bitmask is
	; rejected.
	Local $ITLS = BitOR ( 0x0800 , 0x0200 , 0x0080 )
	If Not _WINHTTPSETOPTION ( $ACALL [ 0 ] , $WINHTTP_OPTION_SECURE_PROTOCOLS , $ITLS ) Then
		_WINHTTPSETOPTION ( $ACALL [ 0 ] , $WINHTTP_OPTION_SECURE_PROTOCOLS , 0x0800 )
	EndIf
	Return $ACALL [ 0 ]
EndFunc
Func _WINHTTPOPENREQUEST ( $HCONNECT , $SVERB = Default , $SOBJECTNAME = Default , $SVERSION = Default , $SREFERRER = Default , $SACCEPTTYPES = Default , $IFLAGS = Default )
	__WINHTTPDEFAULT ( $SVERB , "GET" )
	__WINHTTPDEFAULT ( $SOBJECTNAME , "" )
	__WINHTTPDEFAULT ( $SVERSION , "HTTP/1.1" )
	__WINHTTPDEFAULT ( $SREFERRER , $WINHTTP_NO_REFERER )
	__WINHTTPDEFAULT ( $IFLAGS , $WINHTTP_FLAG_ESCAPE_DISABLE )
	Local $PACCEPTTYPES
	If $SACCEPTTYPES = Default Or Number ( $SACCEPTTYPES ) = - 1 Then
		$PACCEPTTYPES = $WINHTTP_DEFAULT_ACCEPT_TYPES
	Else
		Local $ATYPES = StringSplit ( $SACCEPTTYPES , "," , 2 )
		Local $TACCEPTTYPES = DllStructCreate ( "ptr[" & UBound ( $ATYPES ) + 1 & "]" )
		Local $TTYPE [ UBound ( $ATYPES ) ]
		For $I = 0 To UBound ( $ATYPES ) - 1
			$TTYPE [ $I ] = DllStructCreate ( "wchar[" & StringLen ( $ATYPES [ $I ] ) + 1 & "]" )
			DllStructSetData ( $TTYPE [ $I ] , 1 , $ATYPES [ $I ] )
			DllStructSetData ( $TACCEPTTYPES , 1 , DllStructGetPtr ( $TTYPE [ $I ] ) , $I + 1 )
		Next
		$PACCEPTTYPES = DllStructGetPtr ( $TACCEPTTYPES )
	EndIf
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "handle" , "WinHttpOpenRequest" , "handle" , $HCONNECT , "wstr" , StringUpper ( $SVERB ) , "wstr" , $SOBJECTNAME , "wstr" , StringUpper ( $SVERSION ) , "wstr" , $SREFERRER , "ptr" , $PACCEPTTYPES , "dword" , $IFLAGS )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return $ACALL [ 0 ]
EndFunc
Func _WINHTTPQUERYAUTHSCHEMES ( $HREQUEST , ByRef $ISUPPORTEDSCHEMES , ByRef $IFIRSTSCHEME , ByRef $IAUTHTARGET )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpQueryAuthSchemes" , "handle" , $HREQUEST , "dword*" , 0 , "dword*" , 0 , "dword*" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	$ISUPPORTEDSCHEMES = $ACALL [ 2 ]
	$IFIRSTSCHEME = $ACALL [ 3 ]
	$IAUTHTARGET = $ACALL [ 4 ]
	Return 1
EndFunc
Func _WINHTTPQUERYDATAAVAILABLE ( $HREQUEST )
	Local $SREADTYPE = "dword*"
	If BitAND ( _WINHTTPQUERYOPTION ( _WINHTTPQUERYOPTION ( _WINHTTPQUERYOPTION ( $HREQUEST , $WINHTTP_OPTION_PARENT_HANDLE ) , $WINHTTP_OPTION_PARENT_HANDLE ) , $WINHTTP_OPTION_CONTEXT_VALUE ) , $WINHTTP_FLAG_ASYNC ) Then $SREADTYPE = "ptr"
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpQueryDataAvailable" , "handle" , $HREQUEST , $SREADTYPE , 0 )
	If @error Then Return SetError ( 1 , 0 , 0 )
	Return SetExtended ( $ACALL [ 2 ] , $ACALL [ 0 ] )
EndFunc
Func _WINHTTPQUERYHEADERS ( $HREQUEST , $IINFOLEVEL = Default , $SNAME = Default , $IINDEX = Default )
	__WINHTTPDEFAULT ( $IINFOLEVEL , $WINHTTP_QUERY_RAW_HEADERS_CRLF )
	__WINHTTPDEFAULT ( $SNAME , $WINHTTP_HEADER_NAME_BY_INDEX )
	__WINHTTPDEFAULT ( $IINDEX , $WINHTTP_NO_HEADER_INDEX )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpQueryHeaders" , "handle" , $HREQUEST , "dword" , $IINFOLEVEL , "wstr" , $SNAME , "wstr" , "" , "dword*" , 65536 , "dword*" , $IINDEX )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , "" )
	Return SetExtended ( $ACALL [ 6 ] , $ACALL [ 4 ] )
EndFunc
Func _WINHTTPQUERYOPTION ( $HINTERNET , $IOPTION )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpQueryOption" , "handle" , $HINTERNET , "dword" , $IOPTION , "ptr" , 0 , "dword*" , 0 )
	If @error Or $ACALL [ 0 ] Then Return SetError ( 1 , 0 , "" )
	Local $ISIZE = $ACALL [ 4 ]
	Local $TBUFFER
	Switch $IOPTION
	Case $WINHTTP_OPTION_CONNECTION_INFO , $WINHTTP_OPTION_PASSWORD , $WINHTTP_OPTION_PROXY_PASSWORD , $WINHTTP_OPTION_PROXY_USERNAME , $WINHTTP_OPTION_URL , $WINHTTP_OPTION_USERNAME , $WINHTTP_OPTION_USER_AGENT , $WINHTTP_OPTION_PASSPORT_COBRANDING_TEXT , $WINHTTP_OPTION_PASSPORT_COBRANDING_URL
		$TBUFFER = DllStructCreate ( "wchar[" & $ISIZE + 1 & "]" )
	Case $WINHTTP_OPTION_PARENT_HANDLE , $WINHTTP_OPTION_CALLBACK
		$TBUFFER = DllStructCreate ( "ptr" )
	Case $WINHTTP_OPTION_CONNECT_TIMEOUT , $WINHTTP_AUTOLOGON_SECURITY_LEVEL_HIGH , $WINHTTP_AUTOLOGON_SECURITY_LEVEL_LOW , $WINHTTP_AUTOLOGON_SECURITY_LEVEL_MEDIUM , $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH , $WINHTTP_OPTION_CONNECT_RETRIES , $WINHTTP_OPTION_EXTENDED_ERROR , $WINHTTP_OPTION_HANDLE_TYPE , $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER , $WINHTTP_OPTION_MAX_CONNS_PER_SERVER , $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS , $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT , $WINHTTP_OPTION_RECEIVE_TIMEOUT , $WINHTTP_OPTION_RESOLVE_TIMEOUT , $WINHTTP_OPTION_SECURITY_FLAGS , $WINHTTP_OPTION_SECURITY_KEY_BITNESS , $WINHTTP_OPTION_SEND_TIMEOUT
		$TBUFFER = DllStructCreate ( "int" )
	Case $WINHTTP_OPTION_CONTEXT_VALUE
		$TBUFFER = DllStructCreate ( "dword_ptr" )
Case Else
		$TBUFFER = DllStructCreate ( "byte[" & $ISIZE & "]" )
	EndSwitch
	$ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpQueryOption" , "handle" , $HINTERNET , "dword" , $IOPTION , "struct*" , $TBUFFER , "dword*" , $ISIZE )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 2 , 0 , "" )
	Return DllStructGetData ( $TBUFFER , 1 )
EndFunc
Func _WINHTTPREADDATA ( $HREQUEST , $IMODE = Default , $INUMBEROFBYTESTOREAD = Default , $PBUFFER = Default )
	__WINHTTPDEFAULT ( $IMODE , 0 )
	__WINHTTPDEFAULT ( $INUMBEROFBYTESTOREAD , 8192 )
	Local $TBUFFER , $VOUTONERROR = ""
	If $IMODE = 2 Then $VOUTONERROR = Binary ( $VOUTONERROR )
	Switch $IMODE
	Case 1 , 2
		If $PBUFFER And $PBUFFER <> Default Then
			$TBUFFER = DllStructCreate ( "byte[" & $INUMBEROFBYTESTOREAD & "]" , $PBUFFER )
		Else
			$TBUFFER = DllStructCreate ( "byte[" & $INUMBEROFBYTESTOREAD & "]" )
		EndIf
Case Else
		$IMODE = 0
		If $PBUFFER And $PBUFFER <> Default Then
			$TBUFFER = DllStructCreate ( "char[" & $INUMBEROFBYTESTOREAD & "]" , $PBUFFER )
		Else
			$TBUFFER = DllStructCreate ( "char[" & $INUMBEROFBYTESTOREAD & "]" )
		EndIf
	EndSwitch
	Local $SREADTYPE = "dword*"
	If BitAND ( _WINHTTPQUERYOPTION ( _WINHTTPQUERYOPTION ( _WINHTTPQUERYOPTION ( $HREQUEST , $WINHTTP_OPTION_PARENT_HANDLE ) , $WINHTTP_OPTION_PARENT_HANDLE ) , $WINHTTP_OPTION_CONTEXT_VALUE ) , $WINHTTP_FLAG_ASYNC ) Then $SREADTYPE = "ptr"
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpReadData" , "handle" , $HREQUEST , "struct*" , $TBUFFER , "dword" , $INUMBEROFBYTESTOREAD , $SREADTYPE , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , "" )
	If Not $ACALL [ 4 ] Then Return SetError ( - 1 , 0 , $VOUTONERROR )
	If $ACALL [ 4 ] < $INUMBEROFBYTESTOREAD Then
		Switch $IMODE
		Case 0
			Return SetExtended ( $ACALL [ 4 ] , StringLeft ( DllStructGetData ( $TBUFFER , 1 ) , $ACALL [ 4 ] ) )
		Case 1
			Return SetExtended ( $ACALL [ 4 ] , BinaryToString ( BinaryMid ( DllStructGetData ( $TBUFFER , 1 ) , 1 , $ACALL [ 4 ] ) , 4 ) )
		Case 2
			Return SetExtended ( $ACALL [ 4 ] , BinaryMid ( DllStructGetData ( $TBUFFER , 1 ) , 1 , $ACALL [ 4 ] ) )
		EndSwitch
	Else
		Switch $IMODE
		Case 0 , 2
			Return SetExtended ( $ACALL [ 4 ] , DllStructGetData ( $TBUFFER , 1 ) )
		Case 1
			Return SetExtended ( $ACALL [ 4 ] , BinaryToString ( DllStructGetData ( $TBUFFER , 1 ) , 4 ) )
		EndSwitch
	EndIf
EndFunc
Func _WINHTTPRECEIVERESPONSE ( $HREQUEST )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpReceiveResponse" , "handle" , $HREQUEST , "ptr" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return 1
EndFunc
Func _WINHTTPSENDREQUEST ( $HREQUEST , $SHEADERS = Default , $SOPTIONAL = Default , $ITOTALLENGTH = Default , $ICONTEXT = Default )
	__WINHTTPDEFAULT ( $SHEADERS , $WINHTTP_NO_ADDITIONAL_HEADERS )
	__WINHTTPDEFAULT ( $SOPTIONAL , $WINHTTP_NO_REQUEST_DATA )
	__WINHTTPDEFAULT ( $ITOTALLENGTH , 0 )
	__WINHTTPDEFAULT ( $ICONTEXT , 0 )
	Local $POPTIONAL = 0 , $IOPTIONALLENGTH = 0
	If @NumParams > 2 Then
		Local $TOPTIONAL
		$IOPTIONALLENGTH = BinaryLen ( $SOPTIONAL )
		$TOPTIONAL = DllStructCreate ( "byte[" & $IOPTIONALLENGTH & "]" )
		If $IOPTIONALLENGTH Then $POPTIONAL = DllStructGetPtr ( $TOPTIONAL )
		DllStructSetData ( $TOPTIONAL , 1 , $SOPTIONAL )
	EndIf
	If Not $ITOTALLENGTH Or $ITOTALLENGTH < $IOPTIONALLENGTH Then $ITOTALLENGTH += $IOPTIONALLENGTH
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpSendRequest" , "handle" , $HREQUEST , "wstr" , $SHEADERS , "dword" , 0 , "ptr" , $POPTIONAL , "dword" , $IOPTIONALLENGTH , "dword" , $ITOTALLENGTH , "dword_ptr" , $ICONTEXT )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return 1
EndFunc
Func _WINHTTPSETCREDENTIALS ( $HREQUEST , $IAUTHTARGETS , $IAUTHSCHEME , $SUSERNAME , $SPASSWORD )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpSetCredentials" , "handle" , $HREQUEST , "dword" , $IAUTHTARGETS , "dword" , $IAUTHSCHEME , "wstr" , $SUSERNAME , "wstr" , $SPASSWORD , "ptr" , 0 )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return 1
EndFunc
Func _WINHTTPSETOPTION ( $HINTERNET , $IOPTION , $VSETTING , $ISIZE = Default )
	If $ISIZE = Default Then $ISIZE = - 1
	If IsBinary ( $VSETTING ) Then
		$ISIZE = DllStructCreate ( "byte[" & BinaryLen ( $VSETTING ) & "]" )
		DllStructSetData ( $ISIZE , 1 , $VSETTING )
		$VSETTING = $ISIZE
		$ISIZE = DllStructGetSize ( $VSETTING )
	EndIf
	Local $STYPE
	Switch $IOPTION
	Case $WINHTTP_OPTION_AUTOLOGON_POLICY , $WINHTTP_OPTION_CODEPAGE , $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH , $WINHTTP_OPTION_CONNECT_RETRIES , $WINHTTP_OPTION_CONNECT_TIMEOUT , $WINHTTP_OPTION_DISABLE_FEATURE , $WINHTTP_OPTION_ENABLE_FEATURE , $WINHTTP_OPTION_ENABLETRACING , $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER , $WINHTTP_OPTION_MAX_CONNS_PER_SERVER , $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS , $WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE , $WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE , $WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE , $WINHTTP_OPTION_READ_BUFFER_SIZE , $WINHTTP_OPTION_RECEIVE_TIMEOUT , $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT , $WINHTTP_OPTION_REDIRECT_POLICY , $WINHTTP_OPTION_REJECT_USERPWD_IN_URL , $WINHTTP_OPTION_REQUEST_PRIORITY , $WINHTTP_OPTION_RESOLVE_TIMEOUT , $WINHTTP_OPTION_SECURE_PROTOCOLS , $WINHTTP_OPTION_SECURITY_FLAGS , $WINHTTP_OPTION_SECURITY_KEY_BITNESS , $WINHTTP_OPTION_SEND_TIMEOUT , $WINHTTP_OPTION_SPN , $WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS , $WINHTTP_OPTION_WORKER_THREAD_COUNT , $WINHTTP_OPTION_WRITE_BUFFER_SIZE
		$STYPE = "dword*"
		$ISIZE = 4
	Case $WINHTTP_OPTION_CALLBACK , $WINHTTP_OPTION_PASSPORT_SIGN_OUT
		$STYPE = "ptr*"
		$ISIZE = 4
		If @AutoItX64 Then $ISIZE = 8
		If Not IsPtr ( $VSETTING ) Then Return SetError ( 3 , 0 , 0 )
	Case $WINHTTP_OPTION_CONTEXT_VALUE
		$STYPE = "dword_ptr*"
		$ISIZE = 4
		If @AutoItX64 Then $ISIZE = 8
	Case $WINHTTP_OPTION_PASSWORD , $WINHTTP_OPTION_PROXY_PASSWORD , $WINHTTP_OPTION_PROXY_USERNAME , $WINHTTP_OPTION_USER_AGENT , $WINHTTP_OPTION_USERNAME
		$STYPE = "wstr"
		If ( IsDllStruct ( $VSETTING ) Or IsPtr ( $VSETTING ) ) Then Return SetError ( 3 , 0 , 0 )
		If $ISIZE < 1 Then $ISIZE = StringLen ( $VSETTING )
	Case $WINHTTP_OPTION_CLIENT_CERT_CONTEXT , $WINHTTP_OPTION_GLOBAL_PROXY_CREDS , $WINHTTP_OPTION_GLOBAL_SERVER_CREDS , $WINHTTP_OPTION_HTTP_VERSION , $WINHTTP_OPTION_PROXY
		$STYPE = "ptr"
		If Not ( IsDllStruct ( $VSETTING ) Or IsPtr ( $VSETTING ) ) Then Return SetError ( 3 , 0 , 0 )
Case Else
		Return SetError ( 1 , 0 , 0 )
	EndSwitch
	If $ISIZE < 1 Then
		If IsDllStruct ( $VSETTING ) Then
			$ISIZE = DllStructGetSize ( $VSETTING )
		Else
			Return SetError ( 2 , 0 , 0 )
		EndIf
	EndIf
	Local $ACALL
	If IsDllStruct ( $VSETTING ) Then
		$ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpSetOption" , "handle" , $HINTERNET , "dword" , $IOPTION , $STYPE , DllStructGetPtr ( $VSETTING ) , "dword" , $ISIZE )
	Else
		$ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpSetOption" , "handle" , $HINTERNET , "dword" , $IOPTION , $STYPE , $VSETTING , "dword" , $ISIZE )
	EndIf
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 4 , 0 , 0 )
	Return 1
EndFunc
Func _WINHTTPSETTIMEOUTS ( $HINTERNET , $IRESOLVETIMEOUT = Default , $ICONNECTTIMEOUT = Default , $ISENDTIMEOUT = Default , $IRECEIVETIMEOUT = Default )
	__WINHTTPDEFAULT ( $IRESOLVETIMEOUT , 0 )
	__WINHTTPDEFAULT ( $ICONNECTTIMEOUT , 60000 )
	__WINHTTPDEFAULT ( $ISENDTIMEOUT , 30000 )
	__WINHTTPDEFAULT ( $IRECEIVETIMEOUT , 30000 )
	Local $ACALL = DllCall ( $HWINHTTPDLL__WINHTTP , "bool" , "WinHttpSetTimeouts" , "handle" , $HINTERNET , "int" , $IRESOLVETIMEOUT , "int" , $ICONNECTTIMEOUT , "int" , $ISENDTIMEOUT , "int" , $IRECEIVETIMEOUT )
	If @error Or Not $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return 1
EndFunc
Func _WINHTTPSIMPLEREADDATA ( $HREQUEST , $IMODE = Default )
	If $IMODE = Default Then
		$IMODE = 0
		If __WINHTTPCHARSET ( _WINHTTPQUERYHEADERS ( $HREQUEST , $WINHTTP_QUERY_CONTENT_TYPE ) ) = 65001 Then $IMODE = 1
	Else
		__WINHTTPDEFAULT ( $IMODE , 0 )
	EndIf
	If $IMODE > 2 Or $IMODE < 0 Then Return SetError ( 1 , 0 , "" )
	Local $VDATA = Binary ( "" )
	If _WINHTTPQUERYDATAAVAILABLE ( $HREQUEST ) Then
		Do
			$VDATA &= _WINHTTPREADDATA ( $HREQUEST , 2 )
		Until @error
		Switch $IMODE
		Case 0
			Return BinaryToString ( $VDATA )
		Case 1
			Return BinaryToString ( $VDATA , 4 )
	Case Else
			Return $VDATA
		EndSwitch
	EndIf
	Return SetError ( 2 , 0 , $VDATA )
EndFunc
Func _WINHTTPSIMPLESENDSSLREQUEST ( $HCONNECT , $STYPE = Default , $SPATH = Default , $SREFERRER = Default , $SDATA = Default , $SHEADER = Default )
	__WINHTTPDEFAULT ( $STYPE , "GET" )
	__WINHTTPDEFAULT ( $SPATH , "" )
	__WINHTTPDEFAULT ( $SREFERRER , $WINHTTP_NO_REFERER )
	__WINHTTPDEFAULT ( $SDATA , $WINHTTP_NO_REQUEST_DATA )
	__WINHTTPDEFAULT ( $SHEADER , $WINHTTP_NO_ADDITIONAL_HEADERS )
	Local $HREQUEST = _WINHTTPOPENREQUEST ( $HCONNECT , $STYPE , $SPATH , Default , $SREFERRER , Default , BitOR ( $WINHTTP_FLAG_SECURE , $WINHTTP_FLAG_ESCAPE_DISABLE ) )
	If Not $HREQUEST Then Return SetError ( 1 , @error , 0 )
	If $STYPE = "POST" And $SHEADER = $WINHTTP_NO_ADDITIONAL_HEADERS Then $SHEADER = "Content-Type: application/x-www-form-urlencoded" & @CRLF
	_WINHTTPSENDREQUEST ( $HREQUEST , $SHEADER , $SDATA )
	If @error Then Return SetError ( 2 , 0 * _WINHTTPCLOSEHANDLE ( $HREQUEST ) , 0 )
	_WINHTTPRECEIVERESPONSE ( $HREQUEST )
	If @error Then Return SetError ( 3 , 0 * _WINHTTPCLOSEHANDLE ( $HREQUEST ) , 0 )
	Return $HREQUEST
EndFunc
Func _WINHTTPSIMPLESSLREQUEST ( $HCONNECT , $STYPE = Default , $SPATH = Default , $SREFERRER = Default , $SDATA = Default , $SHEADER = Default , $FGETHEADERS = Default , $IMODE = Default , $SCREDNAME = Default , $SCREDPASS = Default )
	__WINHTTPDEFAULT ( $STYPE , "GET" )
	__WINHTTPDEFAULT ( $SPATH , "" )
	__WINHTTPDEFAULT ( $SREFERRER , $WINHTTP_NO_REFERER )
	__WINHTTPDEFAULT ( $SDATA , $WINHTTP_NO_REQUEST_DATA )
	__WINHTTPDEFAULT ( $SHEADER , $WINHTTP_NO_ADDITIONAL_HEADERS )
	__WINHTTPDEFAULT ( $FGETHEADERS , False )
	__WINHTTPDEFAULT ( $IMODE , Default )
	__WINHTTPDEFAULT ( $SCREDNAME , "" )
	__WINHTTPDEFAULT ( $SCREDPASS , "" )
	If $IMODE > 2 Or $IMODE < 0 Then Return SetError ( 4 , 0 , 0 )
	Local $HREQUEST = _WINHTTPSIMPLESENDSSLREQUEST ( $HCONNECT , $STYPE , $SPATH , $SREFERRER , $SDATA , $SHEADER )
	If @error Then Return SetError ( @error , 0 , 0 )
	__WINHTTPSETCREDENTIALS ( $HREQUEST , $SHEADER , $SDATA , $SCREDNAME , $SCREDPASS )
	If $FGETHEADERS Then
		Local $ADATA [ 2 ] = [ _WINHTTPQUERYHEADERS ( $HREQUEST ) , _WINHTTPSIMPLEREADDATA ( $HREQUEST , $IMODE ) ]
		_WINHTTPCLOSEHANDLE ( $HREQUEST )
		Return $ADATA
	EndIf
	Local $SOUTDATA = _WINHTTPSIMPLEREADDATA ( $HREQUEST , $IMODE )
	_WINHTTPCLOSEHANDLE ( $HREQUEST )
	Return $SOUTDATA
EndFunc
Func __WINHTTPCHARSET ( $SCONTENTTYPE )
	Local $ACONTENTTYPE = StringRegExp ( $SCONTENTTYPE , "(?i).*?\Qcharset=\E(?U)([^ ]+)(;| |\Z)" , 2 )
	If Not @error Then $SCONTENTTYPE = $ACONTENTTYPE [ 1 ]
	If StringLeft ( $SCONTENTTYPE , 2 ) = "cp" Then Return Int ( StringTrimLeft ( $SCONTENTTYPE , 2 ) )
	If $SCONTENTTYPE = "utf-8" Then Return 65001
EndFunc
Func __WINHTTPSETCREDENTIALS ( $HREQUEST , $SHEADERS = "" , $SOPTIONAL = "" , $SCREDNAME = "" , $SCREDPASS = "" )
	If $SCREDNAME And $SCREDPASS Then
		Local $ISTATUSCODE = _WINHTTPQUERYHEADERS ( $HREQUEST , $WINHTTP_QUERY_STATUS_CODE )
		If $ISTATUSCODE = $HTTP_STATUS_DENIED Or $ISTATUSCODE = $HTTP_STATUS_PROXY_AUTH_REQ Then
			Local $ISUPPORTEDSCHEMES , $IFIRSTSCHEME , $IAUTHTARGET
			If _WINHTTPQUERYAUTHSCHEMES ( $HREQUEST , $ISUPPORTEDSCHEMES , $IFIRSTSCHEME , $IAUTHTARGET ) Then
				If $IFIRSTSCHEME = $WINHTTP_AUTH_SCHEME_PASSPORT And $ISTATUSCODE = $HTTP_STATUS_PROXY_AUTH_REQ Then
					_WINHTTPSETOPTION ( $HREQUEST , $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH , $WINHTTP_ENABLE_PASSPORT_AUTH )
					_WINHTTPSETOPTION ( $HREQUEST , $WINHTTP_OPTION_PROXY_USERNAME , $SCREDNAME )
					_WINHTTPSETOPTION ( $HREQUEST , $WINHTTP_OPTION_PROXY_PASSWORD , $SCREDPASS )
				Else
					_WINHTTPSETCREDENTIALS ( $HREQUEST , $IAUTHTARGET , $IFIRSTSCHEME , $SCREDNAME , $SCREDPASS )
				EndIf
				_WINHTTPSENDREQUEST ( $HREQUEST , $SHEADERS , $SOPTIONAL )
				_WINHTTPRECEIVERESPONSE ( $HREQUEST )
			EndIf
		EndIf
	EndIf
EndFunc
Func __WINHTTPDEFAULT ( ByRef $VINPUT , $VOUTPUT )
	If $VINPUT = Default Or Number ( $VINPUT ) = - 1 Then $VINPUT = $VOUTPUT
EndFunc
Func __WINHTTPMEMGLOBALFREE ( $PMEM )
	Local $ACALL = DllCall ( "kernel32.dll" , "ptr" , "GlobalFree" , "ptr" , $PMEM )
	If @error Or $ACALL [ 0 ] Then Return SetError ( 1 , 0 , 0 )
	Return 1
EndFunc
Func __WINHTTPPTRSTRINGLENW ( $PSTRING )
	Local $ACALL = DllCall ( "kernel32.dll" , "dword" , "lstrlenW" , "ptr" , $PSTRING )
	If @error Then Return SetError ( 1 , 0 , 0 )
	Return $ACALL [ 0 ]
EndFunc
Global Const $CLSID_SHELLLINK = "{00021401-0000-0000-C000-000000000046}"
Global Const $SIID_ISHELLLINKW = "{000214F9-0000-0000-C000-000000000046}"
Global Const $TAG_ISHELLLINKW = "GetPath hresult(long;long;long;long);" & "GetIDList hresult(long);" & "SetIDList hresult(long);" & "GetDescription hresult(long;long);" & "SetDescription hresult(wstr);" & "GetWorkingDirectory hresult(long;long);" & "SetWorkingDirectory hresult(long;long);" & "GetArguments hresult(long;long);" & "SetArguments hresult(ptr);" & "GetHotkey hresult(long);" & "SetHotkey hresult(word);" & "GetShowCmd hresult(long);" & "SetShowCmd hresult(int);" & "GetIconLocation hresult(long;long;long);" & "SetIconLocation hresult(wstr;int);" & "SetRelativePath hresult(long;long);" & "Resolve hresult(long;long);" & "SetPath hresult(wstr);"
Global Const $TAG_IPERSIST = "GetClassID hresult(long);"
Global Const $SIID_IPERSISTFILE = "{0000010b-0000-0000-C000-000000000046}"
Global Const $TAG_IPERSISTFILE = $TAG_IPERSIST & "IsDirty hresult();" & "Load hresult(wstr;dword);" & "Save hresult(wstr;bool);" & "SaveCompleted hresult(long);" & "GetCurFile hresult(long);"
Global Const $STGM_READ = 0
Global Const $STGM_READWRITE = 2
Global Const $STGM_SHARE_DENY_NONE = 64
Global Const $TAGPROPERTYKEY = "struct;ulong Data1;ushort Data2;ushort Data3;byte Data4[8];DWORD pid;endstruct"
Global $TAGPROPVARIANT = "USHORT vt;" & "WORD wReserved1;" & "WORD wReserved2;" & "WORD wReserved3;" & "LONG;PTR"
Global Const $SIID_IPROPERTYSTORE = "{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}"
Global Const $VT_EMPTY = 0 , $VT_LPWSTR = 31
Func _WINDOWAPPID ( $HWND , $APPID = Default )
	Local $TPIPROPERTYSTORE = DllStructCreate ( "ptr" )
	_WINAPI_SHGETPROPERTYSTOREFORWINDOW ( $HWND , $SIID_IPROPERTYSTORE , $TPIPROPERTYSTORE )
	Local $PPROPERTYSTORE = DllStructGetData ( $TPIPROPERTYSTORE , 1 )
	Local $OPROPERTYSTORE = ObjCreateInterface ( $PPROPERTYSTORE , $SIID_IPROPERTYSTORE , "GetCount HRESULT(PTR);GetAt HRESULT(DWORD; PTR);GetValue HRESULT(PTR;PTR);" & "SetValue HRESULT(PTR;PTR);Commit HRESULT()" )
	If Not IsObj ( $OPROPERTYSTORE ) Then Return SetError ( 1 , 0 , "" )
	Local $TPKEY = _PKEY_APPUSERMODEL_ID ( )
	Local $TPROPVARIANT = DllStructCreate ( $TAGPROPVARIANT )
	Local $SAPPID
	If $APPID = Default Then
		$OPROPERTYSTORE .GetValue ( DllStructGetPtr ( $TPKEY ) , DllStructGetPtr ( $TPROPVARIANT ) )
		If DllStructGetData ( $TPROPVARIANT , "vt" ) <> $VT_EMPTY Then
			Local $BUF = DllStructCreate ( "wchar[128]" )
			DllCall ( "Propsys.dll" , "long" , "PropVariantToString" , "ptr" , DllStructGetPtr ( $TPROPVARIANT ) , "ptr" , DllStructGetPtr ( $BUF ) , "uint" , DllStructGetSize ( $BUF ) )
			If Not @error Then
				$SAPPID = DllStructGetData ( $BUF , 1 )
			EndIf
		EndIf
	Else
		_WINAPI_INITPROPVARIANTFROMSTRING ( $APPID , $TPROPVARIANT )
		$OPROPERTYSTORE .SetValue ( DllStructGetPtr ( $TPKEY ) , DllStructGetPtr ( $TPROPVARIANT ) )
		$OPROPERTYSTORE .Commit ( )
		$SAPPID = $APPID
	EndIf
	Return SetError ( ( $SAPPID == "" ) * 2 , 0 , $SAPPID )
EndFunc
Func _SHORTCUTAPPID ( $LNKFILE , $APPID = Default )
	Local $OISHELLLINKW = ObjCreateInterface ( $CLSID_SHELLLINK , $SIID_ISHELLLINKW , $TAG_ISHELLLINKW )
	If Not IsObj ( $OISHELLLINKW ) Then Return SetError ( 1 , 0 , "" )
	Local $PIPERSISTFILE , $OIPERSISTFILE , $OPROPERTYSTORE , $RET , $SAPPID
	Local $TRIID_IPERSISTFILE = _WINAPI_GUIDFROMSTRING ( $SIID_IPERSISTFILE )
	$OISHELLLINKW .QueryInterface ( $TRIID_IPERSISTFILE , $PIPERSISTFILE )
	$OIPERSISTFILE = ObjCreateInterface ( $PIPERSISTFILE , $SIID_IPERSISTFILE , $TAG_IPERSISTFILE )
	If IsObj ( $OIPERSISTFILE ) Then
		If $APPID == Default Then
			$RET = $OIPERSISTFILE .Load ( $LNKFILE , BitOR ( $STGM_READ , $STGM_SHARE_DENY_NONE ) )
		Else
			$RET = $OIPERSISTFILE .Load ( $LNKFILE , $STGM_READWRITE )
		EndIf
		If $RET = 0 Then
			Local $TPKEY = _PKEY_APPUSERMODEL_ID ( )
			Local $TPROPVARIANT = DllStructCreate ( $TAGPROPVARIANT )
			$TRIID_IPROPERTYSTORE = _WINAPI_GUIDFROMSTRING ( $SIID_IPROPERTYSTORE )
			Local $PPROPERTYSTORE
			$OISHELLLINKW .QueryInterface ( $TRIID_IPROPERTYSTORE , $PPROPERTYSTORE )
			$OPROPERTYSTORE = ObjCreateInterface ( $PPROPERTYSTORE , $SIID_IPROPERTYSTORE , "GetCount HRESULT(PTR);GetAt HRESULT(DWORD;PTR);GetValue HRESULT(PTR;PTR);" & "SetValue HRESULT(PTR;PTR);Commit HRESULT()" )
			If IsObj ( $OPROPERTYSTORE ) Then
				If $APPID == Default Then
					$OPROPERTYSTORE .GetValue ( DllStructGetPtr ( $TPKEY ) , DllStructGetPtr ( $TPROPVARIANT ) )
					If DllStructGetData ( $TPROPVARIANT , "vt" ) <> $VT_EMPTY Then
						Local $BUF = DllStructCreate ( "wchar[128]" )
						DllCall ( "Propsys.dll" , "long" , "PropVariantToString" , "ptr" , DllStructGetPtr ( $TPROPVARIANT ) , "ptr" , DllStructGetPtr ( $BUF ) , "uint" , DllStructGetSize ( $BUF ) )
						$SAPPID = DllStructGetData ( $BUF , 1 )
					EndIf
				Else
					_WINAPI_INITPROPVARIANTFROMSTRING ( $APPID , $TPROPVARIANT )
					$OPROPERTYSTORE .SetValue ( DllStructGetPtr ( $TPKEY ) , DllStructGetPtr ( $TPROPVARIANT ) )
					$OPROPERTYSTORE .Commit ( )
					$OIPERSISTFILE .Save ( $LNKFILE , True )
					$SAPPID = $APPID
				EndIf
			EndIf
		EndIf
	EndIf
	If IsObj ( $OPROPERTYSTORE ) Then $OPROPERTYSTORE .Release ( )
	If IsObj ( $OIPERSISTFILE ) Then $OIPERSISTFILE .Release ( )
	If IsObj ( $OISHELLLINKW ) Then $OISHELLLINKW .Release ( )
	Return SetError ( ( $SAPPID == "" ) * 2 , 0 , $SAPPID )
EndFunc
Func _WINAPI_INITPROPVARIANTFROMSTRING ( $SUNICODESTRING , ByRef $TPROPVARIANT )
	DllStructSetData ( $TPROPVARIANT , "vt" , $VT_LPWSTR )
	Local $ARET = DllCall ( "Shlwapi.dll" , "LONG" , "SHStrDupW" , "WSTR" , $SUNICODESTRING , "PTR" , DllStructGetPtr ( $TPROPVARIANT ) + 8 )
	If @error Then Return SetError ( @error , @extended , False )
	Local $BSUCCESS = $ARET [ 0 ] == 0
	If ( Not $BSUCCESS ) Then $TPROPVARIANT = DllStructCreate ( $TAGPROPVARIANT )
	Return SetExtended ( $ARET [ 0 ] , $BSUCCESS )
EndFunc
Func _PKEY_APPUSERMODEL_ID ( )
	Local $TPKEY = DllStructCreate ( $TAGPROPERTYKEY )
	_WINAPI_GUIDFROMSTRINGEX ( "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}" , DllStructGetPtr ( $TPKEY ) )
	DllStructSetData ( $TPKEY , "pid" , 5 )
	Return $TPKEY
EndFunc
Func _WINAPI_SHGETPROPERTYSTOREFORWINDOW ( $HWND , $SIID , ByRef $TPOINTER )
	Local $TIID = _WINAPI_GUIDFROMSTRING ( $SIID )
	Local $PP = IsPtr ( $TPOINTER ) ? $TPOINTER : DllStructGetPtr ( $TPOINTER )
	Local $ARET = DllCall ( "Shell32.dll" , "LONG" , "SHGetPropertyStoreForWindow" , "HWND" , $HWND , "STRUCT*" , $TIID , "PTR" , $PP )
	If @error Then Return SetError ( @error , @extended , False )
	Return SetExtended ( $ARET [ 0 ] , ( $ARET [ 0 ] = 0 ) )
EndFunc
Global Const $SCLSID_MMDEVICEENUMERATOR = "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
Global Const $SIID_IMMDEVICEENUMERATOR = "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
Global Const $STAGIMMDEVICEENUMERATOR = "EnumAudioEndpoints hresult(int;dword;ptr*);" & "GetDefaultAudioEndpoint hresult(int;int;ptr*);" & "GetDevice hresult(wstr;ptr*);" & "RegisterEndpointNotificationCallback hresult(ptr);" & "UnregisterEndpointNotificationCallback hresult(ptr)"
Global Const $SIID_IMMDEVICE = "{D666063F-1587-4E43-81F1-B948E807363F}"
Global Const $STAGIMMDEVICE = "Activate hresult(struct*;dword;ptr;ptr*);" & "OpenPropertyStore hresult(dword;ptr*);" & "GetId hresult(wstr*);" & "GetState hresult(dword*)"
Global Const $SIID_IAUDIOSESSIONMANAGER2 = "{77aa99a0-1bd6-484f-8bc7-2c654c9a9b6f}"
Global Const $STAGIAUDIOSESSIONMANAGER = "GetAudioSessionControl hresult(ptr;dword;ptr*);" & "GetSimpleAudioVolume hresult(ptr;dword;ptr*);"
Global Const $STAGIAUDIOSESSIONMANAGER2 = $STAGIAUDIOSESSIONMANAGER & "GetSessionEnumerator hresult(ptr*);" & "RegisterSessionNotification hresult(ptr);" & "UnregisterSessionNotification hresult(ptr);" & "RegisterDuckNotification hresult(wstr;ptr);" & "UnregisterDuckNotification hresult(ptr)"
Global Const $SIID_IAUDIOSESSIONENUMERATOR = "{e2f5bb11-0570-40ca-acdd-3aa01277dee8}"
Global Const $STAGIAUDIOSESSIONENUMERATOR = "GetCount hresult(int*);GetSession hresult(int;ptr*)"
Global Const $STAGIAUDIOSESSIONCONTROL = "GetState hresult(int*);GetDisplayName hresult(ptr);" & "SetDisplayName hresult(wstr);GetIconPath hresult(ptr);" & "SetIconPath hresult(wstr;ptr);GetGroupingParam hresult(ptr*);" & "SetGroupingParam hresult(ptr;ptr);RegisterAudioSessionNotification hresult(ptr);" & "UnregisterAudioSessionNotification hresult(ptr);"
Global Const $SIID_IAUDIOSESSIONCONTROL2 = "{bfb7ff88-7239-4fc9-8fa2-07c950be9c6d}"
Global Const $STAGIAUDIOSESSIONCONTROL2 = $STAGIAUDIOSESSIONCONTROL & "GetSessionIdentifier hresult(ptr)" & "GetSessionInstanceIdentifier hresult(ptr);" & "GetProcessId hresult(dword*);IsSystemSoundsSession hresult();" & "SetDuckingPreferences hresult(bool);"
Global Const $SIID_ISIMPLEAUDIOVOLUME = "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"
Global Const $STAGISIMPLEAUDIOVOLUME = "SetMasterVolume hresult(float;ptr);" & "GetMasterVolume hresult(float*);" & "SetMute hresult(int;ptr);" & "GetMute hresult(int*)"
Global $__OIAUDIOSESSIONMANAGER2
Func AUDIO_SETAPPMUTE ( $PID , $BMUTE = 0 )
	If Not IsObj ( $__OIAUDIOSESSIONMANAGER2 ) Then
		$__OIAUDIOSESSIONMANAGER2 = AUDIO_GETIAUDIOSESSIONMANAGER2 ( )
	EndIf
	If Not IsObj ( $__OIAUDIOSESSIONMANAGER2 ) Then Return
	Local $PIAUDIOSESSIONENUMERATOR , $OIAUDIOSESSIONENUMERATOR
	If $__OIAUDIOSESSIONMANAGER2 .GetSessionEnumerator ( $PIAUDIOSESSIONENUMERATOR ) < 0 Then Return
	$OIAUDIOSESSIONENUMERATOR = ObjCreateInterface ( $PIAUDIOSESSIONENUMERATOR , $SIID_IAUDIOSESSIONENUMERATOR , $STAGIAUDIOSESSIONENUMERATOR )
	If Not IsObj ( $OIAUDIOSESSIONENUMERATOR ) Then Return SetError ( 1 )
	Local $I , $NSESSIONS , $PIAUDIOSESSIONCONTROL2 , $OIAUDIOSESSIONCONTROL2
	Local $PROCESSID , $OISIMPLEAUDIOVOLUME , $OK = 0
	If $OIAUDIOSESSIONENUMERATOR .GetCount ( $NSESSIONS ) >= 0 Then
		For $I = 0 To $NSESSIONS - 1
			If $OIAUDIOSESSIONENUMERATOR .GetSession ( $I , $PIAUDIOSESSIONCONTROL2 ) >= 0 Then
				$OIAUDIOSESSIONCONTROL2 = ObjCreateInterface ( $PIAUDIOSESSIONCONTROL2 , $SIID_IAUDIOSESSIONCONTROL2 , $STAGIAUDIOSESSIONCONTROL2 )
				If @error Then ContinueLoop
				$OIAUDIOSESSIONCONTROL2 .GetProcessId ( $PROCESSID )
				If $PROCESSID = $PID Then
					$OISIMPLEAUDIOVOLUME = ObjCreateInterface ( $PIAUDIOSESSIONCONTROL2 , $SIID_ISIMPLEAUDIOVOLUME , $STAGISIMPLEAUDIOVOLUME )
					If @error Then ContinueLoop
					$OIAUDIOSESSIONCONTROL2 .AddRef ( )
					If $OISIMPLEAUDIOVOLUME .SetMute ( $BMUTE , 0 ) >= 0 Then
						$OK = 1
						ExitLoop
					EndIf
				EndIf
			EndIf
		Next
	EndIf
	$OISIMPLEAUDIOVOLUME = 0
	$OIAUDIOSESSIONCONTROL2 = 0
	$OIAUDIOSESSIONENUMERATOR = 0
	Return $OK
EndFunc
Func AUDIO_GETIAUDIOSESSIONMANAGER2 ( )
	Local $OIAUDIOSESSIONMANAGER2 = 0
	Local Const $EMULTIMEDIA = 1 , $CLSCTX_INPROC_SERVER = 1
	Local $PIMMDEVICE , $OMMDEVICE , $PIAUDIOSESSIONMANAGER2
	Local $OMMDEVICEENUMERATOR = ObjCreateInterface ( $SCLSID_MMDEVICEENUMERATOR , $SIID_IMMDEVICEENUMERATOR , $STAGIMMDEVICEENUMERATOR )
	If IsObj ( $OMMDEVICEENUMERATOR ) Then
		If $OMMDEVICEENUMERATOR .GetDefaultAudioEndpoint ( 0 , $EMULTIMEDIA , $PIMMDEVICE ) >= 0 Then
			$OMMDEVICE = ObjCreateInterface ( $PIMMDEVICE , $SIID_IMMDEVICE , $STAGIMMDEVICE )
			If IsObj ( $OMMDEVICE ) Then
				If $OMMDEVICE .Activate ( __UUIDOF ( $SIID_IAUDIOSESSIONMANAGER2 ) , $CLSCTX_INPROC_SERVER , 0 , $PIAUDIOSESSIONMANAGER2 ) >= 0 Then
					$OIAUDIOSESSIONMANAGER2 = ObjCreateInterface ( $PIAUDIOSESSIONMANAGER2 , $SIID_IAUDIOSESSIONMANAGER2 , $STAGIAUDIOSESSIONMANAGER2 )
				EndIf
				$OMMDEVICE = 0
			EndIf
		EndIf
		$OMMDEVICEENUMERATOR = 0
	EndIf
	If IsObj ( $OIAUDIOSESSIONMANAGER2 ) Then
		Return $OIAUDIOSESSIONMANAGER2
	EndIf
EndFunc
Func __UUIDOF ( $SGUID )
	Local $TGUID = DllStructCreate ( "ulong Data1;ushort Data2;ushort Data3;byte Data4[8]" )
	DllCall ( "ole32.dll" , "long" , "CLSIDFromString" , "wstr" , $SGUID , "struct*" , $TGUID )
	If @error Then Return SetError ( @error , @extended , 0 )
	Return $TGUID
EndFunc
Func _RUNDOS ( $SCOMMAND )
	Local $NRESULT = RunWait ( @ComSpec & " /C " & $SCOMMAND , "" , @SW_HIDE )
	Return SetError ( @error , @extended , $NRESULT )
EndFunc
Global Const $SCS_32BIT_BINARY = 0
Global Const $SCS_64BIT_BINARY = 6
Func _WINAPI_GETBINARYTYPE ( $SFILEPATH )
	Local $ARET = DllCall ( "kernel32.dll" , "int" , "GetBinaryTypeW" , "wstr" , $SFILEPATH , "dword*" , 0 )
	If @error Then Return SetError ( @error , @extended , 0 )
	If Not $ARET [ 0 ] Then $ARET [ 2 ] = 0
	Return SetExtended ( $ARET [ 2 ] , $ARET [ 0 ] )
EndFunc
Func _STRINGENDSWITH ( $SINPUT , $SSEARCH , $FCASESENSITIVE = False )
	$ISEARCHLEN = StringLen ( $SSEARCH )
	$IINPUTLEN = StringLen ( $SINPUT )
	If ( ( $SINPUT = "" ) Or ( $SSEARCH = "" ) ) Then
		SetError ( 2 )
		Return False
	EndIf
	If ( $ISEARCHLEN > $IINPUTLEN ) Then
		SetError ( 1 )
		Return False
	EndIf
	If ( $FCASESENSITIVE == True ) Then
		If ( StringMid ( $SINPUT , $IINPUTLEN - $ISEARCHLEN + 1 , $ISEARCHLEN ) == $SSEARCH ) Then
			Return True
		EndIf
	Else
		If ( StringMid ( $SINPUT , $IINPUTLEN - $ISEARCHLEN + 1 , $ISEARCHLEN ) = $SSEARCH ) Then
			Return True
		EndIf
	EndIf
	SetError ( 0 )
	Return False
EndFunc