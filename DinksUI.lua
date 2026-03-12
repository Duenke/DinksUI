-- AceAddon makes creating an addon easy. All addons are frames, btw.
DinksUI = LibStub("AceAddon-3.0"):NewAddon("DinksUI", "AceConsole-3.0", "AceEvent-3.0")

------------------------------------------
-- #region: locals
------------------------------------------

local DEBUG = false
local DEBUG_FRAME = nil
local DEBUG_COUNTER = 0

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
local duiToggledOff = false
local FrameWrapperTable = {}

-- An AceConfig schema options object.
local options = {
    name = "DinksUI",
    handler = DinksUI,
    type = "group",
    childGroups = "tab",
    get = "GetValue",
    set = "SetValue",
    args = {
        help = {
            type = "group",
            name = "Help",
            order = 0,
            args = {
                title = {
                    type = "header",
                    name = "DinksUI Conditional Visibility Guide",
                    order = 0
                },
                guide = {
                    type = "description",
                    order = 1,
                    fontSize = "medium",
                    name =
                        "|cffffd200How It Works|r\n" ..
                        "Enter a |cff00ccffmacro conditional|r to control when a frame is hidden or shown.\n" ..
                        "The |cff00ccffDefault|r profile comes blank.\n" ..
                        "Just work with the |cff00ccffDefault|r profile, create |cff00ccffmultiple profiles|r, or try out the |cff00ccffDinksDefaults|r profile.\n\n" ..

                        "|cffffd200Syntax|r\n" ..
                        "[condition] show; hide\n" ..
                        "[condition] hide; show\n\n" ..

                        "|cffffd200Examples|r\n" ..
                        "|cff00ff00Action Bar 1|r\n" ..
                        "  [flying, nocombat] hide; show\n\n" ..

                        "|cff00ff00Action Bar 2|r\n" ..
                        "  [mod:ctrl][mod:alt][combat] show; hide\n\n" ..

                        "|cff00ff00Raid Frame|r\n" ..
                        "  [mod:ctrl][nocombat] show; hide\n\n" ..

                        "|cff00ff00Damage Meters|r\n" ..
                        "  [group, nomod][group, nomod:ctrl, combat] show; hide\n\n" ..

                        "|cffffd200Tips|r\n" ..
                        "• Use hold |cff00ccffCTRL|r or |cff00ccffALT|r to temporarily show UI elements.\n" ..
                        "• Use |cff00ccffcombat|r or |cff00ccffnocombat|r conditions for combat visibility.\n" ..
                        "• Multiple conditions can be chained together.\n" ..
                        "• Multiple frames can be overlapping if they show at different times.\n" ..
                        "• Create macros with the below slash commands.\n" ..
                        "• Now integrated with Plumber's addon compartment!\n\n" ..

                        "|cffffd200Commands|r\n" ..
                        "|cff00ccff/dinksui|r or |cff00ccff/dui|r\n" ..
                        "|cff00ccff/dinksui show|r or |cff00ccff/dui show|r\n" ..
                        "|cff00ccff/dinksui hide|r or |cff00ccff/dui hide|r\n" ..
                        "|cff00ccff/dinksui toggle|r or |cff00ccff/dui toggle|r\n\n" ..

                        "For help with macro conditionals you can reference:\n" ..
                        "|cff00ccffhttps://wowpedia.fandom.com/wiki/Macro_conditionals|r"
                }
            }
        },
        actionbars = {
            type = "group",
            name = "Action Bars",
            order = 1,
            args = {
                actionBar1 =   { type = "input", name = "Action Bar 1",   desc = "MainActionBar",       width = "full" },
                actionBar2 =   { type = "input", name = "Action Bar 2",   desc = "MultiBarBottomLeft",  width = "full" },
                actionBar3 =   { type = "input", name = "Action Bar 3",   desc = "MultiBarBottomRight", width = "full" },
                actionBar4 =   { type = "input", name = "Action Bar 4",   desc = "MultiBarRight",       width = "full" },
                actionBar5 =   { type = "input", name = "Action Bar 5",   desc = "MultiBarLeft",        width = "full" },
                actionBar6 =   { type = "input", name = "Action Bar 6",   desc = "MultiBar5",           width = "full" },
                actionBar7 =   { type = "input", name = "Action Bar 7",   desc = "MultiBar6",           width = "full" },
                actionBar8 =   { type = "input", name = "Action Bar 8",   desc = "MultiBar7",           width = "full" },
                petActionBar = { type = "input", name = "Pet Action Bar", desc = "PetActionBar",        width = "full" },
                stanceBar =    { type = "input", name = "Stance Bar",     desc = "StanceBar",           width = "full" },
            }
        },
        unitframes = {
            type = "group",
            name = "Unit Frames",
            order = 2,
            args = {
                bossFrames =  { type = "input", name = "Boss Frames",  desc = "BossTargetFrameContainer",  width = "full" },
                focusFrame =  { type = "input", name = "Focus Frame",  desc = "FocusFrame",                width = "full" },
                partyFrame =  { type = "input", name = "Party Frame",  desc = "PartyFrame",                width = "full" },
                petFrame =    { type = "input", name = "Pet Frame",    desc = "PetFrame",                  width = "full" },
                playerFrame = { type = "input", name = "Player Frame", desc = "PlayerFrame",               width = "full" },
                raidFrame =   { type = "input", name = "Raid Frame",   desc = "CompactRaidFrameContainer", width = "full" },
                targetFrame = { type = "input", name = "Target Frame", desc = "TargetFrame",               width = "full" },
            }
        },
        interface = {
            type = "group",
            name = "Interface",
            order = 3,
            args = {
                bagsBar =          { type = "input", name = "Bags Bar",                  desc = "BagsBar",                        width = "full" },
                buffFrame =        { type = "input", name = "Buff Frame",                desc = "BuffFrame",                      width = "full" },
                chatFrame =        { type = "input", name = "Chat Frame",                desc = "ChatFrame",                      width = "full" },
                damageMeter =      { type = "input", name = "Damage Meters",             desc = "DamageMeter",                    width = "full" },
                debuffFrame =      { type = "input", name = "Debuff Frame",              desc = "DebuffFrame",                    width = "full" },
                experienceBar =    { type = "input", name = "Experience Bar",            desc = "MainStatusTrackingBarContainer", width = "full" },
                microMenu =        { type = "input", name = "Micro Menu",                desc = "MicroMenuContainer",             width = "full" },
                minimap =          { type = "input", name = "Minimap",                   desc = "MinimapCluster",                 width = "full" },
                objectiveTracker = { type = "input", name = "Objective Tracker",         desc = "ObjectiveTrackerFrame",          width = "full" },
                personResource =   { type = "input", name = "Personal Resource Display", desc = "PersonalResourceDisplayFrame",   width = "full" },
            }
        }
    }
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

		bossFrames = "",
		focusFrame = "",
		partyFrame = "",
		petFrame = "",
		playerFrame = "",
		raidFrame = "",
		targetFrame = "",

		bagsBar = "",
		buffFrame = "",
		chatFrame = "",
		damageMeter = "",
		debuffFrame = "",
		experienceBar = "",
		microMenu = "",
		minimap = "",
		objectiveTracker = "",
		personResource = "",
	}
}

