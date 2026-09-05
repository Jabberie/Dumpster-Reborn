local Dumpster = Dumpster
local L = LibStub("AceLocale-3.0"):GetLocale("Dumpster", true)

function Dumpster:EatTheLeftovers(so)
    local leftoverpos = so.search:find(";")

    if leftoverpos then
        if so.leftovers and so.leftovers ~= "" then
            so.leftovers =
                so.search:sub(leftoverpos + 1) ..
                ";" ..
                so.leftovers
        else
            so.leftovers =
                so.search:sub(leftoverpos + 1)
        end

        so.search =
            so.search:sub(1, leftoverpos - 1)

        if Dumpster.debug then
            self:Print(
                L.debugleftovers(
                    so.leftovers
                )
            )
        end
    end
end

function Dumpster:ExpandSets(so)
    local setloop = true
    local expanded = false

    while setloop do
        Dumpster:EatTheLeftovers(so)

        local setname =
            so.search:gsub(" ", "")

        if dumpset[setname]
            and dumpset[setname] ~= "" then

            expanded = true

            self:Print(
                L.dumpsetuse(
                    setname,
                    dumpset[setname]
                )
            )

            so.search =
                dumpset[setname]

            if so.search:gsub(" ", "") == setname then
                -- Avoid this case:
                -- dumpset["shoes"] = "shoes"
                setloop = false
            end
        else
            setloop = false
        end
    end

    return expanded
end

