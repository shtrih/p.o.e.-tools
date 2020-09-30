#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Hitagi

 Script Function:
	Seal prophecies and put it into inventory. Works on 1920x1080 fullscreen (or borderless).
#ce ----------------------------------------------------------------------------
#pragma compile(Console, true)
#pragma compile(x64, true)

#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>
#include <include/Items.au3>

Global Const $DEBUG = $CmdLine[0] ? $CmdLine[1] = 'debug' : False

HotKeySet("^k", "Start")
HotKeySet("^l", "Stop")

Global $hWnd
Global $isStarted = False
Global $inventoryNeedRescan = False

Global Const $PropheciesPositions = [ [320, 256], [168,  315], [458, 315], [132, 480], [492, 480], [224, 640], [408, 640] ]
Global Const $ProphecySeekButtonPositions = [ [298, 770], [365, 787] ]
Global Const $ProphecySealButtonPositions = [ [298, 215], [365, 232] ]

Global Const $BORDER_WIDTH = 3
Global Const $CELL_WIDTH = 50
Global Const $CELL_START_POS_X = 1269
Global Const $CELL_START_POS_Y = 585
Global Const $HOR_COUNT = 12
Global Const $VERT_COUNT = 5
Global Const $CELL_EMPTY_CHECKSUM = 5

Main()

Func Main()
   $hWnd = WinGetHandle("Path of Exile")
   ;$hWnd = WinGetHandle("XnView - [PathOfExile_x64Steam_2020-09-28_17-52-04-5.png]")

   If @error Then
	 MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
	 Exit
   EndIf

   Log_(@ScriptName & ' is ready. Open Navali Prophecies dialog and press Ctrl+K to start or Ctrl+L to pause!')

   $inventory = False

   While True
	  WinWaitActive($hWnd)

;   $inventory = InventoryScan()
;   InventoryPutItem($inventory)
;   If @error Then Log_('errror')

;   Beep(500, 500)
;   Exit

	  ; Check Prophecy Window is open
	  ;  No:
	  ;   Stop Script
	  ; Check Prophecy Exists
	  ;  Yes:
	  ;   Click Seal Button
	  ;   Check "not enough coins" dialog
	  ;    Yes:
	  ;     Stop Script
	  ;    No:
	  ;     Confirm Prophecy Sealing
	  ;     Move to inventory step
	  ;  No:
	  ;   Click Seek Button
	  ;   Check "not enough coins" dialog
	  ;    Yes:
	  ;     Stop Script
	  ;    No:
	  ;     Move to "Check Prophecy Window is open" step
	  Sleep(100)

	  If Not $isStarted Then
		 ContinueLoop
	  EndIf

	  If CheckProphWindowOpen() Then
		 Log_('Prophecies window is Open')
	  Else
		 SetStateStop('Prophecies window is Closed.')
		 ContinueLoop
	  EndIf

	  If CheckProphecyExist() Then
		 PressSeal()
		 Sleep(100)

		 If CheckEmptyWalletDialog() Then
			SetStateStop('Not enough Silver coins to Seal.')
			ContinueLoop
		 EndIf

		 If CheckConfirmDialog() Then
			PressConfirmDialog()
		 Else
			SetStateStop('Unknown problem in CheckConfirmDialog.')
			ContinueLoop
		 EndIf

		 If CheckInventoryClosed() Then
			Log_('Opening inventory...')
			Send('{I}')
		 EndIf

		 If Not IsArray($inventory) Or $inventoryNeedRescan Then
			$inventoryNeedRescan = False
			$inventory = InventoryScan()
		 EndIf

		 InventoryPutItem($inventory)
		 If @error Then
			SetStateStop('Inventory is full.')
			ContinueLoop
		 EndIf

		 ;SetStateStop('TODO.')
		 ;ContinueLoop
	  Else
		 PressSeek()
		 Sleep(100)

		 If CheckEmptyWalletDialog() Then
			SetStateStop('Not enough Silver coins to Seek.')
			ContinueLoop
		 EndIf

		 ;ContinueLoop
	  EndIf
   WEnd
EndFunc

Func Start($state = True)
   $state = IsDeclared('state') ? $state : True ; Because HotKeySet ignore default values of arguments too!

   $inventoryNeedRescan = True
   $isStarted = $state
   Log_('Started: ' & $isStarted)

   Beep($isStarted ? 250 : 200, 250)
EndFunc

Func Stop()
   SetStateStop('Sent Stop signal.')
EndFunc

Func CheckProphWindowOpen()
   $left = $ProphecySeekButtonPositions[0][0]
   $top = $ProphecySeekButtonPositions[1][1]
   $right = $left + 3
   $bottom = $top + 1
   ; Used 'Seek' button to check. It have 3 states...
   Const $CHECKSUM = 1928661472
   Const $CHECKSUM_HOVER = 2469203117
   Const $CHECKSUM_DISABLED = 1724451001

   $checksumActual = PixelChecksum($left, $top, $right, $bottom, 1, $hWnd)
   If $DEBUG Then Log_('CheckProphWindowOpen: ' & PixelChecksum($left, $top, $right, $bottom, 1, $hWnd))
   Return $CHECKSUM = $checksumActual Or $CHECKSUM_HOVER = $checksumActual Or $CHECKSUM_DISABLED = $checksumActual
EndFunc

