local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

-- ---------------------------------------------------------------------------
-- Interaction state
-- ---------------------------------------------------------------------------

local atBank = false
local atGuildBank = false
local atMailbox = false
local atMerchant = false
local atTrade = false

Dumpster.atAccountBank = false

-- ---------------------------------------------------------------------------
-- Account / Warband bank
-- ---------------------------------------------------------------------------

function Dumpster:AtAccountBank()
    if not atBank then
        return false
    end

    local bankType = Dumpster.Compat:GetActiveBankType()

    if bankType ~= nil
        and Enum
        and Enum.BankType then

        if bankType == Enum.BankType.Account then
            if Dumpster.debug then
                self:Print(L.debugatAccountBank)
            end

            return true
        end

        return false
    end

    -- Older-client / compatibility fallback.
    if Dumpster.Compat:IsAccountBankVisible() then
        if Dumpster.debug then
            self:Print(L.debugatAccountBank)
        end

        return true
    end

    if Dumpster.debug and Dumpster.atAccountBank then
        self:Print(L.debugatAccountBankflag)
    end

    return Dumpster.atAccountBank
end

-- ---------------------------------------------------------------------------
-- Interaction state helpers
-- ---------------------------------------------------------------------------

function Dumpster:Nowhere()
    atBank = false
    atGuildBank = false
    Dumpster.atAccountBank = false
    atMailbox = false
    atMerchant = false
    atTrade = false
end

-- ---------------------------------------------------------------------------
-- Modern Retail interaction manager
-- ---------------------------------------------------------------------------

function Dumpster:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(_, interactionType)
    if not Enum or not Enum.PlayerInteractionType then
        return
    end

    if interactionType == Enum.PlayerInteractionType.GuildBanker then
        Dumpster:Nowhere()
        atGuildBank = true

        if Dumpster.debug then
            self:Print("PLAYER_INTERACTION_MANAGER_FRAME_SHOW: GuildBanker")
        end

    elseif interactionType == Enum.PlayerInteractionType.Banker then
        Dumpster:Nowhere()
        atBank = true

        if Dumpster.debug then
            self:Print("PLAYER_INTERACTION_MANAGER_FRAME_SHOW: Banker")
        end
    end
end

function Dumpster:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(_, interactionType)
    if not Enum or not Enum.PlayerInteractionType then
        return
    end

    if interactionType == Enum.PlayerInteractionType.GuildBanker then
        atGuildBank = false

        if Dumpster.CancelGuildBankQueue then
            Dumpster:CancelGuildBankQueue()
        end

        if Dumpster.debug then
            self:Print("PLAYER_INTERACTION_MANAGER_FRAME_HIDE: GuildBanker")
        end

    elseif interactionType == Enum.PlayerInteractionType.Banker then
        atBank = false

        if Dumpster.debug then
            self:Print("PLAYER_INTERACTION_MANAGER_FRAME_HIDE: Banker")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Legacy / Classic interaction events
-- ---------------------------------------------------------------------------

function Dumpster:BANKFRAME_OPENED()
    Dumpster:Nowhere()
    atBank = true

    if Dumpster.debug then
        self:Print(L.debugevent("BANKFRAME_OPENED"))
    end
end

function Dumpster:BANKFRAME_CLOSED()
    atBank = false
    Dumpster.atAccountBank = false

    if Dumpster.debug then
        self:Print(L.debugevent("BANKFRAME_CLOSED"))
    end
end

function Dumpster:GUILDBANKFRAME_OPENED()
    Dumpster:Nowhere()
    atGuildBank = true

    if Dumpster.debug then
        self:Print(L.debugevent("GUILDBANKFRAME_OPENED"))
    end
end

function Dumpster:GUILDBANKFRAME_CLOSED()
    atGuildBank = false

    if Dumpster.CancelGuildBankQueue then
        Dumpster:CancelGuildBankQueue()
    end

    if Dumpster.debug then
        self:Print(L.debugevent("GUILDBANKFRAME_CLOSED"))
    end
end

function Dumpster:MAIL_SHOW()
    Dumpster:Nowhere()
    atMailbox = true

    if Dumpster.debug then
        self:Print(L.debugevent("MAIL_SHOW"))
    end
end

function Dumpster:MAIL_CLOSED()
    atMailbox = false

    if Dumpster.debug then
        self:Print(L.debugevent("MAIL_CLOSED"))
    end
end

function Dumpster:MAIL_INBOX_UPDATE()
    if Dumpster.debug then
        self:Print(L.debugevent("MAIL_INBOX_UPDATE"))
    end
end

function Dumpster:MERCHANT_SHOW()
    Dumpster:Nowhere()
    atMerchant = true

    Dumpster:ProcessDelayed()

    if Dumpster.debug then
        self:Print(L.debugevent("MERCHANT_SHOW"))
    end
end

function Dumpster:MERCHANT_CLOSED()
    atMerchant = false

    if Dumpster.debug then
        self:Print(L.debugevent("MERCHANT_CLOSED"))
    end
end

