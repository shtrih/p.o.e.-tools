#include <MsgBoxConstants.au3>
#include <WinAPISysWin.au3>
#include <Date.au3>

Global Const $HP_MORE_THAN_25_PERCENT_HASH = 352781054
Global Const $HP_MORE_THAN_35_PERCENT_HASH = 421331853
Global Const $HP_MORE_THAN_65_PERCENT_HASH = 257753630

HotKeySet("{F1}", "Terminate")

Global Const $hWnd = WinGetHandle("Path of Exile")
;Global Const $hWnd = WinGetHandle("XnView - [20200925134940_1.jpg]")
If @error Then
  MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
  Exit
EndIf

$pos = WinGetPos($hWnd)
If @error Then
  MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the $windowHeight")
  Exit
EndIf
Global $windowOffsetLeft = $pos[0]
Global $windowOffsetTop = $pos[1]
Global $windowWidth = $pos[2]
Global $windowHeight = $pos[3]

Main()

Func Main()
   Const $FLASK_COOLDOWN = 4000
   Const $CHECK_PERIOD = 250

   Log_(@ScriptName & ' started!')

   $flaskCooldown = 0
   $isStrongFlaskCooldown = False
   While True
	  WinWaitActive($hWnd)

;   $x = 35 ; 40 875
;   $y = $windowHeight - 161 ; 866 от 1027
;Sleep(1000)

;Opt('PixelCoordMode', 0)
;   Log_(Hex(PixelGetColor($x, $y, $hWnd), 6))
;   Log_(Hex(PixelGetColor($x + $windowOffsetLeft, $y + $windowOffsetTop, $hWnd), 6))
;   Log_(Hex(PixelGetColor(10, 10, $hWnd), 6))
;$p = PixelSearch(8, 880, 20, 1024, 0xd9c195, 0, 1, $hWnd)
;$p = PixelSearch(30, 880, 45, 890, 0xffebb7, 15, 1, $hWnd)
;$p = PixelSearch(35+$windowOffsetLeft, 866+$windowOffsetTop, 40+$windowOffsetLeft, 875+$windowOffsetTop, 0xffebb7, 5, 1, $hWnd)
;;If Not @error Then
;   Log_(0 & $p[0] & 'x' & $p[1])
;EndIf
;Opt('PixelCoordMode', 1)
;   Log_(Hex(PixelGetColor($x, $y, $hWnd), 6))
;   Log_(Hex(PixelGetColor($x + $windowOffsetLeft, $y + $windowOffsetTop, $hWnd), 6))
;   Log_(Hex(PixelGetColor(10, 10, $hWnd), 6))
;$p = PixelSearch(8, 880, 20, 1024, 0xd9c195, 0, 1, $hWnd)
;$p = PixelSearch(8+$windowOffsetLeft, 850+$windowOffsetTop, 30+$windowOffsetLeft, 1024+$windowOffsetTop, 0xd9c195, 5, 1, $hWnd)
;If Not @error Then
;   Log_(1 & $p[0] & 'x' & $p[1])
;EndIf
;Opt('PixelCoordMode', 2)
;   Log_(Hex(PixelGetColor($x, $y, $hWnd), 6))
;   Log_(Hex(PixelGetColor($x + $windowOffsetLeft, $y + $windowOffsetTop, $hWnd), 6))
;   Log_(Hex(PixelGetColor(10, 10, $hWnd), 6))
;$p = PixelSearch(8, 880, 20, 1024, 0xd9c195, 0, 1, $hWnd)

;$p = PixelSearch(8+$windowOffsetLeft, 850+$windowOffsetTop, 30+$windowOffsetLeft, 1024+$windowOffsetTop, 0xd9c195, 10, 1, $hWnd)
;If Not @error Then
;   Log_(2& $p[0] & 'x' & $p[1])
;EndIf
;Opt('PixelCoordMode', Default)


