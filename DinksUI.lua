DinksUI = LibStub("AceAddon-3.0"):NewAddon("DinksUI", "AceConsole-3.0")

------------------------------------------
-- #region: locals
------------------------------------------

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
		topReload2 = { type = "execute", name = "Reload UI", order = 4, func = function() ReloadUI() end },

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
		chatFrame = { type = "input", name = "ChatFrame", desc = "ChatFrame", width = "full", order = 20 },
		minimap = { type = "input", name = "Minimap", desc = "Minimap", width = "full", order = 21 },
		bagsBar = { type = "input", name = "BagsBar", desc = "BagsBar", width = "full", order = 22 },
		microMenuContainer = { type = "input", name = "MicroMenuContainer", desc = "MicroMenuContainer", width = "full", order = 23 },
		buffFrame = { type = "input", name = "BuffFrame", desc = "BuffFrame", width = "full", order = 24 },
		debuffFrame = { type = "input", name = "DebuffFrame", desc = "DebuffFrame", width = "full", order = 25 },
		experienceBar = { type = "input", name = "ExperienceBar", desc = "MainStatusTrackingBarContainer", width = "full", order = 26 },

		bottomReload1 = { type = "description", name = "You will need to reload after confirming changes.", fontSize = "medium", order = 98 },
		bottomReload2 = { type = "execute", name = "Reload UI", func = function() ReloadUI() end, order = 99 },
	},
}

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
		chatFrame = "",
		minimap = "",
		bagsBar = "[mod:ctrl] show; hide",
		microMenuContainer = "[mod:ctrl] show; hide",
		buffFrame = "",
		debuffFrame = "",
		experienceBar = "",
	},
}

------------------------------------------
-- #endregion: locals
------------------------------------------

------------------------------------------
-- #region: lifecycle functions
------------------------------------------

function DinksUI:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("DinksUIDB", defaults, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DinksUI_options", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DinksUI_options", "DinksUI")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DinksUI_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DinksUI_Profiles", "Profiles", "DinksUI")

	-- self:RegisterChatCommand("dinksui", "HandleSlashCommand")
end

function DinksUI:OnEnable()
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
	self:Register(frames.chatFrame.desc, conditionals.chatFrame)
	self:Register(frames.minimap.desc, conditionals.minimap)
	self:Register(frames.bagsBar.desc, conditionals.bagsBar)
	self:Register(frames.microMenuContainer.desc, conditionals.microMenuContainer)
	self:Register(frames.buffFrame.desc, conditionals.buffFrame)
	self:Register(frames.debuffFrame.desc, conditionals.debuffFrame)
	self:Register(frames.experienceBar.desc, conditionals.experienceBar)
end

function DinksUI:OnDisable()
	self:Print("Addon Disabled")
end

------------------------------------------
-- #endregion: lifecycle functions
------------------------------------------

------------------------------------------
-- #region: local functions
------------------------------------------

function DinksUI:GetValue(info)
	return self.db.profile[info[#info]]
end

function DinksUI:SetValue(info, value)
	self.db.profile[info[#info]] = value
end

function DinksUI:HandleSlashCommand(command)
	if not command or command:trim() == "" then
		-- https://github.com/Stanzilla/WoWUIBugs/issues/89
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	else
		self:Print("Command not found '" .. command .. "'")
	end
end

function DinksUI:Register(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		RegisterAttributeDriver(_G[frameKey], "state-visibility", conditionalMacro)
	end
end

function DinksUI:RegisterStance(frameKey, conditionalMacro)
	if GetShapeshiftFormInfo(1) then
		self:Register(frameKey, conditionalMacro)
	end
end

function DinksUI:RegisterObjective(frameKey, conditionalMacro)
	self:Register(frameKey, conditionalMacro)

	local originalShow = _G[frameKey].Show
	_G[frameKey].Show = function(self, ...)
		local stack = debugstack(2, 1, 0)
		local caller = stack:match("([^:]+): in function")
		if caller == "100" then
			return originalShow(self, ...)
		end
	end
end

------------------------------------------
-- #endregion: local functions
------------------------------------------
