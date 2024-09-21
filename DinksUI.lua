-- AceAddon makes creating an addon easy. All addons are frames, btw.
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
local UIParent = UIParent

-- Some frames don't handle it well when we trigger their `Hide` and `Show` methods.
-- So we will just wrap them in new frames that will hide/show just fine.
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
		slashCmdTxt = { type = "description", name = "You can use '/dinksui show' and /dinksui hide' to temporarily toggle visibility. You can even make a macro!", fontSize = "medium", order = 3 },
		blank = { type = "description", name = " ", fontSize = "medium", order = 4 },
		reloadTxt = { type = "description", name = "You will need to activate after confirming changes.", fontSize = "medium", order = 5 },
		reloadBtn = {
			type = "execute",
			name = "Activate",
			order = 6,
			func = function()
				DinksUI:UnregisterAllFrames()
				DinksUI:RegisterAllFrames()
			end
		},

		actionBar1 = { type = "input", name = "Action Bar 1", desc = "MainMenuBar", width = "full", order = 7 },
		actionBar2 = { type = "input", name = "Action Bar 2", desc = "MultiBarBottomLeft", width = "full", order = 8 },
		actionBar3 = { type = "input", name = "Action Bar 3", desc = "MultiBarBottomRight", width = "full", order = 9 },
		actionBar4 = { type = "input", name = "Action Bar 4", desc = "MultiBarRight", width = "full", order = 10 },
		actionBar5 = { type = "input", name = "Action Bar 5", desc = "MultiBarLeft", width = "full", order = 11 },
		actionBar6 = { type = "input", name = "Action Bar 6", desc = "MultiBar5", width = "full", order = 12 },
		actionBar7 = { type = "input", name = "Action Bar 7", desc = "MultiBar6", width = "full", order = 13 },
		actionBar8 = { type = "input", name = "Action Bar 8", desc = "MultiBar7", width = "full", order = 14 },
		petActionBar = { type = "input", name = "Pet Action Bar", desc = "PetActionBar", width = "full", order = 15 },
		stanceBar = { type = "input", name = "Stance Bar", desc = "StanceBar", width = "full", order = 16 },
		playerFrame = { type = "input", name = "Player Frame", desc = "PlayerFrame", width = "full", order = 17 },
		targetFrame = { type = "input", name = "Target Frame", desc = "TargetFrame", width = "full", order = 18 },
		focusFrame = { type = "input", name = "Focus Frame", desc = "FocusFrame", width = "full", order = 19 },
		petFrame = { type = "input", name = "Pet Frame", desc = "PetFrame", width = "full", order = 20 },
		raidFrame = { type = "input", name = "Raid Frame", desc = "CompactRaidFrameContainer", width = "full", order = 21 },
		partyFrame = { type = "input", name = "Party Frame", desc = "PartyFrame", width = "full", order = 22 },
		objectiveTracker = { type = "input", name = "Objective Tracker", desc = "ObjectiveTrackerFrame", width = "full", order = 23 },
		chatFrame = { type = "input", name = "Chat Frame", desc = "ChatFrame", width = "full", order = 24 },
		minimap = { type = "input", name = "Minimap", desc = "MinimapCluster", width = "full", order = 25 },
		bagsBar = { type = "input", name = "Bags Bar", desc = "BagsBar", width = "full", order = 26 },
		microMenu = { type = "input", name = "Micro Menu", desc = "MicroMenuContainer", width = "full", order = 27 },
		buffFrame = { type = "input", name = "Buff Frame", desc = "BuffFrame", width = "full", order = 28 },
		debuffFrame = { type = "input", name = "Debuff Frame", desc = "DebuffFrame", width = "full", order = 29 },
		experienceBar = { type = "input", name = "Experience Bar", desc = "MainStatusTrackingBarContainer", width = "full", order = 30 },
		encounterBar = { type = "input", name = "EncounterBar / Sky Riding Bar", desc = "EncounterBar", width = "full", order = 31 },

		bottomBlank = { type = "description", name = " ", fontSize = "medium", order = 97 },
		bottomReloadTxt = { type = "description", name = "You will need to activate after confirming changes.", fontSize = "medium", order = 98 },
		bottomReloadBtn = {
			type = "execute",
			name = "Activate",
			order = 99,
			func = function()
				DinksUI:UnregisterAllFrames()
				DinksUI:RegisterAllFrames()
			end
		},
	},
}

