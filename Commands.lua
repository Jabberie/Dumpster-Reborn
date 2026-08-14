local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

function Dumpster:DumpsterDump(arg) -- /dumpster
	if arg=="debug" then
		if Dumpster.debug then
			self:Print(L.debugDisabled);
			Dumpster.debug=false
			Dumpster.superdebug=false
		else
			self:Print(L.debugEnabled);
			Dumpster.debug=true
			Dumpster.superdebug=false
		end
	elseif arg=="superdebug" then
		if Dumpster.superdebug then
			self:Print(L.debugSuperDisabled);
			Dumpster.debug=false
			Dumpster.superdebug=false
		else
			self:Print(L.debugSuperEnabled);
			Dumpster.debug=true
			Dumpster.superdebug=true
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
	local names = {}
	for setname in pairs(dumpset) do
		names[#names + 1] = setname
	end
	table.sort(names)
	self:Print(L.dumpsetlist(#names))
	for index, setname in ipairs(names) do
		self:Print(tostring(index)..". "..setname..": "..dumpset[setname])
	end
end

-- ############# utility functions
