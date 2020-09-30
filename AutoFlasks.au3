#pragma compile(Console, True)
#pragma compile(x64, true)
#pragma compile(Icon, "flask.ico")

#include <MsgBoxConstants.au3>
#include <WinAPISysWin.au3>
#include <Date.au3>
#include "include/Log_.au3"

;HotKeySet("{F1}", "Terminate")
Global Const $eg_iSmallPercent = 35
Global Const $eg_iSmallCooldown = 8000
Global Const $eg_sSmallHotkey = '{1}'
Global Const $eg_iSmallHash = 0
Global Const $eg_iBigPercent = 65
Global Const $eg_iBigCooldown = 4000
Global Const $eg_sBigHotkey = '{4}'
Global Const $eg_iBigHash = 0

Global $g_sSmallHotkey
Global $g_iSmallCooldown
Global $g_iSmallPercent
Global $g_iSmallHash
Global $g_sBigHotkey
Global $g_iBigCooldown
Global $g_iBigPercent
Global $g_iBigHash

Global Const $eg_sConfigFilePath = @ScriptFullPath & '.ini'
configRead($eg_sConfigFilePath)

Global Const $eg_sWindowTitle = 'Path of Exile'
;Global Const $eg_sWindowTitle = 'XnView - [Awakened_PoE_Trade_2020-09-30_11-28-42.png]'
Global $g_hWnd = 0 

Main()

Func Main()
   Const $CHECK_PERIOD = 250

   Log_(@ScriptName & ' started!')

   $flaskCooldown = 0
   $isStrongFlaskCooldown = False
   While True
      If IsHwnd($g_hWnd) Then
         $hwnd = WinWaitActive($g_hWnd, '', 10)
         If $hwnd = 0 Then ; timeout
            Log_('WaitActive timeout. Continue...', $LOG_LEVEL_DEBUG)
            Sleep($CHECK_PERIOD)
            ContinueLoop
         EndIf
      Else
         $g_hWnd = WinGetHandle($eg_sWindowTitle)
         If @error Then
            Log_("An error occurred when trying to retrieve the window handle PoE")
            ;MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
            ;Exit
            Sleep(5000)
            ContinueLoop
         EndIf

         $pos = WinGetPos($g_hWnd)
         If @error Then
            MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the $windowHeight")
            Exit
         EndIf

         Global $windowOffsetLeft = $pos[0]
         Global $windowOffsetTop = $pos[1]
         Global $windowWidth = $pos[2]
         Global $windowHeight = $pos[3]
      EndIf

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
         $hpChecksum = getHPChecksum($g_iBigPercent, $windowHeight)
         If $g_iBigHash = 0 Then
            Log_('Writing new BigFlask hash')
            $g_iBigHash = $hpChecksum
            configWriteHash($eg_sConfigFilePath, 'BigFlask', $g_iBigHash)
         ElseIf ($hpChecksum <> $g_iBigHash) Then
            ;If ($flaskCooldown <= 0) Then
               DrinkFlask($g_sBigHotkey)
               $flaskCooldown = $g_iBigCooldown
               $isStrongFlaskCooldown = True
            ;Else
            ;   Log_(StringFormat('Мало хп (<%d%%), но фласка в кд (%s)', 65, $flaskCooldown))
            ;EndIf
         EndIf
      EndIf

      If (Not $isStrongFlaskCooldown) Then
         $hpChecksum = getHPChecksum($g_iSmallPercent, $windowHeight)
         If $g_iSmallHash = 0 Then
            Log_('Writing new SmallFlask hash')
            $g_iSmallHash = $hpChecksum
            configWriteHash($eg_sConfigFilePath, 'SmallFlask', $g_iSmallHash)
         ElseIf ($hpChecksum <> $g_iSmallHash) Then
            If ($flaskCooldown <= 0) Then
               DrinkFlask($g_sSmallHotkey)
               $flaskCooldown = $g_iSmallCooldown
            Else
               Log_(StringFormat('Мало хп (<%d%%), но фласка в кд (%s)', $g_iSmallPercent, $flaskCooldown))
            EndIf
         EndIf
      EndIf

      Sleep($CHECK_PERIOD)
   WEnd
EndFunc

