-- ============================================================
--  LAYOUTS — snapshots de "que apps tinham em quais workspaces"
--
--  Save:    dump JSON em ~/.cache/hyprland/layouts/<name>.json
--           (workspace_id → list de {class, title})
--  List:    enumera nomes
--  Show:    summary humano via notify
--  Diff:    o que está faltando abrir vs snapshot
--
--  Não tenta restore automático — Hyprland scrolling layout + apps com
--  state interno (PWAs, sessões) torna spawn fidedigno fora de escopo.
--  O valor é checklist mental ao recriar setup.
--
--  CLI: hypr-layout {save|list|show|diff} [name]
-- ============================================================

local core = require("core")

local M = {}

local DIR = os.getenv("HOME") .. "/.cache/hyprland/layouts"

local function ensure_dir()
    os.execute("mkdir -p " .. DIR)
end

local function path(name) return DIR .. "/" .. name .. ".json" end

local function escape_json(s)
    return (s or ""):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
end

-- ── save(name) ───────────────────────────────────────────────
function M.save(name)
    if not name or name == "" then return "ERR: nome vazio" end
    ensure_dir()

    local by_ws = {}  -- { [ws_id] = { {class, title}, ... } }
    for _, c in ipairs(core.clients_cached()) do
        local wid = c.workspace and c.workspace.id
        if wid then
            by_ws[wid] = by_ws[wid] or {}
            table.insert(by_ws[wid], { class = c.class or "", title = c.title or "" })
        end
    end

    local parts = {
        string.format('"name":"%s"', escape_json(name)),
        string.format('"saved_at":%d', os.time()),
    }
    local ws_parts = {}
    for wid, items in pairs(by_ws) do
        local item_parts = {}
        for _, it in ipairs(items) do
            table.insert(item_parts, string.format(
                '{"class":"%s","title":"%s"}',
                escape_json(it.class), escape_json(it.title)))
        end
        table.insert(ws_parts, string.format(
            '"%s":[%s]', tostring(wid), table.concat(item_parts, ",")))
    end
    table.insert(parts, '"workspaces":{' .. table.concat(ws_parts, ",") .. "}")

    local json = "{" .. table.concat(parts, ",") .. "}"
    local f = io.open(path(name), "w")
    if not f then return "ERR: nao consegui escrever " .. path(name) end
    f:write(json)
    f:close()

    local total_ws, total_clients = 0, 0
    for _, items in pairs(by_ws) do
        total_ws = total_ws + 1
        total_clients = total_clients + #items
    end
    core.notify("📐 Layout salvo: " .. name,
        total_clients .. " janelas em " .. total_ws .. " workspaces",
        { timeout = 1500, urgency = "low" })
    return "saved: " .. name .. " (" .. total_clients ..
        " janelas em " .. total_ws .. " workspaces)"
end

-- ── list() ───────────────────────────────────────────────────
function M.list()
    ensure_dir()
    local out = {}
    -- io.popen é OK aqui — chamado raramente, sob demanda do usuário
    local p = io.popen("ls -1 " .. DIR .. "/*.json 2>/dev/null | sed 's|.*/||;s|\\.json$||'")
    if not p then return "" end
    for line in p:lines() do table.insert(out, line) end
    p:close()
    if #out == 0 then return "(nenhum layout salvo)" end
    return table.concat(out, "\n")
end

-- Parser simples do JSON salvo (formato controlado por nós; sem dependência externa).
local function parse_snapshot(name)
    local f = io.open(path(name), "r")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()
    if not raw then return nil end

    local snap = { name = name, workspaces = {} }
    snap.saved_at = tonumber(raw:match('"saved_at":(%d+)'))

    -- Extrai o bloco "workspaces":{...}
    local ws_block = raw:match('"workspaces"%s*:%s*(%b{})')
    if not ws_block then return snap end

    -- Itera "<id>":[...]
    for ws_id, arr in ws_block:gmatch('"([^"]+)"%s*:%s*(%b[])') do
        local items = {}
        for obj in arr:gmatch('%b{}') do
            local cls   = obj:match('"class"%s*:%s*"([^"]*)"')   or ""
            local title = obj:match('"title"%s*:%s*"([^"]*)"')   or ""
            table.insert(items, { class = cls, title = title })
        end
        snap.workspaces[ws_id] = items
    end
    return snap
end

-- ── show(name) ───────────────────────────────────────────────
function M.show(name)
    local snap = parse_snapshot(name)
    if not snap then return "ERR: " .. name .. " não existe" end

    local lines = { "Layout: " .. snap.name ..
        " (saved " .. os.date("%Y-%m-%d %H:%M", snap.saved_at) .. ")" }
    local ws_ids = {}
    for id in pairs(snap.workspaces) do table.insert(ws_ids, id) end
    table.sort(ws_ids, function(a, b) return tonumber(a) < tonumber(b) end)

    for _, wid in ipairs(ws_ids) do
        local items = snap.workspaces[wid]
        local classes = {}
        for _, it in ipairs(items) do table.insert(classes, it.class) end
        table.insert(lines, "  ws " .. wid .. " (" .. #items .. "): " ..
            table.concat(classes, ", "))
    end
    return table.concat(lines, "\n")
end

-- ── diff(name) — o que falta abrir pra bater com o snapshot ──
function M.diff(name)
    local snap = parse_snapshot(name)
    if not snap then return "ERR: " .. name .. " não existe" end

    -- Conta classes presentes atualmente
    local present = {}  -- { [class] = count }
    for _, c in ipairs(core.clients_cached()) do
        local k = c.class or ""
        present[k] = (present[k] or 0) + 1
    end

    -- Conta classes no snapshot
    local wanted = {}
    for _, items in pairs(snap.workspaces) do
        for _, it in ipairs(items) do
            wanted[it.class] = (wanted[it.class] or 0) + 1
        end
    end

    local missing, extra = {}, {}
    for cls, n in pairs(wanted) do
        local have = present[cls] or 0
        if have < n then
            table.insert(missing, cls .. " (faltam " .. (n - have) .. ")")
        end
    end
    for cls, n in pairs(present) do
        local need = wanted[cls] or 0
        if n > need and need > 0 then
            table.insert(extra, cls .. " (sobram " .. (n - need) .. ")")
        end
    end

    local lines = { "Diff vs layout '" .. name .. "':" }
    if #missing == 0 and #extra == 0 then
        table.insert(lines, "  ✅ tudo certo")
    else
        if #missing > 0 then
            table.insert(lines, "  faltando:")
            for _, m in ipairs(missing) do table.insert(lines, "    - " .. m) end
        end
        if #extra > 0 then
            table.insert(lines, "  a mais:")
            for _, e in ipairs(extra) do table.insert(lines, "    + " .. e) end
        end
    end
    return table.concat(lines, "\n")
end

-- Globals pra REPL/CLI usar via hyprlua-eval
function layouts_save(n)  return M.save(n)   end
function layouts_list()    return M.list()   end
function layouts_show(n)   return M.show(n)  end
function layouts_diff(n)   return M.diff(n)  end

return M
