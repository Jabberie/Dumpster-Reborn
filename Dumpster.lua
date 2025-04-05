Dumpster = LibStub("AceAddon-3.0"):NewAddon("Dumpster","AceConsole-3.0","AceEvent-3.0","AceTimer-3.0")

local categoryDumpster, layoutDumpster -- neevor: Settings fix 11.x.x
local categoryHelp, layoutHelp -- neevor: Settings fix 11.x.x

local version = "v12"
local Dumpster = Dumpster
--local pt = LibStub("LibPeriodicTable-3.1", true)
--local gratuity = AceLibrary("Gratuity-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster",true)
local debug = false;
--local debug = true;
local superdebug = false;

local delayedso="";
local delayedinout="";
local delayedWaitMail=0.5;
local delayedWaitGbank=3.0;

local tt -- scanning tooltip
local panel, helppanel

local changeGuildTab = false
local tooltipError = false

local DumpsterGuildBank = ...
local lower, gsub = string.lower, string.gsub

local SetGuildBankTab
local clickFunctions = {
	function() GuildBankTab1Button:Click() end,
	function() GuildBankTab2Button:Click() end,
	function() GuildBankTab3Button:Click() end,
	function() GuildBankTab4Button:Click() end,
	function() GuildBankTab5Button:Click() end,
	function() GuildBankTab6Button:Click() end,
	function() GuildBankTab7Button:Click() end
}

SetGuildBankTab = function(tab)
	local func = clickFunctions[tab]
	if func then
		return func()
	else
		error(string.format("Tab %s cannot be clicked!", tab), 2)
	end
end

-- ############# what version are we in? 

Dumpster.WOWClassic = false
Dumpster.WOWBCClassic = false
Dumpster.WOWWotLKClassic = false
Dumpster.WOWCataClassic = false
Dumpster.WOWRetail = false

if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC then Dumpster.WOWClassic = true end
if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC then Dumpster.WOWBCClassic = true end
if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC then Dumpster.WOWWotLKClassic = true end
if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC then Dumpster.WOWCataClassic = true end
if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then Dumpster.WOWRetail = true end

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
	-- self:Print(L.startupmsg(version));
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

-- standard output
local log = function(msg)
	print("|cff33FF99Dumpster GB: |r"..msg)
end

-- create frame for gui and event handling
local DumpsterGuildFrame = CreateFrame("frame","DumpsterGuildFrame",UIParent)
DumpsterGuildFrame:SetFrameStrata("background")
DumpsterGuildFrame:SetWidth(1)
DumpsterGuildFrame:SetHeight(1)
DumpsterGuildFrame:SetClampedToScreen(true)
DumpsterGuildFrame:SetPoint("CENTER",0,0)
DumpsterGuildFrame:RegisterEvent("GUILDBANKFRAME_OPENED")
DumpsterGuildFrame:RegisterEvent("GUILDBANKFRAME_CLOSED")
DumpsterGuildFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
DumpsterGuildFrame:RegisterEvent("GUILDBANKFRAME_CLOSED")
DumpsterGuildFrame:RegisterEvent("ADDON_LOADED")
DumpsterGuildFrame:Hide()

-- event handling
DumpsterGuildFrame:SetScript("OnEvent",function(s,e,a)
	if e == "ADDON_LOADED" and a == "Dumpster" then
		DumpsterGuildFrame:UnregisterEvent("ADDON_LOADED")
	elseif e == "GUILDBANKFRAME_OPENED" then
		DumpsterGuildFrame:Show()
	elseif e == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
		DumpsterGuildFrame:Show()		
	elseif e == "GUILDBANKFRAME_CLOSED" then
		DumpsterGuildFrame:SetScript("OnUpdate",nil)
		DumpsterGuildFrame:Hide()
	end
end)

local function IsGuildBankFrameOpen()

	local IsGuildBankFrameOpen = false 

	if debug then print("IsGuildBankFrameOpen is set to " .. IsGuildBankFrameOpen) end	

	IsGuildBankFrameOpen = ((GuildBankFrame and GuildBankFrame:IsVisible()) or Baganator_SingleViewGuildViewFrame:IsVisible())

-- /run print(Baganator_SingleViewGuildViewFrame:IsVisible())

	if debug then print("IsGuildBankFrameOpen is set to " .. IsGuildBankFrameOpen) end

    return IsGuildBankFrameOpen
end



