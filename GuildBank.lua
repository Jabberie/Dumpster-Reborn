local Dumpster = Dumpster

Dumpster.guildBankQueue = Dumpster.guildBankQueue or {}
Dumpster.guildBankTabReady = false

local queueFrame = CreateFrame("Frame", "DumpsterGuildQueueFrame", UIParent)
queueFrame:Hide()

local elapsed = 0
local movementType

local function StopQueue(markTabReady)
    queueFrame:SetScript("OnUpdate", nil)
    queueFrame:Hide()

    elapsed = 0
    movementType = nil

    if markTabReady then
        Dumpster.guildBankTabReady = true
    end
end

function Dumpster:SetGuildBankTab(tab)
    -- Standard Blizzard guild-bank UI.
    local button = _G["GuildBankTab" .. tostring(tab) .. "Button"]

    if button and button.Click then
        button:Click()
        return true
    end

    -- The current guild-bank tab can also be selected directly when the
    -- Blizzard frame has been replaced by another addon.
    if SetCurrentGuildBankTab then
        SetCurrentGuildBankTab(tab)
        return true
    end

    return false
end

function Dumpster:QueueGuildBankItem(bagID, slotID)
    self.guildBankQueue[#self.guildBankQueue + 1] = {
        bagID,
        slotID,
    }
end

function Dumpster:ClearGuildBankQueue()
    wipe(self.guildBankQueue)
    StopQueue(false)
end

function Dumpster:CancelGuildBankQueue()
    self:ClearGuildBankQueue()
end

function Dumpster:StartGuildBankQueue(direction)
    if #self.guildBankQueue == 0 then
        self.guildBankTabReady = true
        return
    end

    -- Don't restart an already-running queue.
    if queueFrame:IsShown() then
        return
    end

    movementType = direction
    elapsed = 0

    queueFrame:Show()

    queueFrame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta

        local delay

        if movementType == "give" then
            delay = 1.0
        else
            delay = 0.5
        end

        if elapsed < delay then
            return
        end

        elapsed = 0

        -- IMPORTANT:
        -- Do not check GuildBankFrame/Baganator frame visibility here.
        --
        -- AtGuildBank() uses the actual player interaction state on Retail,
        -- so this continues to work when Baganator or another addon replaces
        -- Blizzard's guild-bank window.
        if not Dumpster:AtGuildBank() then
            Dumpster:ClearGuildBankQueue()
            return
        end

        local entry = table.remove(Dumpster.guildBankQueue, 1)

        if not entry then
            StopQueue(true)
            return
        end

        local bagID = entry[1]
        local slotID = entry[2]

        if movementType == "take" then
            AutoStoreGuildBankItem(bagID, slotID)
        else
            Dumpster.Compat:UseContainerItem(bagID, slotID)
        end

        if #Dumpster.guildBankQueue == 0 then
            StopQueue(true)
        end
    end)
end