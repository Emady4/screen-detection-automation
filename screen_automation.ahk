#Persistent
#SingleInstance Force
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

; ================= GLOBALS =================
global colorToFind := "0xFF0000"
global toggle := false
global x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight
global webhookURL := ""
global discordID := ""
global intervalMs := 1000
global toggleHotkey := "F9"
global monitorChoice := "Both"
global repeatInterval := 780000     ; default 13 min
global noDetectionInterval := 2400000 ; default 40 min
global lastClickX := "", lastClickY := ""
global lastDetectionTime := 0
global settingsFile := A_ScriptDir "\settings.ini"

; ================= GUI =================
Gui, Add, Text,, Color to detect (hex):
Gui, Add, Edit, vColorEdit w100 gUpdateColorPreview, %colorToFind%
Gui, Add, Button, gPickColor, Pick Color from Screen
Gui, Add, Text, vColorPreviewBox w30 h20 +BackgroundFF0000
Gui, Add, Button, gSelectArea, Select Area

Gui, Add, Text,, Check interval (seconds):
Gui, Add, Edit, vIntervalEdit w50, 1

Gui, Add, Text,, Toggle hotkey (e.g. F9, ^+t):
Gui, Add, Edit, vHotkeyEdit w100, %toggleHotkey%

Gui, Add, Text,, Monitor to check:
Gui, Add, DropDownList, vMonitorChoice w150, Monitor 1|Monitor 2|Both Monitors, %monitorChoice%

Gui, Add, Text,, Repeat click interval (minutes):
Gui, Add, Edit, vRepeatIntervalEdit w50, % repeatInterval//60000

Gui, Add, Text,, No detection alert interval (minutes):
Gui, Add, Edit, vNoDetectIntervalEdit w50, % noDetectionInterval//60000

Gui, Add, Button, gToggleTimer, Start/Stop Detection

Gui, Add, Text,, Discord Webhook URL:
Gui, Add, Edit, vWebhookEdit w300, %webhookURL%

Gui, Add, Text,, Discord User ID to ping:
Gui, Add, Edit, vDiscordIDEdit w200, %discordID%

Gui, Add, Text, vStatusText w400, Status: Stopped
Gui, Show,, Color Click & Notify

; Load saved settings
LoadSettings()
return

; ================= GUI HANDLERS =================
UpdateColorPreview:
    Gui, Submit, NoHide
    color := ColorEdit
    StringTrimLeft, colorWithoutPrefix, color, 2
    if (StrLen(colorWithoutPrefix) = 6)
        GuiControl, +Background0x%colorWithoutPrefix%, ColorPreviewBox
return

PickColor:
    Gui, Hide
    ToolTip, Move your mouse to the color and left-click to pick it...
    KeyWait, LButton, D
    MouseGetPos, x, y
    PixelGetColor, color, x, y, RGB
    colorToFind := color
    GuiControl,, ColorEdit, %color%
    StringTrimLeft, colorWithoutPrefix, color, 2
    GuiControl, +Background0x%colorWithoutPrefix%, ColorPreviewBox
    ToolTip
    Gui, Show
return

SelectArea:
    Gui, Hide
    Sleep, 200
    MsgBox, Click and drag to select area. Press ESC to cancel.

    KeyWait, LButton, D
    MouseGetPos, startX, startY

    Gui, 2:Destroy
    Gui, 2:+AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound +Owner
    Gui, 2:Color, EEAA99
    WinSet, Transparent, 60

    Gui, 3:Destroy
    Gui, 3:+AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound +Owner
    Gui, 3:Color, Red
    WinSet, Transparent, 255

    Loop
    {
        if GetKeyState("Escape", "P")
        {
            Gui, 2:Hide
            Gui, 3:Hide
            Gui, Show
            MsgBox, Area selection canceled.
            return
        }

        GetKeyState, state, LButton, P
        if (state = "U")
            break

        MouseGetPos, currentX, currentY
        x := (startX < currentX ? startX : currentX)
        y := (startY < currentY ? startY : currentY)
        w := Abs(currentX - startX)
        h := Abs(currentY - startY)

        Gui, 2:Show, x%x% y%y% w%w% h%h% NoActivate
        Gui, 3:Show, x%x% y%y% w%w% h%h% NoActivate
        Sleep, 10
    }

    x1 := (startX < currentX ? startX : currentX)
    y1 := (startY < currentY ? startY : currentY)
    x2 := (startX > currentX ? startX : currentX)
    y2 := (startY > currentY ? startY : currentY)

    Gui, 2:Hide
    Gui, 3:Hide
    Gui, Show
    MsgBox, Area selected: %x1%, %y1% to %x2%, %y2%