-- Guild throttling workaround
DumpsterQueue = {}
guildbank_queue = function(movementtype)
    wait = 0.5
    elapsed = 0
    maytake = true
    DumpsterGuildFrame:SetScript("OnUpdate", function(self, e)
        if maytake then
            elapsed = elapsed + e
            if movementtype == "give" then delay = 2 * wait else delay = wait end
            if elapsed > delay and maytake then
                maytake = false
                elapsed = 0

                -- Check if the guild bank is still open
                if not IsGuildBankFrameOpen() then
                    DumpsterGuildFrame:SetScript("OnUpdate", nil)
                    changeGuildTab = true
                    if debug then log("Queue Aborted: Guild Bank Closed") end
                    return
                end

                if DumpsterQueue[1] then -- as moved items' table entries are removed rather than set to nil, we simply need to check if the first entry exists
                    if debug then print(DumpsterQueue[1][1] .. ", " .. DumpsterQueue[1][2]) end
                    if movementtype == "take" then
                        AutoStoreGuildBankItem(DumpsterQueue[1][1], DumpsterQueue[1][2])
                    else -- give
                        C_Container.UseContainerItem(DumpsterQueue[1][1], DumpsterQueue[1][2]) -- neevor 12/15/2022
                    end
                    tremove(DumpsterQueue, 1)
                    maytake = true
                else
                    DumpsterGuildFrame:SetScript("OnUpdate", nil)
                    changeGuildTab = true
                    if debug then log("Queue Completed") end
                end
            end
        end
    end)
end

--  ########################################################

local function IsAccountBankPanelOpen()
    return (BankFrame and BankFrame:IsVisible() or Baganator_SingleViewBankViewFrameblizzard and Baganator_SingleViewBankViewFrameblizzard:IsVisible()) and BankFrame:GetActiveBankType() == Enum.BankType.Account
end

function Dumpster:AtAccountBank()
	if debug then self:Print("Checking AtAccountBank"); end
	if ((BankFrame and BankFrame:IsVisible() or Baganator_SingleViewBankViewFrameblizzard and Baganator_SingleViewBankViewFrameblizzard:IsVisible()) and BankFrame:GetActiveBankType() == Enum.BankType.Account) then
		if debug then self:Print(L.debugatAccountBank); end
		return true
	end
	if debug and atAccountBank then self:Print(L.debugatAccountBankflag); end
	return AtAccountBank
end

-- ############# Event processing

local atBank = false
local atGuildBank = false
local atAccountBank = false
local atMailbox = false
local atMerchant = false
local atTrade = false

-- presumably you can't have both mail and bank open at the same time, or bank and guild bank
function Dumpster:Nowhere()
	atBank = false
	atGuildBank = false
	atAccountBank = false
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
	if ((GuildBankFrame and GuildBankFrame:IsVisible()) or Baganator_SingleViewGuildViewFrame and Baganator_SingleViewGuildViewFrame:IsVisible()) then
		if debug then self:Print(L.debugatGuildBank); end
		return true
	end
	if debug and atGuildBank then self:Print(L.debugatGuildBankflag); end
	return atGuildBank
end

function Dumpster:ProcessDelayed()
	if delayedinout and delayedinout~="" then
		if debug then self:Print(L.debugProcessDelayed(delayedinout,delayedso.search)); end
	--	delayedinout="";
		delayedso.delayed=true
		changeGuildTab = true
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
		-- neevor: Settings fix 11.x.x
		if Dumpster.WOWRetail then
			Settings.OpenToCategory("Dumpster")
		else
			InterfaceOptionsFrame_OpenToCategory(Dumpster.helppanel); 
		end

	else
		-- self:Print(L.usage);
		 -- neevor: Settings fix 11.x.x
		if Dumpster.WOWRetail then
			Settings.OpenToCategory("Dumpster")
		else
			InterfaceOptionsFrame_OpenToCategory(Dumpster.panel);
		end
		
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
		soulbound="soulbound", sb="soulbound", nb="notbound", notbound="notbound",
		warbound="Warbound", wb="Warbound", btw="Warbound"}, -- neevor: Warbound flags
		quality = { poor=0, common=1, uncommon=2, rare=3, epic=4, legendary=5, artifact=6, 
		grey=0, gray=0, white=1, green=2, blue=3, purple=4, orange=5, red=6 },
		stackfull = { full="full", partial="partial" },
		expansion = { classic=0, tbc=1, wotlk=2, cata=3, mop=4, wod=5, legion=6, bfa=7 }
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

	if superdebug then 
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
		so.search="." -- they specified a qualifier but not a text
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
	elseif so.where=="gbank" and so.inout =="in" then
		DumpsterScanningTooltip:SetBagItem(so.bag,so.slot)
	elseif so.where=="gbank" and so.inout =="out" then
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


		if ( strsub(item, 13, 21) == "battlepet" ) then -- |cff0070dd|Hbattlepet:868:1:3:158:10:12:0x0000000000000000|h[Pandaren Water Spirit]|h|r
		 --	local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(":", item);
		 --	local link = "battlepet:"..speciesID..":"..level..":"..breedQuality..":"..maxHealth..":"..power..":"..speed..":"..battlePetID
		 --	SetItemRef(link, item, DumpsterScanningTooltip)
		 	tooltipError = true
		else
			DumpsterScanningTooltip:SetHyperlink(item)
		end



		
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

