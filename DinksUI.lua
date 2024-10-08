-- AceAddon makes creating an addon easy. All addons are frames, btw.
DinksUI = LibStub("AceAddon-3.0"):NewAddon("DinksUI", "AceConsole-3.0", "AceEvent-3.0")

------------------------------------------
-- #region: locals
------------------------------------------

local DEBUG = false
local DEBUG_FRAME = "ObjectiveTrackerFrame"

-- WoW's globals that are exposed for addons.
local _G = _G
local CreateFrame = CreateFrame
local EventRegistry = EventRegistry
local hooksecurefunc = hooksecurefunc
local OpenToCategory = Settings.OpenToCategory
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local RegisterAttributeDriver = RegisterAttributeDriver
local UIParent = UIParent
local UnregisterAttributeDriver = UnregisterAttributeDriver

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
		info = { type = "description", name = "For each frame below that you want to hide, supply a macro conditional of your chosing.", fontSize = "medium", order = 0 },
		ex1 = { type = "description", name = "Ex 1: Action Bar 1: [flying, nocombat] hide; show", fontSize = "medium", order = 1 },
		ex2 = { type = "description", name = "Ex 2: Action Bar2:  [mod:ctrl][mod:alt][combat] show; hide", fontSize = "medium", order = 2 },
		ex3 = { type = "description", name = "Ex 3: Raid Frame:   [mod:ctrl][nocombat] show; hide", fontSize = "medium", order = 3 },
		dinksdefaults = { type = "description", name = "You can save as many profiles as you want, or just use DinksDefaults!", fontSize = "medium", order = 4 },
		slashCmdTxt = { type = "description", name = "Type '/dinksui help' or '/dui h' in the chat window for more.", fontSize = "medium", order = 5 },
		blank = { type = "description", name = " ", fontSize = "medium", order = 6 },

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
		skyRidingBar = { type = "input", name = "Sky Riding Bar", desc = "UIWidgetPowerBarContainerFrame", width = "full", order = 31 },
	},
}

-- Default options match a subset of the `options.args` above.
local blanks = {
	profile = {
		actionBar1 = "",
		actionBar2 = "",
		actionBar3 = "",
		actionBar4 = "",
		actionBar5 = "",
		actionBar6 = "",
		actionBar7 = "",
		actionBar8 = "",
		petActionBar = "",
		stanceBar = "",
		playerFrame = "",
		targetFrame = "",
		focusFrame = "",
		petFrame = "",
		raidFrame = "",
		partyFrame = "",
		objectiveTracker = "",
		chatFrame = "",
		minimap = "",
		bagsBar = "",
		microMenu = "",
		buffFrame = "",
		debuffFrame = "",
		experienceBar = "",
		skyRidingBar = "",
	}
}

local dinksDefaults = {
	profile = {
		actionBar1 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar2 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar3 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar4 = "[mod:ctrl] show; hide",
		actionBar5 = "[mod:ctrl] show; hide",
		actionBar6 = "",
		actionBar7 = "",
		actionBar8 = "",
		petActionBar = "[mod:ctrl, @pet, exists] show; hide",
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
		skyRidingBar = "[mod:ctrl][mod:alt][combat] show; hide",
	}
}

------------------------------------------
-- #endregion: locals
------------------------------------------

------------------------------------------
-- #region: AceAddon lifecycle functions
------------------------------------------

function DinksUI:OnInitialize()
	self:Debug("OnInitialize")

	self.db = LibStub("AceDB-3.0"):New("DinksUIDB", blanks, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DinksUI_options", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DinksUI_options", "DinksUI")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DinksUI_Profiles", profiles)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DinksUI_Profiles", "Profiles", "DinksUI")

	self.db.RegisterCallback(self, "OnProfileChanged", "ReapplyAllFrames")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReapplyAllFrames")
	self.db.RegisterCallback(self, "OnProfileReset", "ReapplyAllFrames")
