DinksUI = LibStub("AceAddon-3.0"):NewAddon("DinksUI", "AceConsole-3.0")

------------------------------------------
-- #region: locals
------------------------------------------

-- WoW's globals that are exposed for addons.
local _G = _G
local EventRegistry = EventRegistry
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local OpenToCategory = Settings.OpenToCategory
local RegisterAttributeDriver = RegisterAttributeDriver
local ReloadUI = ReloadUI
local UnitExists = UnitExists
local UnregisterAttributeDriver = UnregisterAttributeDriver

-- Need to store the original `ObjectiveTrackerFrame:Show()` method and override it below.
local OriginalObjectiveTrackerFrameShow = _G["ObjectiveTrackerFrame"].Show

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
		topReload1 = { type = "description", name = "You will need to reload after confirming changes.", fontSize = "medium", order = 3 },
		topReload2 = { type = "execute", name = "Reload UI", order = 4, func = ReloadUI },

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
		objectiveTrackerFrame = { type = "input", name = "ObjectiveTrackerFrame (mostly works)", desc = "ObjectiveTrackerFrame", width = "full", order = 19 },
		minimap = { type = "input", name = "Minimap", desc = "Minimap", width = "full", order = 20 },
		bagsBar = { type = "input", name = "BagsBar", desc = "BagsBar", width = "full", order = 21 },
		microMenuContainer = { type = "input", name = "MicroMenuContainer", desc = "MicroMenuContainer", width = "full", order = 22 },
		buffFrame = { type = "input", name = "BuffFrame", desc = "BuffFrame", width = "full", order = 23 },
		debuffFrame = { type = "input", name = "DebuffFrame", desc = "DebuffFrame", width = "full", order = 24 },
		experienceBar = { type = "input", name = "ExperienceBar", desc = "MainStatusTrackingBarContainer", width = "full", order = 25 },
		skyRidingBar = { type = "input", name = "SkyRidingBar", desc = "UIWidgetPowerBarContainerFrame", width = "full", order = 26 },

		bottomReload1 = { type = "description", name = "You will need to reload after confirming changes.", fontSize = "medium", order = 98 },
		bottomReload2 = { type = "execute", name = "Reload UI", func = function() ReloadUI() end, order = 99 },
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
		experienceBar = "",
		skyRidingBar = "",
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
	self:RegisterChatCommand("dinksui", "HandleSlashCommand")
	self:RegisterAllFrames()
	EventRegistry:RegisterCallback("EditMode.Enter", self.UnregisterAllFrames, self)
	EventRegistry:RegisterCallback("EditMode.Exit", self.RegisterAllFrames, self)
end

function DinksUI:OnDisable()
	self:UnregisterChatCommand("dinksui")
	self:UnregisterAllFrames()
	EventRegistry:RegisterCallback("EditMode.Enter", self)
	EventRegistry:RegisterCallback("EditMode.Exit", self)
end

------------------------------------------
-- #endregion: AceAddon lifecycle functions
------------------------------------------

------------------------------------------
-- #region: local functions
------------------------------------------