function Dumpster:GetExpacID(item)
	local itemName, _, _, _, _, _, _, _, _, _, _, _, _, _, expacID  = GetItemInfo(item)
	return expacID
end

function Dumpster:CheckBindandTooltip(item,so)
	local tooltip=""
	local expID

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


	if so.expansion~="AllExp" then
		
		expID=Dumpster:GetExpacID(item)

		if debug then self:Print(L.debugExpansion(expID)); end

		if  expID ~= so.expansion then
			if not so.except then
				if debug then self:Print(L.debugTooltipExpansionFail(so.expansion,L[so.expansion])); end
				return false
			end
		else
			if so.except then
				if debug then self:Print(L.debugTooltipExpansionFail(so.expansion,L[so.expansion])); end
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
	elseif so.where=="gbank" and so.inout =="in" then
		return GetNumBankSlots()
	elseif so.where=="gbank" and so.inout =="out" then
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
		return  C_Container.GetContainerNumSlots(so.bag) -- neevor 12/15/2022
	elseif so.where=="gbank" and so.inout =="in" then
		return  C_Container.GetContainerNumSlots(so.bag) -- neevor 12/15/2022
	elseif so.where=="gbank" and so.inout =="out" then
		return 98
	elseif so.where=="abank" and so.inout =="in" then
		return C_Container.GetContainerNumSlots(so.bag)	
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
		return  C_Container.GetContainerItemLink(so.bag, so.slot) -- neevor 12/15/2022
	elseif so.where=="gbank" and so.inout =="in" then
		return  C_Container.GetContainerItemLink(so.bag, so.slot) -- neevor 12/15/2022
	elseif so.where=="gbank" and so.inout =="out" then
		return GetGuildBankItemLink(so.bag, so.slot)
	elseif so.where=="abank" then
		return  C_Container.GetContainerItemLink(so.bag, so.slot) 		
	elseif so.where=="mail" then
		return GetInboxItemLink(so.bag, so.slot)
	elseif so.where=="merchant" then
		return GetMerchantItemLink(so.slot)
	else
		return nil
	end
end

function Dumpster:getNumInStack(so)
    local count

    if so.where == "bank" then
        if Dumpster.WOWRetail then
            local texture, c, locked, quality, readable = C_Container.GetContainerItemInfo(so.bag, so.slot)  -- neevor 12/15/2022
            count = c
        else
            local itemInfo = C_Container.GetContainerItemInfo(so.bag, so.slot) -- 졸부김 08/12/2023
            count = itemInfo.stackCount -- 졸부김 08/12/2023
        end
    elseif so.where == "gbank" and so.inout == "in" then
        if Dumpster.WOWRetail then
            local texture, c, locked, quality, readable = C_Container.GetContainerItemInfo(so.bag, so.slot)  -- neevor 12/15/2022
            count = c
        else
            local itemInfo = C_Container.GetContainerItemInfo(so.bag, so.slot) -- 졸부김 08/12/2023
            count = itemInfo.stackCount -- 졸부김 08/12/2023
        end
    elseif so.where == "mail" then
        if Dumpster.WOWRetail then
            local name, itemTexture, c, quality, canUse = GetInboxItem(so.bag, so.slot)
            count = c
        else
            local name, itemid, itemTexture, c, quality, canUse = GetInboxItem(so.bag, so.slot) -- 졸부김 08/12/2023
            count = c
        end
    elseif so.where == "gbank" and so.inout == "out" then
        local texture, c, locked = GetGuildBankItemInfo(so.bag, so.slot)
        count = c
    elseif so.where == "merchant" then
        local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(so.slot)
        count = quantity
    else
        count = 1
    end

    return count
