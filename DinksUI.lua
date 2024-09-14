DinksUI = LibStub("AceAddon-3.0"):NewAddon("DinksUI", "AceConsole-3.0", "AceEvent-3.0")

------------------------------------------
-- #region: locals
------------------------------------------

-- WoW's globals that are exposed for addons.
local _G = _G
local CreateFrame = CreateFrame
local EventRegistry = EventRegistry
local OpenToCategory = Settings.OpenToCategory
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local RegisterAttributeDriver = RegisterAttributeDriver
local ReloadUI = ReloadUI
local UIParent = UIParent
local UnregisterAttributeDriver = UnregisterAttributeDriver

-- Some frames don't handle it well when you call their `Hide` and `Show` methods.
-- For those, we will wrap them in new frames that will hide/show just fine.
local FrameWrapperTable = {}

-- An AceConfig schema options object.
local options = {
	name = "DinksUI",
	handler = DinksUI,
	type = 'group',
	get = "GetValue",
	set = "SetValue",
	args = {
		desc1 = { type = "description", name = "Supply each frame below with a macro conditional of your chosing or none.", fontSize = "medium", order = 0 },
		desc2 = { type = "description", name = "Ex 1: MainMenuBar: [vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide", fontSize = "medium", order = 1 },
		desc3 = { type = "description", name = "Ex 2: PetActionBar: [mod:ctrl,@pet,exists] show; hide", fontSize = "medium", order = 2 },
		reloadTxt = { type = "description", name = "You will need to reload after confirming changes.", fontSize = "medium", order = 3 },
		reloadBtn = { type = "execute", name = "Reload UI", order = 4, func = ReloadUI },

		actionBar1 = { type = "input", name = "ActionBar1", desc = "MainMenuBar", width = "full", order = 5 },
		actionBar2 = { type = "input", name = "ActionBar2", desc = "MultiBarBottomLeft", width = "full", order = 6 },
		actionBar3 = { type = "input", name = "ActionBar3", desc = "MultiBarBottomRight", width = "full", order = 7 },
		actionBar4 = { type = "input", name = "ActionBar4", desc = "MultiBarRight", width = "full", order = 8 },
		actionBar5 = { type = "input", name = "ActionBar5", desc = "MultiBarLeft", width = "full", order = 9 },
		actionBar6 = { type = "input", name = "ActionBar6", desc = "MultiBar5", width = "full", order = 10 },
		actionBar7 = { type = "input", name = "ActionBar7", desc = "MultiBar6", width = "full", order = 11 },
		actionBar8 = { type = "input", name = "ActionBar8", desc = "MultiBar7", width = "full", order = 12 },
		petActionBar = { type = "input", name = "PetActionBar", desc = "PetActionBar", width = "full", order = 13 },
		stanceBar = { type = "input", name = "StanceBar", desc = "StanceBar", width = "full", order = 14 },
		playerFrame = { type = "input", name = "PlayerFrame", desc = "PlayerFrame", width = "full", order = 15 },
		targetFrame = { type = "input", name = "TargetFrame", desc = "TargetFrame", width = "full", order = 16 },
		focusFrame = { type = "input", name = "FocusFrame", desc = "FocusFrame", width = "full", order = 17 },
		petFrame = { type = "input", name = "PetFrame", desc = "PetFrame", width = "full", order = 18 },
		objectiveTrackerFrame = { type = "input", name = "ObjectiveTrackerFrame", desc = "ObjectiveTrackerFrame", width = "full", order = 19 },
		chatFrame = { type = "input", name = "ChatFrames", desc = "ChatFrame", width = "full", order = 20 },
		minimap = { type = "input", name = "Minimap", desc = "Minimap", width = "full", order = 21 },
		bagsBar = { type = "input", name = "BagsBar", desc = "BagsBar", width = "full", order = 22 },
		microMenuContainer = { type = "input", name = "MicroMenuContainer", desc = "MicroMenuContainer", width = "full", order = 23 },
		buffFrame = { type = "input", name = "BuffFrame", desc = "BuffFrame", width = "full", order = 24 },
		debuffFrame = { type = "input", name = "DebuffFrame", desc = "DebuffFrame", width = "full", order = 25 },
		experienceBar = { type = "input", name = "ExperienceBar", desc = "MainStatusTrackingBarContainer", width = "full", order = 26 },
		skyRidingBar = { type = "input", name = "SkyRidingBar", desc = "UIWidgetPowerBarContainerFrame", width = "full", order = 27 },

		slashCmdTxt = { type = "description", name = "You can use '/dinksui show' and /dinksui hide' to temporarily toggle visibility. You can even make a macro!", fontSize = "medium", order = 97 },
		bottomReloadTxt = { type = "description", name = "You will need to reload after confirming changes.", fontSize = "medium", order = 98 },
		bottomReloadBtn = { type = "execute", name = "Reload UI", func = function() ReloadUI() end, order = 99 },
	},
}