function Dumpster:TRADE_SHOW()
    Dumpster:Nowhere()
    atTrade = true

    if Dumpster.debug then
        self:Print(L.debugevent("TRADE_SHOW"))
    end
end

function Dumpster:TRADE_CLOSED()
    atTrade = false

    if Dumpster.debug then
        self:Print(L.debugevent("TRADE_CLOSED"))
    end
end

-- ---------------------------------------------------------------------------
-- Mail detection
-- ---------------------------------------------------------------------------

function Dumpster:AtMail()
    if (MailFrame and MailFrame:IsVisible())
        or (SendMailFrame and SendMailFrame:IsVisible()) then

        return true
    end

    if Dumpster.debug and atMailbox then
        self:Print(L.debugatMailboxflag)
    end

    return atMailbox
end

function Dumpster:AtMailInbox()
    if MailFrame and MailFrame:IsVisible() then
        if InboxPrevPageButton and InboxPrevPageButton:IsVisible() then
            return true
        else
            if Dumpster.debug then
                self:Print(L.debugatMailInbox)
            end
        end
    end

    if Dumpster.debug and atMailbox then
        self:Print(L.debugatMailboxflag)
    end

    return atMailbox
end

function Dumpster:AtMailSend()
    if SendMailFrame and SendMailFrame:IsVisible() then
        if InboxPrevPageButton and InboxPrevPageButton:IsVisible() then
            return false
        else
            if Dumpster.debug then
                self:Print(L.debugatMailSend)
            end

            return true
        end
    end

    if Dumpster.debug and atMailbox then
        self:Print(L.debugatMailboxflag)
    end

    return atMailbox
end

-- ---------------------------------------------------------------------------
-- Gossip
-- ---------------------------------------------------------------------------

function Dumpster:AtGossip()
    if GossipFrame and GossipFrame:IsVisible() then
        if Dumpster.debug then
            self:Print(L.debugatGossip)
        end

        return true
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Merchant
-- ---------------------------------------------------------------------------

function Dumpster:AtMerchant()
    if MerchantFrame and MerchantFrame:IsVisible() then
        if Dumpster.debug then
            self:Print(L.debugatMerchant)
        end

        return true
    end

    if Dumpster.debug and atMerchant then
        self:Print(L.debugatMerchantflag)
    end

    return atMerchant
end

-- ---------------------------------------------------------------------------
-- Trade
-- ---------------------------------------------------------------------------

function Dumpster:AtTrade()
    if TradeFrame and TradeFrame:IsVisible() then
        if Dumpster.debug then
            self:Print(L.debugatMerchant)
        end

        return true
    end

    if Dumpster.debug and atTrade then
        self:Print(L.debugatTradeflag)
    end

    return atTrade
end

-- ---------------------------------------------------------------------------
-- Bank
-- ---------------------------------------------------------------------------

function Dumpster:AtBank()
    if not atBank then
        return false
    end

    local bankType = Dumpster.Compat:GetActiveBankType()

    if bankType ~= nil
        and Enum
        and Enum.BankType then

        if bankType == Enum.BankType.Character then
            if Dumpster.debug then
                self:Print(L.debugatBankflag)
            end

            return true
        end

        return false
    end

    -- If the interaction is definitely open but the client/addon
    -- cannot expose a bank type, treat it as a normal character bank.
    if Dumpster.debug then
        self:Print(L.debugatBankflag)
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Guild bank
-- ---------------------------------------------------------------------------

function Dumpster:AtGuildBank()
    -- Event/interaction state is authoritative.
    -- In Retail, PLAYER_INTERACTION_MANAGER_FRAME_SHOW with
    -- Enum.PlayerInteractionType.GuildBanker sets this flag.
    if atGuildBank then
        if Dumpster.debug then
            self:Print(L.debugatGuildBankflag)
        end

        return true
    end

    -- Compatibility fallback for older clients and known bag addons.
    if Dumpster.Compat:IsGuildBankVisible() then
        if Dumpster.debug then
            self:Print(L.debugatGuildBank)
        end

        return true
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Delayed processing
-- ---------------------------------------------------------------------------

function Dumpster:ProcessDelayed()
    if Dumpster.delayedInOut and Dumpster.delayedInOut ~= "" then
        if Dumpster.debug then
            self:Print(
                L.debugProcessDelayed(
                    Dumpster.delayedInOut,
                    Dumpster.delayedSO.search
                )
            )
        end

        Dumpster.delayedSO.delayed = true
        Dumpster.guildBankTabReady = true

        Dumpster:DumpWithso(Dumpster.delayedSO)
    end
end

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------

function Dumpster:DeepCopy(object)
    local lookupTable = {}

    local function Copy(value)
        if type(value) ~= "table" then
            return value
        elseif lookupTable[value] then
            return lookupTable[value]
        end

        local newTable = {}
        lookupTable[value] = newTable

        for index, childValue in pairs(value) do
            newTable[Copy(index)] = Copy(childValue)
        end

        return setmetatable(newTable, getmetatable(value))
    end

    return Copy(object)
end
