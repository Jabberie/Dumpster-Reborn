Dumpster = LibStub("AceAddon-3.0"):NewAddon("Dumpster","AceConsole-3.0","AceEvent-3.0","AceTimer-3.0")

local version = "v4.0"
local Dumpster = Dumpster
--local pt = LibStub("LibPeriodicTable-3.1", true)
--local gratuity = AceLibrary("Gratuity-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster",true)
local debug = false;
local superdebug = false;

local delayedso="";
local delayedinout="";
local delayedWaitMail=2.0;
local delayedWaitGbank=3.0;

local tt -- scanning tooltip
local panel, helppanel

-- ############# addon initialization

function Dumpster:OnInitialize() -- Called when the addon is first loaded (but not yet enabled)
	self:RegisterChatCommand("dumpster","DumpsterDump");
	self:RegisterChatCommand("din","DumpItIn");
	self:RegisterChatCommand("dout","DumpItOut");
	self:RegisterChatCommand("dall","DumpItAllOut");
	self:RegisterChatCommand("dadd","DumpSetAdd");
	self:RegisterChatCommand("ddel","DumpSetDel");
	self:RegisterChatCommand("dlist","DumpSetList");
end

function Dumpster:OnEnable(firstload) -- Called when the addon is enabled
	self:Print(L.startupmsg(version));
	-- we trap these events because other addons like Baggins hide the BankFrame and such
	self:RegisterEvent("BANKFRAME_OPENED");
	self:RegisterEvent("BANKFRAME_CLOSED");
	self:RegisterEvent("GUILDBANKFRAME_OPENED");
	self:RegisterEvent("GUILDBANKFRAME_CLOSED");
	-- don't pay attention to MAIL_SHOW because we can't tell the difference between inbox and sending
	--self:RegisterEvent("MAIL_SHOW");
	self:RegisterEvent("MAIL_CLOSED");
	self:RegisterEvent("MAIL_INBOX_UPDATE");
	self:RegisterEvent("MERCHANT_SHOW");
	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("TRADE_SHOW");
	self:RegisterEvent("TRADE_CLOSED");

	if not dumpset then
		dumpset = { }
	end

	Dumpster:SetUpInterfaceOptions()
end

function Dumpster:OnDisable() -- Called when the addon is disabled
end

-- ############# Event processing

local atBank = false
local atGuildBank = false
local atMailbox = false
local atMerchant = false
local atTrade = false

-- presumably you can't have both mail and bank open at the same time, or bank and guild bank
function Dumpster:Nowhere()
	atBank = false
	atGuildBank = false
	atMailbox = false
	atMerchant = false
	atTrade = false
end

function Dumpster:BANKFRAME_OPENED()
	Dumpster:Nowhere(); atBank=true;
	if debug then self:Print(L.debugevent("BANKFRAME_OPENED")); end
end
function Dumpster:BANKFRAME_CLOSED()
	Dumpster:Nowhere();
	if debug then self:Print(L.debugevent("BANKFRAME_CLOSED")); end
end
function Dumpster:GUILDBANKFRAME_OPENED()
	Dumpster:Nowhere(); atGuildBank=true;
	if debug then self:Print(L.debugevent("GUILDBANKFRAME_OPENED")); end
end
function Dumpster:GUILDBANKFRAME_CLOSED()
	Dumpster:Nowhere();
	if debug then self:Print(L.debugevent("GUILDBANKFRAME_CLOSED")); end
end
function Dumpster:MAIL_SHOW()
	Dumpster:Nowhere(); atMailbox=true;
	if debug then self:Print(L.debugevent("MAIL_SHOW")); end
end
function Dumpster:MAIL_CLOSED()
	Dumpster:Nowhere();
	if debug then self:Print(L.debugevent("MAIL_CLOSED")); end
end
function Dumpster:MAIL_INBOX_UPDATE()
	Dumpster:Nowhere();
	if debug then self:Print(L.debugevent("MAIL_INBOX_UPDATE")); end
end
function Dumpster:MERCHANT_SHOW()
	Dumpster:Nowhere(); atMerchant=true;
	Dumpster:ProcessDelayed();
	if debug then self:Print(L.debugevent("MERCHANT_SHOW")); end
end
function Dumpster:MERCHANT_CLOSED()
	Dumpster:Nowhere();
	if debug then self:Print(L.debugevent("MERCHANT_CLOSED")); end
end
function Dumpster:TRADE_SHOW()
	Dumpster:Nowhere(); atTrade=true;
	if debug then self:Print(L.debugevent("TRADE_SHOW")); end
