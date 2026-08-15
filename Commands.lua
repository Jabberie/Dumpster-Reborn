local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

-- ---------------------------------------------------------------------------
-- /dumpster
-- ---------------------------------------------------------------------------

function Dumpster:DumpsterDump(arg)
    arg = strtrim(
        (arg or ""):lower()
    )

    -- -----------------------------------------------------------------------
    -- Debug
    -- -----------------------------------------------------------------------

    if arg == "debug" then
        Dumpster.debug =
            not Dumpster.debug

        if Dumpster.debug then
            Dumpster.superdebug = false
            self:Print("Debug enabled.")
        else
            Dumpster.superdebug = false
            self:Print("Debug disabled.")
        end

        return
    end

    if arg == "superdebug" then
        Dumpster.superdebug =
            not Dumpster.superdebug

        if Dumpster.superdebug then
            Dumpster.debug = true
            self:Print("Super debug enabled.")
        else
            self:Print("Super debug disabled.")
        end

        return
    end

    -- -----------------------------------------------------------------------
    -- Bank compatibility diagnostics
    -- -----------------------------------------------------------------------

    if arg == "banktype" then
        if not Dumpster.Compat
            or not Dumpster.Compat.GetActiveBankType then

            self:Print(
                "Bank type detection is unavailable."
            )

            return
        end

        local bankType, provider =
            Dumpster.Compat:GetActiveBankType()

        local bankName =
            Dumpster.Compat:GetBankTypeName(
                bankType
            )

        self:Print(
            "Bank type: " ..
            bankName ..
            " | Detector: " ..
            tostring(provider or "none")
        )

        return
    end

    if arg == "bankdebug" then
        if Dumpster.Compat
            and Dumpster.Compat.PrintBankDiagnostics then

            Dumpster.Compat:
                PrintBankDiagnostics()
        else
            self:Print(
                "Bank diagnostics are unavailable."
            )
        end

        return
    end

    if arg == "bankframes" then
        if Dumpster.Compat
            and Dumpster.Compat.PrintKnownBankFrames then

            Dumpster.Compat:
                PrintKnownBankFrames()
        else
            self:Print(
                "Bank frame diagnostics are unavailable."
            )
        end

        return
    end

    -- -----------------------------------------------------------------------
    -- Help
    -- -----------------------------------------------------------------------

    if arg == "help"
        or arg == "extrahelp" then

        if Dumpster.WOWRetail then
            if Dumpster.settingsHelpCategoryID then
                Settings.OpenToCategory(
                    Dumpster.settingsHelpCategoryID
                )

                return
            end
        else
            if Dumpster.helppanel then
                InterfaceOptionsFrame_OpenToCategory(
                    Dumpster.helppanel
                )

                InterfaceOptionsFrame_OpenToCategory(
                    Dumpster.helppanel
                )

                return
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Default: open Dumpster settings
    -- -----------------------------------------------------------------------

    if Dumpster.WOWRetail then
        if Dumpster.settingsCategoryID then
            Settings.OpenToCategory(
                Dumpster.settingsCategoryID
            )
        end
    else
        if Dumpster.panel then
            InterfaceOptionsFrame_OpenToCategory(
                Dumpster.panel
            )

            InterfaceOptionsFrame_OpenToCategory(
                Dumpster.panel
            )
        end
    end
end

-- ---------------------------------------------------------------------------
-- Main dump commands
-- ---------------------------------------------------------------------------

function Dumpster:DumpItIn(search)
    Dumpster:DumpIt(
        search,
        "in"
    )
end

function Dumpster:DumpItOut(search)
    Dumpster:DumpIt(
        search,
        "out"
    )
end

function Dumpster:DumpItAllOut(search)
    Dumpster:DumpIt(
        search,
        "all"
    )
end

-- ---------------------------------------------------------------------------
-- Saved sets
-- ---------------------------------------------------------------------------

function Dumpster:DumpSetAdd(args)
    args = args or ""

    local setname =
        args:match("^(%S+)")

    if not setname
        or setname == "" then

        self:Print(
            "Usage: /dadd setname setdetails"
        )

        return false
    end

    local details =
        args:sub(#setname + 1)

    details =
        strtrim(details)

    if details == "" then
        self:Print(
            "No definition supplied for set '" ..
            setname ..
            "'."
        )

        return false
    end

    if type(dumpset) ~= "table" then
        dumpset = {}
    end

    dumpset[setname] =
        details

    self:Print(
        "Saved set '" ..
        setname ..
        "': " ..
        details
    )

    return true
end

function Dumpster:DumpSetDel(args)
    args =
        strtrim(args or "")

    if args == "" then
        self:Print(
            "Usage: /ddel setname"
        )

        return false
    end

    if type(dumpset) ~= "table"
        or dumpset[args] == nil then

        self:Print(
            "Saved set '" ..
            args ..
            "' was not found."
        )

        return false
    end

    dumpset[args] = nil

    self:Print(
        "Deleted saved set '" ..
        args ..
        "'."
    )

    return true
end

function Dumpster:DumpSetList()
    if type(dumpset) ~= "table" then
        dumpset = {}
    end

    local names = {}

    for setname in pairs(dumpset) do
        names[#names + 1] =
            setname
    end

    table.sort(
        names,
        function(a, b)
            return a:lower() <
                b:lower()
        end
    )

    if #names == 0 then
        self:Print(
            "No saved sets."
        )

        return
    end

    self:Print(
        tostring(#names) ..
        " saved set(s):"
    )

    for index, setname
        in ipairs(names) do

        self:Print(
            tostring(index) ..
            ". " ..
            setname ..
            ": " ..
            tostring(
                dumpset[setname]
            )
        )
    end
end