return

; ================= TOGGLE DETECTION =================
ToggleTimer:
    Gui, Submit, NoHide
    if (!toggle)
    {
        colorToFind := ColorEdit
        webhookURL := WebhookEdit
        discordID := DiscordIDEdit
        intervalMs := IntervalEdit * 1000
        toggleHotkey := HotkeyEdit
        if (toggleHotkey = "")  ; Fix: default hotkey if empty
            toggleHotkey := "F9"
        monitorChoice := MonitorChoice
        repeatInterval := RepeatIntervalEdit * 60000
        noDetectionInterval := NoDetectIntervalEdit * 60000

        SysGet, mCount, MonitorCount
        if (monitorChoice = "Monitor 1") {
            SysGet, m1, Monitor, 1
            x1 := m1Left, y1 := m1Top, x2 := m1Right, y2 := m1Bottom
        }
        else if (monitorChoice = "Monitor 2") {
            if (mCount >= 2) {
                SysGet, m2, Monitor, 2
                x1 := m2Left, y1 := m2Top, x2 := m2Right, y2 := m2Bottom
            } else {
                MsgBox, Monitor 2 not detected. Defaulting to Monitor 1.
                SysGet, m1, Monitor, 1
                x1 := m1Left, y1 := m1Top, x2 := m1Right, y2 := m1Bottom
            }
        }
        else {
            x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight
        }

        Hotkey, %toggleHotkey%, ToggleTimerHotkey, On
        toggle := true
        SetTimer, CheckForColor, %intervalMs%
        lastDetectionTime := A_TickCount
        SetTimer, RepeatLastClick, %repeatInterval%
        SetTimer, CheckNoDetection, 60000
        GuiControl,, StatusText, Status: Running (Interval: %IntervalEdit%s, Hotkey: %toggleHotkey%, %monitorChoice%)
    }
    else
    {
        toggle := false
        SetTimer, CheckForColor, Off
        SetTimer, RepeatLastClick, Off
        SetTimer, CheckNoDetection, Off
        Hotkey, %toggleHotkey%, ToggleTimerHotkey, Off
        GuiControl,, StatusText, Status: Stopped
        SaveSettings()
    }
return

ToggleTimerHotkey:
    Gosub, ToggleTimer
return

; ================= COLOR DETECTION =================
CheckForColor:
    if (!toggle)
        return

    tolerance := 3
    margin := 5
    searchX1 := x1 + margin, searchY1 := y1 + margin
    searchX2 := x2 - margin, searchY2 := y2 - margin

    PixelSearch, foundX, foundY, searchX1, searchY1, searchX2, searchY2, %colorToFind%, %tolerance%, Fast RGB
    if (ErrorLevel = 0)
    {
        MouseGetPos, oldX, oldY
        MouseMove, foundX, foundY, 0
        Click
        lastClickX := foundX, lastClickY := foundY
        lastDetectionTime := A_TickCount
        MouseMove, oldX, oldY, 0
        if (webhookURL != "")
            SendMessageToDiscord(webhookURL, "Clicked color detected at (" foundX "," foundY ")")
    }
return

