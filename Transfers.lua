local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

local MAIL_RETRY_DELAY = 0.5
local GUILD_BANK_TAB_DELAY = 3.0
local GUILD_BANK_SLOTS_PER_TAB = _G.MAX_GUILDBANK_SLOTS_PER_TAB or 98
local MAIL_ATTACHMENTS_PER_MESSAGE = _G.ATTACHMENTS_MAX_RECEIVE or 12

function Dumpster:SelectVendor()
    if not (GetNumGossipOptions and GetGossipOptions and SelectGossipOption) then
        return false
    end

    local numGossips = GetNumGossipOptions()
    local gossips = { GetGossipOptions() }

    for index = 1, numGossips do
        local text = gossips[(index * 2) - 1]
        local optionType = gossips[index * 2]
        if optionType == "vendor" then
            if Dumpster.debug then self:Print(L.debugGossipOption(text)) end
            SelectGossipOption(index)
            return true
        end
    end

    return false
end
function Dumpster:OkToDump(so)
	if (not so.search) or (so.search=="") then
		self:Print(L.nothingtodump);
		return false
	end

	if so.only then
		if Dumpster:AtTrade() or Dumpster:AtMerchant() then
			self:Print(L.notsafeonly);
			return false
		end
	end

	if Dumpster:AtGuildBank() then return true end
	if Dumpster:AtAccountBank() then return true end
	if Dumpster:AtBank() then return true end
	if Dumpster:AtTrade() then return true end
	if Dumpster:AtMerchant() then return true end

	if Dumpster:AtGossip() then return true end

	if so.inout and so.inout=="in" then
		if Dumpster:AtMail() then
			MailFrameTab_OnClick(nil, 2)
		end

		if Dumpster:AtMailSend() then
			return true
		end
			self:Print(L.notsafein);
	else
		if Dumpster:AtMail() then
			MailFrameTab_OnClick(nil, 1)
		end
		if Dumpster:AtMailInbox() then
			return true
		end
		self:Print(L.notsafeout);
	end
	return false
end
function Dumpster:GetExistingCount(originalso)
	local checkso=Dumpster:DeepCopy(originalso)

	checkso.justcount=true
	checkso.maxcount=999
	checkso.remain=false
	checkso.only=false

	if originalso.inout=="in" then
		checkso.inout = "out"
	else
		checkso.inout = "in"
	end

	local dumpcount = 0
	dumpcount = Dumpster:DumpWithso(checkso)
	if Dumpster.debug then self:Print(L.debugExistingCount(dumpcount)); end
	return dumpcount
end
function Dumpster:getMaxBags(so)
    if so.where == "bank" then
        return #Dumpster.Compat:GetCharacterBankContainers()
    elseif so.where == "gbank" and so.inout == "in" then
        return #Dumpster.Compat:GetPlayerBagContainers()
    elseif so.where == "gbank" and so.inout == "out" then
        return GetNumGuildBankTabs()
    elseif so.where == "mail" then
        return GetInboxNumItems()
    elseif so.where == "merchant" then
        return 1
    end

    return 0
end
function Dumpster:getMaxSlots(so)
	if so.where=="bank" then
		if so.bag ~= nil then
			return Dumpster.Compat:GetContainerNumSlots(so.bag)
		else
			return 0
		end
	elseif so.where=="gbank" and so.inout =="in" then
		return Dumpster.Compat:GetContainerNumSlots(so.bag)
	elseif so.where=="gbank" and so.inout =="out" then
		return GUILD_BANK_SLOTS_PER_TAB
	elseif so.where=="abank" then
		return Dumpster.Compat:GetContainerNumSlots(so.bag)
	elseif so.where=="mail" then
		return MAIL_ATTACHMENTS_PER_MESSAGE -- scan every possible attachment slot
	elseif so.where=="merchant" then
		return GetMerchantNumItems()
	else
		return 0
	end
end
function Dumpster:getItemLink(so)
	if so.where=="bank" then
		return Dumpster.Compat:GetContainerItemLink(so.bag, so.slot)
	elseif so.where=="gbank" and so.inout =="in" then
		return Dumpster.Compat:GetContainerItemLink(so.bag, so.slot)
	elseif so.where=="gbank" and so.inout =="out" then
		return GetGuildBankItemLink(so.bag, so.slot)
	elseif so.where=="abank" then
		return Dumpster.Compat:GetContainerItemLink(so.bag, so.slot)
	elseif so.where=="mail" then
		return GetInboxItemLink(so.bag, so.slot)
	elseif so.where=="merchant" then
		return GetMerchantItemLink(so.slot)
	else
		return nil
	end