end
function Dumpster:TRADE_CLOSED()
	Dumpster:Nowhere();
	if debug then self:Print(L.debugevent("TRADE_CLOSED")); end
end

function Dumpster:AtMail()
	if (MailFrame and MailFrame:IsVisible()) or (SendMailFrame and SendMailFrame:IsVisible()) then
		return true
	end
	if debug and atMailbox then self:Print(L.debugatMailboxflag); end
	return atMailbox
end

function Dumpster:AtMailInbox()
	if (MailFrame) and (MailFrame:IsVisible()) then
		if InboxPrevPageButton and InboxPrevPageButton:IsVisible() then
			return true -- we're looking at the Inbox
		else
			if debug then self:Print(L.debugatMailInbox); end
		end
	end
	if debug and atMailbox then self:Print(L.debugatMailboxflag); end
	return atMailbox
end

function Dumpster:AtMailSend()
	if SendMailFrame and SendMailFrame:IsVisible() then
		if InboxPrevPageButton and InboxPrevPageButton:IsVisible() then
			return false -- we're looking at the Inbox
		else
			if debug then self:Print(L.debugatMailSend); end
			return true
		end
	end
	if debug and atMailbox then self:Print(L.debugatMailboxflag); end
	return atMailbox
end

function Dumpster:AtGossip()
	if GossipFrame and GossipFrame:IsVisible() then
--GossipTitleButton1
		if debug then self:Print(L.debugatGossip); end
		return true
	end
	return false
end

function Dumpster:AtMerchant()
	if MerchantFrame and MerchantFrame:IsVisible() then
-- As it turns out, you can sell to the buyback page.  You shouldn't be able to, but whatever. One less test.
--		if MerchantItem1ItemButton and MerchantItem1ItemButton:IsVisible() then
			if debug then self:Print(L.debugatMerchant); end
			return true
--		end
	end
	if debug and atMerchant then self:Print(L.debugatMerchantflag); end
	return atMerchant
end

function Dumpster:AtTrade()
	if TradeFrame and TradeFrame:IsVisible() then
		if debug then self:Print(L.debugatMerchant); end
		return true
	end
	if debug and atTrade then self:Print(L.debugatTradeflag); end
	return atTrade
end

function Dumpster:AtBank()
	if BankFrame and BankFrame:IsVisible() then
		if debug then self:Print(L.debugatBank); end
		return true
	end
	if debug and atBank then self:Print(L.debugatBankflag); end
	return atBank
end

function Dumpster:AtGuildBank()
	if GuildBankFrame and GuildBankFrame:IsVisible() then
		if debug then self:Print(L.debugatGuildBank); end
		return true
	end
	if debug and atGuildBank then self:Print(L.debugatGuildBankflag); end
	return atGuildBank
end

function Dumpster:ProcessDelayed()
	if delayedinout and delayedinout~="" then
		if debug then self:Print(L.debugProcessDelayed(delayedinout,delayedso.search)); end
		delayedinout="";
		delayedso.delayed=true
		Dumpster:DumpWithso(delayedso);
	end
end

-- ############# slashcommand processing

function Dumpster:DumpsterDump(arg) -- /dumpster
	if arg=="debug" then
		if debug then
			self:Print(L.debugDisabled);
			debug=false
			superdebug=false
		else
			self:Print(L.debugEnabled);
			debug=true
			superdebug=false
		end
	elseif arg=="superdebug" then
		if superdebug then
			self:Print(L.debugSuperDisabled);
			debug=false
			superdebug=false
		else
			self:Print(L.debugSuperEnabled);
			debug=true
			superdebug=true
		end	
	elseif arg=="extrahelp" or arg=="help" then
		InterfaceOptionsFrame_OpenToCategory(Dumpster.helppanel);
	else
		-- self:Print(L.usage);
		InterfaceOptionsFrame_OpenToCategory(Dumpster.panel);
	end
end

function Dumpster:DumpItIn(search)	Dumpster:DumpIt(search,"in") end -- /din
function Dumpster:DumpItAllOut(search)	Dumpster:DumpIt(search,"all") end -- /dall
function Dumpster:DumpItOut(search)	Dumpster:DumpIt(search,"out") end -- /dout

-- ############# DumpSet functions

function Dumpster:DumpSetAdd(arrrrgs)
	local setname=arrrrgs:match("%w+")
	if setname and setname~="" then
		arrrrgs = arrrrgs:gsub(setname,"",1):gsub("  "," "):gsub("^ ",""):gsub(" $","")
		if arrrrgs and arrrrgs~="" then
			dumpset[setname]=arrrrgs
			self:Print(L.dumpsetadded(setname,arrrrgs))
			return true
		else
			self:Print(L.dumpsetempty(setname))
			return false
		end
	else
		setname=""
	end
	self:Print(L.dumpsetinvalid(setname))