RepeatLastClick:
    if (!toggle || lastClickX = "" || lastClickY = "")
        return
    MouseGetPos, oldX, oldY
    MouseMove, lastClickX, lastClickY, 0
    Click
    MouseMove, oldX, oldY, 0
    if (webhookURL != "")
        SendMessageToDiscord(webhookURL, "⏰ Repeated click at (" lastClickX "," lastClickY ")")
return

CheckNoDetection:
    if (!toggle)
        return
    if (A_TickCount - lastDetectionTime > noDetectionInterval) {
        if (webhookURL != "") {
            mention := (discordID != "" ? "<@" . discordID . "> " : "")
            SendMessageToDiscord(webhookURL, mention . "⚠ No color detected for over " . (noDetectionInterval//60000) . " minutes!")
        }
        lastDetectionTime := A_TickCount
    }
return

; ================= DISCORD WEBHOOK =================
SendMessageToDiscord(url, message)
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", url, false)
    whr.SetRequestHeader("Content-Type", "application/json")
    payload := "{""content"":""" message """}"
    whr.Send(payload)
}

; ================= SETTINGS =================
SaveSettings() {
    global colorToFind, webhookURL, discordID, intervalMs, toggleHotkey, monitorChoice, repeatInterval, noDetectionInterval, settingsFile
    Gui, Submit, NoHide
    IniWrite, %ColorEdit%, %settingsFile%, Settings, Color
    IniWrite, %WebhookEdit%, %settingsFile%, Settings, Webhook
    IniWrite, %DiscordIDEdit%, %settingsFile%, Settings, DiscordID
    IniWrite, %IntervalEdit%, %settingsFile%, Settings, IntervalSec
    IniWrite, %HotkeyEdit%, %settingsFile%, Settings, Hotkey
    IniWrite, %MonitorChoice%, %settingsFile%, Settings, Monitor
    IniWrite, %RepeatIntervalEdit%, %settingsFile%, Settings, RepeatMin
    IniWrite, %NoDetectIntervalEdit%, %settingsFile%, Settings, NoDetectMin
}

LoadSettings() {
    global settingsFile, colorToFind, webhookURL, discordID, intervalMs, toggleHotkey, monitorChoice, repeatInterval, noDetectionInterval
    IniRead, colorToFind, %settingsFile%, Settings, Color, 0xFF0000
    IniRead, webhookURL, %settingsFile%, Settings, Webhook,
    IniRead, discordID, %settingsFile%, Settings, DiscordID,
    IniRead, intervalSec, %settingsFile%, Settings, IntervalSec, 1
    IniRead, toggleHotkey, %settingsFile%, Settings, Hotkey, F9
    IniRead, monitorChoice, %settingsFile%, Settings, Monitor, Both Monitors
    IniRead, repeatMin, %settingsFile%, Settings, RepeatMin, 13
    IniRead, noDetectMin, %settingsFile%, Settings, NoDetectMin, 40

    intervalMs := intervalSec * 1000
    repeatInterval := repeatMin * 60000
    noDetectionInterval := noDetectMin * 60000

    GuiControl,, ColorEdit, %colorToFind%
    StringTrimLeft, colorWithoutPrefix, colorToFind, 2
    if (StrLen(colorWithoutPrefix) = 6)
        GuiControl, +Background0x%colorWithoutPrefix%, ColorPreviewBox
    GuiControl,, WebhookEdit, %webhookURL%
    GuiControl,, DiscordIDEdit, %discordID%
    GuiControl,, IntervalEdit, %intervalSec%
    GuiControl,, HotkeyEdit, %toggleHotkey%
    GuiControl,, MonitorChoice, |Monitor 1||Monitor 2||Both Monitors
    GuiControl,, MonitorChoice, %monitorChoice%
    GuiControl,, RepeatIntervalEdit, %repeatMin%
    GuiControl,, NoDetectIntervalEdit, %noDetectMin%
}

GuiClose:
    SaveSettings()
    ExitApp