Func CheckProphecyExist()
   $left = $PropheciesPositions[0][0]
   $top = $PropheciesPositions[0][1]
   $right = $left + 3
   $bottom = $top + 1
   Const $CHECKSUM = 1701578884

   $checksumActual = PixelChecksum($left, $top, $right, $bottom, 1, $hWnd)
   If $DEBUG Then Log_('CheckProphecyExist: ' & $checksumActual)

   Return $CHECKSUM = $checksumActual
EndFunc

Func PressSeek()
   $x = Random($ProphecySeekButtonPositions[0][0], $ProphecySeekButtonPositions[1][0], 1)
   $y = Random($ProphecySeekButtonPositions[0][1], $ProphecySeekButtonPositions[1][1], 1)
   $speed = Random(10, 20, 1)

   Log_('PressSeek')
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func PressSeal()
   $x = Random($ProphecySealButtonPositions[0][0], $ProphecySealButtonPositions[1][0], 1)
   $y = Random($ProphecySealButtonPositions[0][1], $ProphecySealButtonPositions[1][1], 1)
   $speed = Random(10, 20, 1)

   Log_('PressSeal')
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func CheckEmptyWalletDialog()
   Const $POSITION_X = 962
   Const $POSITION_Y = 508
   Const $DELTA_X = 16
   Const $DELTA_Y = 1
   Const $CHECKSUM = 3145278307

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   If $DEBUG Then Log_('CheckEmptyWalletDialog: ' & $checksumActual)

   Return $CHECKSUM = $checksumActual
EndFunc

Func CheckConfirmDialog()
   Const $POSITION_X = 820
   Const $POSITION_Y = 541
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   Const $CHECKSUM = 1266288032

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   If $DEBUG Then Log_('CheckConfirmDialog: ' & $checksumActual)

   Return $CHECKSUM = $checksumActual
EndFunc

Func PressConfirmDialog()
   $x = Random(777, 896, 1)
   $y = Random(542, 568, 1)
   $speed = Random(10, 20, 1)

   Log_('PressConfirmDialog')
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func CheckInventoryClosed()
   Const $POSITION_X = 1415
   Const $POSITION_Y = 74
   Const $DELTA_X = 7
   Const $DELTA_Y = 1
   Const $CHECKSUM = 147196555

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   If $DEBUG Then Log_('CheckInventoryClosed: ' & $checksumActual)

   Return $CHECKSUM <> $checksumActual
EndFunc

Func CellNum2PixelPos($numX, $numY)
   $posX = $CELL_START_POS_X + ($CELL_WIDTH * $numX) + ($BORDER_WIDTH * ($numX + 1))
   $posY = $CELL_START_POS_Y + ($CELL_WIDTH * $numY) + ($BORDER_WIDTH * ($numY + 1))

   Local $result[2] = [$posX, $posY]

   Return $result
EndFunc

Func CellIsEmpty($numX, $numY)
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   $cellPixelPositions = CellNum2PixelPos($numX, $numY)
   Const $POSITION_X = $cellPixelPositions[0] + 23
   Const $POSITION_Y = $cellPixelPositions[1] + 24

   If $DEBUG Then Log_(StringFormat('CellIsEmpty(%s, %s)(%s, %s, %s, %s)', $numX, $numY, $POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y))

   PixelSearch($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 0x050505, 5, 1, $hWnd)

   Return Not @error
EndFunc

Func InventoryScan()
   $inventoryNeedRescan = False

   Log_('Scanning inventory...')
   Local $result[$HOR_COUNT * $VERT_COUNT]

   Local $counter = 0
   For $x = 0 to ($HOR_COUNT - 1)
	  For $y = 0 to ($VERT_COUNT - 1)
		 If CellIsEmpty($x, $y) Then
			Local $cell[2] = [$x, $y]
			$result[$counter] = $cell

			$counter += 1
		 EndIf
	  Next
   Next

   Return $result
EndFunc

Func InventoryFindEmptySpace($inventory)
   Local $result[2]

   For $i = 0 To UBound($inventory) - 1
	  If IsArray($inventory[$i]) Then
		 $result[0] = $i
		 $result[1] = $inventory[$i]

		 Return $result
	  EndIf
   Next

   Return False
EndFunc

Func InventoryPutItem(ByRef $inventory)
   $cell = InventoryFindEmptySpace($inventory)

   If Not IsArray($cell) Then
	  Return SetError(1, 0, 0)
   EndIf

   $invKey = $cell[0]
   $cellPos = $cell[1]

   $inventory[ $invKey ] = False

   $mousePos = CellNum2PixelPos($cellPos[0], $cellPos[1])
   Const $x = Random($mousePos[0], $mousePos[0] + $CELL_WIDTH, 1)
   Const $y = Random($mousePos[1], $mousePos[1] + $CELL_WIDTH, 1)
   Const $speed = Random(10, 20, 1)

   If $DEBUG Then Log_(StringFormat('InventoryPutItem(%s, %s)(%s, %s)', $cellPos[0], $cellPos[1], $x, $y))
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func SetStateStop($reason = '')
   If $reason Then Log_($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc
;https://poe.ninja/api/data/itemoverview?league=Heist&type=Prophecy&language=en
Func Log_($data)
   $data = _Now() & ' - ' & $data

;~    $FileName = @ScriptDir & '\' & @ScriptName & '.log'
;~    $hFile = FileOpen($FileName, 1)
;~    If $hFile <> -1 Then
;~ 	 FileWriteLine($hFile, $data)
;~ 	 FileClose($hFile)
;~    EndIf

   ConsoleWrite($data & @CRLF)
EndFunc