function Dumpster:ParseOptions(so)
    -- To print out quality colors:
    -- /script for i = 0, 6 do
    --     local r, g, b, hex = GetItemQualityColor(i)
    --     print(i, hex, _G["ITEM_QUALITY"..i.."_DESC"] or "")
    -- end

    local setloop = true

    while setloop do
        Dumpster:ExpandSets(so)

        -- -------------------------------------------------------------------
        -- Stack count
        -- -------------------------------------------------------------------

        local maxcountString =
            so.search:match("%d+")

        if maxcountString
            and maxcountString ~= "" then

            local maxcount =
                tonumber(maxcountString)

            if maxcount then
                if Dumpster.debug then
                    self:Print(
                        L.debugnumstacks(
                            maxcount
                        )
                    )
                end

                so.maxcount = maxcount
                so.keepmaxcount = maxcount

                so.search =
                    so.search:gsub(
                        "%d+",
                        " "
                    )
            end
        end

        so.limitcount =
            so.keepmaxcount

        if so.inout == "in"
            and Dumpster:AtTrade()
            and so.maxcount > 6 then

            if Dumpster.debug then
                self:Print(
                    L.debugnumstacks6
                )
            end

            so.maxcount = 6
            so.limitcount = 6
        end

        if so.inout == "in"
            and Dumpster:AtMail()
            and so.maxcount > 12 then

            if Dumpster.debug then
                self:Print(
                    L.debugnumstacks12
                )
            end

            so.maxcount = 12
            so.limitcount = 12
        end

        -- -------------------------------------------------------------------
        -- Flags
        -- -------------------------------------------------------------------

        local boolFlags = {
            only = "only",
            test = "test",
            remain = "remain",
            except = "except",
            existing = "existing",
        }

        local parameterFlags = {
            tooltipsearch = "tooltipsearch",
            tooltip = "tooltipsearch",
            to = "to",
            t = "tooltipsearch",
        }

        if Dumpster.debug then
            self:Print(
                L.debugSearch(
                    so.search
                )
            )
        end

        so.search =
            so.search:lower():gsub(
                "  ",
                " "
            )

        so.search =
            so.search
                :gsub("^ ", "")
                :gsub(" $", "")

        if Dumpster.debug then
            self:Print(
                L.debugSearch(
                    so.search
                )
            )
        end

        -- -------------------------------------------------------------------
        -- Expansion exclusions
        -- -------------------------------------------------------------------

        -- /notcurrent
        if so.search:find(
            "/notcurrent%f[%A]"
        ) then

            if GetExpansionLevel then
                so.excludedExpansion =
                    GetExpansionLevel()

                if Dumpster.debug then
                    self:Print(
                        "DEBUG Excluding current expansion [" ..
                        tostring(
                            so.excludedExpansion
                        ) ..
                        "]"
                    )
                end
            else
                self:Print(
                    "Dumpster: Unable to determine the current expansion."
                )

                so.invalid = true
            end

            so.search =
                so.search:gsub(
                    "/notcurrent%f[%A]",
                    ""
                ):gsub(
                    "  ",
                    " "
                )
        end

        -- /notexp <expansion>
        -- /exceptexp <expansion>
        for _, qualifier in ipairs({
            "notexp",
            "exceptexp",
        }) do
            local pattern =
                "/" ..
                qualifier ..
                "%s+([%w_%-]+)"

            local expansionName =
                so.search:match(pattern)

            if expansionName then
                expansionName =
                    expansionName:lower()

                local expansionID =
                    self.multiFlags.expansion[
                        expansionName
                    ]

                if expansionID ~= nil then
                    so.excludedExpansion =
                        expansionID

                    if Dumpster.debug then
                        self:Print(
                            "DEBUG Excluding expansion [" ..
                            expansionName ..
                            "] ID [" ..
                            tostring(
                                expansionID
                            ) ..
                            "]"
                        )
                    end
                else
                    self:Print(
                        "Dumpster: Unknown expansion for /" ..
                        qualifier ..
                        ": " ..
                        expansionName
                    )

                    so.invalid = true
                end

                so.search =
                    so.search:gsub(
                        "/" ..
                        qualifier ..
                        "%s+" ..
                        expansionName,
                        "",
                        1
                    ):gsub(
                        "  ",
                        " "
                    )
            end
        end

        -- -------------------------------------------------------------------
        -- Boolean flags
        -- -------------------------------------------------------------------

        for flag in pairs(boolFlags) do
            local pattern =
                "/" ..
                flag:gsub(
                    "([^%w])",
                    "%%%1"
                ) ..
                "%f[%A]"

            if so.search:find(pattern) then
                if Dumpster.debug then
                    self:Print(
                        L.debugfoundflag(
                            flag
                        )
                    )
                end

                so[flag] = true

                so.search =
                    so.search:gsub(
                        pattern,
                        ""
                    ):gsub(
                        "  ",
                        " "
                    )

                if Dumpster.debug then
                    self:Print(
                        L.debugSearch(
                            so.search
                        )
                    )
                end
            end
        end

        -- -------------------------------------------------------------------
        -- Multivalue flags
        -- -------------------------------------------------------------------

        for flag, flagvalues
            in pairs(self.multiFlags) do

            for flagsearch, flagtoken
                in pairs(flagvalues) do

                local pattern =
                    "/" ..
                    flagsearch:gsub(
                        "([^%w])",
                        "%%%1"
                    ) ..
                    "%f[%A]"

                if so.search:find(pattern) then
                    local tokenToPrint =
                        flagtoken

                    if flag == "expansion"
                        and type(flagtoken) == "number" then

                        tokenToPrint =
                            self:ExpansionIdToKey(
                                flagtoken
                            )
                    end

                    if Dumpster.debug then
                        self:Print(
                            L.debugfoundflag(
                                flag ..
                                "=" ..
                                tostring(
                                    tokenToPrint
                                )
                            )
                        )
                    end

                    so[flag] =
                        flagtoken

                    so.search =
                        so.search:gsub(
                            pattern,
                            ""
                        ):gsub(
                            "  ",
                            " "
                        )

                    if Dumpster.debug then
                        self:Print(
                            L.debugSearch(
                                so.search
                            )
                        )
                    end
                end
            end
        end

        -- -------------------------------------------------------------------
        -- Flags that take a parameter
        -- -------------------------------------------------------------------

        for flagsearch, flag
            in pairs(parameterFlags) do

            local flagpos =
                so.search:find(
                    "/" .. flagsearch
                )

            if flagpos
                and flagpos > 0 then

                if Dumpster.debug then
                    self:Print(
                        L.debugfoundflag(
                            flag
                        )
                    )
                end

                local flagtoken =
                    so.search:sub(
                        flagpos +
                        flagsearch:len() +
                        1
                    )

                if Dumpster.debug then
                    self:Print(
                        L.debugflagtoken(
                            flagtoken
                        )
                    )
                end

                -- /flag token /anotherflag
                local flagendpos =
                    flagtoken:find("/")

                if flagendpos
                    and flagendpos > 0 then

                    flagtoken =
                        flagtoken:sub(
                            1,
                            flagendpos - 1
                        )

                    if Dumpster.debug then
                        self:Print(
                            L.debugflagtoken(
                                flagtoken
                            )
                        )
                    end
                end

                -- /flag "token" somethingelse
                local flagmatch =
                    flagtoken:match(
                        "\"[^\"]+\""
                    )

                if flagmatch
                    and flagmatch ~= "" then

                    flagtoken =
                        flagmatch

                    if Dumpster.debug then
                        self:Print(
                            L.debugflagtoken(
                                flagtoken
                            )
                        )
                    end
                else
                    -- /flag token somethingelse
                    -- Match "-" for cross-realm
                    -- character names.

                    flagmatch =
                        flagtoken:match(
                            "%w+%-?%w+"
                        )

                    if flagmatch
                        and flagmatch ~= "" then

                        flagtoken =
                            flagmatch

                        if Dumpster.debug then
                            self:Print(
                                L.debugflagtoken(
                                    flagtoken
                                )
                            )
                        end
                    end
                end

                -- Strip out /flag flagtoken.
                flagendpos =
                    so.search:find(
                        flagtoken,
                        flagpos,
                        true
                    )

                if flagendpos then
                    so.search =
                        so.search:sub(
                            1,
                            flagpos - 1
                        ) ..
                        so.search:sub(
                            flagendpos +
                            flagtoken:len() +
                            1
                        )
                end

                if Dumpster.debug then
                    self:Print(
                        L.debugSearch(
                            so.search
                        )
                    )
                end

                flagtoken =
                    flagtoken
                        :gsub("\"", "")
                        :gsub("  ", " ")

                so[flag] =
                    flagtoken
            end
        end

        -- -------------------------------------------------------------------
        -- Remaining search text
        -- -------------------------------------------------------------------

        so.search =
            so.search
                :gsub("^ ", "")
                :gsub(" $", "")

        if Dumpster.debug then
            self:Print(
                L.debugSearch(
                    so.search
                )
            )
        end

        local qualitynumber =
            tonumber(
                so.quality
            )

        if qualitynumber
            and qualitynumber < 7
            and qualitynumber > -1 then

            so.qualitynumber =
                qualitynumber
        end

        if Dumpster.superdebug then
            for key, value
                in pairs(so) do

                if type(value) ~= "string" then
                    value =
                        tostring(value)
                end

                self:Print(
                    L.debugParseResults(
                        key,
                        value
                    )
                )
            end
        end

        if not so.search
            or so.search == ""
            or so.search == " " then

            -- Qualifier supplied without
            -- explicit item-name search.
            so.search = "."
        end

        setloop =
            Dumpster:ExpandSets(so)
    end

    -- -----------------------------------------------------------------------
    -- Final normalization
    -- -----------------------------------------------------------------------

    so.search =
        so.search:gsub(
            "%-",
            "%%%-"
        )

    so.tooltipsearch =
        (so.tooltipsearch or ""):gsub(
            "%-",
            "%%%-"
        )

    -- /existing is only meaningful for deposits.
    if so.existing
        and so.inout ~= "in" then

        self:Print(
            "Dumpster: /existing can only be used with /din."
        )

        so.invalid = true
    end
end