-- Returns the value associated with `options.args` properties.
-- Since the "AceDB" is set up and populated in "DinksUI:OnInitialize",
--   we immediately start interfacing with `self.db` instead of the values stored in `options.args`.
function DinksUI:GetValue(info)
	return self.db.profile[info[#info]]
end

function DinksUI:SetValue(info, value)
	self.db.profile[info[#info]] = value
end

function DinksUI:HandleSlashCommand(command)
	if not command or command:trim() == "" then
		OpenToCategory(self.optionsFrame.name)
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
	self:RegisterStance(frames.stanceBar.desc, conditionals.stanceBar)
	self:Register(frames.playerFrame.desc, conditionals.playerFrame)
	self:Register(frames.targetFrame.desc, conditionals.targetFrame)
	self:Register(frames.focusFrame.desc, conditionals.focusFrame)
	self:Register(frames.petFrame.desc, conditionals.petFrame)
	self:RegisterObjective(frames.objectiveTrackerFrame.desc, conditionals.objectiveTrackerFrame)
	self:Register(frames.minimap.desc, conditionals.minimap)
	self:Register(frames.bagsBar.desc, conditionals.bagsBar)
	self:Register(frames.microMenuContainer.desc, conditionals.microMenuContainer)
	self:Register(frames.buffFrame.desc, conditionals.buffFrame)
	self:Register(frames.debuffFrame.desc, conditionals.debuffFrame)
	self:Register(frames.experienceBar.desc, conditionals.experienceBar)
	self:Register(frames.skyRidingBar.desc, conditionals.skyRidingBar)
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
	self:UnregisterStance(frames.stanceBar.desc, conditionals.stanceBar)
	self:Unregister(frames.playerFrame.desc, conditionals.playerFrame)
	self:UnregisterTarget(frames.targetFrame.desc, conditionals.targetFrame)
	self:Unregister(frames.focusFrame.desc, conditionals.focusFrame)
	self:Unregister(frames.petFrame.desc, conditionals.petFrame)
	self:UnregisterObjective(frames.objectiveTrackerFrame.desc, conditionals.objectiveTrackerFrame)
	self:Unregister(frames.minimap.desc, conditionals.minimap)
	self:Unregister(frames.bagsBar.desc, conditionals.bagsBar)
	self:Unregister(frames.microMenuContainer.desc, conditionals.microMenuContainer)
	self:Unregister(frames.buffFrame.desc, conditionals.buffFrame)
	self:Unregister(frames.debuffFrame.desc, conditionals.debuffFrame)
	self:Unregister(frames.experienceBar.desc, conditionals.experienceBar)
	self:Unregister(frames.skyRidingBar.desc, conditionals.skyRidingBar)
end

function DinksUI:Register(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		RegisterAttributeDriver(_G[frameKey], "state-visibility", conditionalMacro)
	end
end

-- Wrapper on `DinksUI:Register` that only acts if the current spec even has stances.
--   Otherwise, you will get a "shadow StanceBar".
function DinksUI:RegisterStance(frameKey, conditionalMacro)
	if GetShapeshiftFormInfo(1) then
		self:Register(frameKey, conditionalMacro)
	end
end

-- Wrapper on `DinksUI:Register` that also overrides `OriginalObjectiveTrackerFrameShow`.
--   Various other events will cause the frame to flicker between show and hide.
--   This will prevent any other event from calling `OriginalObjectiveTrackerFrameShow`.
--   ...I have no idea why DinksUI is caller "100", but it is what it is.
function DinksUI:RegisterObjective(frameKey, conditionalMacro)
	self:Register(frameKey, conditionalMacro)

	_G[frameKey].Show = function(self, ...)
		local stack = debugstack(2, 1, 0)
		local caller = stack:match("([^:]+): in function")
		if caller == "100" then
			return OriginalObjectiveTrackerFrameShow(self, ...)
		end
	end
end

function DinksUI:RegisterChat(frameKey, conditionalMacro)
	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G[frameKey .. i]
		self:Register(chatFrame:GetName(), conditionalMacro)
	end
end

function DinksUI:Unregister(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		UnregisterAttributeDriver(_G[frameKey], "state-visibility")
		_G[frameKey]:Show()
	end
end

function DinksUI:UnregisterStance(frameKey, conditionalMacro)
	if GetShapeshiftFormInfo(1) then
		self:Unregister(frameKey, conditionalMacro)
	end
end

function DinksUI:UnregisterObjective(frameKey, conditionalMacro)
	_G[frameKey].Show = OriginalObjectiveTrackerFrameShow
	self:Unregister(frameKey, conditionalMacro)
end

function DinksUI:UnregisterTarget(frameKey, conditionalMacro)
	self:Unregister(frameKey, conditionalMacro)
	if not UnitExists("target") then
		_G[frameKey]:Hide()
	end
end

------------------------------------------
-- #endregion: local functions
------------------------------------------