end

function Dumpster:DumpSetDel(arrrrgs)
	local setname=arrrrgs:match("%w+")
	if setname and setname~="" then
		if dumpset[setname] then
			dumpset[setname]=nil
			self:Print(L.dumpsetdeleted(setname))
			return true
		end
	else
		setname=""
	end
	self:Print(L.dumpsetinvalid(setname))
end

function Dumpster:DumpSetList(arrrrgs)
	self:Print(L.dumpsetlist(#dumpset))
	local x = 0;
	table.sort(dumpset)
	for setname, setdetails in pairs(dumpset) do
		x=x+1
		self:Print(tostring(x)..". "..setname..": "..setdetails)
	end
end


-- ############# utility functions

function deepcopy(object)
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

function Dumpster:SelectVendor()
	local numgossips = GetNumGossipOptions()
	local gossips = {GetGossipOptions()}
	-- GetGossipOptions is retarded, by the way
	for x=2,numgossips*2,2 do
		if gossips[x]=="vendor" then
			if debug then self:Print(L.debugGossipOption(gossips[x-1])); end
			SelectGossipOption(x/2)
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

function Dumpster:EatTheLeftovers(so)
	local leftoverpos = so.search:find(";")
	if leftoverpos then
		if so.leftovers and so.leftovers~="" then
			so.leftovers = so.search:sub(leftoverpos+1)..";"..so.leftovers
		else
			so.leftovers = so.search:sub(leftoverpos+1)
		end
		so.search = so.search:sub(1,leftoverpos-1)
		if debug then self:Print(L.debugleftovers(so.leftovers)); end
	end
end

function Dumpster:ExpandSets(so)
	local setloop=true
	local expanded=false
	while setloop do
		Dumpster:EatTheLeftovers(so)

		local setname = so.search:gsub(" ","")
		if dumpset[setname] and dumpset[setname]~="" then
			expanded=true
			self:Print(L.dumpsetuse(setname,dumpset[setname]))
			so.search=dumpset[setname]
			if so.search:gsub(" ","")==setname then
				-- avoid this case: dumpset["shoes"]="shoes"
				-- yes, this actually occurred during testing :)
				setloop = false
			end
		else
			setloop=false
		end
	end
	return expanded
end

function Dumpster:ParseOptions(so)
--	To print out quality colors:
--	/script for x=0,6 do local r,g,b,h = GetItemQualityColor(x); w=string.sub(h,3,10); self:Print(h..x.." = "..w) end

	local setloop=true
	while setloop do
	Dumpster:ExpandSets(so)

	local maxcountString = so.search:match("%d+")
	if maxcountString and maxcountString~="" then
		local maxcount = tonumber(maxcountString)
		if maxcount then
			if debug then self:Print(L.debugnumstacks(maxcount)); end
			so.maxcount = maxcount
			so.keepmaxcount = maxcount
			so.search = so.search:gsub("%d+"," ")
		end
	end
	so.limitcount=so.keepmaxcount
	if so.inout=="in" and Dumpster:AtTrade() and so.maxcount>6 then
		if debug then self:Print(L.debugnumstacks6); end
		so.maxcount=6
		so.limitcount=6
	end
	if so.inout=="in" and Dumpster:AtMail() and so.maxcount>12 then
		if debug then self:Print(L.debugnumstacks12); end
		so.maxcount=12
		so.limitcount=12
	end

	local boolFlags = { only="only", test="test", remain="remain", except="except" }
	local parameterFlags = { tooltipsearch="tooltipsearch", tooltip="tooltipsearch", to="to", t="tooltipsearch" }
	local multiFlags = {
		bind = { account="bindBOA", use="bindBOU", equip="bindBOE", pickup="bindBOP", 
		boa="bindBOA", bou="bindBOU", boe="bindBOE", bop="bindBOP",
		soulbound="soulbound", sb="soulbound", nb="notbound", notbound="notbound" },
		quality = { poor=0, common=1, uncommon=2, rare=3, epic=4, legendary=5, artifact=6, 
		grey=0, gray=0, white=1, green=2, blue=3, purple=4, orange=5, red=6 },
		stackfull = { full="full", partial="partial" }
		}
		


	if debug then self:Print(L.debugSearch(so.search)); end
	so.search = so.search:lower():gsub("  "," ")
	so.search = so.search:gsub("^ ",""):gsub(" $","")
	if debug then self:Print(L.debugSearch(so.search)); end

	local flag=""
	local flagsearch=""
	local flagvalues=""
	local flagtoken=""
	local flagpos=0
	local flagendpos=0
	local flagmatch=""

	-- parse boolean flags
	for flag in pairs(boolFlags) do
		if so.search:find("/"..flag) then
			if debug then self:Print(L.debugfoundflag(flag)); end
			so[flag]=true

			-- strip out /flag
			so.search = so.search:gsub("/"..flag,""):gsub("  "," ")
			if debug then self:Print(L.debugSearch(so.search)); end
		end
	end

	-- parse multivalue flags
	for flag, flagvalues in pairs(multiFlags) do
		for flagsearch, flagtoken in pairs(flagvalues) do
			if so.search:find("/"..flagsearch) then
				if debug then self:Print(L.debugfoundflag(flag.."="..flagtoken)); end
				so[flag]=flagtoken

				-- strip out /flag
				so.search = so.search:gsub("/"..flagsearch,""):gsub("  "," ")
				if debug then self:Print(L.debugSearch(so.search)); end
			end
		end
	end

	-- parse flags that take a parameter
	for flagsearch,flag in pairs(parameterFlags) do
		flagpos=so.search:find("/"..flagsearch)
		if flagpos and flagpos>0 then
			if debug then self:Print(L.debugfoundflag(flag)); end
			flagtoken=so.search:sub(flagpos+flagsearch:len()+1)
			if debug then self:Print(L.debugflagtoken(flagtoken)); end

			-- /flag token /anotherflag
			flagendpos=flagtoken:find("/")
			if flagendpos and flagendpos>0 then
				flagtoken=flagtoken:sub(1,flagendpos-1)
				if debug then self:Print(L.debugflagtoken(flagtoken)); end
			end

			-- /flag "token" somethingelse
			flagmatch=flagtoken:match("\"[^\"]+\"")
			if flagmatch and flagmatch~="" then
				flagtoken=flagmatch
				if debug then self:Print(L.debugflagtoken(flagtoken)); end
			else
				-- /flag token somethingelse
				-- Thanks neevor
				-- match "-" to, for mailing merged realms, but affects other tokens as well
				   flagmatch=flagtoken:match("%w+%-?%w+")  -- new code
				-- flagmatch=flagtoken:match("%w+") -- commented out old code
				if flagmatch and flagmatch~="" then
					flagtoken=flagmatch
					if debug then self:Print(L.debugflagtoken(flagtoken)); end
				end
			end

			-- strip out /flag flagtoken
			flagendpos=so.search:find(flagtoken,flagpos,true)
			so.search=so.search:sub(1,flagpos-1)..so.search:sub(flagendpos+flagtoken:len()+1)
			if debug then self:Print(L.debugSearch(so.search)); end

			flagtoken=flagtoken:gsub("\"",""):gsub("  "," ")
			so[flag]=flagtoken
		end
	end

	-- Whatever's left should be the search text
	
	so.search = so.search:gsub("^ ",""):gsub(" $","")
	if debug then self:Print(L.debugSearch(so.search)); end

	local qualitynumber=tonumber(so.quality)
	if qualitynumber and qualitynumber<7 and qualitynumber>-1 then
		local r,g,b,hex=GetItemQualityColor(qualitynumber)
		so.search = hex..".+"..so.search
	end

	if debug then 
		local key=""
		local value=""
		for key, value in pairs(so) do
			if type(value)~=string then
				value=tostring(value)
			end
			self:Print(L.debugParseResults(key,value))
		end
	end
	if (not so.search) or (so.search=="") or (so.search==" ") then
		if so.bind=="bindAll" and (so.tooltipsearch:gsub(" ","")=="") then
			self:Print(L.nothingtodump);
			so.search=""
		else
			so.search="." -- they specified a qualifier but not a text
		end
	end
	setloop=Dumpster:ExpandSets(so)
	end
	so.search = so.search:gsub("%-","%%%-")
	so.tooltipsearch = so.tooltipsearch:gsub("%-","%%%-")
end

function Dumpster:GetTooltipFromItem(item,so)
	DumpsterScanningTooltip:ClearLines()
	if so.where=="bank" then
		DumpsterScanningTooltip:SetBagItem(so.bag,so.slot)
	elseif so.where=="gbank" then
		DumpsterScanningTooltip:SetGuildBankItem(so.bag,so.slot)
	elseif so.where=="mail" then
		DumpsterScanningTooltip:SetInboxItem(so.bag,so.slot)
	elseif so.where=="merchant" then
		DumpsterScanningTooltip:SetMerchantItem(so.slot)
	else
		DumpsterScanningTooltip:SetHyperlink(item)
	end

	if DumpsterScanningTooltip:NumLines()==0 then
		if superdebug then self:Print(L.debugTooltipFailed(so.where,so.bag,so.slot)); end
		DumpsterScanningTooltip:SetHyperlink(item)
	end

	local mytext
	local text=""
	for i=1,DumpsterScanningTooltip:NumLines() do
		mytext = _G["DumpsterScanningTooltipTextLeft" .. i]:GetText()
		if mytext then
			if superdebug then self:Print(i.."L: "..mytext); end
			text = text .. mytext
		end
		mytext = _G["DumpsterScanningTooltipTextRight" .. i]:GetText()
		if mytext then
			if superdebug then self:Print(i.."R: "..mytext); end
			text = text .. mytext
		end
	end
	return text
end

function Dumpster:CheckBindandTooltip(item,so)
	local tooltip=""

	if so.bind=="notbound" then
		tooltip=Dumpster:GetTooltipFromItem(item,so)
		if debug then self:Print(L.debugTooltip(tooltip)); end
		if tooltip:lower():find(L.bindBound:lower()) then
			if not so.except then
				if superdebug then self:Print(L.debugTooltipBindFail(so.bind,L.bindBound)); end
				return false
			end
		else
			if so.except then
				if superdebug then self:Print(L.debugTooltipBindFail(so.bind,L.bindBound)); end
				return false
			end
		end
	elseif so.bind~="bindAll" then
		tooltip=Dumpster:GetTooltipFromItem(item,so)
		if debug then self:Print(L.debugTooltip(tooltip)); end
		if not tooltip:lower():find(L[so.bind]:lower()) then
			if not so.except then
				if superdebug then self:Print(L.debugTooltipBindFail(so.bind,L[so.bind])); end
				return false
			end
		else
			if so.except then
				if superdebug then self:Print(L.debugTooltipBindFail(so.bind,L[so.bind])); end
				return false
			end
		end
	end

	if so.tooltipsearch and so.tooltipsearch~="" then
		if tooltip=="" then
			tooltip=Dumpster:GetTooltipFromItem(item,so)
			if debug then self:Print(L.debugTooltip(tooltip)); end
		end
		if not tooltip:lower():find(so.tooltipsearch:lower()) then
			if superdebug then self:Print(L.debugTooltipFail(so.tooltipsearch)); end
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
	local name, link, quality, iLevel, reqLevel, itemtype, subType, maxStack, equipSlot, itemtexture = GetItemInfo(item)
	return maxStack
end

function Dumpster:checkStackFull(so,item,count)
	if (not so.stackfull) or (so.stackfull=="") then
		if superdebug then self:Print(L.debugNoStackFull); end
		return true
	end
	maxStack = Dumpster:getMaxStack(item)
	if superdebug then self:Print(L.debugStackFullcheckmatch(maxStack,count)); end
	if so.stackfull=="full" then
		return (maxStack==count)
	elseif so.stackfull=="partial" then
		return not (maxStack==count)
	else
		if debug then self:Print(L.debugInvalidStackFull(so.stackfull)); end
	end
	return false
end

function Dumpster:GetExistingCount(originalso)
	local checkso=deepcopy(originalso)

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
	if debug then self:Print(L.debugExistingCount(dumpcount)); end
	return dumpcount
end

function Dumpster:getMaxBags(so)
	if so.where=="bank" then
		return GetNumBankSlots()
	elseif so.where=="gbank" then
		return GetNumGuildBankTabs()
	elseif so.where=="mail" then
		return GetInboxNumItems()
	elseif so.where=="merchant" then
		return 1
	else
		return 0
	end
end

function Dumpster:getMaxSlots(so)
	if so.where=="bank" then
		return GetContainerNumSlots(so.bag)
	elseif so.where=="gbank" then
		return 98
	elseif so.where=="mail" then
--		local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated, canReply, isGM, itemQuantity = GetInboxHeaderInfo(so.bag)
--		if itemCount then return itemCount else return 0 end
		return 12 -- hardcode this because we need to check all slots, not 1..itemCount like you would think
	elseif so.where=="merchant" then
		return GetMerchantNumItems()
	else
		return 0
	end
end

function Dumpster:getItemLink(so)
	if so.where=="bank" then
		return GetContainerItemLink(so.bag, so.slot)
	elseif so.where=="gbank" then
		return GetGuildBankItemLink(so.bag, so.slot)
	elseif so.where=="mail" then
		return GetInboxItemLink(so.bag, so.slot)
	elseif so.where=="merchant" then
		return GetMerchantItemLink(so.slot)
	else
		return nil
	end
end

function Dumpster:getNumInStack(so)
	if so.where=="bank" then
		local texture, count, locked, quality, readable = GetContainerItemInfo(so.bag, so.slot)
		if count then return count else return 1 end
	elseif so.where=="gbank" then
		local texture, count, locked = GetGuildBankItemInfo(so.bag, so.slot)
		if count then return count else return 1 end
	elseif so.where=="mail" then
		local name, itemTexture, count, quality, canUse = GetInboxItem(so.bag, so.slot)
		if count then return count else return 1 end
	elseif so.where=="merchant" then
		local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(so.slot)
		if quantity then return quantity else return 1 end
	else
		return 1
	end
end

function Dumpster:DumpItem(so)
	if so.where=="bank" then
		UseContainerItem(so.bag,so.slot)
	elseif so.where=="gbank" then
		AutoStoreGuildBankItem(so.bag, so.slot)
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
	so.where="bank"

	-- Dump main bag
	so.bag = BANK_CONTAINER; -- BANK_CONTAINER = -1
	local dumpcount = Dumpster:NewDumpBag(so);
	
	-- Dump purchaseable bags
	local numBankBags = GetNumBankSlots()
	if debug then self:Print(L.debugNumBankBags(numBankBags));end

	if numBankBags>0 then
		local x
		for x=(NUM_BAG_SLOTS+1), ((NUM_BAG_SLOTS+1)+numBankBags-1) do
			so.bag=x
			dumpcount = dumpcount + Dumpster:NewDumpBag(so)
		end
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
	so.where="bank"
	local dumpcount = 0
	local x
	for x = 0, NUM_BAG_SLOTS do
		so.bag = x
		dumpcount = dumpcount + Dumpster:NewDumpBag(so)
	end
	if Dumpster:AtMailSend() and so.to~="" then
		SendMailNameEditBox:SetText(so.to)
		SendMailSubjectEditBox:SetFocus()
	end
	return dumpcount
end

function Dumpster:DumpAllGbankTabs(so)
	so.where = "gbank"
	local numGuildTabs = GetNumGuildBankTabs()
	local currentTab = GetCurrentGuildBankTab()
	local dumpcount = 0
	if so.delayed then
		if debug then self:Print(L.debugGbankDelayed); end
		-- we're in a loop
		so.bag=currentTab
		dumpcount = Dumpster:NewDumpBag(so)
		if currentTab < numGuildTabs then
			delayedinout=so.inout
			SetCurrentGuildBankTab(currentTab+1)
			self:ScheduleTimer("ProcessDelayed",delayedWaitGbank,"");
		else
			delayedinout="" -- we're done!
		end
	else
		if debug then self:Print(L.debugGbankFirst); end
		-- first invocation
		delayedso=deepcopy(so)
		delayedinout=so.inout
		if currentTab==1 then
			-- we're already on first tab, so go ahead and dump it
			so.bag=currentTab
			dumpcount = dumpcount + Dumpster:NewDumpBag(so)
			if numGuildTabs > 1 then
				SetCurrentGuildBankTab(2)
				-- we'll reenter the loop
			end
		else
			-- start at first tab
			SetCurrentGuildBankTab(1)
		end
		if numGuildTabs > 1 then
				self:ScheduleTimer("ProcessDelayed",delayedWaitGbank,"");
		end
	end
	return dumpcount
end

function Dumpster:NewDumpBag(so)
-- so.where must be declared

	local maxslots = Dumpster:getMaxSlots(so)
	if debug then self:Print(L.debugDumpBag(so.where,so.bag, maxslots, so.search)); end
	local dumpcount=0
	local x = maxslots -- start from the back for mail
	while (x > 0) and (so.maxcount > 0) do
		so.slot=x
		local item = Dumpster:getItemLink(so)
		if item then
			if superdebug then self:Print(L.debugDumpBagCheckItem(item,so.bag,so.slot)); end
			if Dumpster:CheckSearchText(item,so) and Dumpster:CheckBindandTooltip(item,so) then
				local numinstack = Dumpster:getNumInStack(so)
				if Dumpster:checkStackFull(so,item,numinstack) then
					if so.maxcount>0 then
						if debug then self:Print(L.debugDumpBagDumpItem(item,so.maxcount));end
						if not so.remain then
							dumpcount = dumpcount + 1
						end
						if not so.justcount then
							if (not so.test) and not (so.remain) then
								Dumpster:DumpItem(so)
							end
							so.maxcount = so.maxcount - 1
							if so.where=="merchant" then
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
								delayedso = deepcopy(so)
								delayedinout = so.inout
								self:ScheduleTimer("ProcessDelayed",delayedWaitMail,"");
								so.maxcount = 0 -- we can't take any more this pass
							end
						end
					else
						if debug then self:Print(L.debugDumpBagMax(item)); end
					end
				end
			end
		else
			if superdebug then self:Print(L.debugnoitem(so.where,so.bag,so.slot)); end
		end
		x = x - 1
	end
	return dumpcount
end

function Dumpster:DumpIt(argsearch,arginout)
	-- initialize search options (so)
	local so = { search=argsearch; bind="bindAll"; tooltipsearch=""; stackfull=""; maxcount=999; keepmaxcount=999; inout=arginout; only=false; test=false; justcount=false; delayed=false; remain=false; except=false; stacksize=1; where=""; leftovers=""; to=""; limitcount=999 }

	Dumpster:ParseOptions(so)

	if not Dumpster:OkToDump(so) then
		self:Print(L.notsafe);
		return
	end

	if Dumpster:AtGossip() then
		if Dumpster:SelectVendor() then
			delayedso=deepcopy(so)
			delayedinout=so.inout
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


	if debug then self:Print(L.debugDumpIt(so.maxcount,so.bind,so.inout,so.search)); end

	if so.only then
		existingCount = Dumpster:GetExistingCount(so)
		so.maxcount = so.maxcount - existingCount
	else
		existingCount = 0
	end

	if so.maxcount > 0 then
		if so.inout=="all" then
			if Dumpster:AtGuildBank() then
				dumpcount = Dumpster:DumpAllGbankTabs(so)
			else
				so.inout="out" -- pretend they used /dout since we're not at the guild bank
			end
		end
		if so.inout=="in" then
			dumpcount = Dumpster:DumpIn(so)
		elseif so.inout=="out" then
			if Dumpster:AtGuildBank() then
				dumpcount = Dumpster:DumpOutCurrentGbankTab(so)
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
			self:Print(L.AllExist(colorstring..tostring(dumpcount),so.search,so.keepmaxcount,existingCount));
		else
			self:Print(L.totaldumped(colorstring..tostring(dumpcount),so.search,so.keepmaxcount));
		end

		if (delayedinout=="") and (so.leftovers~="") then
			so.search = so.leftovers
			so.leftovers = ""
			so.maxcount=so.keepmaxcount
			so.to = "" -- only need to set this once
			Dumpster:ParseOptions(so)

			if ((dumpcount>0) and Dumpster:AtMail() and (so.inout~="in")) or (so.inout=="all") then
				delayedso = deepcopy(so)
				delayedinout = so.inout
				self:ScheduleTimer("ProcessDelayed",delayedWaitMail,"");
			else
				dumploop=true
			end
		end
	end

	end

	return dumpcount
end

-- ############# addon configuration panel
function Dumpster:showHelpPanel()
	local frame = Dumpster.helppanel

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
        title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
        title:SetJustifyH("LEFT")
        title:SetJustifyV("TOP")
        title:SetText("Dumpster Usage")
	
	local mainhelp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainhelp:SetPoint("TOP", title, "BOTTOM", 0, -10)
        mainhelp:SetPoint("LEFT", frame, "LEFT", 10, 0)
        mainhelp:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        mainhelp:SetJustifyH("LEFT")
        mainhelp:SetJustifyV("TOP")
        mainhelp:SetText(L.extrahelp)

	frame:SetScript("OnShow", nil)
end

function Dumpster:showPanel()
	local frame = Dumpster.panel
	local dropdown, editbox, newbutt, delbutt, helpbutt
	local selected

	local function updatewithset(setname)
		UIDropDownMenu_SetSelectedValue(dropdown,setname)
		editbox:SetText(dumpset[setname])
	end

	local function focuslost()
		local text = editbox:GetText()
		if selected and selected~="" then
			dumpset[selected] = text
		end
	end

	local function dropdown_onclick(this)
		focuslost()
		selected = this.value
		updatewithset(selected)
	end

	local function initdropdown()
		local info = UIDropDownMenu_CreateInfo()
		for setname, settext in pairs(dumpset) do
			info.text = setname
			info.func = dropdown_onclick
			info.value = setname
			info.checked = false
			UIDropDownMenu_AddButton(info)
		end
	end

	StaticPopupDialogs["DUMPSTER_HELP"] = {
  		text = L.extrahelp,
  		button1 = OKAY,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	};

	StaticPopupDialogs["DUMPSTER_GETNEWSET"] = {
  		text = "New set name?",
  		button1 = OKAY,
  		button2 = CANCEL,
  		OnAccept = function(self)
			local newname = self.editBox:GetText()
			dumpset[newname]=""
			local info = UIDropDownMenu_CreateInfo()
			info.text = newname
			info.func = dropdown_onclick
			info.value = newname
			info.checked = false
			UIDropDownMenu_AddButton(info)
  		end,
		timeout = 0,
		whileDead = 1,
		hasEditBox = 1,
		hideOnEscape = 1
	};

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
        title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
        title:SetJustifyH("LEFT")
        title:SetJustifyV("TOP")
        title:SetText("Dumpster")


	local dropdownlabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropdownlabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        dropdownlabel:SetText("Set")
        dropdownlabel:SetHeight(15)
        dropdownlabel:SetWidth(20)

	dropdown = CreateFrame("Frame", "DumpsterDropDown", frame, "UIDropDownMenuTemplate")
        dropdown:EnableMouse(true)
        dropdown:SetPoint("TOPLEFT", dropdownlabel, "TOPRIGHT")
        UIDropDownMenu_Initialize(dropdown, initdropdown)
	for k, v in pairs(dumpset) do
		selected = k
	end
        UIDropDownMenu_SetSelectedValue(dropdown, selected)
        UIDropDownMenu_SetWidth(dropdown, 160)
        UIDropDownMenu_JustifyText(dropdown, "LEFT")
	DumpsterDropDownLeft:SetHeight(50)
        DumpsterDropDownMiddle:SetHeight(50)
        DumpsterDropDownRight:SetHeight(50)
        DumpsterDropDownButton:SetPoint("TOPRIGHT", DumpsterDropDownRight, "TOPRIGHT", -16, -12)

	newbutt =  CreateFrame("Button","DumpsterNewButton",frame,"UIPanelButtonTemplate")
        newbutt:SetText("New")
        newbutt:SetWidth(80)
        newbutt:SetPoint("TOPLEFT", dropdown, "TOPRIGHT", 0, 5)
        newbutt:SetScript("OnClick", function()
		focuslost()
		StaticPopup_Show("DUMPSTER_GETNEWSET");
		selected=nil
		UIDropDownMenu_ClearAll(dropdown) 
        	editbox:SetText("")
        end)

	delbutt =  CreateFrame("Button","DumpsterDelButton",frame,"UIPanelButtonTemplate")
        delbutt:SetText("Delete")
        delbutt:SetWidth(80)
        delbutt:SetPoint("TOPLEFT", newbutt, "TOPRIGHT", 0, 0)
        delbutt:SetScript("OnClick", function()
		dumpset[selected] = nil
		selected=nil
		UIDropDownMenu_ClearAll(dropdown) 
        end)

	helpbutt =  CreateFrame("Button","DumpsterHelpButton",frame,"UIPanelButtonTemplate")
        helpbutt:SetText("Help")
        helpbutt:SetWidth(80)
        helpbutt:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        helpbutt:SetScript("OnClick", function()
		-- StaticPopup_Show("DUMPSTER_HELP");
		InterfaceOptionsFrame_OpenToCategory(Dumpster.helppanel);
        end)


	editbox = CreateFrame("EditBox", "DumpsterEditBox", frame)
        editbox:SetPoint("TOP", dropdown, "BOTTOM")
        editbox:SetPoint("LEFT", 5, 0)
        editbox:SetPoint("BOTTOMRIGHT", -5, 5)
        editbox:SetFontObject(GameFontNormal)
        editbox:SetTextColor(.8,.8,.8)
        editbox:SetTextInsets(8,8,8,8)
        editbox:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 16,
                insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        editbox:SetBackdropColor(.1,.1,.1,.3)
        editbox:SetBackdropBorderColor(.5,.5,.5)
        editbox:SetMultiLine(true)
        editbox:SetAutoFocus(false)
	if selected and selected~="" then
        	editbox:SetText(dumpset[selected])
	end
	
        editbox:SetScript("OnEditFocusLost", focuslost)
        editbox:SetScript("OnEscapePressed", editbox.ClearFocus)

	frame:SetScript("OnShow", nil)
end

function Dumpster:SetUpInterfaceOptions()
	Dumpster.panel = CreateFrame("FRAME", "DumpsterPanel", UIParent)
	Dumpster.panel.name = "Dumpster "..version
	-- Dumpster.panel.parent = ""
	Dumpster.panel:SetScript("OnShow",Dumpster.showPanel)
	InterfaceOptions_AddCategory(Dumpster.panel)

	Dumpster.helppanel = CreateFrame("FRAME", "DumpsterPanel", UIParent)
	Dumpster.helppanel.name = "Usage"
	Dumpster.helppanel.parent = Dumpster.panel.name
	Dumpster.helppanel:SetScript("OnShow",Dumpster.showHelpPanel)
	InterfaceOptions_AddCategory(Dumpster.helppanel)
end
