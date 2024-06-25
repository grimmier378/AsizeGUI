--[[
	Title: AutoSizeGui
	Author: Grimmier
	Includes: 
	Description: MQ2AutoSize Lua GUI
]]

-- Load Libraries
local mq = require('mq')
local ImGui = require('ImGui')
local LoadTheme = require('lib.theme_loader')
local Icon = require('mq.ICONS')
local rIcon -- resize icon variable holder
local lIcon -- lock icon variable holder

-- Variables
local script = 'AutoSizeGui' -- Change this to the name of your script
local meName -- Character Name
local themeName = 'Default'
local gIcon = Icon.MD_SETTINGS -- Gear Icon for Settings
local themeID = 1
local theme, defaults, settings = {}, {}, {}
local RUNNING = true
local showMainGUI, showConfigGUI = true, false
local scale = 1
local aSize, locked, hasThemeZ = false, false, false

-- GUI Settings
local winFlags = bit32.bor(ImGuiWindowFlags.None)

-- File Paths
local themeFile = string.format('%s/MyUI/MyThemeZ.lua', mq.configDir)
local configFile = string.format('%s/MyUI/%s/%s_Configs.lua', mq.configDir, script, script)
local themezDir = mq.luaDir .. '/themez/init.lua'
local PluginLoaded = false
local TogglePC = true
local ToggleNPC = true
local ToggleSelf = true
local ToggleDist = true
local ToggleMount = true
local ToggleAutoSize = true
local ToggleCorpse = true
local TogglePets = true
local ToggleMercs = true
local ToggleTarget = true
local ToggleEverything = true
local AutoSave = true
local SizeEverything = 6
local SizePC = 6
local SizeNPC = 6
local SizeTarget = 6
local SizePets = 6
local SizeMercs = 6
local SizeMounts = 6
local SizeCorpse = 6
local SizeSelf = 6
-- Default Settings
defaults = {
	GrpCmd = '/dgge ',
	RaidCmd = '/dgre ',
	ZoneCmd = '/dgze ',
	Scale = 1.0,
	LoadTheme = 'Default',
	locked = false,
	LoadPlugin = true,
	Range = 50,
}

---comment Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

local function LoadAutoSize()
	if settings[script].LoadPlugin then
		if not mq.TLO.Plugin('mq2autosize').IsLoaded() then
			mq.cmdf("/squelch /plugin autosize noauto")
			PluginLoaded = true
		end
	end
end

local function loadTheme()
	-- Check for the Theme File
	if File_Exists(themeFile) then
		theme = dofile(themeFile)
	else
		-- Create the theme file from the defaults
		theme = require('themes') -- your local themes file incase the user doesn't have one in config folder
		mq.pickle(themeFile, theme)
	end
	-- Load the theme from the settings file
	themeName = settings[script].LoadTheme or 'Default'
	-- Find the theme ID
	if theme and theme.Theme then
		for tID, tData in pairs(theme.Theme) do
			if tData['Name'] == themeName then
				themeID = tID
			end
		end
	end
end

local function loadSettings()
	local newSetting = false -- Check if we need to save the settings file

	-- Check Settings File_Exists
	if not File_Exists(configFile) then
		-- Create the settings file from the defaults
		settings[script] = defaults
		mq.pickle(configFile, settings)
		loadSettings()
	else
		-- Load settings from the Lua config file
		settings = dofile(configFile)
		-- Check if the settings are missing from the file
		if settings[script] == nil then
			settings[script] = {}
			settings[script] = defaults
			newSetting = true
		end
	end

	-- Check if the settings are missing and use defaults if they are

	if settings[script].locked == nil then
		settings[script].locked = false
		newSetting = true
	end

	if settings[script].Scale == nil then
		settings[script].Scale = 1
		newSetting = true
	end

	if not settings[script].LoadTheme then
		settings[script].LoadTheme = 'Default'
		newSetting = true
	end

	if settings[script].LoadPlugin == nil then
		settings[script].LoadPlugin = true
		newSetting = true
	end

	PluginLoaded = mq.TLO.Plugin('mq2autosize').IsLoaded()
	if not PluginLoaded and settings[script].LoadPlugin then
		LoadAutoSize()
	end

	if AutoSave == nil then
	AutoSave = true
		newSetting = true
	end

	if settings[script].GrpCmd == nil then
		settings[script].GrpCmd = '/dgge '
		newSetting = true
	end

	if settings[script].RaidCmd == nil then
		settings[script].RaidCmd = '/dgre '
		newSetting = true
	end

	if settings[script].Range == nil then
		settings[script].Range = 100
		newSetting = true
	end

	if settings[script].ZoneCmd == nil then
		settings[script].ZoneCmd = '/dgze '
		newSetting = true
	end
	
	-- Load the theme
	loadTheme()

	-- Set the settings to the variables
	aSize = settings[script].AutoSize
	locked = settings[script].locked
	scale = settings[script].Scale
	themeName = settings[script].LoadTheme

	-- Save the settings if new settings were added
	if newSetting then mq.pickle(configFile, settings) end

