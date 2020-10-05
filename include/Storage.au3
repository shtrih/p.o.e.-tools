#include-once

#include <AutoItConstants.au3>
#include <Array.au3>
#include "Log_.au3"

Global $g_initStorage = False
Global $g_borderWidth
Global $g_cellWidth
Global $g_cellStartPosX
Global $g_cellStartPosY
Global $g_horCount
Global $g_vertCount

Global $COLOR_PROPHECY = 0x811469
Global $COLOR_PROPHECY_SHADE = 4
Global $COLOR_EMPTY = 0x050505
Global $COLOR_EMPTY_SHADE = 5

Func InitStorageSettings($borderWidth=2, $cellWidth=50, $cellStartPosX=1269, $cellStartPosY=585, $HorCellCount=12, $VertCellCount=5)
   $g_borderWidth   = $borderWidth
   $g_cellWidth     = $cellWidth
   $g_cellStartPosX = $cellStartPosX
   $g_cellStartPosY = $cellStartPosY
   $g_horCount      = $HorCellCount
   $g_vertCount     = $VertCellCount
   $g_initStorage   = True
EndFunc

Func CellNum2PixelPos($numX, $numY)
   $posX = $g_cellStartPosX + ($g_cellWidth * $numX) + ($g_borderWidth * ($numX + 1))
   $posY = $g_cellStartPosY + ($g_cellWidth * $numY) + ($g_borderWidth * ($numY + 1))

   Local $result[2] = [$posX, $posY]

   Return $result
EndFunc

Func CellCenterPixel()
   Return $g_cellWidth/2
EndFunc

Func CellCheckColor($numX, $numY, $checkColor, $shadeVariation)
   Const $DELTA_X = 2 ; 2x2 turns to 3x3 in PixelSearch()
   Const $DELTA_Y = 2
   $cellPixelPositions = CellNum2PixelPos($numX, $numY)
   Const $POSITION_X = Ceiling($cellPixelPositions[0] + $g_cellWidth/2 - $DELTA_X/2)
   Const $POSITION_Y = Ceiling($cellPixelPositions[1] + $g_cellWidth/2 - $DELTA_Y/2)

   Log_(StringFormat('CellCheckColor(%s, %s)(%s, %s, %s, %s)', $numX, $numY, $POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y), $LOG_LEVEL_DEBUG)
   ;If $DEBUG Then Log_(SquareGetColors($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y), $LOG_LEVEL_DEBUG)
   ;MouseMove($POSITION_X, $POSITION_Y, 1)

   PixelSearch($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, $checkColor, $shadeVariation)
   $result = Not @error

   Return $result
EndFunc

Func CellCheckIsEmpty($numX, $numY)
   Return CellCheckColor($numX, $numY, $COLOR_EMPTY, $COLOR_EMPTY_SHADE)
EndFunc

; x <= x1, y <= y1
Func SquareGetColors($x, $y, $x1, $y1)
   $iCount = ($x1 - $x + 1) * ($y1 - $y + 1)
   Local $result[$iCount]

   $k = 0
   For $i = $y To $y1
      For $j = $x To $x1
         $result[$k] = '#' & Hex(PixelGetColor($j, $i), 6)

         $k += 1
      Next
   Next

   Return $result
EndFunc

Func StorageScan($checkColor, $shadeVariation)
   Local $result[0][2]

   $isInverted = False
   Const $iVertMax = $g_vertCount - 1

   For $x = 0 to ($g_horCount - 1)
      $isInverted = Mod($x, 2) = 0 ? False : True

      For $y = 0 to $iVertMax
         $iSnakeY = $isInverted ? $iVertMax - $y : $y

         If CellCheckColor($x, $iSnakeY, $checkColor, $shadeVariation) Then
            Local $resultSub[1][2] = [[$x, $iSnakeY]]
            _ArrayAdd($result, $resultSub)
         EndIf
      Next
   Next

   Return $result
EndFunc

Func StorageFindEmptySpace(ByRef $inventory)
   Local $result[2]

   For $i = 0 To UBound($inventory) - 1
      Local $pos[2] = [$inventory[$i][0], $inventory[$i][1]]
      $result[0] = $i
      $result[1] = $pos

      Return $result
   Next

   Return False
EndFunc

Func StorageClickItem($numX, $numY)
   $mousePos = CellNum2PixelPos($numX, $numY)
   Const $offset = 8 ;
   Const $x = Random($mousePos[0] + $offset, $mousePos[0] + $g_cellWidth - $offset, 1)
   Const $y = Random($mousePos[1] + $offset, $mousePos[1] + $g_cellWidth - $offset, 1)
   Const $speed = Random(8, 12, 1)

   Log_(StringFormat('StorageClickItem(%s, %s)(%s, %s)', $numX, $numY, $x, $y), $LOG_LEVEL_DEBUG)

   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func StoragePutItem(ByRef $inventory)
   $cell = StorageFindEmptySpace($inventory)

   If $cell = False Then
      Return SetError(1, 0, 0)
   EndIf

   $invKey = $cell[0]
   $cellPos = $cell[1]

   _ArrayDelete($inventory, $invKey)

   StorageClickItem($cellPos[0], $cellPos[1])
EndFunc

Func IsStorageVisible()
   $x = $g_cellStartPosX + $g_borderWidth + $g_cellWidth + 1
   $y = $g_cellStartPosY + $g_borderWidth + 1

   $pos = PixelSearch($x, $y, $x + 1, $y + 1, 0x1c1522, 2) ; color with item
   If Not @error Then
      ;LogV($pos[0], $pos[1])
      Return True
   EndIf

   PixelSearch($x, $y, $x + 1, $y + 1, 0x2a2117, 2) ; empty cell color
   $bResult = Not @error

   Return $bResult
EndFunc

Func CellMove($numX, $numY)
   $pos = CellNum2PixelPos($numX, $numY)
   Const $offset = Ceiling($g_cellWidth / 100 * 20)
   $mousePosX = Random($pos[0] + $offset, $pos[0] + $g_cellWidth - $offset, 1)
   $mousePosY = Random($pos[1] + $offset, $pos[1] + $g_cellWidth - $offset, 1)
   $mouseSpeed = Random(4, 7, 1)

   MouseMove($mousePosX, $mousePosY, $mouseSpeed)
EndFunc

Func GetItemInfo($bPushCtrlC = True)
   If $bPushCtrlC Then
      Send('^c')
      Sleep(100)
   EndIf

   $sItemInfo = ClipGet()
;Logv('Item: ', $numX, $numY, $sItemInfo)
   If @error Then
      Return SetError(@error, 0, '')
   EndIf

   Return $sItemInfo
EndFunc

Func StorageScanItemsInfo($checkColor, $shadeVariation, ByRef $bContinue)
   Local $result[0][3]

   $isInverted = False
   Const $iVertMax = $g_vertCount - 1

   Send('{CTRLDOWN}')

   For $x = 0 to ($g_horCount - 1)
      $isInverted = Mod($x, 2) = 0 ? False : True

      For $y = 0 to $iVertMax
         If Not $bContinue Then
            ExitLoop 2
         EndIf

         $iSnakeY = $isInverted ? $iVertMax - $y : $y
         CellMove($x, $iSnakeY)

         If Not CellCheckColor($x, $iSnakeY, $checkColor, $shadeVariation) Then
            Send('{c}')
            Sleep(100)

            Local $resultSub[1][3] = [[$x, $iSnakeY, GetItemInfo(False)]]
            _ArrayAdd($result, $resultSub)
         EndIf
      Next
   Next

   Send('{CTRLUP}')

   Return $result
EndFunc