;GUICreate("test", 100, 100, $x + $windowOffsetLeft, $y + $windowOffsetTop)
;GUISetState()
;Sleep(6000)
;   Terminate()

	  If ($flaskCooldown >= 0) Then
		 $flaskCooldown -= $CHECK_PERIOD
	  Else
		 $isStrongFlaskCooldown = False
	  EndIf

	  If Not isVisibleHP() Then
		 Sleep($CHECK_PERIOD)
		 ContinueLoop
	  EndIf

	  If (Not $isStrongFlaskCooldown) Then
		 $hpChecksum = getHPChecksum(65, $windowHeight)
		 If ($hpChecksum <> $HP_MORE_THAN_65_PERCENT_HASH) Then
			;If ($flaskCooldown <= 0) Then
			   DrinkFlask(4)
			   $flaskCooldown = $FLASK_COOLDOWN
			   $isStrongFlaskCooldown = True
			;Else
			;   Log_(StringFormat('Мало ХП (<%d%%), но фласка в КД (%s)', 65, $flaskCooldown))
			;EndIf
		 EndIf
	  EndIf

	  If (Not $isStrongFlaskCooldown) Then
		 $hpChecksum = getHPChecksum(35, $windowHeight)
		 If ($hpChecksum <> $HP_MORE_THAN_35_PERCENT_HASH) Then
			If ($flaskCooldown <= 0) Then
			   DrinkFlask()
			   $flaskCooldown = $FLASK_COOLDOWN
			Else
			   Log_(StringFormat('Мало ХП (<%d%%), но фласка в КД (%s)', 35, $flaskCooldown))
			EndIf
		 EndIf
	  EndIf

	  Sleep($CHECK_PERIOD)
   WEnd
EndFunc

Func Log_($data)
   $data = _Now() & ' - ' & $data

;~    $FileName = @ScriptDir & '\Log.txt'
;~    $hFile = FileOpen($FileName, 1)
;~    If $hFile <> -1 Then
;~ 	 FileWriteLine($hFile, $data)
;~ 	 FileClose($hFile)
;~    EndIf

   ConsoleWrite($data & @CRLF)
EndFunc

; 192px = hp bar height
; 8px = hp bottom offset
; 134px = hp on X axis
Func getHPChecksum($hpPercent, $windowHeight)
   Local Const $BAR_HEIGHT = 190
   Local Const $BAR_BOTTOM_OFFSET = 8
   Local Const $BAR_X_OFFSET = 100

   $percentHeight = Ceiling($BAR_HEIGHT / 100 * $hpPercent)
   $yPos = $windowHeight - ($BAR_HEIGHT + $BAR_BOTTOM_OFFSET - $percentHeight)

;GUICreate("test", 100, $BAR_HEIGHT, $BAR_X_OFFSET + $windowOffsetLeft, $yPos + $windowOffsetTop)
;GUISetState()
   $result = PixelChecksum($BAR_X_OFFSET, $yPos, $BAR_X_OFFSET + 3, $yPos, 1, $hWnd)

;   Log_(' Color: #' & Hex(PixelGetColor($BAR_X_OFFSET, $yPos, $hWnd), 6) & StringFormat(' Hash: %s, Offset Top: %s, yPos: %s, hp: %s%%', $result, $windowOffsetTop, $yPos, $hpPercent))

   Return $result
EndFunc

Func isVisibleHP()
   $result = False

   Opt('PixelCoordMode', 0)

   $p = PixelSearch(30, 880, 45, 890, 0xffebb7, 15, 1, $hWnd) ; ищем светлую кожу на лице тянки
   If Not @error Then
	  $result = True
   EndIf

   Opt('PixelCoordMode', Default)

   Return $result
EndFunc

Func DrinkFlask($flaskNumber = 1)
   Send("{" & $flaskNumber & "}", $hWnd)
   SoundPlay('potion.wav')
   Log_('Drink #' & $flaskNumber)
EndFunc

Func Terminate()
	Exit
EndFunc