end
function Dumpster:getNumInStack(so)
    if so.where == "bank" or (so.where == "gbank" and so.inout == "in") or so.where == "abank" then
        return Dumpster.Compat:GetContainerItemStackCount(so.bag, so.slot)
    elseif so.where == "mail" then
        local _, _, count = GetInboxItem(so.bag, so.slot)
        return count or 0
    elseif so.where == "gbank" and so.inout == "out" then
        local _, count = GetGuildBankItemInfo(so.bag, so.slot)
        return count or 0
    elseif so.where == "merchant" then
        local _, _, _, quantity = GetMerchantItemInfo(so.slot)
        return quantity or 0
    end

    return 1
end
function Dumpster:DumpItem(so)
	if so.where=="bank" then
		 Dumpster.Compat:UseContainerItem(so.bag, so.slot)
	elseif so.where=="gbank" then
		Dumpster:QueueGuildBankItem(so.bag, so.slot)
	--	AutoStoreGuildBankItem(so.bag, so.slot)
	elseif so.where=="abank" then
		Dumpster.Compat:UseContainerItem(so.bag, so.slot)
	elseif so.where=="mail" then
		TakeInboxItem(so.bag, so.slot)
	elseif so.where=="merchant" then
		BuyMerchantItem(so.slot,1)
	end
end

-- ############# the meat and potatoes
function Dumpster:DumpOutCurrentGbankTab(so)
	so.where="gbank"
	so.bag=GetCurrentGuildBankTab()
	return Dumpster:NewDumpBag(so)
end
function Dumpster:DumpOutAllBankBags(so)
    so.where = "bank"
    local dumpcount = 0

    for _, bagID in ipairs(Dumpster.Compat:GetCharacterBankContainers()) do
        so.bag = bagID
        dumpcount = dumpcount + Dumpster:NewDumpBag(so)
    end

    return dumpcount
end
function Dumpster:DumpOutAllMail(so)
	so.where="mail"
	local dumpcount = 0
        local x = Dumpster:getMaxBags(so)
	local existing = 0
	if not so.only then
		-- convert to /only existing+requested so we pull the proper amount
		existing = Dumpster:GetExistingCount(so)
		so.only = true
		so.maxcount = so.maxcount+existing
	end
        while x > 0 do -- start from the back
                so.bag=x -- bag in this case is the mail number
		dumpcount = dumpcount + Dumpster:NewDumpBag(so);
		x = x -1
	end
	return dumpcount
end
function Dumpster:DumpOutMerchant(so)
	so.where="merchant"
	so.bag=1
	if so.maxcount==999 then
		-- if we're buying from a merchant, only buy one unless otherwise specified
		so.maxcount=1
	end
	
	return Dumpster:NewDumpBag(so);
end
function Dumpster:DumpIn(so)
    local dumpcount = 0

    for _, bagID in ipairs(Dumpster.Compat:GetPlayerBagContainers()) do
        so.bag = bagID
        dumpcount = dumpcount + Dumpster:NewDumpBag(so)
    end

    if Dumpster:AtMailSend() and so.to ~= "" then
        SendMailNameEditBox:SetText(so.to)
        SendMailSubjectEditBox:SetFocus()
    end

    return dumpcount