end

local function Draw_GUI()

	if showMainGUI then
		ImGui.SetNextWindowSize(ImVec2(500, 350), ImGuiCond.Appearing)
		-- Set Window Name
		local winName = string.format('%s##Main_%s', script, meName)
		-- Load Theme
		local ColorCount, StyleCount = LoadTheme.StartTheme(theme.Theme[themeID])
		-- Create Main Window
		local openMain, showMain = ImGui.Begin(winName,true,winFlags)
		-- Check if the window is open
		if not openMain then
			showMainGUI = false
		end
		-- Check if the window is showing
		if showMain then
			-- Set Window Font Scale
			ImGui.SetWindowFontScale(scale)
			-- Draw Config Gear Icon
			ImGui.Text(gIcon)
			if ImGui.IsItemHovered() then
				-- Set Tooltip
				ImGui.SetTooltip("Set##tings")
				-- Check if the Gear Icon is clicked
				if ImGui.IsMouseReleased(0) then
					-- Toggle Config Window
					showConfigGUI = not showConfigGUI
				end
			end
			local label1 = PluginLoaded and "Unload" or "Load"
			if ImGui.Button(label1) then
				if PluginLoaded then
					mq.cmdf("/squelch /plugin autosize unload")
					PluginLoaded = false
				else
					LoadAutoSize()
				end
			end
			if PluginLoaded == true then
				ImGui.SameLine()
				if ImGui.Button("Save to plugin INI") then
					mq.cmdf("/autosize save")
				end
				ImGui.SameLine()
				local autoSave = false
			AutoSave, autoSave = ImGui.Checkbox("Auto Save##check", AutoSave)
				if autoSave then
					mq.cmd("/multiline ; /autosize autosave; /timed 5 /autosize status")
				end
				local pressed1 = false
				ToggleEverything , pressed1 = ImGui.Checkbox("Zone Wide##check", ToggleEverything)
				if pressed1 then
					mq.cmd("/multiline ;  /autosize; /timed 5, /autosize status")
				end
				if ImGui.BeginChild("##SettingsChild", 0.0, 0.0) then
					if ImGui.BeginTable("##TableSettings", 3, bit32.bor(ImGuiTableFlags.Resizable), -1, -1) then
						ImGui.TableSetupColumn("##Column1", ImGuiTableColumnFlags.WidthAlwaysAutoResize, -1)
						ImGui.TableSetupColumn("##Column2", ImGuiTableColumnFlags.WidthAlwaysAutoResize, -1)
						ImGui.TableSetupColumn("##Column3", ImGuiTableColumnFlags.WidthAlwaysAutoResize, -1)
						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressedX = false
						ToggleDist , pressedX = ImGui.Checkbox("Range Based Toggle##check", ToggleDist)
						if pressedX then
							mq.cmd("/multiline ; /autosize dist; /timed 5, /autosize status")
						end

						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
						settings[script].Range = ImGui.InputInt("Range Distance##input", settings[script].Range, 1, 10)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##Range") then

							mq.cmdf("/timed 5, /autosize range %d", settings[script].Range)
							printf("/timed 5, /autosize range %d", settings[script].Range)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Range") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize range %d", settings[script].GrpCmd,settings[script].Range)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Range") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize range %d", settings[script].ZoneCmd,settings[script].Range)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Range") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize range %d", settings[script].RaidCmd,settings[script].Range)
							
						end
						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed2 = false
						TogglePC, pressed2 = ImGui.Checkbox("PC##check", TogglePC)
						if pressed2 then
							mq.cmd("/multiline ;  /autosize pc; /timed 5, /autosize status")
						end

						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizePC = ImGui.InputInt("PC##input", SizePC, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##PCSize") then

							mq.cmdf("/autosize sizepc %d", SizePC)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##PC") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizepc %d", settings[script].GrpCmd,SizePC)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##PC") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizepc %d", settings[script].ZoneCmd,SizePC)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##PC") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizepc %d", settings[script].RaidCmd,SizePC)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed3 = false
						ToggleNPC, pressed3 = ImGui.Checkbox("NPC##check", ToggleNPC)
						if pressed3 then
							mq.cmd("/multiline ;  /autosize npc; /timed 5, /autosize status")
						end
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizeNPC = ImGui.InputInt("NPC##input", SizeNPC, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##NPCSize") then

							mq.cmdf("/autosize sizenpc %d", SizeNPC)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##NPC") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizenpc %d", settings[script].GrpCmd,SizeNPC)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##NPC") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizenpc %d", settings[script].ZoneCmd,SizeNPC)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##NPC") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizenpc %d", settings[script].RaidCmd,SizeNPC)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed4 = false
					ToggleSelf, pressed4 = ImGui.Checkbox("Self##check", ToggleSelf)
						if pressed4 then
							mq.cmd("/multiline ;  /autosize self; /timed 5, /autosize status")
						end
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizeSelf = ImGui.InputInt("Self##input", SizeSelf, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##SelfSize") then

							mq.cmdf("/autosize sizeself %d", SizeSelf)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Self") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizeself %d", settings[script].GrpCmd,SizeSelf)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Self") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizeself %d", settings[script].ZoneCmd,SizeSelf)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Self") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizeself %d", settings[script].RaidCmd,SizeSelf)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed5 = false
					ToggleMount, pressed5 = ImGui.Checkbox("Mounts##check", ToggleMount)
						if pressed5 then
							mq.cmd("/multiline ;  /autosize mounts; /timed 5, /autosize status")
						end
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizeMounts = ImGui.InputInt("Mounts##input", SizeMounts, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##MountSize") then

							mq.cmdf("/autosize sizemounts %d", SizeMounts)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Mounts") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizemounts %d", settings[script].GrpCmd,SizeMounts)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Mounts") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizemounts %d", settings[script].ZoneCmd,SizeMounts)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Mounts") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizemounts %d", settings[script].RaidCmd,SizeMounts)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed6 = false
					ToggleCorpse, pressed6 = ImGui.Checkbox("Corpse##check", ToggleCorpse)
						if pressed6 then
							mq.cmd("/multiline ;  /autosize corpse; /timed 5, /autosize status")
						end
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizeCorpse = ImGui.InputInt("Corpse##input", SizeCorpse, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##CorpseSize") then

							mq.cmdf("/autosize sizecorpse %d", SizeCorpse)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Corpse") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizecorpse %d", settings[script].GrpCmd,SizeCorpse)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Corpse") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizecorpse %d", settings[script].ZoneCmd,SizeCorpse)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Corpse") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizecorpse %d", settings[script].RaidCmd,SizeCorpse)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed7 = false
					TogglePets, pressed7 = ImGui.Checkbox("Pets##check", TogglePets)
						if pressed7 then
							mq.cmd("/multiline ;  /autosize pets; /timed 5, /autosize status")
						end
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizePets = ImGui.InputInt("Pets##input", SizePets, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##PetsSize") then

							mq.cmdf("/autosize sizepets %d", SizePets)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Pets") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizepets %d", settings[script].GrpCmd,SizePets)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Pets") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizepets %d", settings[script].ZoneCmd,SizePets)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Pets") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizepets %d", settings[script].RaidCmd,SizePets)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						local pressed8 = false
					ToggleMercs, pressed8 = ImGui.Checkbox("Mercs##check", ToggleMercs)
						if pressed8 then
							mq.cmd("/multiline ;  /autosize mercs; /timed 5, /autosize status")
						end
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizeMercs = ImGui.InputInt("Mercs##input", SizeMercs, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##MercsSize") then

							mq.cmdf("/autosize sizemercs %d", SizeMercs)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Mercs") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizemercs %d", settings[script].GrpCmd,SizeMercs)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Mercs") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizemercs %d", settings[script].ZoneCmd,SizeMercs)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Mercs") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizemercs %d", settings[script].RaidCmd,SizeMercs)
							
						end

						ImGui.TableNextRow()
						ImGui.TableNextColumn()
						
						ImGui.TableNextColumn()
						ImGui.SetNextItemWidth(100)
					SizeTarget = ImGui.InputInt("Target##input", SizeTarget, 1, 250)
						ImGui.TableNextColumn()
						if ImGui.Button("Set##TargetSize") then

							mq.cmdf("/multiline ;  /autosize sizetarget %d; /timed 5, /autosize status; /timed 10, /autosize target", SizeTarget)
						end
						ImGui.SameLine()
						if ImGui.Button("Grp##Target") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizetarget %d; /timed 5, /autosize target;", settings[script].GrpCmd,SizeTarget)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Zone##Target") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizetarget %d; /timed 5, /autosize target;", settings[script].ZoneCmd,SizeTarget)
							
						end
						ImGui.SameLine()
						if ImGui.Button("Raid##Target") then

							mq.cmdf("%s/multiline ; /timed 5, /autosize sizetarget %d; /timed 5, /autosize target;", settings[script].RaidCmd,SizeTarget)
							
						end

						ImGui.EndTable()
					end
					ImGui.EndChild()
				end
			else
				ImGui.Text("Plugin is not loaded.")
			end
			-- Reset Font Scale
			ImGui.SetWindowFontScale(1)
		-- Unload Theme
		LoadTheme.EndTheme(ColorCount, StyleCount)
		ImGui.End()
		else
		-- Unload Theme
		LoadTheme.EndTheme(ColorCount, StyleCount)
		ImGui.End()
		end


	end

	if showConfigGUI then
			local winName = string.format('%s Config##Config_%s',script, meName)
			local ColCntConf, StyCntConf = LoadTheme.StartTheme(theme.Theme[themeID])
			local openConfig, showConfig = ImGui.Begin(winName,true,bit32.bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoDocking))
			if not openConfig then
				showConfigGUI = false
			end
			if showConfig then

				-- Configure ThemeZ --
				ImGui.SeparatorText("Theme##"..script)
				ImGui.Text("Cur Theme: %s", themeName)

				-- Combo Box Load Theme
				if ImGui.BeginCombo("Load Theme##"..script, themeName) then
					for k, data in pairs(theme.Theme) do
						local isSelected = data.Name == themeName
						if ImGui.Selectable(data.Name, isSelected) then
							theme.LoadTheme = data.Name
							themeID = k
							themeName = theme.LoadTheme
						end
					end
					ImGui.EndCombo()
				end

				-- Configure Scale --
				scale = ImGui.SliderFloat("Scale##"..script, scale, 0.5, 2)
				if scale ~= settings[script].Scale then
					if scale < 0.5 then scale = 0.5 end
					if scale > 2 then scale = 2 end
				end

				-- Edit ThemeZ Button if ThemeZ lua exists.
				if hasThemeZ then
					if ImGui.Button('Edit ThemeZ') then
						mq.cmd("/lua run themez")
					end
					ImGui.SameLine()
				end

				-- Reload Theme File incase of changes --
				if ImGui.Button('Reload Theme File') then
					loadTheme()
				end

				ImGui.Separator()
				settings[script].GrpCmd = ImGui.InputText("Group Command##"..script, settings[script].GrpCmd)
				-- check for a slash at the end of cmd = eqbca command leave it alone
				if settings[script].GrpCmd:find("/$") then
					settings[script].GrpCmd = settings[script].GrpCmd
				elseif not settings[script].GrpCmd:find(" $") then
					-- check for a space if no slash add one if missing
					settings[script].GrpCmd = settings[script].GrpCmd.." "
				end
				settings[script].RaidCmd = ImGui.InputText("Raid Command##"..script, settings[script].RaidCmd)
				if settings[script].RaidCmd:find("/$") then
					settings[script].RaidCmd = settings[script].RaidCmd
				elseif not settings[script].RaidCmd:find(" $") then
					settings[script].RaidCmd = settings[script].RaidCmd.." "
				end
				settings[script].ZoneCmd = ImGui.InputText("Zone Command##"..script, settings[script].ZoneCmd)
				if settings[script].ZoneCmd:find("/$") then
					settings[script].ZoneCmd = settings[script].ZoneCmd
				elseif not settings[script].ZoneCmd:find(" $") then
					settings[script].ZoneCmd = settings[script].ZoneCmd.." "
				end
				ImGui.Separator()
				-- Save & Close Button --
				if ImGui.Button("Save & Close") then
					settings[script].Scale = scale
					settings[script].LoadTheme = themeName
					mq.pickle(configFile, settings)
					showConfigGUI = false
				end
				LoadTheme.EndTheme(ColCntConf, StyCntConf)
				ImGui.End()
			else
				LoadTheme.EndTheme(ColCntConf, StyCntConf)
				ImGui.End()
			end

	end

