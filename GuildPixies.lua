-----------------------------------------------------------------------------------------------
-- Client Lua Script for GuildPixies
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

-----------------------------------------------------------------------------------------------
-- GuildPixies Module Definition
-----------------------------------------------------------------------------------------------
local GuildPixies = {}

-----------------------------------------------------------------------------------------------
-- Upvalues
-----------------------------------------------------------------------------------------------
local setmetatable, pairs, ipairs = setmetatable, pairs, ipairs

-- Wildstar APIs
local Apollo, GuildLib = Apollo, GuildLib

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local ktAmpInfo = {
    [394] = { BGColor = "ffcc1919", strSprite = "CRB_Raid:sprRaid_Icon_Class_Warrior" }, -- Warrior
    [395] = { BGColor = "ffa5a500", strSprite = "CRB_Raid:sprRaid_Icon_Class_Engineer" }, -- Engineer
    [396] = { BGColor = "ff339919", strSprite = "CRB_Raid:sprRaid_Icon_Class_Medic" }, -- Medic
    [397] = { BGColor = "ff7f19cc", strSprite = "CRB_Raid:sprRaid_Icon_Class_Stalker" }, -- Stalker
    [398] = { BGColor = "ff197fb2", strSprite = "CRB_Raid:sprRaid_Icon_Class_Esper" }, -- Esper
    [399] = { BGColor = "ffe75f00", strSprite = "CRB_Raid:sprRaid_Icon_Class_Spellslinger" }, -- Spellslinger
}

local ktQualitySizeMap = {
    [3] = { tIcon = {  -8,  -8,  8,  8 } }, -- Slightly
    [4] = { tIcon = { -12, -12, 12, 12 } }, -- Greatly
    [5] = { tIcon = { -16, -16, 16, 16 } }, -- Attract
}

local ktTradeskillAdditives = {
    [320] = { strText = "A", strSprite = "IconSprites:Icon_Achievement_UI_Tradeskills_Architect"},
    [321] = { strText = "T", strSprite = "IconSprites:Icon_Achievement_UI_Tradeskills_Technologist"},
}

local ktTradeskillTierMap = {
    [15] = "ItemQuality_Good",      -- Apprentice
    [25] = "ItemQuality_Excellent", -- Journeyman
    [35] = "ItemQuality_Superb",    -- Artisan
    [45] = "ItemQuality_Legendary", -- Expert
}

local tUsePixie = {
    bLine = false,
    loc = {
        fPoints = { 1, 1, 1, 1 },
        nOffsets = { -6, -6, 6, 6 },
    },
    strSprite = "WhiteFill",
    fRotation = 45,
}

local ktBaseCatalystOffsets = { -2, -2, 2, 2 }
local tCatalystPixie =  {
    loc = {
        fPoints = { 0, 1, 0, 1 },
        nOffsets = { -2, -2, 2, 2 },
    },
    strSprite = "WhiteFill",
    fRotation = 45,
}

local tCatalystTypePixie = {
    loc = {
        fPoints = { 0.5, 0.5, 0.5, 0.5 },
        nOffsets = { -10, -10, 10, 10 },
    },
    crText = "White",
    strFont = "CRB_Interface9_BO",
    flagsText = {
        DT_CENTER = true,
        DT_VCENTER = true,
    },
}

local tClassPixie = {
    loc = {
        fPoints = { 0, 0, 1, 1 },
        nOffsets = { 0, 0, 0, 0 },
    },
}

local aGuildBank

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function GuildPixies:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function GuildPixies:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = {
        "GuildBank",
    }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- GuildPixies OnLoad
-----------------------------------------------------------------------------------------------
function GuildPixies:OnLoad()
    aGuildBank = Apollo.GetAddon("GuildBank")
    Apollo.RegisterEventHandler("GuildBankTab", "OnGuildBankTab", self)
    Apollo.RegisterEventHandler("GuildBankItem", "OnGuildBankItem", self)
end

