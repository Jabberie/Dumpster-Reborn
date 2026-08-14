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
    local button = _G["GuildBankTab" .. tostring(tab) .. "Button"]
    if not button or not button.Click then
        return false
    end

    button:Click()
    return true
end

function Dumpster:QueueGuildBankItem(bagID, slotID)
    self.guildBankQueue[#self.guildBankQueue + 1] = { bagID, slotID }
end

function Dumpster:ClearGuildBankQueue()
    wipe(self.guildBankQueue)
    StopQueue(false)
end

function Dumpster:StartGuildBankQueue(direction)
    if #self.guildBankQueue == 0 then
        self.guildBankTabReady = true
        return
    end

    movementType = direction
    elapsed = 0
    queueFrame:Show()

    queueFrame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta

        local delay = movementType == "give" and 1.0 or 0.5
        if elapsed < delay then
            return
        end
        elapsed = 0

        if not Dumpster.Compat:IsGuildBankVisible() then
            StopQueue(true)
            return
        end

        local entry = table.remove(Dumpster.guildBankQueue, 1)
        if not entry then
            StopQueue(true)
            return
        end

        local bagID, slotID = entry[1], entry[2]
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
