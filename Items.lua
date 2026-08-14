local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

function Dumpster:GetTooltipFromItem(item, so)
    local data = Dumpster.Compat:GetTooltipData(item, so)
    local modernText = Dumpster.Compat:TooltipDataToText(data)
    if modernText and modernText ~= "" then
        if Dumpster.superdebug then
            self:Print("Tooltip data: " .. modernText)
        end
        return modernText
    end

    -- Classic-family fallback: scan a hidden GameTooltip.
    DumpsterScanningTooltip:ClearLines()
    if so.where == "bank" or (so.where == "gbank" and so.inout == "in") or so.where == "abank" then
        DumpsterScanningTooltip:SetBagItem(so.bag, so.slot)
    elseif so.where == "gbank" and so.inout == "out" then
        DumpsterScanningTooltip:SetGuildBankItem(so.bag, so.slot)
    elseif so.where == "mail" then
        DumpsterScanningTooltip:SetInboxItem(so.bag, so.slot)
    elseif so.where == "merchant" then
        DumpsterScanningTooltip:SetMerchantItem(so.slot)
    else
        DumpsterScanningTooltip:SetHyperlink(item)
    end

    if DumpsterScanningTooltip:NumLines() == 0 then
        if Dumpster.superdebug then
            self:Print(L.debugTooltipFailed(so.where, so.bag, so.slot))
        end

        if item and item:find("|Hbattlepet:", 1, true) then
            Dumpster.tooltipError = true
        elseif item then
            DumpsterScanningTooltip:SetHyperlink(item)
        end
    end

    local text = {}
    for i = 1, DumpsterScanningTooltip:NumLines() do
        local left = _G["DumpsterScanningTooltipTextLeft" .. i]
        local right = _G["DumpsterScanningTooltipTextRight" .. i]
        local leftText = left and left:GetText()
        local rightText = right and right:GetText()

        if leftText then
            if Dumpster.superdebug then self:Print(i .. "L: " .. leftText) end
            text[#text + 1] = leftText
        end
        if rightText then
            if Dumpster.superdebug then self:Print(i .. "R: " .. rightText) end
            text[#text + 1] = rightText
        end
    end

    return table.concat(text)
end

function Dumpster:GetExpacID(item)
	local _, _, _, _, _, _, _, _, _, _, _, _, _, _, expacID = GetItemInfo(item)
	return expacID
end
function Dumpster:CheckBindandTooltip(item,so)
	local tooltip=""
	local expID

	if so.bind=="notbound" then
		tooltip=Dumpster:GetTooltipFromItem(item,so)
		if Dumpster.debug then self:Print(L.debugTooltip(tooltip)); end
		if tooltip:lower():find(L.bindBound:lower()) then
			if not so.except then
				if Dumpster.superdebug then self:Print(L.debugTooltipBindFail(so.bind,L.bindBound)); end
				return false
			end
		else
			if so.except then
				if Dumpster.superdebug then self:Print(L.debugTooltipBindFail(so.bind,L.bindBound)); end
				return false
			end
		end
	elseif so.bind~="bindAll" then
		tooltip=Dumpster:GetTooltipFromItem(item,so)
		if Dumpster.debug then self:Print(L.debugTooltip(tooltip)); end
		if not tooltip:lower():find(L[so.bind]:lower()) then
			if not so.except then
				if Dumpster.superdebug then self:Print(L.debugTooltipBindFail(so.bind,L[so.bind])); end
				return false
			end
		else
			if so.except then
				if Dumpster.superdebug then self:Print(L.debugTooltipBindFail(so.bind,L[so.bind])); end
				return false
			end
		end
	end


	if so.expansion ~= "AllExp" then
		expID = self:GetExpacID(item)

		if Dumpster.debug then
			local expKey = self:ExpansionIdToKey(expID)
			self:Print(L.debugExpansion(expID) .. " (" .. expKey .. ")")
		end

		if expID ~= so.expansion then
			if not so.except then
				if Dumpster.debug then
					local searchKey = self:ExpansionIdToKey(so.expansion)
					self:Print(L.debugTooltipExpansionFail(so.expansion, L[searchKey] or "unknown"))
				end
				return false
			end
		else
			if so.except then
				if Dumpster.debug then
					local searchKey = self:ExpansionIdToKey(so.expansion)
					self:Print(L.debugTooltipExpansionFail(so.expansion, L[searchKey] or "unknown"))
				end
				return false
			end
		end
	end



	if so.tooltipsearch and so.tooltipsearch~="" then
		if tooltip=="" then
			tooltip=Dumpster:GetTooltipFromItem(item,so)
			if Dumpster.debug then self:Print(L.debugTooltip(tooltip)); end
		end
		if not tooltip:lower():find(so.tooltipsearch:lower()) then
			if Dumpster.superdebug then self:Print(L.debugTooltipFail(so.tooltipsearch)); end
			return so.except -- so.except is normally false
		end
		return (not so.except) -- so.except is normally false
	else
		return true -- no tooltip so so.except doesn't apply
	end
end
function Dumpster:CheckSearchText(item,so)
	if so.search=="." then
		return true
	end
	if item:lower():find(so.search:lower()) then
		return (not so.except) -- so.except is normally false
	else
		return so.except -- so.except is normally false
	end
end
function Dumpster:getMaxStack(item)
	local _, _, _, _, _, _, _, maxStack = GetItemInfo(item)
	return maxStack or 1
end
function Dumpster:checkStackFull(so,item,count)
	if (not so.stackfull) or (so.stackfull=="") then
		if Dumpster.superdebug then self:Print(L.debugNoStackFull); end
		return true
	end
	local maxStack = Dumpster:getMaxStack(item)
	if Dumpster.superdebug then self:Print(L.debugStackFullcheckmatch(maxStack,count)); end
	if so.stackfull=="full" then
		return (maxStack==count)
	elseif so.stackfull=="partial" then
		return not (maxStack==count)
	else
		if Dumpster.debug then self:Print(L.debugInvalidStackFull(so.stackfull)); end
	end
	return false
end
function Dumpster:CheckItemQuality(item, so)
    if not so.qualitynumber then return true end
    local itemQuality = select(3, GetItemInfo(item))
    return itemQuality == so.qualitynumber
end
function Dumpster:ExpansionIdToKey(id)
    local expansions = self.multiFlags.expansion
    if not expansions then return tostring(id) end
    for k, v in pairs(expansions) do
        if v == id then return k end
    end
    return tostring(id)
end


-- ############# Expansion
