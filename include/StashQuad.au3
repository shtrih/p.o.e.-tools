#include-once

#include <AutoItConstants.au3>
#include "Log_.au3"
#include "Storage.au3"
#include <Array.au3>

;HotKeySet('{ESC}', 'Terminate')

;$hWnd = WinGetHandle("XnView")
;WinWaitActive($hWnd)
;Beep(250, 250)
;InitStashQuadSettings()
;$aStash = StashQuadScan()
;Beep(150, 250)
;_ArrayDisplay($aStash)
;Log_(IsStorageVisible())
;Beep(100, 250)

Func InitStashQuadSettings()
   Const $iBorderWidth   = 2
   Const $iCellWidth     = 24.5 ; Because cell size is sometimes 24 or 25
   Const $iCellStartPosX = 15
   Const $iCellStartPosY = 160
   Const $iHorCount      = 24
   Const $iVertCount     = 24

   InitStorageSettings($iBorderWidth, $iCellWidth, $iCellStartPosX, $iCellStartPosY, $iHorCount, $iVertCount)
EndFunc

Func StashQuadScan()
   Return StorageScan(0x050505, 5)
EndFunc

Func Terminate()
   Exit
EndFunc

