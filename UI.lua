local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

local categoryDumpster
local categoryHelp

-- ---------------------------------------------------------------------------
-- Shared UI helpers
-- ---------------------------------------------------------------------------

local function CreateSectionTitle(parent, text, anchor, x, y)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

    if anchor then
        title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -20)
    else
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 16, y or -16)
    end

    title:SetText(text)
    title:SetJustifyH("LEFT")

    return title
end

local function CreateDescription(parent, text, anchor, x, y, width)
    local description = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -6)
    description:SetWidth(width or 540)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    description:SetText(text)

    return description
end

local function CreateCheckbox(parent, label, anchor, x, y, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -8)

    checkbox.Text:SetText(label)
    checkbox.Text:SetFontObject("GameFontNormal")

    checkbox:SetChecked(getValue())
    checkbox:SetScript("OnClick", function(self)
        setValue(self:GetChecked() == true)
    end)

    return checkbox
end

-- ---------------------------------------------------------------------------
-- Usage panel
-- ---------------------------------------------------------------------------

function Dumpster:showHelpPanel()
    local frame = Dumpster.helppanel

    if frame._dumpsterBuilt then
        return
    end

    frame._dumpsterBuilt = true

    local title = CreateSectionTitle(frame, "Dumpster Usage")

    local mainhelp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainhelp:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    mainhelp:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    mainhelp:SetJustifyH("LEFT")
    mainhelp:SetJustifyV("TOP")
    mainhelp:SetText(L.extrahelp)
end

-- ---------------------------------------------------------------------------
-- Main settings panel
-- ---------------------------------------------------------------------------

function Dumpster:showPanel()
    local frame = Dumpster.panel

    if frame._dumpsterBuilt then
        return
    end

    frame._dumpsterBuilt = true

    local dropdown
    local editbox
    local selected

    local function getSortedSetNames()
        local names = {}

        for setname in pairs(dumpset) do
            names[#names + 1] = setname
        end

        table.sort(names, function(a, b)
            return a:lower() < b:lower()
        end)

        return names
    end

    local function saveCurrentSet()
        if selected and selected ~= "" then
            dumpset[selected] = editbox:GetText() or ""
        end
    end

    local function selectSet(setname)
        selected = setname

        if setname and dumpset[setname] ~= nil then
            UIDropDownMenu_SetSelectedValue(dropdown, setname)
            UIDropDownMenu_SetText(dropdown, setname)
            editbox:SetText(dumpset[setname] or "")
        else
            UIDropDownMenu_ClearAll(dropdown)
            UIDropDownMenu_SetText(dropdown, "No saved sets")
            editbox:SetText("")
        end
    end

    local function dropdownOnClick(info)
        saveCurrentSet()
        selectSet(info.value)
    end

    local function initializeDropdown()
        for _, setname in ipairs(getSortedSetNames()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = setname
            info.value = setname
            info.func = dropdownOnClick
            info.checked = (setname == selected)
            UIDropDownMenu_AddButton(info)
        end
    end

    local function refreshDropdown(preferredSet)
        UIDropDownMenu_Initialize(dropdown, initializeDropdown)

        local names = getSortedSetNames()

        if preferredSet and dumpset[preferredSet] ~= nil then
            selectSet(preferredSet)
        elseif selected and dumpset[selected] ~= nil then
            selectSet(selected)
        else
            selectSet(names[1])
        end
    end

    -- -----------------------------------------------------------------------
    -- Page heading
    -- -----------------------------------------------------------------------

    local title = CreateSectionTitle(frame, "Dumpster")

    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    version:SetText(Dumpster.VERSION or "Dev")

    local intro = CreateDescription(
        frame,
        "Create and manage reusable item-matching sets. Sets can contain the same search terms and qualifiers used with /din and /dout.",
        title,
        0,
        -8,
        560
    )

    local helpButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    helpButton:SetSize(90, 24)
    helpButton:SetText("Usage")
    helpButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -16)
    helpButton:SetScript("OnClick", function()
        if Dumpster.WOWRetail and categoryHelp then
            Settings.OpenToCategory(categoryHelp.ID)
        else
            InterfaceOptionsFrame_OpenToCategory(Dumpster.helppanel)
            InterfaceOptionsFrame_OpenToCategory(Dumpster.helppanel)
        end
    end)

    -- -----------------------------------------------------------------------
    -- Saved Sets
    -- -----------------------------------------------------------------------

    local setsTitle = CreateSectionTitle(frame, "Saved Sets", intro, 0, -22)

    local setsDescription = CreateDescription(
        frame,
        "Select a saved set to edit it, or create a new one. Changes are saved automatically when you change sets or leave the editor.",
        setsTitle,
        0,
        -6,
        560
    )

    local setLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    setLabel:SetPoint("TOPLEFT", setsDescription, "BOTTOMLEFT", 0, -14)
    setLabel:SetText("Set")

    dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", setLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(dropdown, 220)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")

    local newButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newButton:SetSize(80, 24)
    newButton:SetText("New")
    newButton:SetPoint("LEFT", dropdown, "RIGHT", -8, 2)

    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetSize(80, 24)
    deleteButton:SetText("Delete")
    deleteButton:SetPoint("LEFT", newButton, "RIGHT", 6, 0)

    local definitionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    definitionLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 16, -10)
    definitionLabel:SetText("Definition")

    local backdropInfo = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = {
            left = 1,
            right = 1,
            top = 1,
            bottom = 1,
        },
    }

    editbox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editbox:SetPoint("TOPLEFT", definitionLabel, "BOTTOMLEFT", 0, -6)
    editbox:SetPoint("RIGHT", frame, "RIGHT", -26, 0)
    editbox:SetHeight(110)
    editbox:SetFontObject(GameFontHighlight)
    editbox:SetTextColor(0.9, 0.9, 0.9)
    editbox:SetTextInsets(10, 10, 10, 10)
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(false)
    editbox:SetBackdrop(backdropInfo)
    editbox:SetScript("OnEditFocusLost", saveCurrentSet)
    editbox:SetScript("OnEscapePressed", function(self)
        saveCurrentSet()
        self:ClearFocus()
    end)

    local example = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    example:SetPoint("TOPLEFT", editbox, "BOTTOMLEFT", 4, -6)
    example:SetWidth(550)
    example:SetJustifyH("LEFT")
    example:SetText('Example: /green /boe /legion /to "Jabberie-Draka"')

    StaticPopupDialogs["DUMPSTER_GETNEWSET"] = {
        text = "New set name?",
        button1 = OKAY,
        button2 = CANCEL,
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,

        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,

        OnAccept = function(self)
            local newname = strtrim(self.editBox:GetText() or "")

            if newname == "" then
                return
            end

            saveCurrentSet()

            if dumpset[newname] == nil then
                dumpset[newname] = ""
            end

            refreshDropdown(newname)
            editbox:SetFocus()
        end,
    }

    StaticPopupDialogs["DUMPSTER_DELETESET"] = {
        text = "Delete the saved set |cffffffff%s|r?",
        button1 = DELETE,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,

        OnAccept = function(_, data)
            if data and dumpset[data] ~= nil then
                dumpset[data] = nil
            end

            selected = nil
            refreshDropdown()
        end,
    }

    newButton:SetScript("OnClick", function()
        saveCurrentSet()
        StaticPopup_Show("DUMPSTER_GETNEWSET")
    end)

    deleteButton:SetScript("OnClick", function()
        if not selected or dumpset[selected] == nil then
            return
        end

        StaticPopup_Show("DUMPSTER_DELETESET", selected, nil, selected)
    end)

    refreshDropdown()

    -- -----------------------------------------------------------------------
    -- Advanced
    -- -----------------------------------------------------------------------

    local advancedTitle = CreateSectionTitle(frame, "Advanced", example, -4, -24)

    local advancedDescription = CreateDescription(
        frame,
        "Diagnostic options. Leave these disabled unless you are troubleshooting Dumpster.",
        advancedTitle,
        0,
        -6,
        560
    )

    local debugCheckbox = CreateCheckbox(
        frame,
        "Debug output",
        advancedDescription,
        0,
        -8,
        function()
            return Dumpster.debug == true
        end,
        function(enabled)
            Dumpster.debug = enabled

            if not enabled then
                Dumpster.superdebug = false
            end
        end
    )

    local superDebugCheckbox

    superDebugCheckbox = CreateCheckbox(
        frame,
        "Super debug output",
        debugCheckbox,
        24,
        -2,
        function()
            return Dumpster.superdebug == true
        end,
        function(enabled)
            Dumpster.superdebug = enabled

            if enabled then
                Dumpster.debug = true
                debugCheckbox:SetChecked(true)
            end
        end
    )

    debugCheckbox:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            superDebugCheckbox:SetChecked(false)
        end
    end)

    local advancedHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    advancedHint:SetPoint("TOPLEFT", superDebugCheckbox, "BOTTOMLEFT", 4, -2)
    advancedHint:SetWidth(540)
    advancedHint:SetJustifyH("LEFT")
    advancedHint:SetText("These options are temporary for the current session and can also be toggled with /dumpster debug and /dumpster superdebug.")
