-- ============================================================
--  PlayerDossier – GroupHistory.lua
--  Logs everyone you group with (name, realm, class, role, content
--  type) so you can retroactively add them to the Dossier or Ignore
--  List after the group has already disbanded.
--
--  DB: PlayerDossierDB.history = {
--    ["Name-Realm"] = { name, realm, class, role, guid, context,
--                        firstSeen, lastSeen, count }
--  }
-- ============================================================

local PD = PlayerDossier
local L  = PD.L

local MAX_HISTORY = 300   -- oldest entries are trimmed beyond this

-- ================================================================
-- 1.  DB-LAYER
-- ================================================================

function PD:GH_Init()
    if not PlayerDossierDB then PD:Init() end
    if not PlayerDossierDB.history then
        PlayerDossierDB.history = {}
    end
end

function PD:GH_GetAll()
    return (PlayerDossierDB and PlayerDossierDB.history) or {}
end

function PD:GH_GetEntry(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.history then return nil end
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    return PlayerDossierDB.history[PD:GetKey(name, realm)]
end

function PD:GH_Count()
    local n = 0
    for _ in pairs(PD:GH_GetAll()) do n = n + 1 end
    return n
end

local function TrimHistory()
    local h = PlayerDossierDB and PlayerDossierDB.history
    if not h then return end
    local n = 0
    for _ in pairs(h) do n = n + 1 end
    if n <= MAX_HISTORY then return end

    local list = {}
    for k, e in pairs(h) do list[#list + 1] = { k = k, ts = e.lastSeen or 0 } end
    table.sort(list, function(a, b) return a.ts < b.ts end)
    for i = 1, (n - MAX_HISTORY) do
        h[list[i].k] = nil
    end
end

-- isNewInGroup: true only on the first tick a player is seen in the
-- current, continuous group membership -> bumps the "grouped" counter
-- context: content-type label at the time of recording (e.g. "M+15",
-- "Timewalking", "Raid") - nil if unknown/not in an instance; only
-- overwrites the stored value when a fresh label is actually known,
-- so it isn't wiped out again on the way back out of the instance.
function PD:GH_Record(name, realm, class, role, guid, isNewInGroup, context)
    PD:GH_Init()
    realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
    local key = PD:GetKey(name, realm)
    local h   = PlayerDossierDB.history
    local e   = h[key]

    if e then
        e.lastSeen = time()
        if class   and class   ~= "UNKNOWN" then e.class   = class   end
        if role    and role    ~= "NONE"    then e.role    = role    end
        if guid    and guid    ~= ""        then e.guid    = guid    end
        if context then e.context = context end
        if isNewInGroup then e.count = (e.count or 1) + 1 end
    else
        h[key] = {
            name      = name,
            realm     = realm,
            class     = class or "UNKNOWN",
            role      = role  or "NONE",
            guid      = guid  or "",
            context   = context,
            firstSeen = time(),
            lastSeen  = time(),
            count     = 1,
        }
        TrimHistory()
    end
end

function PD:GH_RemoveEntry(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.history then return end
    PlayerDossierDB.history[PD:GetKey(name, realm)] = nil
end

-- ================================================================
-- 2.  GROUP TRACKING
-- ================================================================

local seenThisGroup = {}

-- Content-type of the current group, or nil if unknown/not in an
-- instance. Wrapped in pcall since not every API exists on every
-- client build.
local function GetContentLabel()
    local ok, result = pcall(function()
        if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive() then
            local level = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
            return level and ("M+" .. level) or "M+"
        end

        if C_PartyInfo and C_PartyInfo.IsDelveInProgress and C_PartyInfo.IsDelveInProgress() then
            return L["HIST_CTX_DELVE"]
        end

        local inInstance = IsInInstance()
        if not inInstance then return nil end

        local _, iType, difficultyID, difficultyName = GetInstanceInfo()
        if difficultyID == 24 or difficultyID == 33 then
            return L["HIST_CTX_TIMEWALKING"]
        elseif iType == "raid" then
            return difficultyName or L["HIST_CTX_RAID"]
        elseif iType == "party" then
            return difficultyName or L["HIST_CTX_DUNGEON"]
        elseif iType == "pvp" or iType == "arena" then
            return difficultyName or L["HIST_CTX_PVP"]
        elseif iType == "scenario" then
            return L["HIST_CTX_SCENARIO"]
        end
        return difficultyName
    end)
    if ok then return result end
    return nil
end

local function ScanGroup()
    if not PD:OPT_Get("trackGroupHistory") then return end
    local context = GetContentLabel()

    -- Only Mythic+ groups are worth tracking - raids, heroics, timewalking,
    -- delves, scenarios, PvP and out-of-instance groups are filtered out.
    if not context or not context:find("^M%+") then return end

    local isRaid  = IsInRaid()
    local num     = GetNumGroupMembers()
    for i = 1, num do
        local unit = isRaid and ("raid" .. i) or ("party" .. i)
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm, ok = PD:SafeUnitName(unit)
            if ok and name then
                realm = (realm and realm ~= "") and realm or PD.GetMyRealm()
                local key   = PD:GetKey(name, realm)
                local _, class = UnitClass(unit)
                local guid  = UnitGUID(unit)
                local role  = (UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)) or "NONE"
                local isNew = not seenThisGroup[key]
                PD:GH_Record(name, realm, class, role, guid, isNew, context)
                seenThisGroup[key] = true
            end
        end
    end
end

local ghEventFrame = CreateFrame("Frame", "PDGroupHistoryEvents")
ghEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
ghEventFrame:RegisterEvent("GROUP_LEFT")
ghEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local ghUpdatePending = false

ghEventFrame:SetScript("OnEvent", function(_, event)
    if event == "GROUP_ROSTER_UPDATE" then
        if not ghUpdatePending then
            ghUpdatePending = true
            C_Timer.After(0.6, function()
                ghUpdatePending = false
                ScanGroup()
            end)
        end
    elseif event == "GROUP_LEFT" then
        wipe(seenThisGroup)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, ScanGroup)
    end
end)

-- ================================================================
-- 3.  HELPERS
-- ================================================================

local function RoleText(role)
    if     role == "TANK"    then return L["HIST_ROLE_TANK"]
    elseif role == "HEALER"  then return L["HIST_ROLE_HEALER"]
    elseif role == "DAMAGER" then return L["HIST_ROLE_DAMAGER"]
    else                          return L["HIST_ROLE_NONE"]
    end
end

function PD:GH_RoleText(role)
    return RoleText(role)
end

-- ================================================================
-- 4.  HISTORY PANEL (Tab 4)
-- ================================================================

local GetHistRow, HideAllHistRows = PD:NewRowPool()

-- Column offsets (shared with Players/Ignore List tabs, PD.COL)
local H_COL_NAME  = PD.COL.NAME
local H_COL_REALM = PD.COL.REALM
local H_COL_ROLE  = PD.COL.ROLE
local H_COL_MODE  = PD.COL.MODE
local H_COL_SEEN  = PD.COL.SEIT
local H_COL_COUNT = PD.COL.LAST
local H_ROW_H     = 40
local H_ROW_PAD   = 2

function PD:BuildHistoryPanel(panel)
    if panel._histBuilt then return end
    panel._histBuilt = true

    local heads = {
        { text = L["HIST_COL_NAME"],  x = H_COL_NAME  },
        { text = L["HIST_COL_REALM"], x = H_COL_REALM },
        { text = L["HIST_COL_ROLE"],  x = H_COL_ROLE  },
        { text = L["HIST_COL_MODE"],  x = H_COL_MODE  },
        { text = L["HIST_COL_SEEN"],  x = H_COL_SEEN  },
        { text = L["HIST_COL_COUNT"], x = H_COL_COUNT },
    }
    PD:BuildColumnHeaders(panel, heads)

    local sf = CreateFrame("ScrollFrame", "PDHistScrollFrame", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4,  -22)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 32)
    local content = CreateFrame("Frame", "PDHistScrollContent", sf)
    content:SetWidth(sf:GetWidth())
    content:SetHeight(1)
    sf:SetScrollChild(content)
    panel.histContent = content

    local clearBtn = CreateFrame("Button", "PDClearHistoryBtn", panel, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetText(L["BTN_CLEAR_ALL"])
    clearBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 6)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("PD_CONFIRM_CLEAR_HISTORY")
    end)