local dinksDefaults = {
	profile = {
		actionBar1 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar2 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar3 = "[mod:ctrl][mod:alt][combat] show; hide",
		actionBar4 = "[mod:ctrl][mod:alt, nocombat] show; hide",
		actionBar5 = "[mod:ctrl][mod:alt, nocombat] show; hide",
		actionBar6 = "",
		actionBar7 = "",
		actionBar8 = "",
		petActionBar = "[mod:ctrl] show; hide",
		stanceBar = "[mod:ctrl][mod:alt][combat] show; hide",

		bossFrames = "[mod:ctrl] show; hide",
		focusFrame = "",
		partyFrame = "",
		petFrame = "[mod:ctrl][mod:alt][combat] show; hide",
		playerFrame = "[mod:ctrl] show; hide",
		raidFrame = "[mod:ctrl][nocombat] show; hide",
		targetFrame = "[mod:ctrl] show; hide",

		bagsBar = "[mod:ctrl] show; hide",
		buffFrame = "",
		chatFrame = "",
		damageMeter = "[group, nomod][group, nomod:ctrl, combat] show; hide",
		debuffFrame = "",
		experienceBar = "[mod:ctrl][mod:alt][combat] show; hide",
		microMenu = "[mod:ctrl] show; hide",
		minimap = "",
		objectiveTracker = "[mod:ctrl][mod:alt, nocombat] show; hide",
		personResource = "[mod:ctrl][mod:alt][combat] show; hide",
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
	elseif cmd == "toggle" then
		self:ToggleAllFrames()
	else
		self:Print("Command not found '" .. command .. "'")
	end
end

function DinksUI:ReapplyAllFrames()
	self:Debug("ReapplyAllFrames")

	self:UnregisterAllFrames()
	self:RegisterAllFrames()
end

-- Someone asked for a 1-button toggle function. To be used in a macro.
function DinksUI:ToggleAllFrames()
	self:Debug("ToggleAllFrames")

	if duiToggledOff then
		self:RegisterAllFrames()
	else
		self:UnregisterAllFrames()
	end
end

-- This is the main function. This is where new frames can be added.
function DinksUI:RegisterAllFrames()
	self:Debug("RegisterAllFrames")

	duiToggledOff = false

	local conditionals = self.db.profile

	local actionbars = options.args.actionbars.args
	local unitframes = options.args.unitframes.args
	local interface = options.args.interface.args

	self:Register(actionbars.actionBar1.desc, conditionals.actionBar1)
	self:Register(actionbars.actionBar2.desc, conditionals.actionBar2)
	self:Register(actionbars.actionBar3.desc, conditionals.actionBar3)
	self:Register(actionbars.actionBar4.desc, conditionals.actionBar4)
	self:Register(actionbars.actionBar5.desc, conditionals.actionBar5)
	self:Register(actionbars.actionBar6.desc, conditionals.actionBar6)
	self:Register(actionbars.actionBar7.desc, conditionals.actionBar7)
	self:Register(actionbars.actionBar8.desc, conditionals.actionBar8)
	self:Register(actionbars.petActionBar.desc, conditionals.petActionBar)
	self:Register(actionbars.stanceBar.desc, conditionals.stanceBar)
	self:Register(unitframes.playerFrame.desc, conditionals.playerFrame)
	self:Register(unitframes.targetFrame.desc, conditionals.targetFrame)
	self:Register(unitframes.focusFrame.desc, conditionals.focusFrame)
	self:Register(unitframes.petFrame.desc, conditionals.petFrame)
	self:Register(unitframes.raidFrame.desc, conditionals.raidFrame)
	self:Register(unitframes.partyFrame.desc, conditionals.partyFrame)
	self:Register(unitframes.bossFrames.desc, conditionals.bossFrames)
	self:Register(interface.objectiveTracker.desc, conditionals.objectiveTracker)
	self:RegisterChat(interface.chatFrame.desc, conditionals.chatFrame)
	self:Register(interface.minimap.desc, conditionals.minimap)
	self:Register(interface.bagsBar.desc, conditionals.bagsBar)
	self:Register(interface.microMenu.desc, conditionals.microMenu)
	self:Register(interface.buffFrame.desc, conditionals.buffFrame)
	self:Register(interface.debuffFrame.desc, conditionals.debuffFrame)
	self:Register(interface.experienceBar.desc, conditionals.experienceBar)
	self:Register(interface.personResource.desc, conditionals.personResource)
	self:Register(interface.damageMeter.desc, conditionals.damageMeter)
end

-- Remember to also add new frames here as well.
function DinksUI:UnregisterAllFrames()
	self:Debug("UnregisterAllFrames")

	duiToggledOff = true

	local actionbars = options.args.actionbars.args
	local unitframes = options.args.unitframes.args
	local interface = options.args.interface.args

	self:Unregister(actionbars.actionBar1.desc)
	self:Unregister(actionbars.actionBar2.desc)
	self:Unregister(actionbars.actionBar3.desc)
	self:Unregister(actionbars.actionBar4.desc)
	self:Unregister(actionbars.actionBar5.desc)
	self:Unregister(actionbars.actionBar6.desc)
	self:Unregister(actionbars.actionBar7.desc)
	self:Unregister(actionbars.actionBar8.desc)
	self:Unregister(actionbars.petActionBar.desc)
	self:Unregister(actionbars.stanceBar.desc)
	self:Unregister(unitframes.playerFrame.desc)
	self:Unregister(unitframes.targetFrame.desc)
	self:Unregister(unitframes.focusFrame.desc)
	self:Unregister(unitframes.petFrame.desc)
	self:Unregister(unitframes.raidFrame.desc)
	self:Unregister(unitframes.partyFrame.desc)
	self:Unregister(unitframes.bossFrames.desc)
	self:Unregister(interface.objectiveTracker.desc)
	self:UnregisterChat(interface.chatFrame.desc)
	self:Unregister(interface.minimap.desc)
	self:Unregister(interface.bagsBar.desc)
	self:Unregister(interface.microMenu.desc)
	self:Unregister(interface.buffFrame.desc)
	self:Unregister(interface.debuffFrame.desc)
	self:Unregister(interface.experienceBar.desc)
	self:Unregister(interface.personResource.desc)
	self:Unregister(interface.damageMeter.desc)
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
		_G[frameKey]:SetParent(oldParent)
	end
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

	local parentName = "DinksUI_" .. frameKey
	local newParent = CreateFrame("Frame", parentName, UIParent, "SecureHandlerStateTemplate")
	newParent:SetFrameStrata("MEDIUM")

	return newParent
end

function DinksUI:Debug(message, frameKey)
	if DEBUG then
		if DEBUG_FRAME == frameKey or DEBUG_FRAME == nil or frameKey == nil then
			DEBUG_COUNTER = DEBUG_COUNTER + 1
			self:Print(_G["ChatFrame1"], DEBUG_COUNTER .. ": " .. message .. "\n ")
		end
	end
end

------------------------------------------
-- #endregion: local functions
------------------------------------------

------------------------------------------
-- #region: escape hatches
------------------------------------------

-- Frustratingly, the game will re-parent certain frames for various reasons:
-- 1) The player has leveled up
-- 2) The player is level scaled for TimeWalking instances
-- 3) Other game state changes
-- For these reasons, we need to watch for re-parenting and re-register frames as needed.
function DinksUI:HookSetParent(frame, conditionalKey)
	-- Prevent multiple hooks on the same frame
	if frame.SetParentHooked then return end

	local frameKey = frame:GetName()

	hooksecurefunc(frame, "SetParent", function()
		if duiToggledOff then return end

		-- Check if the frame's parent has been changed by the game
		local wrapper = FrameWrapperTable[frameKey]
		local currentParent = _G[frameKey]:GetParent()

		if wrapper then
    		local expectedParent = wrapper['newParent']

    		if expectedParent ~= currentParent then
    			self:Debug("SetParent hook triggered for: " .. frameKey, frameKey)
    			self:Debug("Parent mismatch detected, re-registering: " .. frameKey, frameKey)
    			self:Register(frameKey, self.db.profile[conditionalKey])
    		end
        else
            self:Debug("SetParent hook FAILED for: " .. frameKey, frameKey)
		end
	end)

	self:Debug("Permanent SetParent hook installed for: " .. frameKey, frameKey)
	frame.SetParentHooked = true
end

------------------------------------------
-- #endregion: escape hatches
------------------------------------------

------------------------------------------
-- #region: external integrations
------------------------------------------

-- The Plumber addon scans other addons' toc files to include them in it's Addon Compartment.
-- It looks for a line like `## AddonCompartmentFunc: DinksUI_AddonCompartmentOnClick` in DinksUI.toc.
function DinksUI_AddonCompartmentOnClick()
    DinksUI:ToggleAllFrames()
end

------------------------------------------
-- #endregion: external integrations
------------------------------------------