end
function Dumpster:DumpAllGbankTabs(so)
	so.where = "gbank"
	so.inout = "out"

	local numGuildTabs = GetNumGuildBankTabs()
	local currentTab = GetCurrentGuildBankTab()
	local dumpcount = 0
	local delay = 0

	if so.delayed then
		if Dumpster.debug then self:Print(L.debugGbankDelayed); end
		-- we're in a loop
		if currentTab < numGuildTabs and Dumpster.guildBankTabReady then
			Dumpster:SetGuildBankTab(currentTab + 1)
			so.bag=currentTab
			dumpcount = dumpcount + Dumpster:NewDumpBag(so)
			Dumpster.guildBankTabReady = false
		end
		
		if currentTab < numGuildTabs then
			Dumpster.delayedInOut="all"
			delay = dumpcount + GUILD_BANK_TAB_DELAY
			self:ScheduleTimer("ProcessDelayed", delay, "");
		else
			Dumpster.delayedInOut="" -- we're done!
			Dumpster.guildBankTabReady = false
		end
	else
		if Dumpster.debug then self:Print(L.debugGbankFirst); end
		-- first invocation
		Dumpster.delayedSO=Dumpster:DeepCopy(so)
		Dumpster.delayedInOut="all"
		if currentTab==1 then -- we're already on first tab, so go ahead and dump it
			so.bag=currentTab
			dumpcount = dumpcount + Dumpster:NewDumpBag(so)
		else
			Dumpster:SetGuildBankTab(1) -- start at first tab
		end
		if numGuildTabs > 1 then
				delay = dumpcount + GUILD_BANK_TAB_DELAY
				self:ScheduleTimer("ProcessDelayed", delay, "");
		end
	end
	return dumpcount
end
function Dumpster:NewDumpBag(so)
 -- so.where must be declared
	local maxslots = Dumpster:getMaxSlots(so)
	if Dumpster.debug then self:Print(L.debugDumpBag(so.where,so.bag, maxslots, so.search)); end
	local dumpcount=0
	local x = maxslots -- start from the back for mail
	while (x > 0) and (so.maxcount > 0) do
		so.slot=x
		local item = Dumpster:getItemLink(so)
		if item then
			if Dumpster.superdebug then self:Print(L.debugDumpBagCheckItem(item,so.bag,so.slot)); end
			--if Dumpster:CheckSearchText(item,so) and Dumpster:CheckBindandTooltip(item,so) then
			if Dumpster:CheckSearchText(item, so) and Dumpster:CheckBindandTooltip(item, so) and Dumpster:CheckItemQuality(item, so) then
				local numinstack = Dumpster:getNumInStack(so)
				if Dumpster:checkStackFull(so,item,numinstack) then
					if so.maxcount>0 then
						if Dumpster.debug then self:Print(L.debugDumpBagDumpItem(item,so.maxcount)); end
						if not so.remain then
							dumpcount = dumpcount + 1
						end
						if not so.justcount then
							if (not so.test) and not (so.remain) then
								Dumpster:DumpItem(so)
							end
							so.maxcount = so.maxcount - 1
							if so.where=="merchant" then
								if Dumpster.debug then self:Print("AtMerchant"); end
								while so.maxcount > 0 do
									Dumpster:DumpItem(so)
									dumpcount = dumpcount + 1
									so.maxcount = so.maxcount - 1
								end
							end				
							if so.remain and so.maxcount == 0 then
								so.remain = false
								so.maxcount = 999
							end
							if (not so.countonly) and (not so.test) and (so.where=="mail") and (so.inout~="in") and (so.only or (so.maxcount > 0)) then
								Dumpster.delayedSO = Dumpster:DeepCopy(so)
								Dumpster.delayedInOut = so.inout
								self:ScheduleTimer("ProcessDelayed",MAIL_RETRY_DELAY,"");
								so.maxcount = 0 -- we can't take any more this pass
							end
						end
					else
						if Dumpster.debug then self:Print(L.debugDumpBagMax(item)); end
					end
				end
			end
		else
			if Dumpster.superdebug then self:Print(L.debugnoitem(so.where,so.bag,so.slot)); end
		end
		x = x - 1
	end
	if (so.inout == "in") then
		Dumpster:StartGuildBankQueue("give")
	else
		Dumpster:StartGuildBankQueue("take")
	end
	return dumpcount
end
function Dumpster:DumpIt(argsearch,arginout)
	-- initialize search options (so)
	local so = { search=argsearch; expansion="AllExp"; bind="bindAll"; tooltipsearch=""; stackfull=""; maxcount=999; keepmaxcount=999; inout=arginout; only=false; test=false; justcount=false; delayed=false; remain=false; except=false; stacksize=1; where=""; leftovers=""; to=""; limitcount=999 }

	Dumpster:ParseOptions(so)

	if not Dumpster:OkToDump(so) then
		self:Print(L.notsafe);
		return
	end

	if Dumpster:AtGossip() then
		if Dumpster:SelectVendor() then
			Dumpster.delayedSO=Dumpster:DeepCopy(so)
			Dumpster.delayedInOut=so.inout
		else	
			self:Print(L.novendor);
		end
	else
		Dumpster:DumpWithso(so)
	end