end

function Dumpster:DumpItem(so)
	if so.where=="bank" then
		 C_Container.UseContainerItem(so.bag, so.slot) -- neevor 12/15/2022
	elseif so.where=="gbank" then
		tinsert(DumpsterQueue,{so.bag, so.slot})
	--	AutoStoreGuildBankItem(so.bag, so.slot)
	elseif so.where=="abank" then
		C_Container.UseContainerItem(so.bag, so.slot)
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

    -- Dump main bag
    so.bag = BANK_CONTAINER; -- BANK_CONTAINER = -1
    local dumpcount = Dumpster:NewDumpBag(so);

    -- Dump purchaseable bags
    local numBankBags = GetNumBankSlots()
    if debug then self:Print(L.debugNumBankBags(numBankBags)); end

    local startIndex = Dumpster.WOWRetail and 6 or 5  -- Choose the start index based on environment

    for x = startIndex, (startIndex + numBankBags - 1) do
        so.bag = x
        dumpcount = dumpcount + Dumpster:NewDumpBag(so)
    end

    -- Use reagent bank section only if it's retail
    if Dumpster.WOWRetail then
        reagentBank = IsReagentBankUnlocked()
        if reagentBank then
            BankFrameTab2:Click()
            so.bag = -3
            dumpcount = dumpcount + Dumpster:NewDumpBag(so)
            BankFrameTab1:Click()
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
    -- so.where=="bank"
    local dumpcount = 0
    local x

    for x = 0, NUM_BAG_SLOTS do
        so.bag = x
        dumpcount = dumpcount + Dumpster:NewDumpBag(so)
    end

    if Dumpster.WOWRetail then
        -- reagent bag (5) -- neevor 12/15/2022
        if 0 ~= C_Container.GetContainerNumSlots(5) then
            so.bag = 5
            dumpcount = dumpcount + Dumpster:NewDumpBag(so)
        end
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
	local guildTabLeft = GetNumGuildBankTabs()
	local currentTab = GetCurrentGuildBankTab()
	local dumpcount = 0
	local delay = 0

	if so.delayed then
		if debug then self:Print(L.debugGbankDelayed); end
		-- we're in a loop
		if currentTab < numGuildTabs and changeGuildTab then
			SetGuildBankTab(currentTab+1)
			so.bag=currentTab
			dumpcount = dumpcount + Dumpster:NewDumpBag(so)
			changeGuildTab = false
		end
		
		if currentTab < numGuildTabs then
			delayedinout="all"
			delay = dumpcount + delayedWaitGbank
			self:ScheduleTimer("ProcessDelayed", delay, "");
		else
			delayedinout="" -- we're done!
			changeGuildTab = false
		end
	else
		if debug then self:Print(L.debugGbankFirst); end
		-- first invocation
		delayedso=deepcopy(so)
		delayedinout="all"
		if currentTab==1 then -- we're already on first tab, so go ahead and dump it
			so.bag=currentTab
			dumpcount = dumpcount + Dumpster:NewDumpBag(so)
		else
			SetGuildBankTab(1) -- start at first tab
		end
		if numGuildTabs > 1 then
				delay = dumpcount + delayedWaitGbank
				self:ScheduleTimer("ProcessDelayed", delay, "");
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
						if debug then self:Print(L.debugDumpBagDumpItem(item,so.maxcount)); end
						if not so.remain then
							dumpcount = dumpcount + 1
						end
						if not so.justcount then
							if (not so.test) and not (so.remain) then
								Dumpster:DumpItem(so)
							end
							so.maxcount = so.maxcount - 1
							if so.where=="merchant" then
								if debug then self:Print("AtMerchant"); end
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
	if (so.inout == "in") then
		guildbank_queue("give")
	else
		guildbank_queue("take")
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

		if debug then self:Print(L.debugDumpIt(so.maxcount,tostring(so.expansion),so.bind,so.inout,so.search)); end

		if so.only then
			existingCount = Dumpster:GetExistingCount(so)
			so.maxcount = so.maxcount - existingCount
		else
			existingCount = 0
		end

	--	print("DumpWithso: ["..so.search.."] - ["..so.inout.."] - ["..so.where.."] - ["..delayedinout.."]") 

		if so.maxcount > 0 then
			if so.inout=="all" or delayedinout=="all" then
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
				if tooltipError then self:Print(L.battlepet); end
				self:Print(L.AllExist(colorstring..tostring(dumpcount),so.search,so.keepmaxcount,existingCount));
			else
				if tooltipError then self:Print(L.battlepet); end
				self:Print(L.totaldumped(colorstring..tostring(dumpcount),so.search,so.keepmaxcount));
			end

			tooltipError = false

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

	title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
        title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
        title:SetJustifyH("LEFT")
        title:SetJustifyV("TOP")
        title:SetText("Dumpster")


	dropdownlabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropdownlabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        dropdownlabel:SetText("Set:")
        dropdownlabel:SetHeight(15)
        dropdownlabel:SetWidth(25)

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
		-- neevor: Settings fix 11.x.x
		if Dumpster.WOWRetail then
			Settings.OpenToCategory(categoryHelp.ID)
		else
			InterfaceOptionsFrame_OpenToCategory(Dumpster.helppanel); 
		end
	end)

	local backdropInfo =
	{
	    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	 	tile = true,
	 	tileEdge = true,
	 	tileSize = 8,
	 	edgeSize = 8,
	 	insets = { left = 1, right = 1, top = 1, bottom = 1 },
	}

	editbox = CreateFrame("EditBox", "DumpsterEditBox", frame, "BackdropTemplate")

        editbox:SetPoint("TOP", dropdown, "BOTTOM")
        editbox:SetPoint("LEFT", 5, 0)
        editbox:SetPoint("BOTTOMRIGHT", -5, 5)
        editbox:SetFontObject(GameFontNormal)
        editbox:SetTextColor(.8,.8,.8)
        editbox:SetTextInsets(8,8,8,8)
        editbox:SetMultiLine(true)
        editbox:SetAutoFocus(false)
        editbox:SetHeight(5) 
        editbox:SetBackdrop(backdropInfo)    


		if selected and selected~="" then
	        	editbox:SetText(dumpset[selected])
		end
	
        editbox:SetScript("OnEditFocusLost", focuslost)
        editbox:SetScript("OnEscapePressed", editbox.ClearFocus)


	frame:SetScript("OnShow", nil)
