local Dumpster = Dumpster

Dumpster.Compat = Dumpster.Compat or {}

local Compat = Dumpster.Compat

-- ---------------------------------------------------------------------------
-- Bank detector registry
-- ---------------------------------------------------------------------------

Compat.BankDetectors = Compat.BankDetectors or {}

function Compat:RegisterBankDetector(name, detector)
    if type(name) ~= "string" or type(detector) ~= "function" then
        return
    end

    self.BankDetectors[#self.BankDetectors + 1] = {
        name = name,
        detector = detector,
    }
end

function Compat:GetActiveBankType()
    for _, provider in ipairs(self.BankDetectors) do
        local ok, bankType = pcall(provider.detector)

        if ok and bankType ~= nil then
            return bankType, provider.name
        end
    end

    return nil, nil
end

-- ---------------------------------------------------------------------------
-- Blizzard bank detector
-- ---------------------------------------------------------------------------

Compat:RegisterBankDetector("Blizzard", function()
    if BankFrame and BankFrame.GetActiveBankType then
        return BankFrame:GetActiveBankType()
    end

    return nil
end)

-- ---------------------------------------------------------------------------
-- Generic addon bank API
--
-- EllesmereUI exposes Addon_GetBankType() for compatibility with other
-- addons. Other bank addons may use the same compatibility contract.
-- ---------------------------------------------------------------------------

Compat:RegisterBankDetector("Addon API", function()
    if type(_G.Addon_GetBankType) == "function" then
        return _G.Addon_GetBankType()
    end

    return nil
end)

-- ---------------------------------------------------------------------------
-- Baganator detector
--
-- Baganator replaces Blizzard's active bank-frame state, but its selected
-- bank view exposes bankType on the currently visible child.
-- ---------------------------------------------------------------------------

Compat:RegisterBankDetector("Baganator", function()
    local frame = _G.Baganator_SingleViewBankViewFramedark

    if not frame or not frame.GetChildren then
        return nil
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        if child.bankType ~= nil then
            local shown = child:IsShown()

            if shown then
                return child.bankType
            end
        end
    end

    return nil
end)

-- ---------------------------------------------------------------------------
-- Bank helpers
-- ---------------------------------------------------------------------------

function Compat:IsCharacterBankActive()
    if not Enum or not Enum.BankType then
        return false
    end

    local bankType = self:GetActiveBankType()

    return bankType == Enum.BankType.Character
end

function Compat:IsAccountBankActive()
    if not Enum or not Enum.BankType then
        return false
    end

    local bankType = self:GetActiveBankType()

    return bankType == Enum.BankType.Account
end

function Compat:GetBankTypeName(bankType)
    if bankType == nil then
        return "Unknown (nil)"
    end

    if Enum and Enum.BankType then
        if bankType == Enum.BankType.Character then
            return "Character"
        end

        if bankType == Enum.BankType.Account then
            return "Account / Warband"
        end
    end

    return "Unknown (" .. tostring(bankType) .. ")"
end

-- ---------------------------------------------------------------------------
-- Safe bank diagnostics
-- ---------------------------------------------------------------------------

function Compat:PrintBankDiagnostics()
    Dumpster:Print("Bank Compatibility Diagnostics")
    Dumpster:Print("------------------------------")

    local bankType, provider = self:GetActiveBankType()

    Dumpster:Print(
        "Detected bank type: " ..
        self:GetBankTypeName(bankType)
    )

    Dumpster:Print(
        "Detector: " ..
        tostring(provider or "none")
    )

    if BankFrame and BankFrame.GetActiveBankType then
        local ok, value = pcall(
            BankFrame.GetActiveBankType,
            BankFrame
        )

        Dumpster:Print(
            "Blizzard active type: " ..
            tostring(ok and value or nil)
        )
    else
        Dumpster:Print(
            "Blizzard active type: unavailable"
        )
    end

    Dumpster:Print("Known detector results:")

    for _, entry in ipairs(self.BankDetectors) do
        local ok, value = pcall(entry.detector)

        Dumpster:Print(
            "  " ..
            entry.name ..
            ": " ..
            tostring(ok and value or nil)
        )
    end
end

function Compat:PrintKnownBankFrames()
    Dumpster:Print("Known bank frames:")
    Dumpster:Print("------------------")

    local frames = {
        "BankFrame",
        "GuildBankFrame",
        "Baganator_SingleViewBankViewFramedark",
        "EUI_BankFrame",
    }

    for _, name in ipairs(frames) do
        Dumpster:Print(
            name ..
            ": " ..
            (_G[name] and "present" or "not found")
        )
    end
end

-- ---------------------------------------------------------------------------
-- Container API compatibility
-- ---------------------------------------------------------------------------

function Compat:GetContainerNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    end

    if GetContainerNumSlots then
        return GetContainerNumSlots(bag)
    end

    return 0
end

function Compat:GetContainerItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(
            bag,
            slot
        )
    end

    if GetContainerItemLink then
        return GetContainerItemLink(
            bag,
            slot
        )
    end

    return nil
end

