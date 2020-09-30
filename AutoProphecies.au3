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
#include "include/Storage.au3"
#include "include/Log_.au3"

HotKeySet("^k", "Start")
HotKeySet("^l", "Stop")

Global $hWnd
Global $isStarted = False
Global $inventoryNeedRescan = False

Global Const $PropheciesPositions = [ [320, 256], [168,  315], [458, 315], [132, 480], [492, 480], [224, 640], [408, 640] ]
Global Const $ProphecySeekButtonPositions = [ [298, 770], [365, 787] ]
Global Const $ProphecySealButtonPositions = [ [298, 215], [365, 232] ]

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

Main()

Func Main()
   $hWnd = WinGetHandle("Path of Exile")
   ;$hWnd = WinGetHandle("XnView - [PathOfExile_x64Steam_2020-09-28_17-52-04-5.png]")

   If @error Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
     Exit
   EndIf

   Log_(@ScriptName & ' is ready. Open Navali Prophecies dialog and press Ctrl+K to start or Ctrl+L to pause!')

   InitInventory()
   Local $inventory = False

   While True
      WinWaitActive($hWnd)

   ;   $inventory = InventoryScan()
   ;   InventoryPutItem($inventory)
   ;   If @error Then Log_('errror')

   ;   Beep(500, 500)
   ;   Exit
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
            Log_('Scanning inventory...')
            $inventory = StorageScan(0x050505, 5)
         EndIf

         StoragePutItem($inventory)
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
   Log_('CheckProphWindowOpen: ' & PixelChecksum($left, $top, $right, $bottom, 1, $hWnd), $LOG_LEVEL_DEBUG)
   Return $CHECKSUM = $checksumActual Or $CHECKSUM_HOVER = $checksumActual Or $CHECKSUM_DISABLED = $checksumActual
EndFunc

Func CheckProphecyExist()
   $left = $PropheciesPositions[0][0]
   $top = $PropheciesPositions[0][1]
   $right = $left + 3
   $bottom = $top + 1
   Const $CHECKSUM = 1701578884

   $checksumActual = PixelChecksum($left, $top, $right, $bottom, 1, $hWnd)
   Log_('CheckProphecyExist: ' & $checksumActual, $LOG_LEVEL_DEBUG)

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
   Log_('CheckEmptyWalletDialog: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM = $checksumActual
EndFunc

Func CheckConfirmDialog()
   Const $POSITION_X = 820
   Const $POSITION_Y = 541
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   Const $CHECKSUM = 1266288032

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   Log_('CheckConfirmDialog: ' & $checksumActual, $LOG_LEVEL_DEBUG)

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
   Log_('CheckInventoryClosed: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM <> $checksumActual
EndFunc

Func InitInventory()
   Const $_BORDER_WIDTH = 3
   Const $_CELL_WIDTH = 50
   Const $_CELL_START_POS_X = 1269
   Const $_CELL_START_POS_Y = 585
   Const $_HOR_COUNT = 12
   Const $_VERT_COUNT = 5

   InitStorageSettings($_BORDER_WIDTH, $_CELL_WIDTH, $_CELL_START_POS_X, $_CELL_START_POS_Y, $_HOR_COUNT, $_VERT_COUNT)
EndFunc

Func SetStateStop($reason = '')
   If $reason Then Log_($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc
;https://poe.ninja/api/data/itemoverview?league=Heist&type=Prophecy&language=en
