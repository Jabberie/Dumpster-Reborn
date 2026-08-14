local Dumpster = Dumpster

Dumpster.Compat = Dumpster.Compat or {}
local Compat = Dumpster.Compat

local function AddContainerIfPresent(list, seen, bagID)
    if bagID == nil or seen[bagID] then
        return
    end

    local slots = C_Container.GetContainerNumSlots(bagID)
    if slots and slots > 0 then
        seen[bagID] = true
        list[#list + 1] = bagID
    end
end

function Compat:GetContainerItemStackCount(bagID, slotID)
    local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
    if not itemInfo then
        return 0
    end

    -- Modern clients return a ContainerItemInfo table. Some older variants
    -- still expose the historical tuple return shape.
    if type(itemInfo) == "table" then
        return itemInfo.stackCount or 0
    end

    local _, count = C_Container.GetContainerItemInfo(bagID, slotID)
    return count or 0
end

function Compat:GetPlayerBagContainers()
    local containers = {}
    local seen = {}

    for bagID = 0, NUM_BAG_SLOTS do
        AddContainerIfPresent(containers, seen, bagID)
    end

    if Dumpster.WOWRetail then
        local reagentBag = Enum.BagIndex and Enum.BagIndex.ReagentBag or 5
        AddContainerIfPresent(containers, seen, reagentBag)
    end

    return containers
end

function Compat:GetCharacterBankContainers()
    local containers = {}
    local seen = {}

    AddContainerIfPresent(containers, seen, BANK_CONTAINER)

    if Dumpster.WOWRetail and Enum.BagIndex then
        -- Dragonflight-era bank bags were replaced by character bank tabs.
        -- Use the named enum values when available so account-bank containers
        -- are never accidentally included in a character-bank scan.
        for index = 1, 12 do
            local bagID = Enum.BagIndex["CharacterBankTab_" .. index]
            if bagID == nil then
                break
            end
            AddContainerIfPresent(containers, seen, bagID)
        end
    else
        -- Classic-family clients retain the historical bank-bag indexes.
        for bagID = 5, 12 do
            AddContainerIfPresent(containers, seen, bagID)
        end
    end

    return containers
end

function Compat:GetAccountBankContainers()
    local containers = {}
    local seen = {}

    if not Dumpster.WOWRetail or not Enum.BagIndex then
        return containers
    end

    for index = 1, 12 do
        local bagID = Enum.BagIndex["AccountBankTab_" .. index]
        if bagID == nil then
            break
        end
        AddContainerIfPresent(containers, seen, bagID)
    end

    return containers
end


function Compat:GetContainerNumSlots(bagID)
    return C_Container.GetContainerNumSlots(bagID) or 0
end

function Compat:GetContainerItemLink(bagID, slotID)
    return C_Container.GetContainerItemLink(bagID, slotID)
end

function Dumpster.Compat:UseContainerItem(bag, slot, bankType)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot, nil, bankType)
        return
    end

    if UseContainerItem then
        UseContainerItem(bag, slot)
    end
end

function Compat:GetTooltipData(item, so)
    if not Dumpster.WOWRetail or not C_TooltipInfo then
        return nil
    end

    if so.where == "bank" or (so.where == "gbank" and so.inout == "in") or so.where == "abank" then
        if C_TooltipInfo.GetBagItem then
            return C_TooltipInfo.GetBagItem(so.bag, so.slot)
        end
    elseif so.where == "gbank" and so.inout == "out" then
        if C_TooltipInfo.GetGuildBankItem then
            return C_TooltipInfo.GetGuildBankItem(so.bag, so.slot)
        end
    elseif so.where == "mail" then
        if C_TooltipInfo.GetInboxItem then
            return C_TooltipInfo.GetInboxItem(so.bag, so.slot)
        end
    elseif so.where == "merchant" then
        if C_TooltipInfo.GetMerchantItem then
            return C_TooltipInfo.GetMerchantItem(so.slot)
        end
    end

    if item and C_TooltipInfo.GetHyperlink then
        return C_TooltipInfo.GetHyperlink(item)
    end
end

function Compat:TooltipDataToText(data)
    if not data or not data.lines then
        return nil
    end

    local text = {}
    for _, line in ipairs(data.lines) do
        if line.leftText then
            text[#text + 1] = line.leftText
        end
        if line.rightText then
            text[#text + 1] = line.rightText
        end
    end

    return table.concat(text)
end

function Compat:IsAccountBankVisible()
    if not Dumpster.WOWRetail or not BankFrame or not BankFrame.GetActiveBankType then
        return false
    end

    local bankVisible = BankFrame:IsVisible()
        or (Baganator_SingleViewBankViewFrameblizzard and Baganator_SingleViewBankViewFrameblizzard:IsVisible())

    return bankVisible and BankFrame:GetActiveBankType() == Enum.BankType.Account
end

function Compat:IsGuildBankVisible()
    return (GuildBankFrame and GuildBankFrame:IsVisible())
        or (Baganator_SingleViewGuildViewFrame and Baganator_SingleViewGuildViewFrame:IsVisible())
        or (BagnonGuild1 and BagnonGuild1:IsVisible())
        or false
end

function Dumpster.Compat:GetActiveBankType()
    -- Stock Blizzard bank UI.
    if BankFrame and BankFrame.GetActiveBankType then
        local bankType = BankFrame:GetActiveBankType()

        if bankType ~= nil then
            return bankType
        end
    end

    -- Baganator fallback.
    local frame = _G.Baganator_SingleViewBankViewFramedark

    if frame and frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            if child:IsShown() and child.bankType ~= nil then
                return child.bankType
            end
        end
    end

    return nil
end