end

function DinksUI:OnEnable()
	self:Debug("OnEnable")

	self:SetupDinksDefaults()
	self:RegisterChatCommand("dui", "HandleSlashCommand")
	self:RegisterChatCommand("dinksui", "HandleSlashCommand")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "HandleEnteringWorld")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "HandleLeavingWorld")
	self:HookSetParent(_G["ObjectiveTrackerFrame"], "objectiveTracker")
	EventRegistry:RegisterCallback("EditMode.Enter", self.UnregisterAllFrames, self)
	EventRegistry:RegisterCallback("EditMode.Exit", self.RegisterAllFrames, self)
end

function DinksUI:OnDisable()
	self:Debug("OnDisable")

	self:UnregisterChatCommand("dui")
	self:UnregisterChatCommand("dinksui")
	self:HandleLeavingWorld()
	EventRegistry:UnregisterCallback("EditMode.Enter", self)
	EventRegistry:UnregisterCallback("EditMode.Exit", self)
end

------------------------------------------
-- #endregion: AceAddon lifecycle functions
------------------------------------------

------------------------------------------
-- #region: local functions
------------------------------------------

function DinksUI:SetupDinksDefaults()
	local selectedProfile = self.db:GetCurrentProfile()

	-- Set up the "DinksDefaults" profile.
	self:Debug("SetupDinksDefaults: " .. "dinksdefaults")
	self.db:SetProfile("DinksDefaults")

	for key, value in pairs(dinksDefaults.profile) do
		self.db.profile[key] = value
	end

	-- Now set back to the user selected profile.
	self:Debug("SetupDinksDefaults: " .. selectedProfile)
	self.db:SetProfile(selectedProfile)
end

-- So, `PLAYER_ENTERING_WORLD` basically means "finished any loading screen".
-- Because the UI is rebuilt every loading screen, we need to start all the work here.
-- Yes, at this time, `HandleEnteringWorld` only calls `ReapplyAllFrames`, but
-- at some point it might do more...and I wanted to document all this here.
function DinksUI:HandleEnteringWorld()
	self:Debug("HandleEnteringWorld")

	self:ReapplyAllFrames()
end

function DinksUI:HandleLeavingWorld()
	self:Debug("HandleLeavingWorld")

	self:UnregisterAllFrames()
	FrameWrapperTable = {}
end

function DinksUI:HandleSlashCommand(command)
	self:Debug("HandleSlashCommand: " .. command)

	local cmd = command:trim():lower()
	if not cmd or cmd == "" then
		OpenToCategory(self.optionsFrame.name)
	elseif cmd == "show" then
		self:UnregisterAllFrames()
	elseif cmd == "hide" then
		self:RegisterAllFrames()
	elseif cmd == "h" or cmd == "help" then
		self:Print("\n" ..
			"The Default profile is all blanks and can be reset on demand. \n" ..
			"The DinksDefaults profile is reset on each reload. \n" ..
			"Type '/dinksui show' or '/dui show' to temporarily show all frames. \n" ..
			"Type '/dinksui hide' or '/dui hide' to again hide all frames. \n" ..
			"Tip: Make some macros! =) \n" ..
			"For help with macro conditionals you can reference: \n" ..
			"  https://wowpedia.fandom.com/wiki/Macro_conditionals \n" ..
			"\n")
	else
		self:Print("Command not found '" .. command .. "'")
	end
end

function DinksUI:ReapplyAllFrames()
	self:Debug("ReapplyAllFrames")

	self:UnregisterAllFrames()
	self:RegisterAllFrames()
end

-- This is the main function. This is where new frames can be added.
function DinksUI:RegisterAllFrames()
	self:Debug("RegisterAllFrames")

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
	self:RegisterSkyRiding(frames.skyRidingBar.desc, conditionals.skyRidingBar)
end