end

function PD:RefreshHistoryPanel()
    local myRealm = PD.GetMyRealm()
    local panel = PD.panel3
    if not panel or not panel.histContent then return end
    local content = panel.histContent
    HideAllHistRows()

    local all  = PD:GH_GetAll()
    local list = {}
    for _, e in pairs(all) do list[#list + 1] = e end
    table.sort(list, function(a, b) return (a.lastSeen or 0) > (b.lastSeen or 0) end)

    local count = #list
    if PD.mainFrame then
        PD.mainFrame.subtitle:SetText(
            count == 0 and L["SUB_NO_HISTORY"] or
            (count == 1 and L["SUB_1_HISTORY"] or string.format(L["SUB_N_HISTORY"], count))
        )
    end

    if count == 0 then
        if not panel.emptyLabel then
            panel.emptyLabel = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            panel.emptyLabel:SetPoint("TOP", content, "TOP", 0, -40)
            panel.emptyLabel:SetText(L["HIST_EMPTY"])
            panel.emptyLabel:SetJustifyH("CENTER")
        end
        panel.emptyLabel:Show()
        content:SetHeight(100)
        return
    end
    if panel.emptyLabel then panel.emptyLabel:Hide() end

    local rowW = content:GetWidth() - 4
    local yOff = -H_ROW_PAD

    for i, e in ipairs(list) do
        local row = GetHistRow(content)
        row:SetSize(rowW, H_ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOff)
        row:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
        if i % 2 == 0 then row:SetBackdropColor(0.08, 0.08, 0.10, 0.55)
        else                row:SetBackdropColor(0.13, 0.13, 0.17, 0.55) end

        if not row.nameLabel then
            row.nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameLabel:SetPoint("LEFT", row, "LEFT", H_COL_NAME, 0)
            row.nameLabel:SetWidth(H_COL_REALM - H_COL_NAME - 4)
            row.nameLabel:SetJustifyH("LEFT")
        end
        local cc = PD:OPT_Get("classColors") and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
        if cc then row.nameLabel:SetTextColor(cc.r, cc.g, cc.b)
        else       row.nameLabel:SetTextColor(1, 1, 1) end
        row.nameLabel:SetText(e.name or "?")

        if not row.realmLabel then
            row.realmLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.realmLabel:SetPoint("LEFT", row, "LEFT", H_COL_REALM, 0)
            row.realmLabel:SetWidth(H_COL_ROLE - H_COL_REALM - 4)
            row.realmLabel:SetJustifyH("LEFT")
            row.realmLabel:SetTextColor(0.78, 0.78, 0.78)
        end
        row.realmLabel:SetText(e.realm or myRealm)

        if not row.roleLabel then
            row.roleLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.roleLabel:SetPoint("LEFT", row, "LEFT", H_COL_ROLE, 0)
            row.roleLabel:SetWidth(H_COL_MODE - H_COL_ROLE - 4)
            row.roleLabel:SetJustifyH("LEFT")
        end
        row.roleLabel:SetText(RoleText(e.role))

        if not row.modeLabel then
            row.modeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.modeLabel:SetPoint("LEFT", row, "LEFT", H_COL_MODE, 0)
            row.modeLabel:SetWidth(H_COL_SEEN - H_COL_MODE - 4)
            row.modeLabel:SetJustifyH("LEFT")
            row.modeLabel:SetTextColor(0.6, 0.85, 1)
        end
        row.modeLabel:SetText(e.context or "|cff444444-|r")

        if not row.seenLabel then
            row.seenLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.seenLabel:SetPoint("LEFT", row, "LEFT", H_COL_SEEN, 0)
            row.seenLabel:SetWidth(H_COL_COUNT - H_COL_SEEN - 4)
            row.seenLabel:SetJustifyH("LEFT")
            row.seenLabel:SetTextColor(0.78, 0.78, 0.78)
        end
        row.seenLabel:SetText(PD:TimeAgo(e.lastSeen))

        if not row.countLabel then
            row.countLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.countLabel:SetPoint("LEFT",  row, "LEFT",  H_COL_COUNT, 0)
            row.countLabel:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            row.countLabel:SetJustifyH("LEFT")
            row.countLabel:SetTextColor(0.78, 0.78, 0.78)
        end
        row.countLabel:SetText(tostring(e.count or 1))

        row:EnableMouse(true)
        local eName, eRealm, eClass, eGuid, eRole = e.name, e.realm, e.class, e.guid, e.role
        row:SetScript("OnMouseUp", function(self, btn)
            if btn ~= "RightButton" then return end
            MenuUtil.CreateContextMenu(UIParent, function(_, root)
                root:CreateTitle("|cff9B82F3" .. eName .. "|r")

                local dEntry = PD:GetEntry(eName, eRealm)
                root:CreateButton(dEntry and L["BTN_EDIT"] or L["MENU_ADD"], function()
                    PD:OpenNoteDialog(eName, eRealm, eClass ~= "UNKNOWN" and eClass or nil, eGuid, dEntry and dEntry.mood or "neutral")
                end)

                local isIgn = PD.IL_IsIgnored and PD:IL_IsIgnored(eName, eRealm)
                root:CreateButton(isIgn and L["BTN_UNIGNORE"] or L["BTN_IGNORE"], function()
                    if isIgn then PD:IL_Remove(eName, eRealm)
                    else PD:IL_PromptIgnore(eName, eRealm) end
                end)

                root:CreateDivider()

                root:CreateButton(L["BTN_COPY_NAME"], function()
                    PD:ShowCopyPopup(eName .. "-" .. eRealm)
                end)

                root:CreateButton("|cffff4444" .. L["MENU_REMOVE"] .. "|r", function()
                    PD:GH_RemoveEntry(eName, eRealm)
                    PD:RefreshHistoryPanel()
                end)
            end)
        end)

        if not row.hlTex then
            row.hlTex = row:CreateTexture(nil, "HIGHLIGHT")
            row.hlTex:SetAllPoints()
            row.hlTex:SetColorTexture(1, 1, 1, 0.05)
            row.hlTex:SetBlendMode("ADD")
        end

        yOff = yOff - H_ROW_H - H_ROW_PAD
    end
    content:SetHeight(math.abs(yOff) + H_ROW_PAD)
end

-- ================================================================
-- 5.  INIT-HOOK
-- ================================================================

local origGHInit = PD.Init
PD.Init = function(self)
    origGHInit(self)
    PD:GH_Init()
end