-----------------------------------------------------------------------------------------------
-- GuildPixies Functions
-----------------------------------------------------------------------------------------------
local function SummonPixies(itemDrawing, nTab, nInventorySlot)
    if not aGuildBank.tWndRefs.tBankItemSlots or not aGuildBank.tWndRefs.tBankItemSlots[nInventorySlot] then
        return
    end

    local wndBankIcon = aGuildBank.tWndRefs.tBankItemSlots[nInventorySlot]:FindChild("BankItemIcon")

    local itemType = itemDrawing:GetItemType()
    local tItemDI = itemDrawing:GetDetailedInfo().tPrimary
    -- Something we can use/not use?
    if (tItemDI.arSpells and tItemDI.arClassRequirement and tItemDI.arClassRequirement.bRequirementMet)
        or (tItemDI.arTradeskillReqs and tItemDI.arTradeskillReqs[1].bCanLearn) then
        local strPixieColor = "Green"
        if (tItemDI.arSpells and tItemDI.arSpells[1].strFailure) or
            (tItemDI.arTradeskillReqs and not (tItemDI.tLevelRequirement.bRequirementMet
                and not tItemDI.arTradeskillReqs[1].bIsKnown)) then
            strPixieColor = "Red"
        end
        tUsePixie.cr = strPixieColor
        wndBankIcon:AddPixie(tUsePixie)
    end
    if ktTradeskillAdditives[itemType] then
        local nQuality = itemDrawing:GetItemQuality()
        tCatalystPixie.loc.nOffsets = ktQualitySizeMap[nQuality].tIcon
        local crPowerLevel = ktTradeskillTierMap[itemDrawing:GetPowerLevel()]
        tCatalystPixie.cr = crPowerLevel or "White"
        for nIdx, nOffset in ipairs(ktBaseCatalystOffsets) do
            tCatalystPixie.loc.nOffsets[nIdx] = nOffset * (nQuality - 1)
        end
        wndBankIcon:AddPixie(tCatalystPixie)

        tCatalystTypePixie.strText = ktTradeskillAdditives[itemType].strText
        wndBankIcon:AddPixie(tCatalystTypePixie)
    end
    if ktAmpInfo[itemType] then
        wndBankIcon:SetBGColor(ktAmpInfo[itemType].BGColor)
        tClassPixie.strSprite = ktAmpInfo[itemType].strSprite
        wndBankIcon:AddPixie(tClassPixie)
    else
        wndBankIcon:SetBGColor("ffffffff")
    end
end

function GuildPixies:OnGuildBankTab(guildOwner, nTab)
    if guildOwner:GetType() ~= GuildLib.GuildType_Guild then return end
    local tItemList = {}

    for idx, tBankSlot in pairs(aGuildBank.tWndRefs.tBankItemSlots) do
        tBankSlot:FindChild("BankItemIcon"):DestroyAllPixies()
        tItemList[idx] = tBankSlot
    end
    for idx, tCurrData in ipairs(guildOwner:GetBankTab(nTab)) do -- This doesn't hit the server, but we can still use GuildBankItem for updating afterwards
        SummonPixies(tCurrData.itemInSlot, nTab, tCurrData.nIndex)
        tItemList[tCurrData.nIndex] = nil
    end
    for idx, tBankSlot in pairs(tItemList) do
        local wndBankIcon = tBankSlot:FindChild("BankItemIcon")
        wndBankIcon:SetData(nil)
        wndBankIcon:SetText("")
        wndBankIcon:SetSprite("")
        wndBankIcon:SetTooltip("")
    end
end

function GuildPixies:OnGuildBankItem(guildOwner, nTab, nInventorySlot, itemUpdated, bRemoved)
    if not aGuildBank.tWndRefs.tBankItemSlots or not aGuildBank.tWndRefs.tBankItemSlots[nInventorySlot] then
        return
    end
    local wndBankIcon = aGuildBank.tWndRefs.tBankItemSlots[nInventorySlot]:FindChild("BankItemIcon")

    wndBankIcon:DestroyAllPixies()
    if not bRemoved then
        SummonPixies(itemUpdated, nTab, nInventorySlot)
    end
end

-----------------------------------------------------------------------------------------
-- AmpClassIcons Instance
-----------------------------------------------------------------------------------------------
local GuildPixiesInst = GuildPixies:new()
GuildPixiesInst:Init()
