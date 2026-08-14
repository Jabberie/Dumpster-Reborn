Dumpster = LibStub("AceAddon-3.0"):NewAddon("Dumpster", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local Dumpster = Dumpster

Dumpster.VERSION = Dumpster.VERSION or "v13"
Dumpster.debug = Dumpster.debug or false
Dumpster.superdebug = Dumpster.superdebug or false
Dumpster.delayedSO = Dumpster.delayedSO or nil
Dumpster.delayedInOut = Dumpster.delayedInOut or ""
Dumpster.tooltipError = Dumpster.tooltipError or false

local function ExpansionConstant(name, fallback)
    local value = _G[name]
    if value ~= nil then
        return value
    end
    return fallback
end

Dumpster.WOWClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
Dumpster.WOWBCClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
Dumpster.WOWWotLKClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC
Dumpster.WOWCataClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC
Dumpster.WOWRetail = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE

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
        nb = "notbound",
        notbound = "notbound",
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
        df = LE_EXPANSION_DRAGONFLIGHT,
        dragonflight = LE_EXPANSION_DRAGONFLIGHT,
        tww = LE_EXPANSION_THE_WAR_WITHIN,
        warwithin = LE_EXPANSION_THE_WAR_WITHIN,
        midnight = ExpansionConstant("LE_EXPANSION_MIDNIGHT", 11),
        thelasttitan = ExpansionConstant("LE_EXPANSION_THE_LAST_TITAN", 12),
    },
}

function Dumpster:OnInitialize()
    self:RegisterChatCommand("dumpster", "DumpsterDump")
    self:RegisterChatCommand("din", "DumpItIn")
    self:RegisterChatCommand("dout", "DumpItOut")
    self:RegisterChatCommand("dall", "DumpItAllOut")
    self:RegisterChatCommand("dadd", "DumpSetAdd")
    self:RegisterChatCommand("ddel", "DumpSetDel")
    self:RegisterChatCommand("dlist", "DumpSetList")
end

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

    if not dumpset then
        dumpset = {}
    end

    self:SetUpInterfaceOptions()
end
