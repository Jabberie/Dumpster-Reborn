Dumpster = LibStub("AceAddon-3.0"):NewAddon(
    "Dumpster",
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceTimer-3.0"
)

local Dumpster = Dumpster
local ADDON_NAME = ...

-- ---------------------------------------------------------------------------
-- Version
-- ---------------------------------------------------------------------------

local function GetAddonVersion()
    local version

    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    elseif GetAddOnMetadata then
        version = GetAddOnMetadata(ADDON_NAME, "Version")
    end

    -- Unpackaged development copies still contain the CurseForge token.
    if not version or version == "" or version == "@project-version@" then
        return "Dev"
    end

    return version
end

Dumpster.VERSION = GetAddonVersion()

-- ---------------------------------------------------------------------------
-- Shared runtime state
-- ---------------------------------------------------------------------------

Dumpster.debug = false
Dumpster.superdebug = false

Dumpster.delayedSO = nil
Dumpster.delayedInOut = ""

Dumpster.tooltipError = false

-- ---------------------------------------------------------------------------
-- Client detection
-- ---------------------------------------------------------------------------

Dumpster.WOWClassic =
    _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC

Dumpster.WOWBCClassic =
    _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC

Dumpster.WOWWotLKClassic =
    _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC

Dumpster.WOWCataClassic =
    _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC

Dumpster.WOWRetail =
    _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE

-- ---------------------------------------------------------------------------
-- Expansion constants
-- ---------------------------------------------------------------------------

local function ExpansionConstant(name, fallback)
    local value = _G[name]

    if value ~= nil then
        return value
    end

    return fallback
end

-- ---------------------------------------------------------------------------
-- Parser flags
-- ---------------------------------------------------------------------------

Dumpster.multiFlags = {
    bind = {
        account = "bindBOA",
        use = "bindBOU",
        equip = "bindBOE",
        pickup = "bindBOP",

        boa = "bindBOA",
        bou = "bindBOU",
        boe = "bindBOE",
        bop = "bindBOP",

        soulbound = "soulbound",
        sb = "soulbound",

        notbound = "notbound",
        nb = "notbound",

        warbound = "Warbound",
        wb = "Warbound",
        btw = "Warbound",
    },

    quality = {
        poor = Enum.ItemQuality.Poor,
        common = Enum.ItemQuality.Common,
        uncommon = Enum.ItemQuality.Uncommon,
        rare = Enum.ItemQuality.Rare,
        epic = Enum.ItemQuality.Epic,
        legendary = Enum.ItemQuality.Legendary,
        artifact = Enum.ItemQuality.Artifact,
        heirloom = Enum.ItemQuality.Heirloom,

        grey = Enum.ItemQuality.Poor,
        gray = Enum.ItemQuality.Poor,
        white = Enum.ItemQuality.Common,
        green = Enum.ItemQuality.Uncommon,
        blue = Enum.ItemQuality.Rare,
        purple = Enum.ItemQuality.Epic,
        orange = Enum.ItemQuality.Legendary,
        red = Enum.ItemQuality.Artifact,
        aqua = Enum.ItemQuality.Heirloom,
    },

    stackfull = {
        full = "full",
        partial = "partial",
    },

    expansion = {
        classic = LE_EXPANSION_CLASSIC,
        vanilla = LE_EXPANSION_CLASSIC,

        tbc = LE_EXPANSION_BURNING_CRUSADE,
        bc = LE_EXPANSION_BURNING_CRUSADE,

        wotlk = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
        wrath = LE_EXPANSION_WRATH_OF_THE_LICH_KING,

        cataclysm = LE_EXPANSION_CATACLYSM,
        cata = LE_EXPANSION_CATACLYSM,

        mop = LE_EXPANSION_MISTS_OF_PANDARIA,
        pandaria = LE_EXPANSION_MISTS_OF_PANDARIA,

        wod = LE_EXPANSION_WARLORDS_OF_DRAENOR,
        draenor = LE_EXPANSION_WARLORDS_OF_DRAENOR,

        legion = LE_EXPANSION_LEGION,

        bfa = LE_EXPANSION_BATTLE_FOR_AZEROTH,
        battle = LE_EXPANSION_BATTLE_FOR_AZEROTH,

        shadowlands = LE_EXPANSION_SHADOWLANDS,
        sl = LE_EXPANSION_SHADOWLANDS,

        dragonflight = LE_EXPANSION_DRAGONFLIGHT,
        df = LE_EXPANSION_DRAGONFLIGHT,

        warwithin = LE_EXPANSION_THE_WAR_WITHIN,
        tww = LE_EXPANSION_THE_WAR_WITHIN,

        midnight = ExpansionConstant("LE_EXPANSION_MIDNIGHT", 11),
        thelasttitan = ExpansionConstant("LE_EXPANSION_THE_LAST_TITAN", 12),
    },
}

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

function Dumpster:OnInitialize()
    self:RegisterChatCommand("dumpster", "DumpsterDump")
    self:RegisterChatCommand("din", "DumpItIn")
    self:RegisterChatCommand("dout", "DumpItOut")
    self:RegisterChatCommand("dall", "DumpItAllOut")
    self:RegisterChatCommand("dadd", "DumpSetAdd")
    self:RegisterChatCommand("ddel", "DumpSetDel")
    self:RegisterChatCommand("dlist", "DumpSetList")
end

-- ---------------------------------------------------------------------------
-- Enable
-- ---------------------------------------------------------------------------

function Dumpster:OnEnable()
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")

    self:RegisterEvent("GUILDBANKFRAME_OPENED")
    self:RegisterEvent("GUILDBANKFRAME_CLOSED")

    self:RegisterEvent("MAIL_SHOW")
    self:RegisterEvent("MAIL_CLOSED")
    self:RegisterEvent("MAIL_INBOX_UPDATE")

    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_CLOSED")

    self:RegisterEvent("TRADE_SHOW")
    self:RegisterEvent("TRADE_CLOSED")

    if type(dumpset) ~= "table" then
        dumpset = {}
    end

    self:SetUpInterfaceOptions()
end