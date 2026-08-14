local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

function Dumpster:EatTheLeftovers(so)
	local leftoverpos = so.search:find(";")
	if leftoverpos then
		if so.leftovers and so.leftovers~="" then
			so.leftovers = so.search:sub(leftoverpos+1)..";"..so.leftovers
		else
			so.leftovers = so.search:sub(leftoverpos+1)
		end
		so.search = so.search:sub(1,leftoverpos-1)
		if Dumpster.debug then self:Print(L.debugleftovers(so.leftovers)); end
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
 --	/script for i = 0, 6 do local r, g, b, hex = GetItemQualityColor(i); print(i, hex, _G["ITEM_QUALITY"..i.."_DESC"] or "") end

	local setloop=true
	while setloop do
	Dumpster:ExpandSets(so)

	local maxcountString = so.search:match("%d+")
	if maxcountString and maxcountString~="" then
		local maxcount = tonumber(maxcountString)
		if maxcount then
			if Dumpster.debug then self:Print(L.debugnumstacks(maxcount)); end
			so.maxcount = maxcount
			so.keepmaxcount = maxcount
			so.search = so.search:gsub("%d+"," ")
		end
	end
	so.limitcount=so.keepmaxcount
	if so.inout=="in" and Dumpster:AtTrade() and so.maxcount>6 then
		if Dumpster.debug then self:Print(L.debugnumstacks6); end
		so.maxcount=6
		so.limitcount=6
	end
	if so.inout=="in" and Dumpster:AtMail() and so.maxcount>12 then
		if Dumpster.debug then self:Print(L.debugnumstacks12); end
		so.maxcount=12
		so.limitcount=12
	end

	local boolFlags = { 
		only="only", 
		test="test", 
		remain="remain", 
		except="except" 
	}

	local parameterFlags = { 
		tooltipsearch="tooltipsearch", 
		tooltip="tooltipsearch", 
		to="to", 
		t="tooltipsearch" 
	}

	if Dumpster.debug then self:Print(L.debugSearch(so.search)); end
	so.search = so.search:lower():gsub("  "," ")
	so.search = so.search:gsub("^ ",""):gsub(" $","")
	if Dumpster.debug then self:Print(L.debugSearch(so.search)); end

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
			if Dumpster.debug then self:Print(L.debugfoundflag(flag)); end
			so[flag]=true

			-- strip out /flag
			so.search = so.search:gsub("/"..flag,""):gsub("  "," ")
			if Dumpster.debug then self:Print(L.debugSearch(so.search)); end
		end
	end


	-- parse multivalue flags
	for flag, flagvalues in pairs(self.multiFlags) do
	    for flagsearch, flagtoken in pairs(flagvalues) do
	        local pattern = "/" .. flagsearch:gsub("([^%w])", "%%%1") .. "%f[%A]"
	        if so.search:find(pattern) then
	            local tokenToPrint = flagtoken
	            if flag == "expansion" and type(flagtoken) == "number" then
	                tokenToPrint = self:ExpansionIdToKey(flagtoken)
	            end

	            if Dumpster.debug then
	                self:Print(L.debugfoundflag(flag .. "=" .. tostring(tokenToPrint)))
	            end
	            so[flag] = flagtoken

	            so.search = so.search:gsub(pattern, ""):gsub("  ", " ")
	            if Dumpster.debug then
	                self:Print(L.debugSearch(so.search))
	            end
	        end
	    end
	end

	-- parse flags that take a parameter
	for flagsearch,flag in pairs(parameterFlags) do
		flagpos=so.search:find("/"..flagsearch)
		if flagpos and flagpos>0 then
			if Dumpster.debug then self:Print(L.debugfoundflag(flag)); end
			flagtoken=so.search:sub(flagpos+flagsearch:len()+1)
			if Dumpster.debug then self:Print(L.debugflagtoken(flagtoken)); end

			-- /flag token /anotherflag
			flagendpos=flagtoken:find("/")
			if flagendpos and flagendpos>0 then
				flagtoken=flagtoken:sub(1,flagendpos-1)
				if Dumpster.debug then self:Print(L.debugflagtoken(flagtoken)); end
			end

			-- /flag "token" somethingelse
			flagmatch=flagtoken:match("\"[^\"]+\"")
			if flagmatch and flagmatch~="" then
				flagtoken=flagmatch
				if Dumpster.debug then self:Print(L.debugflagtoken(flagtoken)); end
			else
				-- /flag token somethingelse
				-- Thanks neevor
				-- match "-" to, for mailing merged realms, but affects other tokens as well
				   flagmatch=flagtoken:match("%w+%-?%w+")  -- new code
				-- flagmatch=flagtoken:match("%w+") -- commented out old code
				if flagmatch and flagmatch~="" then
					flagtoken=flagmatch
					if Dumpster.debug then self:Print(L.debugflagtoken(flagtoken)); end
				end
			end

			-- strip out /flag flagtoken
			flagendpos=so.search:find(flagtoken,flagpos,true)
			so.search=so.search:sub(1,flagpos-1)..so.search:sub(flagendpos+flagtoken:len()+1)
			if Dumpster.debug then self:Print(L.debugSearch(so.search)); end

			flagtoken=flagtoken:gsub("\"",""):gsub("  "," ")
			so[flag]=flagtoken
		end
	end

	-- Whatever's left should be the search text
	
	so.search = so.search:gsub("^ ",""):gsub(" $","")
	if Dumpster.debug then self:Print(L.debugSearch(so.search)); end

	local qualitynumber=tonumber(so.quality)
	if qualitynumber and qualitynumber<7 and qualitynumber>-1 then
		local r,g,b,hex=GetItemQualityColor(qualitynumber)
		-- so.search = hex..".+"..so.search
		so.qualitynumber = qualitynumber
	end

	if Dumpster.superdebug then 
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