end

local function EventToggles(line, pc, npc, pets, mercs, mounts, corpses, myself, everything)
	TogglePC = pc == 'on' and true or false
	ToggleNPC = npc == 'on' and true or false
	TogglePets = pets == 'on' and true or false
	ToggleMercs = mercs == 'on' and true or false
	ToggleMount = mounts == 'on' and true or false
	ToggleCorpse = corpses == 'on' and true or false
	ToggleSelf = myself == 'on' and true or false
	
end

local function EventSizes(line, pc, npc, pets, mercs, mounts, corpses, target, myself, everything)
	SizePC = pc
	SizeNPC = npc
	SizePets = pets
	SizeMercs = mercs
	SizeMounts = mounts
	SizeCorpse = corpses
	SizeTarget = target
	SizeSelf = myself
	SizeEverything = everything
end

local function EventStatus(line, method, autoSave)
ToggleEverything = method == 'Zonewide' and true or false
ToggleDist = method == 'Range' and true or false
AutoSave = autoSave == 'AUTOSAVING' and true or false
	mq.pickle(configFile, settings)
end

local function Init()
	-- Load Settings
	loadSettings()
	-- Get Character Name
	meName = mq.TLO.Me.Name()
	mq.event("toggles", "Toggles: PC(#1#) NPC(#2#) Pets(#3#) Mercs(#4#) Mounts(#5#) Corpses(#6#) Self(#7#) Everything(#8#)#*#", EventToggles)
	mq.event("sizes", "Sizes: PC(#1#) NPC(#2#) Pets(#3#) Mercs(#4#) Mounts(#5#) Corpses(#6#) Target(#7#) Self(#8#) Everything(#9#)#*#", EventSizes)
	mq.event('status', 'MQ2AutoSize:: Current Status -- Method: (#1#) #2#', EventStatus)
	-- Check if ThemeZ exists
	if File_Exists(themezDir) then
		hasThemeZ = true
	end
	settings[script].PluginLoaded = mq.TLO.Plugin('mq2autosize').IsLoaded()
	if settings[script].PluginLoaded then
		mq.cmd("/autosize status")
		mq.doevents()
	end
	-- Initialize ImGui
	mq.imgui.init(script, Draw_GUI)
end

local function Loop()
	-- Main Loop
	while RUNNING do
		RUNNING = showMainGUI
		-- Make sure we are still in game or exit the script.
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then printf("\aw[\at%s\ax] \arNot in game, \ayTry again later...", script) mq.exit() end
		settings[script].PluginLoaded = mq.TLO.Plugin('mq2autosize').IsLoaded()
		mq.doevents()
		mq.delay(10) -- delay 1 second

	end
end
-- Make sure we are in game before running the script
if mq.TLO.EverQuest.GameState() ~= "INGAME" then printf("\aw[\at%s\ax] \arNot in game, \ayTry again later...", script) mq.exit() end
Init()
Loop()