end

function Dumpster:SetUpInterfaceOptions()
    -- Create the main panel for the addon
    Dumpster.panel = CreateFrame("FRAME", "DumpsterPanel", UIParent, "BackdropTemplate")
    Dumpster.panel.name = "Dumpster "..version
    Dumpster.panel:SetScript("OnShow", function(self)
        Dumpster.showPanel()
    end)
    
    if Dumpster.WOWRetail then
        -- Register the main category
        local categoryDumpster, layoutDumpster = Settings.RegisterCanvasLayoutCategory(Dumpster.panel, Dumpster.panel.name)
        categoryDumpster.ID = Dumpster.panel.name
        Settings.RegisterAddOnCategory(categoryDumpster)

        -- Create the help panel as a subcategory
        Dumpster.helppanel = CreateFrame("FRAME", "DumpsterHelpPanel", UIParent, "BackdropTemplate")
        Dumpster.helppanel.name = "Usage"
        Dumpster.helppanel.parent = Dumpster.panel.name
        Dumpster.helppanel:SetScript("OnShow", function(self)
            Dumpster.showHelpPanel()
        end)

        -- Register the help panel as a subcategory
        local categoryHelp = Settings.RegisterCanvasLayoutSubcategory(categoryDumpster, Dumpster.helppanel, Dumpster.helppanel.name)
        categoryHelp.ID = Dumpster.helppanel.name
        Settings.RegisterAddOnCategory(categoryHelp)
    else
        -- Fallback for WoW Classic or earlier versions using InterfaceOptions
        InterfaceOptions_AddCategory(Dumpster.panel) 
        Dumpster.helppanel = CreateFrame("FRAME", "DumpsterHelpPanel", UIParent, "BackdropTemplate")
        Dumpster.helppanel.name = "Usage"
        Dumpster.helppanel.parent = Dumpster.panel.name
        Dumpster.helppanel:SetScript("OnShow", function(self)
            Dumpster.showHelpPanel()
        end)
        InterfaceOptions_AddCategory(Dumpster.helppanel)
    end
end


-- ############# Expansion

function Dumpster:DumpOutAccountBank(so)
	so.where="bank"
	so.bag=13
	return Dumpster:NewDumpBag(so)
end