-- Default options match a subset of the `options.args` above.
local defaults = {
	profile = {
		actionBar1 = "[vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide",
		actionBar2 = "[vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide",
		actionBar3 = "[vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide",
		actionBar4 = "[vehicleui] hide; [mod:ctrl] show; hide",
		actionBar5 = "[vehicleui] hide; [mod:ctrl] show; hide",
		actionBar6 = "",
		actionBar7 = "",
		actionBar8 = "",
		petActionBar = "[mod:ctrl,@pet,exists] show; hide",
		stanceBar = "[vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide",
		playerFrame = "[mod:ctrl] show; hide",
		targetFrame = "[mod:ctrl,exists] show; hide",
		focusFrame = "",
		petFrame = "[mod:alt,@pet,exists][mod:ctrl,@pet,exists][combat] show; hide",
		objectiveTrackerFrame = "[mod:ctrl][mod:alt,nocombat] show; hide",
		minimap = "",
		bagsBar = "[mod:ctrl] show; hide",
		microMenuContainer = "[mod:ctrl] show; hide",
		buffFrame = "",
		debuffFrame = "",
		experienceBar = "[vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide",
		skyRidingBar = "[vehicleui] hide; [mod:ctrl][mod:alt][combat] show; hide",
		chatFrame = "",
	},
}

------------------------------------------
-- #endregion: locals
------------------------------------------

------------------------------------------
-- #region: AceAddon lifecycle functions
------------------------------------------

function DinksUI:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("DinksUIDB", defaults, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DinksUI_options", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DinksUI_options", "DinksUI")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DinksUI_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DinksUI_Profiles", "Profiles", "DinksUI")
end

function DinksUI:OnEnable()
	self:RegisterChatCommand("dui", "HandleSlashCommand")
	self:RegisterChatCommand("dinksui", "HandleSlashCommand")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "HandleEnteringWorld")
	EventRegistry:RegisterCallback("EditMode.Enter", self.UnregisterAllFrames, self)
	EventRegistry:RegisterCallback("EditMode.Exit", self.RegisterAllFrames, self)
end

function DinksUI:OnDisable()
	self:UnregisterChatCommand("dui")
	self:UnregisterChatCommand("dinksui")
	self:HandleExitingWorld()
	EventRegistry:UnregisterCallback("EditMode.Enter", self)
	EventRegistry:UnregisterCallback("EditMode.Exit", self)
end

------------------------------------------
-- #endregion: AceAddon lifecycle functions
------------------------------------------

------------------------------------------
-- #region: local functions
------------------------------------------

-- So, `PLAYER_ENTERING_WORLD` basically means "finished any loading screen".
-- Because the UI is rebuilt every loading screen, we need to start all the work here.
-- Yes, at this time, `HandleEnteringWorld` only calls `RegisterAllFrames`, but
-- at some point it might do more...and I wanted to document all this here.
function DinksUI:HandleEnteringWorld()
	self:RegisterAllFrames()
end

function DinksUI:HandleExitingWorld()
	self:UnregisterAllFrames()
	FrameWrapperTable = {}
end

function DinksUI:HandleSlashCommand(command)
	local cmd = command:trim():lower()
	if not cmd or cmd == "" then
		OpenToCategory(self.optionsFrame.name)
	elseif cmd == "h" or cmd == "help" then
		self:Print("type '/dinksui show' to temporarily show all frames.")
		self:Print("type '/dinksui hide' to again hide all frames.")
	elseif cmd == "show" then
		self:UnregisterAllFrames()
	elseif cmd == "hide" then
		self:RegisterAllFrames()
	else
		self:Print("Command not found '" .. command .. "'")
	end
end

-- This is the main function. This is where new frames can be added.
function DinksUI:RegisterAllFrames()
	local frames = options.args
	local conditionals = self.db.profile
	self:Register(frames.actionBar1.desc, conditionals.actionBar1)
	self:Register(frames.actionBar2.desc, conditionals.actionBar2)
	self:Register(frames.actionBar3.desc, conditionals.actionBar3)
	self:Register(frames.actionBar4.desc, conditionals.actionBar4)
	self:Register(frames.actionBar5.desc, conditionals.actionBar5)
	self:Register(frames.actionBar6.desc, conditionals.actionBar6)
	self:Register(frames.actionBar7.desc, conditionals.actionBar7)
	self:Register(frames.actionBar8.desc, conditionals.actionBar8)
	self:Register(frames.petActionBar.desc, conditionals.petActionBar)
	self:RegisterWrapper(frames.stanceBar.desc, conditionals.stanceBar)
	self:Register(frames.playerFrame.desc, conditionals.playerFrame)
	self:RegisterWrapper(frames.targetFrame.desc, conditionals.targetFrame)
	self:Register(frames.focusFrame.desc, conditionals.focusFrame)
	self:Register(frames.petFrame.desc, conditionals.petFrame)
	self:RegisterWrapper(frames.objectiveTrackerFrame.desc, conditionals.objectiveTrackerFrame)
	self:Register(frames.minimap.desc, conditionals.minimap)
	self:Register(frames.bagsBar.desc, conditionals.bagsBar)
	self:Register(frames.microMenuContainer.desc, conditionals.microMenuContainer)
	self:Register(frames.buffFrame.desc, conditionals.buffFrame)
	self:Register(frames.debuffFrame.desc, conditionals.debuffFrame)
	self:Register(frames.experienceBar.desc, conditionals.experienceBar)
	self:Register(frames.skyRidingBar.desc, conditionals.skyRidingBar)
	self:RegisterChat(frames.chatFrame.desc, conditionals.chatFrame)