-- Default options match a subset of the `options.args` above.
local defaults = {
	profile = {
		actionBar1 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar2 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar3 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar4 = "[mod:ctrl] show; hide",
		actionBar5 = "[mod:ctrl] show; hide",
		actionBar6 = "",
		actionBar7 = "",
		actionBar8 = "",
		petActionBar = "[mod:ctrl,@pet,exists] show; hide",
		stanceBar = "[mod:ctrl][mod:alt][combat] show; hide",
		playerFrame = "[mod:ctrl] show; hide",
		targetFrame = "[mod:ctrl] show; hide",
		focusFrame = "",
		petFrame = "[mod:alt, @pet][mod:ctrl, @pet][combat] show; hide",
		raidFrame = "[mod:ctrl][nocombat] show; hide",
		partyFrame = "",
		objectiveTracker = "[mod:ctrl][mod:alt, nocombat] show; hide",
		chatFrame = "",
		minimap = "",
		bagsBar = "[mod:ctrl] show; hide",
		microMenu = "[mod:ctrl] show; hide",
		buffFrame = "",
		debuffFrame = "",
		experienceBar = "[mod:ctrl][mod:alt][combat] show; hide",
		encounterBar = "[mod:ctrl][mod:alt][combat] show; hide",
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
	FrameWrapperTable = nil
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
	self:Register(frames.stanceBar.desc, conditionals.stanceBar)
	self:Register(frames.playerFrame.desc, conditionals.playerFrame)
	self:Register(frames.targetFrame.desc, conditionals.targetFrame)
	self:Register(frames.focusFrame.desc, conditionals.focusFrame)
	self:Register(frames.petFrame.desc, conditionals.petFrame)
	self:Register(frames.raidFrame.desc, conditionals.raidFrame)
	self:Register(frames.partyFrame.desc, conditionals.partyFrame)
	self:Register(frames.objectiveTracker.desc, conditionals.objectiveTracker)
	self:RegisterChat(frames.chatFrame.desc, conditionals.chatFrame)
	self:Register(frames.minimap.desc, conditionals.minimap)
	self:Register(frames.bagsBar.desc, conditionals.bagsBar)
	self:Register(frames.microMenu.desc, conditionals.microMenu)
	self:Register(frames.buffFrame.desc, conditionals.buffFrame)
	self:Register(frames.debuffFrame.desc, conditionals.debuffFrame)
	self:Register(frames.experienceBar.desc, conditionals.experienceBar)
	self:Register(frames.encounterBar.desc, conditionals.encounterBar)
end

-- Remember to also add new frames here as well.
function DinksUI:UnregisterAllFrames()
	local frames = options.args
	self:Unregister(frames.actionBar1.desc)
	self:Unregister(frames.actionBar2.desc)
	self:Unregister(frames.actionBar3.desc)
	self:Unregister(frames.actionBar4.desc)
	self:Unregister(frames.actionBar5.desc)
	self:Unregister(frames.actionBar6.desc)
	self:Unregister(frames.actionBar7.desc)
	self:Unregister(frames.actionBar8.desc)
	self:Unregister(frames.petActionBar.desc)
	self:Unregister(frames.stanceBar.desc)
	self:Unregister(frames.playerFrame.desc)
	self:Unregister(frames.targetFrame.desc)
	self:Unregister(frames.focusFrame.desc)
	self:Unregister(frames.petFrame.desc)
	self:Unregister(frames.raidFrame.desc)
	self:Unregister(frames.partyFrame.desc)
	self:Unregister(frames.objectiveTracker.desc)
	self:UnregisterChat(frames.chatFrame.desc)
	self:Unregister(frames.minimap.desc)
	self:Unregister(frames.bagsBar.desc)
	self:Unregister(frames.microMenu.desc)
	self:Unregister(frames.buffFrame.desc)
	self:Unregister(frames.debuffFrame.desc)
	self:Unregister(frames.experienceBar.desc)
	self:Unregister(frames.encounterBar.desc)
end

function DinksUI:Register(frameKey, conditionalMacro)
	if string.len(string.trim(conditionalMacro)) > 1 then
		-- Save the original parent for `DinksUI.Unregister`.
		-- If the frame was registered already and never unregistered, take the saved original parent.
		local oldParent = FrameWrapperTable[frameKey] or _G[frameKey]:GetParent()
		local newParent = self:CreateNewParentFrame()

		_G[frameKey]:SetParent(newParent)
		FrameWrapperTable[frameKey] = oldParent
		RegisterAttributeDriver(newParent, "state-visibility", conditionalMacro)
	end
end

-- Because chat can have any number of windows, we need a more dynamic method.
function DinksUI:RegisterChat(frameKey, conditionalMacro)
	for i = 1, NUM_CHAT_WINDOWS do
		self:Register(frameKey .. i, conditionalMacro)
	end

	-- Chat kind of also includes those buttons to the left.
	self:Register("GeneralDockManager", conditionalMacro)
	self:Register("QuickJoinToastButton", conditionalMacro)
end

function DinksUI:Unregister(frameKey)
	-- If the frame was registered, then restore the original parent.
	if FrameWrapperTable[frameKey] then
		_G[frameKey]:SetParent(FrameWrapperTable[frameKey])
		FrameWrapperTable[frameKey] = nil
	end
end

function DinksUI:UnregisterChat(frameKey, conditionalMacro)
	for i = 1, NUM_CHAT_WINDOWS do
		self:Unregister(frameKey .. i)
	end

	self:Unregister("GeneralDockManager")
	self:Unregister("QuickJoinToastButton")
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

function DinksUI:CreateNewParentFrame()
	local newParent = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	-- Set up fade-in and fade-out animations
	local fadeIn = newParent:CreateAnimationGroup()
	local fadeInAlpha = fadeIn:CreateAnimation("Alpha")
	fadeInAlpha:SetFromAlpha(0)
	fadeInAlpha:SetToAlpha(1)
	fadeInAlpha:SetDuration(0.125)
	fadeInAlpha:SetSmoothing("IN")

	-- Fade-out animations don't seem to work with this method of hiding frames...
	local fadeOut = newParent:CreateAnimationGroup()
	local fadeOutAlpha = fadeOut:CreateAnimation("Alpha")
	fadeOutAlpha:SetFromAlpha(1)
	fadeOutAlpha:SetToAlpha(0)
	fadeOutAlpha:SetDuration(0.5)
	fadeOutAlpha:SetSmoothing("OUT")

	newParent:SetScript("OnShow", function(self)
		fadeOut:Stop()
		fadeIn:Play()
	end)

	newParent:SetScript("OnHide", function(self)
		fadeIn:Stop()
		fadeOut:Play()
	end)

	return newParent
end

------------------------------------------
-- #endregion: local functions
------------------------------------------