Func getHPChecksum($hpPercent, $windowHeight)
   Local Const $BAR_HEIGHT = 190
   Local Const $BAR_BOTTOM_OFFSET = 8
   Local Const $BAR_X_OFFSET = 100

   $percentHeight = Ceiling($BAR_HEIGHT / 100 * $hpPercent)
   $yPos = $windowHeight - ($BAR_HEIGHT + $BAR_BOTTOM_OFFSET - $percentHeight)

   $result = PixelChecksum($BAR_X_OFFSET, $yPos, $BAR_X_OFFSET + 3, $yPos, 1, $g_hWnd)

;   Log_(' Color: #' & Hex(PixelGetColor($BAR_X_OFFSET, $yPos, $g_hWnd), 6) & StringFormat(' Hash: %s, Offset Top: %s, yPos: %s, hp: %s%%', $result, $windowOffsetTop, $yPos, $hpPercent))

   Return $result
EndFunc

Func isVisibleHP()
   $result = False

   Opt('PixelCoordMode', 0)

   $p = PixelSearch(30, 880, 45, 890, 0xffebb7, 15, 1, $g_hWnd) ; Ищем этот цвет на лице тяночки
   If Not @error Then
      $result = True
   EndIf

   Opt('PixelCoordMode', Default)

   Return $result
EndFunc

Func DrinkFlask($flaskHotkey)
   Send($flaskHotkey, $g_hWnd)
   SoundPlay(@ScriptDir & '\potion.wav')
   Log_('Drink ' & $flaskHotkey)
EndFunc

Func configCreate($sFilePath)
   Log_('Trying to write config file ' & $sFilePath)

   $iResult = IniWrite($sFilePath, 'SmallFlask', 'hotkey', $eg_sSmallHotkey & @CRLF & '; e.g. {f1} or ^q. See also: https://www.autoitscript.com/autoit3/docs/functions/HotKeySet.htm')
   IniWrite($sFilePath, 'SmallFlask', 'cooldown_msec', $eg_iSmallCooldown)
   IniWrite($sFilePath, 'SmallFlask', 'trigger_percent', $eg_iSmallPercent)
   IniWrite($sFilePath, 'SmallFlask', 'trigger_hash', $eg_iSmallHash)
   configWriteHash($sFilePath, 'SmallFlask', $eg_iSmallHash)

   IniWrite($sFilePath, 'BigFlask', 'hotkey', $eg_sBigHotkey)
   IniWrite($sFilePath, 'BigFlask', 'cooldown_msec', $eg_iBigCooldown)
   IniWrite($sFilePath, 'BigFlask', 'trigger_percent', $eg_iBigPercent)
   configWriteHash($sFilePath, 'BigFlask', $eg_iBigHash)

   If Not $iResult Then
      ConsoleWriteError("Failed to save config." & @CRLF)
   EndIf
EndFunc

Func configWriteHash($sFilePath, $sSection, $iValue)
   Return IniWrite($sFilePath, $sSection, 'trigger_hash', $iValue)
EndFunc

Func configCheck($sFilePath)
   If Not FileExists($sFilePath) Then
      configCreate($sFilePath)
   EndIf
EndFunc

Func configRead($sFilePath)
   configCheck($sFilePath)

   $g_sSmallHotkey = IniRead($sFilePath, 'SmallFlask', 'hotkey', $eg_sSmallHotkey)
   $g_iSmallCooldown = IniRead($sFilePath, 'SmallFlask', 'cooldown_msec', $eg_iSmallCooldown)
   $g_iSmallPercent = IniRead($sFilePath, 'SmallFlask', 'trigger_percent', $eg_iSmallPercent)
   $g_iSmallHash = IniRead($sFilePath, 'SmallFlask', 'trigger_hash', $eg_iSmallHash)

   $g_sBigHotkey = IniRead($sFilePath, 'BigFlask', 'hotkey', $eg_sBigHotkey)
   $g_iBigCooldown = IniRead($sFilePath, 'BigFlask', 'cooldown_msec', $eg_iBigCooldown)
   $g_iBigPercent = IniRead($sFilePath, 'BigFlask', 'trigger_percent', $eg_iBigPercent)
   $g_iBigHash = IniRead($sFilePath, 'BigFlask', 'trigger_hash', $eg_iBigHash)
EndFunc

Func Terminate()
   Exit
EndFunc
