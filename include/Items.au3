#include-once

#include <AutoItConstants.au3>
#include <Log_.au3>

Local $BORDER_WIDTH
Local $CELL_WIDTH
Local $CELL_START_POS_X
Local $CELL_START_POS_Y
Local $HOR_COUNT
Local $VERT_COUNT

Func InitTabSettings($borderWidth=2, $cellWidth=50, $cellStartPosX=1269, $cellStartPosY=585, $HorCellCount=12, $VertCellCount=5)
   $BORDER_WIDTH = $borderWidth
   $CELL_WIDTH = $cellWidth
   $CELL_START_POS_X = $cellStartPosX
   $CELL_START_POS_Y = $cellStartPosY
   $HOR_COUNT = $HorCellCount
   $VERT_COUNT = $VertCellCount
EndFunc

Func CellNum2PixelPos($numX, $numY)
   $posX = $CELL_START_POS_X + ($CELL_WIDTH * $numX) + ($BORDER_WIDTH * ($numX + 1))
   $posY = $CELL_START_POS_Y + ($CELL_WIDTH * $numY) + ($BORDER_WIDTH * ($numY + 1))

   Local $result[2] = [$posX, $posY]

   Return $result
EndFunc

Func CellIsEmpty($numX, $numY, $checkColor, $shadeVariation)
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   $cellPixelPositions = CellNum2PixelPos($numX, $numY)
   Const $POSITION_X = $cellPixelPositions[0] + Ceiling($CELL_WIDTH/2 - $DELTA_X/2)
   Const $POSITION_Y = $cellPixelPositions[1] + Ceiling($CELL_WIDTH/2 - $DELTA_Y/2)

   If $DEBUG Then Log_(StringFormat('CellIsEmpty(%s, %s)(%s, %s, %s, %s)', $numX, $numY, $POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y))

   PixelSearch($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, $checkColor, $shadeVariation)

   Return Not @error
EndFunc

Func InventoryScan()
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