function Compat:GetContainerItemStackCount(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info =
            C_Container.GetContainerItemInfo(
                bag,
                slot
            )

        if info then
            return info.stackCount or 0
        end

        return 0
    end

    if GetContainerItemInfo then
        local _, count =
            GetContainerItemInfo(
                bag,
                slot
            )

        return count or 0
    end

    return 0
end

function Compat:UseContainerItem(bag, slot, bankType)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(
            bag,
            slot,
            nil,
            bankType
        )

        return
    end

    if UseContainerItem then
        UseContainerItem(
            bag,
            slot
        )
    end
end

-- ---------------------------------------------------------------------------
-- Player bag enumeration
-- ---------------------------------------------------------------------------

function Compat:GetPlayerBagContainers()
    local bags = {}

    local maxBags =
        NUM_BAG_SLOTS or 4

    for bag = 0, maxBags do
        bags[#bags + 1] = bag
    end

    -- Retail reagent bag.
    if Enum
        and Enum.BagIndex
        and Enum.BagIndex.ReagentBag
        and Enum.BagIndex.ReagentBag > maxBags then

        bags[#bags + 1] =
            Enum.BagIndex.ReagentBag
    end

    return bags
end

-- ---------------------------------------------------------------------------
-- Character bank enumeration
-- ---------------------------------------------------------------------------

function Compat:GetCharacterBankContainers()
    local bags = {}

    if Dumpster.WOWRetail
        and Enum
        and Enum.BagIndex then

        local characterBankTabs = {
            "CharacterBankTab_1",
            "CharacterBankTab_2",
            "CharacterBankTab_3",
            "CharacterBankTab_4",
            "CharacterBankTab_5",
            "CharacterBankTab_6",
        }

        for _, key in ipairs(characterBankTabs) do
            local bagID = Enum.BagIndex[key]

            if bagID ~= nil
                and self:GetContainerNumSlots(bagID) > 0 then

                bags[#bags + 1] = bagID
            end
        end

        return bags
    end

    -- Classic-family fallback.
    if BANK_CONTAINER ~= nil then
        bags[#bags + 1] = BANK_CONTAINER
    end

    local firstBankBag =
        (NUM_BAG_SLOTS or 4) + 1

    local numBankBags =
        NUM_BANKBAGSLOTS or 7

    for bag = firstBankBag,
        firstBankBag + numBankBags - 1 do

        bags[#bags + 1] = bag
    end

    return bags
end

-- ---------------------------------------------------------------------------
-- Account / Warband bank enumeration
-- ---------------------------------------------------------------------------

function Compat:GetAccountBankContainers()
    local bags = {}

    if not Dumpster.WOWRetail then
        return bags
    end

    if not Enum or not Enum.BagIndex then
        return bags
    end

    local accountBags = {
        "AccountBankTab_1",
        "AccountBankTab_2",
        "AccountBankTab_3",
        "AccountBankTab_4",
        "AccountBankTab_5",
    }

    for _, key in ipairs(accountBags) do
        local bagID =
            Enum.BagIndex[key]

        if bagID ~= nil
            and self:GetContainerNumSlots(bagID) > 0 then

            bags[#bags + 1] =
                bagID
        end
    end

    return bags
end

-- ---------------------------------------------------------------------------
-- Legacy / UI visibility fallbacks
-- ---------------------------------------------------------------------------

function Compat:IsGuildBankVisible()
    if GuildBankFrame
        and GuildBankFrame:IsShown() then

        return true
    end

    return false
end

function Compat:IsAccountBankVisible()
    local bankType =
        self:GetActiveBankType()

    if Enum
        and Enum.BankType
        and bankType == Enum.BankType.Account then

        return true
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Tooltip compatibility
-- ---------------------------------------------------------------------------

function Compat:GetTooltipData(item, so)
    if not Dumpster.WOWRetail or not C_TooltipInfo then
        return nil
    end

    if so.where == "bank"
        or (so.where == "gbank" and so.inout == "in")
        or so.where == "abank" then

        if C_TooltipInfo.GetBagItem then
            return C_TooltipInfo.GetBagItem(
                so.bag,
                so.slot
            )
        end

    elseif so.where == "gbank"
        and so.inout == "out" then

        if C_TooltipInfo.GetGuildBankItem then
            return C_TooltipInfo.GetGuildBankItem(
                so.bag,
                so.slot
            )
        end

    elseif so.where == "mail" then
        if C_TooltipInfo.GetInboxItem then
            return C_TooltipInfo.GetInboxItem(
                so.bag,
                so.slot
            )
        end

    elseif so.where == "merchant" then
        if C_TooltipInfo.GetMerchantItem then
            return C_TooltipInfo.GetMerchantItem(
                so.slot
            )
        end
    end

    if item and C_TooltipInfo.GetHyperlink then
        return C_TooltipInfo.GetHyperlink(item)
    end

    return nil
end

function Compat:TooltipDataToText(data)
    if not data or not data.lines then
        return nil
    end

    local text = {}

    for _, line in ipairs(data.lines) do
        if line.leftText then
            text[#text + 1] =
                line.leftText
        end

        if line.rightText then
            text[#text + 1] =
                line.rightText
        end
    end

    return table.concat(text)
end