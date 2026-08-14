local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

local categoryDumpster, layoutDumpster
local categoryHelp, layoutHelp

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
	local title, dropdownlabel
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

	local function getSortedSetNames()
		local names = {}
		for setname in pairs(dumpset) do
			names[#names + 1] = setname
		end
		table.sort(names, function(a, b) return a:lower() < b:lower() end)
		return names
	end

	local function initdropdown()
		for _, setname in ipairs(getSortedSetNames()) do
			local info = UIDropDownMenu_CreateInfo()
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
			local newname = strtrim(self.editBox:GetText() or "")
			if newname == "" then return end
			dumpset[newname] = dumpset[newname] or ""
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
		local names = getSortedSetNames()
		selected = names[1]
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
    Dumpster.panel.name = "Dumpster "..Dumpster.VERSION
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