-- Remember to also add new frames here as well.
function DinksUI:UnregisterAllFrames()
	self:Debug("UnregisterAllFrames")

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
	self:UnregisterSkyRiding(frames.skyRidingBar.desc)
end

function DinksUI:Register(frameKey, conditionalMacro)
	self:Debug("Register: " .. frameKey .. " = " .. conditionalMacro, frameKey)

	if string.len(string.trim(conditionalMacro)) > 1 then
		-- If the frame was registered already and never unregistered, take the saved data.
		FrameWrapperTable[frameKey] = FrameWrapperTable[frameKey] or {}
		local oldParent = FrameWrapperTable[frameKey]['oldParent'] or _G[frameKey]:GetParent()
		local newParent = FrameWrapperTable[frameKey]['newParent'] or self:CreateNewParentFrame(frameKey)

		-- Save the original parent for `DinksUI.Unregister` and the new parent for the escape hatches.
		FrameWrapperTable[frameKey]['oldParent'] = oldParent
		FrameWrapperTable[frameKey]['newParent'] = newParent

		_G[frameKey]:SetParent(newParent)
		RegisterAttributeDriver(newParent, "state-visibility", conditionalMacro)
	end
end

-- The SkyRidingBar is inside the Encoutner frame, and does not do well if we wrap it in a new parent.
-- The downside of wrapping the whole Encounter frame is that it also hides the achievement toast!
function DinksUI:RegisterSkyRiding(frameKey, conditionalMacro)
	self:Debug("Register: SkyRiding", frameKey)

	if string.len(string.trim(conditionalMacro)) > 1 then
		RegisterAttributeDriver(_G[frameKey], "state-visibility", conditionalMacro)
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
	self:Debug("Unregister: " .. frameKey, frameKey)

	if FrameWrapperTable[frameKey] then
		local oldParent = FrameWrapperTable[frameKey]['oldParent']
		FrameWrapperTable[frameKey] = nil
		_G[frameKey]:SetParent(oldParent)
	end
end

function DinksUI:UnregisterSkyRiding(frameKey)
	self:Debug("Unregister: SkyRiding", frameKey)

	UnregisterAttributeDriver(_G[frameKey], "state-visibility")
	_G[frameKey]:Show()
end

function DinksUI:UnregisterChat(frameKey)
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
	self:ReapplyAllFrames()
end

function DinksUI:CreateNewParentFrame(frameKey)
	self:Debug("CreateNewParentFrame: " .. frameKey, frameKey)

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

function DinksUI:Debug(message, frameKey)
	if DEBUG then
		if DEBUG_FRAME == frameKey or DEBUG_FRAME == nil or frameKey == nil then
			self:Print(_G["ChatFrame6"], message .. "\n ")
		end
	end
end

------------------------------------------
-- #endregion: local functions
------------------------------------------

------------------------------------------
-- #region: escape hatches
------------------------------------------

-- Frustratingly, the game will re-parent the `ObjectiveTrackerFrame` for a few reasons.
-- 1) The player has leveled up. 2) The player is level scaled for TimeWalking instances. 3) ???
-- For these reasons, we need to watch for re-parenting on this frame and re-register it as needed.
function DinksUI:HookSetParent(frame, conditionalKey)
	if not frame.SetParentHooked then
		hooksecurefunc(frame, "SetParent", function()
			local frameKey = frame:GetName()

			self:Debug("hooksecurefunc: " .. frameKey, frameKey)
			if FrameWrapperTable[frameKey] then
				self:Debug("???checking parent: " .. frameKey, frameKey)
				if FrameWrapperTable[frameKey]['newParent'] ~= _G[frameKey]:GetParent() then
					self:Debug("!!!resetting parent: " .. frameKey, frameKey)
					self:Register(frameKey, self.db.profile[conditionalKey])
				end
			end
		end)
		frame.SetParentHooked = true
	end
end

------------------------------------------
-- #endregion: escape hatches
------------------------------------------
