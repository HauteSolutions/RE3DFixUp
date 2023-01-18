#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <File.au3>
#include <FileConstants.au3>
#include <AutoItConstants.au3>

; This project requires the ZIP UDF (zipfldr.dll library) by wraithdu: https://www.autoitscript.com/forum/topic/116565-zip-udf-zipfldrdll-library/
#include <_Zip.au3>

Global $ProgName="RE3DFixUp"
Global $ProgVer="v1.02"
Global $ProgTitle = $ProgName & " " & $ProgVer

Global $XPSInputFile = ""
Global $XPSInputFolder = ""
Global $XPSOutputFile = ""
Global $XPSOutputFolder = ""
Global $TempFolder = ""
Global $Welcome = ""

Global $IniFile

; Ensure Master Script Directory is Set As Working Dir
FileChangeDir(@ScriptDir)

; Determine INI Config file name
$IniFile = StringTrimRight(@ScriptFullPath,4) & ".ini"

; Get INI Data
GetConfig($IniFile)

; Display Startup Screen
If $Welcome = "" Then
	DisplayStartup()
	IniWrite($IniFile, "Config", "Welcome", "Done")
EndIf

; Get XPS File Name
$XPSInputFile = FileOpenDialog($ProgTitle, ".", "XPS Files (*.xps)", $FD_FILEMUSTEXIST)
If @error Then
	Info_Exit("No file selected", 1)
EndIf

; Calculate Temp Folder Names
If $TempFolder = "" Then
	$XPSInputFolder = _TempFile(@TempDir, "XPSInput_")
	$XPSInputFolder = StringTrimRight($XPSInputFolder, 4)
	$XPSOutputFolder = _TempFile(@TempDir, "XPSOutput_")
	$XPSOutputFolder = StringTrimRight($XPSOutputFolder, 4)
Else
	If NOT FileExists($TempFolder) Then
		If NOT DirCreate($TempFolder) Then Error_Exit("Unable to Create Temp Folder: " & $TempFolder, 1)
	EndIf
	$XPSInputFolder = $TempFolder & "\XPSInput"
	$XPSOutputFolder = $TempFolder & "\XPSOutput"
	If FileExists($XPSInputFolder) then DirRemove($XPSInputFolder, $DIR_REMOVE)
	If FileExists($XPSOutputFolder) then DirRemove($XPSOutputFolder, $DIR_REMOVE)
EndIf

; Extract XPS File to Temp folder (XPSInputFolder)
Local $TempFile = _TempFile(@TempDir, "~", ".zip")
FileCopy($XPSInputFile, $TempFile)
DirCreate($XPSInputFolder)
_Zip_UnzipAll($TempFile, $XPSInputFolder)
FileDelete($TempFile)

; Confirm this XPS File uses a RESOURCES folder
If Not FileExists($XPSInputFolder & "\Resources") Then
	Info_Exit("Input File (" & $XPSInputFile & ") Does Not Require Conversion", 2)
EndIf

; Copy Temporary XPSInputFolder to Temporary XPSOutputFolder
DirCopy($XPSInputFolder, $XPSOutputFolder)

; Process all *.fpage files...
Local $hSearch = FileFindFirstFile($XPSInputFolder & "\Documents\1\Pages\*.fpage")
If $hSearch = -1 Then
	Error_Exit("No *.fpage files found in XPS File: " & $XPSInputFile, 3)
EndIf
Local $StaticResourceCounter=0
While 1
	Local $sFileName = FileFindNextFile($hSearch)
	If @error Then ExitLoop

	$StaticResourceCounter += ProcessFPageFile($XPSInputFolder, $XPSOutputFolder, $sFileName)
WEnd
FileClose($hSearch)