end
function Dumpster:DumpWithso(so)
	local dumpcount=0
	local dumploop=true
	local existingCount=0

	while dumploop do
		dumpcount=0
		if so.search=="" then return; end -- GetQualityAndBind will empty the so.search if paramters are bad

		if Dumpster.debug then self:Print(L.debugDumpIt(so.maxcount,tostring(so.expansion),so.bind,so.inout,so.search)); end

		if so.only then
			existingCount = Dumpster:GetExistingCount(so)
			so.maxcount = so.maxcount - existingCount
		else
			existingCount = 0
		end

	--	print("DumpWithso: ["..so.search.."] - ["..so.inout.."] - ["..so.where.."] - ["..Dumpster.delayedInOut.."]") 

		if so.maxcount > 0 then
			if so.inout=="all" or Dumpster.delayedInOut=="all" then
				if Dumpster:AtGuildBank() then
					dumpcount = Dumpster:DumpAllGbankTabs(so)
				else
					so.inout="out" -- pretend they used /dout since we're not at the guild bank
				end
			end
			if so.inout=="in" then
				if Dumpster:AtGuildBank() then
					so.where = "gbank"
				elseif Dumpster:AtAccountBank() then
					so.where = "abank"
				else
					so.where = "bank"
				end
				dumpcount = Dumpster:DumpIn(so)
			elseif so.inout=="out" then
				if Dumpster:AtGuildBank() then
					dumpcount = Dumpster:DumpOutCurrentGbankTab(so)
				elseif Dumpster:AtAccountBank() then
					dumpcount = Dumpster:DumpOutAccountBank(so)					
				elseif Dumpster:AtBank() then
					dumpcount = Dumpster:DumpOutAllBankBags(so)
				elseif Dumpster:AtMailInbox() then
					dumpcount = Dumpster:DumpOutAllMail(so)
				elseif Dumpster:AtMerchant() then
					dumpcount = Dumpster:DumpOutMerchant(so)
				else
					self:Print(L.notsafeout)
				end
			end
		end

		dumploop=false
		if not so.justcount then
			local colorstring=""
			if (so.maxcount==so.keepmaxcount) or (so.maxcount==so.limitcount) then	-- nothing dumped
				colorstring="|cFFEE0000"
			elseif (so.maxcount<1) or (so.keepmaxcount==999) then		-- dumped everything we asked for
				colorstring="|cFF00EE00"
			else
				colorstring="|cFF00EEEE"	-- only dumped some
			end
			if so.only then
				if Dumpster.tooltipError then self:Print(L.battlepet); end
				self:Print(L.AllExist(colorstring..tostring(dumpcount),so.search,so.keepmaxcount,existingCount));
			else
				if Dumpster.tooltipError then self:Print(L.battlepet); end
				self:Print(L.totaldumped(colorstring..tostring(dumpcount),so.search,so.keepmaxcount));
			end

			Dumpster.tooltipError = false

			if (Dumpster.delayedInOut=="") and (so.leftovers~="") then
				so.search = so.leftovers
				so.leftovers = ""
				so.maxcount=so.keepmaxcount
				so.to = "" -- only need to set this once
				Dumpster:ParseOptions(so)

				if ((dumpcount>0) and Dumpster:AtMail() and (so.inout~="in")) or (so.inout=="all") then
					Dumpster.delayedSO = Dumpster:DeepCopy(so)
					Dumpster.delayedInOut = so.inout
					self:ScheduleTimer("ProcessDelayed",MAIL_RETRY_DELAY,"");
				else
					dumploop=true
				end
			end
		end
	end

	return dumpcount
end

-- ############# addon configuration panel
function Dumpster:DumpOutAccountBank(so)
    so.where = "abank"
    local dumpcount = 0

    for _, bagID in ipairs(Dumpster.Compat:GetAccountBankContainers()) do
        so.bag = bagID
        dumpcount = dumpcount + Dumpster:NewDumpBag(so)
    end

    return dumpcount
end
