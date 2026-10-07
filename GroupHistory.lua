-- ============================================================
--  PlayerDossier – GroupHistory.lua
--  Logs everyone you group with in Mythic+ (name, realm, class,
--  role, key level) so you can retroactively add them to the
--  Dossier or Ignore List after the group has disbanded.
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
-- 1.  DB LAYER
-- ================================================================

function PD:GH_GetAll()
    return (PlayerDossierDB and PlayerDossierDB.history) or {}
end

function PD:GH_GetEntry(name, realm)
    if not PlayerDossierDB or not PlayerDossierDB.history then return nil end
    return PlayerDossierDB.history[PD:GetKey(name, realm)]
end

local function TrimHistory()
    local h = PlayerDossierDB.history
    local n = PD.TableCount(h)
    if n <= MAX_HISTORY then return end

    local list = {}
    for k, e in pairs(h) do list[#list + 1] = { k = k, ts = e.lastSeen or 0 } end
    table.sort(list, function(a, b) return a.ts < b.ts end)
    for i = 1, n - MAX_HISTORY do
        h[list[i].k] = nil
    end
end

-- isNewInGroup: true only on the first tick a player is seen in the
--   current, continuous group membership → bumps the "grouped" counter.
-- context: content label at the time of recording (e.g. "M+15"); nil if
--   unknown. Only overwrites the stored value when a fresh label is
--   known, so it isn't wiped again on the way out of the instance.
function PD:GH_Record(name, realm, class, role, guid, isNewInGroup, context)
    realm = PD.NormRealm(realm)
    local key = PD:GetKey(name, realm)
    local h   = PlayerDossierDB.history
    local e   = h[key]

    if e then
        e.lastSeen = time()
        if class and class ~= "UNKNOWN" then e.class = class end
        if role  and role  ~= "NONE"    then e.role  = role  end
        if guid  and guid  ~= ""        then e.guid  = guid  end
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

-- Content label of the current group ("M+<level>", "Delve", ...), or nil
-- if unknown/not in an instance. pcall'd since not every API exists on
-- every client build.
local function GetContentLabel()
    local ok, result = pcall(function()
        if PD:IsMythicPlusActive() then
            local level = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
            return level and ("M+" .. level) or "M+"
        end

        if C_PartyInfo and C_PartyInfo.IsDelveInProgress and C_PartyInfo.IsDelveInProgress() then
            return L["HIST_CTX_DELVE"]
        end

        if not IsInInstance() then return nil end

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
    return ok and result or nil
end

local function ScanGroup()
    if not PD:OPT_Get("trackGroupHistory") then return end
    local context = GetContentLabel()

    -- Only Mythic+ groups are worth tracking - raids, heroics, timewalking,
    -- delves, scenarios, PvP and groups outside instances are skipped.
    if not context or not context:find("^M%+") then return end

    PD:ForEachGroupMember(function(unit, name, realm)
        local key      = PD:GetKey(name, realm)
        local _, class = UnitClass(unit)
        local role     = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or "NONE"
        PD:GH_Record(name, realm, class, role, UnitGUID(unit), not seenThisGroup[key], context)
        seenThisGroup[key] = true
    end)
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
-- 3.  HISTORY PANEL
-- ================================================================

-- Role letter shown in the Role column (also used by the Dossier tab)
local ROLE_KEYS = { TANK = "HIST_ROLE_TANK", HEALER = "HIST_ROLE_HEALER", DAMAGER = "HIST_ROLE_DAMAGER" }

function PD:GH_RoleText(role)
    return L[ROLE_KEYS[role] or "HIST_ROLE_NONE"]
end

local GetHistRow, HideAllHistRows = PD:NewRowPool()

local COL_NAME  = PD.COL.NAME
local COL_REALM = PD.COL.REALM
local COL_ROLE  = PD.COL.ROLE
local COL_MODE  = PD.COL.MODE
local COL_SEEN  = PD.COL.SINCE
local COL_COUNT = PD.COL.LAST
local ROW_H     = 40
local ROW_PAD   = 2

local Lower = PD.Lower

local SORT_GETTERS = {
    name  = function(e) return Lower(e.name) end,
    realm = function(e) return Lower(e.realm) end,
    role  = function(e) return Lower(e.role) end,
    mode  = function(e) return Lower(e.context) end,
    since = function(e) return e.lastSeen or 0 end,
    count = function(e) return e.count or 1 end,
}

function PD:BuildHistoryPanel(panel)
    panel.histContent = PD:BuildListPanel(panel, {
        heads = {
            { text = L["HIST_COL_NAME"],  x = COL_NAME,  key = "name"  },
            { text = L["HIST_COL_REALM"], x = COL_REALM, key = "realm" },
            { text = L["HIST_COL_ROLE"],  x = COL_ROLE,  key = "role"  },
            { text = L["HIST_COL_MODE"],  x = COL_MODE,  key = "mode"  },
            { text = L["HIST_COL_SEEN"],  x = COL_SEEN,  key = "since", descFirst = true },
            { text = L["HIST_COL_COUNT"], x = COL_COUNT, key = "count", descFirst = true },
        },
        sort = {
            id       = "history",
            default  = PD.SORT_DEFAULT,
            onChange = function() PD:RefreshHistoryPanel() end,
        },
        scroll     = "PDHistScrollFrame",
        content    = "PDHistScrollContent",
        clearBtn   = "PDClearHistoryBtn",
        clearPopup = "PD_CONFIRM_CLEAR_HISTORY",
    })
end

local function FillHistoryRow(row, e)
    local nameLabel = PD:RowLabel(row, "nameLabel", COL_NAME, COL_REALM)
    PD:ApplyNameColor(nameLabel, e.class)
    nameLabel:SetText(e.name or "?")

    PD:RowLabel(row, "realmLabel", COL_REALM, COL_ROLE, nil, 0.78, 0.78, 0.78)
        :SetText(e.realm or PD.GetMyRealm())
    PD:RowLabel(row, "roleLabel", COL_ROLE, COL_MODE):SetText(PD:GH_RoleText(e.role))
    PD:RowLabel(row, "modeLabel", COL_MODE, COL_SEEN, nil, 0.6, 0.85, 1)
        :SetText(e.context or "|cff444444-|r")
    PD:RowLabel(row, "seenLabel", COL_SEEN, COL_COUNT, nil, 0.78, 0.78, 0.78)
        :SetText(PD:TimeAgo(e.lastSeen))
    PD:RowLabel(row, "countLabel", COL_COUNT, nil, nil, 0.78, 0.78, 0.78)
        :SetText(tostring(e.count or 1))

    local eName, eRealm, eClass, eGuid = e.name, e.realm, e.class, e.guid
    PD:SetRowMenu(row, function(root)
        root:CreateTitle("|cff9B82F3" .. eName .. "|r")

        local dEntry = PD:GetEntry(eName, eRealm)
        root:CreateButton(dEntry and L["BTN_EDIT"] or L["MENU_ADD"], function()
            PD:OpenNoteDialog(eName, eRealm, eClass ~= "UNKNOWN" and eClass or nil, eGuid,
                dEntry and dEntry.mood or "neutral")
        end)

        local isIgn = PD:IL_IsIgnored(eName, eRealm)
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
end

function PD:RefreshHistoryPanel()
    local panel = PD.panel3
    if not panel or not panel.histContent then return end
    local list = {}
    for _, e in pairs(PD:GH_GetAll()) do list[#list + 1] = e end
    PD:RenderList({
        panel    = panel,
        content  = panel.histContent,
        list     = list,
        getRow   = GetHistRow,
        hideAll  = HideAllHistRows,
        sortId   = "history",
        getters  = SORT_GETTERS,
        subtitle = { "SUB_NO_HISTORY", "SUB_1_HISTORY", "SUB_N_HISTORY" },
        empty    = { L["HIST_EMPTY"], 40, 100 },
        rowH     = ROW_H,
        pad      = ROW_PAD,
        tint     = PD.ROW_TINT.default,
        fill     = FillHistoryRow,
    })
end