If $StaticResourceCounter > 0 Then

	$XPSOutputFile = StringTrimRight($XPSInputFile, 4) & "_RE3DFixed"
	_Zip_Create($XPSOutputFile & ".zip", 1)

	Local $hSearch = FileFindFirstFile($XPSOutputFolder & "\*.*")
	While 1
		Local $sFileName = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		_Zip_AddItem($XPSOutputFile & ".zip", $XPSOutputFolder & "\" & $sFileName)
	WEnd
	FileClose($hSearch)

	If FileExists($XPSOutputFile & ".xps") Then
		Local $Response = MsgBox($MB_ICONQUESTION + $MB_YESNO, $ProgTitle, "Output File: " & $XPSOutputFile & ".xps Exists" & @CRLF & @CRLF & "OK To Overwrite?")
		If $Response = $IDNO Then
			msgbox($MB_ICONINFORMATION, $ProgTitle, "Static Resources Found: " & $StaticResourceCounter & @CRLF & @CRLF & "New File: " & $XPSOutputFile & ".zip")
			Cleanup()
			Exit
		EndIf
	EndIf

	FileMove($XPSOutputFile & ".zip", $XPSOutputFile & ".xps", $FC_OVERWRITE)
	msgbox($MB_ICONINFORMATION, $ProgTitle, $StaticResourceCounter & " Static Resources Converted" & @CRLF & @CRLF & "New File: " & $XPSOutputFile & ".xps")

Else
	msgbox($MB_ICONINFORMATION, $ProgTitle, "NO Static Resources Found!" & @CRLF & @CRLF & "No Conversion Necessary!")
EndIf

; Cleanup
CleanUp()

;-------------------------------------------------------------------------------------------------------------------------------------------------

Func ProcessFPageFile($XPSInputFolder, $XPSOutputFolder, $FPageFile)
Local $DictionaryString = '<ResourceDictionary Source="'
Local $ResourceString = '{StaticResource '
Local $HitCount = 0

	Local $TempFile = _TempFile()

	Local $FPageFileIn = $XPSInputFolder & "\Documents\1\Pages\" & $FPageFile  ; Why is the search not returning full path names?
	Local $FPageFileOut = $XPSOutputFolder & "\Documents\1\Pages\" & $FPageFile

	Local $DictFile = ""
	Local $DictFileIn = ""

	Local $hInFile = FileOpen($FPageFileIn, $FO_READ)
	If $hInFile = -1 Then
		Error_Exit("Reading Input FPageFile: " & $FpageFile, 4)
	EndIf

	Local $hOutFile = FileOpen($TempFile, $FO_OVERWRITE)
	If $hInFile = -1 Then
		Error_Exit("Opening Output FPageFile: " & $TempFile, 5)
	EndIf

	While 1

		Local $Line = FileReadLine($hInFile)
		if @error <> 0 Then ExitLoop

		Local $PosFound = StringInStr($Line, $DictionaryString)
		If $PosFound <> 0 Then
			Local $Temp = StringTrimLeft($Line, $PosFound + StringLen($DictionaryString) - 1)
			Local $TempArray = StringSplit($Temp, '"')
			$DictFile = $TempArray[1]
			$DictFileIn = $XPSInputFolder & $DictFile
			; msgbox($MB_ICONINFORMATION,"Found Resource Dictionary", $DictFileIn)
		EndIf

		$PosFound = StringInStr($Line, $ResourceString)
		If $PosFound <> 0 Then
			If $DictFileIn = "" Then Error_Exit("DictFile Not Referenced", 6)
			$HitCount += 1
			Local $Temp = StringTrimLeft($Line, $PosFound + StringLen($ResourceString) - 1)
			Local $TempArray = StringSplit($Temp, "}")
			Local $ResourceName = $TempArray[1]
			; msgbox($MB_ICONINFORMATION,"Found Resource Reference", $ResourceName)

			Local $ResourceData = GetResourceData($DictFileIn, $ResourceName)
			;msgbox($MB_ICONINFORMATION,"Resource Data", $ResourceData)

			Local $RTPos = StringInStr($Line, "RenderTransform=")
			If $RTPos = 0 Then Error_Exit("Render Transform Not Found for Resource " & $ResourceName, 7)
			Local $RenderTransform = StringTrimLeft($Line, $RTPos - 1)

			Local $NewRecord = '	<Path Data="F1 ' & $ResourceData & '" ' & $RenderTransform

			FileWriteLine($hOutFile, $NewRecord)
		Else
			FileWriteLine($hOutFile, $Line)
		EndIf

	WEnd

	FileClose($hOutFile)
	FileClose($hInFile)

	FileCopy($TempFile, $FPageFileOut, $FC_OVERWRITE)
	FileDelete($TempFile)

	Return $HitCount

EndFunc

Func GetResourceData($ResourceFile, $Resource)
Local $ResourceData = ""

	Local $hInFile = FileOpen($ResourceFile, $FO_READ)
	If $hInFile = -1 Then
		Error_Exit("Reading Input DictFile: " & $ResourceFile, 8)
	EndIf

	Local $Found = 0
	While 1

		Local $Line = FileReadLine($hInFile)
		if @error <> 0 Then ExitLoop

		If StringInStr($Line, '<PathGeometry') and StringInStr($Line, 'Key="' & $Resource & '"') Then
			$Found += 1
			Local $FigPos = StringInStr($Line, 'Figures="')
			If $FigPos = 0 Then Error_Exit("Resource Not Found in Dict File", 9)
			$Line = StringTrimLeft($Line, $FigPos + StringLen('Figures="') - 1)

			While 1
				Local $EndPos = StringInStr($Line, '"')
				If $EndPos > 0 Then
					$Line = StringLeft($Line, $EndPos - 1)
					$ResourceData &= $Line
					Return $ResourceData
				EndIf

				$ResourceData &= $Line
				$ResourceData &= @CRLF
				$Line = FileReadLine($hInFile)
			WEnd

		EndIf

	WEnd

	FileClose($hInFile)

EndFunc

Func Error_Exit($msg, $exit_code)
	MsgBox($MB_ICONERROR, $ProgTitle, "Error: " & $msg)
	Cleanup($exit_code)
	Exit($exit_code)
EndFunc

Func Info_Exit($msg, $exit_code)
	MsgBox($MB_ICONINFORMATION, $ProgTitle, $msg)
	CleanUp($exit_code)
	Exit($exit_code)
EndFunc

Func CleanUp($exit_code = 0)
	If $TempFolder = "" Then
		If FileExists($XPSOutputFolder) Then DirRemove($XPSOutputFolder, $DIR_REMOVE)
		If FileExists($XPSInputFolder) Then DirRemove($XPSInputFolder, $DIR_REMOVE)
	ElseIf $exit_code = 0 Then
		MsgBox($MB_ICONINFORMATION, $ProgTitle, "Temp Folders Preserved:" & @CRLF & @CRLF & _
		"Input Folder:  " & $XPSInputFolder & @CRLF & _
		"Output Folder: " & $XPSOutputFolder)
	EndIf

EndFunc

Func GetConfig($IniFile)
	If FileExists($IniFile) then
		$TempFolder = IniRead($IniFile, "Config", "TempFolder", $TempFolder)
		$Welcome    = IniRead($IniFile, "Config", "Welcome",    $Welcome)
	EndIf
EndFunc

Func DisplayStartup()
Local $msg = "So, you bought a laser from a company which uses both" & @CRLF & _
			 "proprietary hardware and proprietary software.  Now they" & @CRLF & _
			 "don't want to support the proprietary software they" & @CRLF & _
			 "created and its the ONLY software which will talk with" & @CRLF & _
			 "the proprietary hardware in your very expensive Laser." & @CRLF & _
			 @CRLF & _
			 "Maybe next time you should consider purchasing" & @CRLF & _
			 "non-proprietary products from a DIFFERENT company" & @CRLF & _
			 "which is willing to provide proper support for their" & @CRLF & _
			"their customers and products?" & @CRLF & _
			 @CRLF & _
			 "Just sayin'..."

	msgbox($MB_ICONWARNING, $ProgTitle, $msg)
EndFunc


