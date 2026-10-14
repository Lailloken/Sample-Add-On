Class SampleAddon
{
	__New(name) ; name is loaded from the JSON file
	{
		this.name := name, this.settings := {}, this.hwnd := {}
		this.config_path := "add-ons\" name "\config" vars.poe_version ".ini" ; vars.poe_version is blank for PoE1 and " 2" for PoE2 // split into separate configs not necessarily required

		If !FileExist(this.config_path)
			IniWrite, % "", % this.config_path, settings
		ini := IniBatchRead(this.config_path)

		this.settings.fSize := (ini.UI.font ? ini.UI.font : settings.general.fSize)
		LLK_FontDimensions(this.settings.fSize, h, w), this.settings.fWidth := w, this.settings.fHeight := h ; get approx. dimensions for font width and height (optional)
		this.settings.hotkey_stats := ini.settings["hotkey stats"]
		this.Init()
	}

	Init()
	{
		; bind customizable hotkey
		If !Blank(this.settings.hotkey_stats) && (key := Hotkeys_Convert(this.settings.hotkey_stats)) ; function converts key-names to scan-codes and also checks validity
		{
			func := ObjBindMethod(this, "Hotkeys")
			Hotkey, IfWinActive, ahk_group poe_window
			Hotkey, % key, % func, on
		}
	}

	Hotkeys() ; called when a customizable hotkey is pressed
	{
		global vars, settings

		hotkey := (StrLen(A_ThisHotkey) > 1 ? LTrim(A_ThisHotkey, "~!+#^") : A_ThisHotkey) ; remove key-modifiers (if needed)
		Switch GetKeyName(hotkey)
		{
			Case this.settings.hotkey_stats:
				text := "hotkey: " GetKeyName(hotkey) " (" hotkey ")`nmouse pos: " vars.general.xMouse ", " vars.general.yMouse "`nclient pos: " vars.client.x ", " vars.client.y "`n    size: " vars.client.w " x " vars.client.h
				text .= "`narea: " vars.log.areaname " (" vars.log.arealevel ")`n    area-id: " vars.log.areaID
				text .= "`ncharacter: " (settings.general.character ? settings.general.character " (" (vars.log.level ? vars.log.level : "?") ")" : "not tracking")
				text .= "`n    class: " (!vars.log.level ? "?" : vars.log.character_class)
				LLK_ToolTip(text, 10000,,, "samplestats") ; 0 duration to make it permanent until manually destroyed (see below)
		}
		KeyWait, % hotkey ; wait until the hotkey is released (prevents continuous function call)
		LLK_Overlay(vars.hwnd.tooltip_samplestats, "destroy") ; tooltip HWNDs are stored in vars.hwnd under "tooltip_" + name used in the parameter of the function
	}

	LogRead(log_text) ; when the tool accesses the game's client.txt log file every second, it reads the whole "chunk" that was added since last accessing the file, then parses each line // method is called for every parsed line
	{
		If InStr(log_text, "something relevant to the add-on")
			LLK_ToolTip("found relevant text in log")
	}

	Settings_menu(mode := "") ; called when clicking the cogwheel-icon in the "add-ons" section of the settings menu
	{
		global vars, settings
		static fSize, wHotkey

		If (mode = "refresh")
		{
			Settings_menu("addons_" this.name)
			Return
		}

		If !fSize
		{
			fSize := settings.general.fSize
			LLK_PanelDimensions([Lang_Trans("global_hotkey"), Lang_Trans("global_save")], fSize, wHotkey, hHotkey)
		}

		GUI := "settings_menu" vars.settings.GUI_toggle, this.hwnd.settings := {}
		Gui, %GUI%: Add, Text, % "x" vars.settings.x_anchor " y" vars.settings.ySelection - 1 " w" settings.general.fWidth * vars.settings.min_width " h1 BackgroundTrans"	; blank text panel to force a minimum width for the settings section
		Gui, %GUI%: Add, Text, % "Section x" vars.settings.x_anchor " y" vars.settings.ySelection " Border BackgroundTrans HWNDhwnd gURL cAqua", % " github "
		Gui, %GUI%: Add, Progress, % "Disabled xp yp wp hp Border HWNDhwnd1 Background" vars.settings.cButtons2 " c" vars.settings.cButtons, 100
		vars.URLs := {}, vars.URLs[hwnd] := "https://github.com/Lailloken/Sample-Add-On", vars.hwnd.help_tooltips["settings_website"] := hwnd1

		Gui, %GUI%: Add, Text, % "ys Border BackgroundTrans HWNDhwnd gURL cAqua", % " ahk: key list "
		Gui, %GUI%: Add, Progress, % "Disabled xp yp wp hp Border HWNDhwnd1 Background" vars.settings.cButtons2 " c" vars.settings.cButtons, 100
		vars.URLs[hwnd] := "https://www.autohotkey.com/docs/v1/KeyList.htm", vars.hwnd.help_tooltips["settings_website|"] := hwnd1

		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "Section xs y+" vars.settings.spacing, % Lang_Trans("global_general")
		Gui, %GUI%: Font, norm

		Gui, %GUI%: Add, Text, % "Hidden Section xs w" wHotkey " Center Border BackgroundTrans cRed HWNDhwnd", % Lang_Trans("global_save")
		Gui, %GUI%: Add, Progress, % "Hidden Disabled xp yp wp hp Border HWNDhwnd1 Background" vars.settings.cButtons2 " c"  vars.settings.cButtons, 100
		this.hwnd.settings.save := hwnd, this.hwnd.settings.save_bar := hwnd1, func := ObjBindMethod(this, "Settings_input", hwnd)
		GuiControl, % "+g", % hwnd, % func

		Gui, %GUI%: Add, Text, % "xp yp wp hp Right Border", % Lang_Trans("global_hotkey") " "
		Gui, %GUI%: Add, Text, % "ys x+-1 hp w" settings.general.fWidth * 6 " Border BackgroundTrans"
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "xp yp wp hp Border cBlack HWNDhwnd Lowercase", % this.settings.hotkey_stats
		Gui, %GUI%: Font, % "s" settings.general.fSize
		this.hwnd.settings.hotkey := vars.hwnd.help_tooltips["settings_macros hotkeys"] := hwnd
		func := ObjBindMethod(this, "Settings_input", hwnd)
		GuiControl, % "+g", % hwnd, % func
	}

	Settings_input(cHWND := "") ; called when the settings menu receives inputs or is otherwise interacted with
	{
		global vars, settings

		check := LLK_HasVal(this.hwnd.settings, cHWND) ; checks which control was interacted with
		Switch
		{
			Case (check = "hotkey"):
				input := LLK_ControlGet(cHWND), modified := (input != this.settings.hotkey_stats)
				GuiControl, % "+c" (modified ? "Red" : "Black"), % cHWND
				GuiControl, % "movedraw", % cHWND
				GuiControl, % (modified ? "-" : "+") "Hidden", % this.hwnd.settings.save
				GuiControl, % (modified ? "-" : "+") "Hidden", % this.hwnd.settings.save_bar
			;##########################################################
			Case (check = "save"):
				input := LLK_ControlGet(this.hwnd.settings.hotkey), func := ObjBindMethod(this, "Hotkeys"), key := Hotkeys_Convert(input)
				If !key ; check for invalid inputs
				{
					WinGetPos, x, y, w, h, % "ahk_id " this.hwnd.settings.hotkey
					LLK_ToolTip(Lang_Trans("global_errorname", 2), 2, x + w, y,, "Red")
					Return
				}
				If !Blank(this.settings.hotkey_stats) && (Blank(input) || key) ; unbind the previous hotkey if applicable
				{
					Hotkey, IfWinActive, ahk_group poe_window
					Hotkey, % Hotkeys_Convert(this.settings.hotkey_stats), % func, off
				}
				Hotkey, IfWinActive, ahk_group poe_window	; set hotkey-context: only use hotkey if the PoE-client is active
				Hotkey, % key, % func, on				; bind the new hotkey

				IniWrite, % """" (this.settings.hotkey_stats := input) """", % this.config_path, settings, hotkey stats	; store the new hotkey in the config
				GuiControl, +Hidden, % this.hwnd.settings.save												; hide the "save" button
				GuiControl, +Hidden, % this.hwnd.settings.save_bar											; hide the background of the "save" button
				GuiControl, +cBlack, % this.hwnd.settings.hotkey												; set the font back to black
				GuiControl, movedraw, % this.hwnd.settings.hotkey												; redraw the edit control to refresh the font color
			;##########################################################
			Default:
				LLK_ToolTip("no action")
		}
	}
}
