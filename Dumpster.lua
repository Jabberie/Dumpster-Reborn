
local Dumpster = Dumpster
--local pt = LibStub("LibPeriodicTable-3.1", true)
--local gratuity = AceLibrary("Gratuity-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster",true)
-- Debug flags are shared through Dumpster so split modules see the same state.






--  ########################################################

function Dumpster:AtAccountBank()
    if Dumpster.Compat:IsAccountBankVisible() then
        if Dumpster.debug then self:Print(L.debugatAccountBank) end
        return true
    end

    if Dumpster.debug and Dumpster.atAccountBank then self:Print(L.debugatAccountBankflag) end
    return Dumpster.atAccountBank
end

-- ############# Event processing

local atBank = false
local atGuildBank = false
Dumpster.atAccountBank = false
local atMailbox = false
local atMerchant = false
local atTrade = false

-- presumably you can't have both mail and bank open at the same time, or bank and guild bank
function Dumpster:Nowhere()
	atBank = false
	atGuildBank = false
	Dumpster.atAccountBank = false
	atMailbox = false
	atMerchant = false
	atTrade = false
end

function Dumpster:BANKFRAME_OPENED()
	Dumpster:Nowhere(); atBank=true;
	if Dumpster.debug then self:Print(L.debugevent("BANKFRAME_OPENED")); end
end

function Dumpster:BANKFRAME_CLOSED()
	Dumpster:Nowhere();
	if Dumpster.debug then self:Print(L.debugevent("BANKFRAME_CLOSED")); end
end

function Dumpster:GUILDBANKFRAME_OPENED()
	Dumpster:Nowhere(); atGuildBank=true;
	if Dumpster.debug then self:Print(L.debugevent("GUILDBANKFRAME_OPENED")); end	
end

function Dumpster:GUILDBANKFRAME_CLOSED()
	Dumpster:Nowhere();
	if Dumpster.debug then self:Print(L.debugevent("GUILDBANKFRAME_CLOSED")); end
end

function Dumpster:MAIL_SHOW()
	Dumpster:Nowhere(); atMailbox=true;
	if Dumpster.debug then self:Print(L.debugevent("MAIL_SHOW")); end
end

function Dumpster:MAIL_CLOSED()
	Dumpster:Nowhere();
	if Dumpster.debug then self:Print(L.debugevent("MAIL_CLOSED")); end
end

function Dumpster:MAIL_INBOX_UPDATE()
	Dumpster:Nowhere();
	if Dumpster.debug then self:Print(L.debugevent("MAIL_INBOX_UPDATE")); end
end

function Dumpster:MERCHANT_SHOW()
	Dumpster:Nowhere(); atMerchant=true;
	Dumpster:ProcessDelayed();
	if Dumpster.debug then self:Print(L.debugevent("MERCHANT_SHOW")); end
end

function Dumpster:MERCHANT_CLOSED()
	Dumpster:Nowhere();
	if Dumpster.debug then self:Print(L.debugevent("MERCHANT_CLOSED")); end
end

function Dumpster:TRADE_SHOW()
	Dumpster:Nowhere(); atTrade=true;
	if Dumpster.debug then self:Print(L.debugevent("TRADE_SHOW")); end
end

function Dumpster:TRADE_CLOSED()
	Dumpster:Nowhere();
	if Dumpster.debug then self:Print(L.debugevent("TRADE_CLOSED")); end
end

function Dumpster:AtMail()
	if (MailFrame and MailFrame:IsVisible()) or (SendMailFrame and SendMailFrame:IsVisible()) then
		return true
	end
	if Dumpster.debug and atMailbox then self:Print(L.debugatMailboxflag); end
	return atMailbox
end

function Dumpster:AtMailInbox()
	if (MailFrame) and (MailFrame:IsVisible()) then
		if InboxPrevPageButton and InboxPrevPageButton:IsVisible() then
			return true -- we're looking at the Inbox
		else
			if Dumpster.debug then self:Print(L.debugatMailInbox); end
		end
	end
	if Dumpster.debug and atMailbox then self:Print(L.debugatMailboxflag); end
	return atMailbox
end

function Dumpster:AtMailSend()
	if SendMailFrame and SendMailFrame:IsVisible() then
		if InboxPrevPageButton and InboxPrevPageButton:IsVisible() then
			return false -- we're looking at the Inbox
		else
			if Dumpster.debug then self:Print(L.debugatMailSend); end
			return true
		end
	end
	if Dumpster.debug and atMailbox then self:Print(L.debugatMailboxflag); end
	return atMailbox
end

function Dumpster:AtGossip()
	if GossipFrame and GossipFrame:IsVisible() then
		--GossipTitleButton1
		if Dumpster.debug then self:Print(L.debugatGossip); end
		return true
	end
	return false
end

function Dumpster:AtMerchant()
	if MerchantFrame and MerchantFrame:IsVisible() then
 -- As it turns out, you can sell to the buyback page.  You shouldn't be able to, but whatever. One less test.
 --		if MerchantItem1ItemButton and MerchantItem1ItemButton:IsVisible() then
			if Dumpster.debug then self:Print(L.debugatMerchant); end
			return true
 --		end
	end
	if Dumpster.debug and atMerchant then self:Print(L.debugatMerchantflag); end
	return atMerchant
end

function Dumpster:AtTrade()
	if TradeFrame and TradeFrame:IsVisible() then
		if Dumpster.debug then self:Print(L.debugatMerchant); end
		return true
	end
	if Dumpster.debug and atTrade then self:Print(L.debugatTradeflag); end
	return atTrade
end

function Dumpster:AtBank()
	if BankFrame and BankFrame:IsVisible() then
		if Dumpster.debug then self:Print(L.debugatBank); end
		return true
	end
	if Dumpster.debug and atBank then self:Print(L.debugatBankflag); end
	return atBank
end

function Dumpster:AtGuildBank()
	if Dumpster.Compat:IsGuildBankVisible() then
		if Dumpster.debug then self:Print(L.debugatGuildBank); end
		return true
	end
	if Dumpster.debug and atGuildBank then self:Print(L.debugatGuildBankflag); end
	return atGuildBank
end

function Dumpster:ProcessDelayed()
	if Dumpster.delayedInOut and Dumpster.delayedInOut~="" then
		if Dumpster.debug then self:Print(L.debugProcessDelayed(Dumpster.delayedInOut,Dumpster.delayedSO.search)); end
	--	Dumpster.delayedInOut="";
		Dumpster.delayedSO.delayed=true
		Dumpster.guildBankTabReady = true
		Dumpster:DumpWithso(Dumpster.delayedSO);
	end
end


-- ############# slashcommand processing

function Dumpster:DeepCopy(object)
 -- taken from http://lua-users.org/wiki/CopyTable
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