end

-- ---------------------------------------------------------------------------
-- Settings registration
-- ---------------------------------------------------------------------------

function Dumpster:SetUpInterfaceOptions()
    Dumpster.panel = CreateFrame(
        "FRAME",
        "DumpsterPanel",
        UIParent,
        "BackdropTemplate"
    )

    Dumpster.panel.name = "Dumpster " .. (Dumpster.VERSION or "Dev")

    Dumpster.helppanel = CreateFrame(
        "FRAME",
        "DumpsterHelpPanel",
        UIParent,
        "BackdropTemplate"
    )

    Dumpster.helppanel.name = "Usage"
    Dumpster.helppanel.parent = Dumpster.panel.name

    if Dumpster.WOWRetail then
        categoryDumpster = Settings.RegisterCanvasLayoutCategory(
            Dumpster.panel,
            Dumpster.panel.name
        )

        categoryDumpster.ID = Dumpster.panel.name
        Settings.RegisterAddOnCategory(categoryDumpster)

        Dumpster.settingsCategoryID = categoryDumpster.ID

        categoryHelp = Settings.RegisterCanvasLayoutSubcategory(
            categoryDumpster,
            Dumpster.helppanel,
            Dumpster.helppanel.name
        )

        categoryHelp.ID = Dumpster.helppanel.name
        Settings.RegisterAddOnCategory(categoryHelp)

        Dumpster.settingsHelpCategoryID = categoryHelp.ID
    else
        InterfaceOptions_AddCategory(Dumpster.panel)
        InterfaceOptions_AddCategory(Dumpster.helppanel)
    end

    -- Build both panels immediately. This avoids the blank-first-open issue
    -- seen with lazily constructed Settings canvas panels.
    Dumpster:showPanel()
    Dumpster:showHelpPanel()
end