end

-- Remember to also add new frames here as well.
function DinksUI:UnregisterAllFrames()
	local frames = options.args
	local conditionals = self.db.profile
	self:Unregister(frames.actionBar1.desc, conditionals.actionBar1)
	self:Unregister(frames.actionBar2.desc, conditionals.actionBar2)
	self:Unregister(frames.actionBar3.desc, conditionals.actionBar3)
	self:Unregister(frames.actionBar4.desc, conditionals.actionBar4)
	self:Unregister(frames.actionBar5.desc, conditionals.actionBar5)
	self:Unregister(frames.actionBar6.desc, conditionals.actionBar6)
	self:Unregister(frames.actionBar7.desc, conditionals.actionBar7)
	self:Unregister(frames.actionBar8.desc, conditionals.actionBar8)
	self:Unregister(frames.petActionBar.desc, conditionals.petActionBar)
	self:UnregisterWrapper(frames.stanceBar.desc, conditionals.stanceBar)
	self:Unregister(frames.playerFrame.desc, conditionals.playerFrame)
	self:UnregisterWrapper(frames.targetFrame.desc, conditionals.targetFrame)
	self:Unregister(frames.focusFrame.desc, conditionals.focusFrame)
	self:Unregister(frames.petFrame.desc, conditionals.petFrame)
	self:UnregisterWrapper(frames.objectiveTrackerFrame.desc, conditionals.objectiveTrackerFrame)
	self:Unregister(frames.minimap.desc, conditionals.minimap)
	self:Unregister(frames.bagsBar.desc, conditionals.bagsBar)
	self:Unregister(frames.microMenuContainer.desc, conditionals.microMenuContainer)
	self:Unregister(frames.buffFrame.desc, conditionals.buffFrame)
	self:Unregister(frames.debuffFrame.desc, conditionals.debuffFrame)
	self:Unregister(frames.experienceBar.desc, conditionals.experienceBar)
	self:Unregister(frames.skyRidingBar.desc, conditionals.skyRidingBar)
	self:UnregisterChat(frames.chatFrame.desc, conditionals.chatFrame)
end

function DinksUI:Register(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		RegisterAttributeDriver(_G[frameKey], "state-visibility", conditionalMacro)
	end
end

function DinksUI:RegisterWrapper(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		local oldParent = _G[frameKey]:GetParent()
		local newParent = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")

		_G[frameKey]:SetParent(newParent)
		FrameWrapperTable[frameKey] = oldParent
		RegisterAttributeDriver(newParent, "state-visibility", conditionalMacro)
	end
end

function DinksUI:RegisterChat(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		for i = 1, NUM_CHAT_WINDOWS do
			self:RegisterWrapper(frameKey .. i, conditionalMacro)
		end

		self:RegisterWrapper("GeneralDockManager", conditionalMacro)
		self:RegisterWrapper("QuickJoinToastButton", conditionalMacro)
	end
end

function DinksUI:Unregister(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		UnregisterAttributeDriver(_G[frameKey], "state-visibility")
		_G[frameKey]:Show()
	end
end

function DinksUI:UnregisterWrapper(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		_G[frameKey]:SetParent(FrameWrapperTable[frameKey])
	end
end

function DinksUI:UnregisterChat(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		for i = 1, NUM_CHAT_WINDOWS do
			self:UnregisterWrapper(frameKey .. i, conditionalMacro)
		end

		self:UnregisterWrapper("GeneralDockManager", conditionalMacro)
		self:UnregisterWrapper("QuickJoinToastButton", conditionalMacro)
	end
end

-- Returns the value associated with `options.args` properties.
-- Since the "AceDB" is set up and populated in "DinksUI.OnInitialize",
-- we immediately start interfacing with `self.db` instead of the values stored in `options.args`.
function DinksUI:GetValue(info)
	return self.db.profile[info[#info]]
end

function DinksUI:SetValue(info, value)
	self.db.profile[info[#info]] = value
end

------------------------------------------
-- #endregion: local functions
------------------------------------------
