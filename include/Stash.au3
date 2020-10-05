#include-once

#include <AutoItConstants.au3>
#include "Log_.au3"
#include "Storage.au3"
#include <Array.au3>

;$hWnd = WinGetHandle("XnView")
;WinWaitActive($hWnd)
;Beep(250, 250)
;InitStashSettings()
;$aStash = StashScan()
;_ArrayDisplay($aStash)
;Log_(IsStorageVisible())
;Beep(250, 250)

Func InitStashSettings()
   Const $iBorderWidth   = 2
   Const $iCellWidth     = 50.5 ; Because cell size is sometimes 50 or 51
   Const $iCellStartPosX = 15
   Const $iCellStartPosY = 160
   Const $iHorCount      = 12
   Const $iVertCount     = 12

   InitStorageSettings($iBorderWidth, $iCellWidth, $iCellStartPosX, $iCellStartPosY, $iHorCount, $iVertCount)
EndFunc

Func StashScan()
   Return StorageScan($COLOR_EMPTY, $COLOR_EMPTY_SHADE)
EndFunc
