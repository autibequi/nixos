-- ============================================================
--  REPL — debug live sem reload do Hyprland
--
--  Protocolo file-based (sem socket Unix; Lua puro):
--    Cliente:  echo 'return #hl.get_clients()' > /tmp/hyprlua.in
--              cat /tmp/hyprlua.out
--    Server:   timer a cada 250ms; se .in não-vazio, executa via load(),
--              escreve resultado em .out, trunca .in.
--
--  Helper CLI: ~/.local/bin/hyprlua-eval (gerado on demand pelo usuário)
--    #!/bin/sh
--    printf '%s' "$*" > /tmp/hyprlua.in
--    while [ -s /tmp/hyprlua.in ]; do sleep 0.05; done
--    cat /tmp/hyprlua.out
-- ============================================================

local IN_FILE  = "/tmp/hyprlua.in"
local OUT_FILE = "/tmp/hyprlua.out"
local LOG_FILE = "/tmp/hyprlua.log"

local function read_all(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local function write_all(path, s)
    local f = io.open(path, "w")
    if not f then return end
    f:write(s)
    f:close()
end

local function format_result(ok, ...)
    if not ok then
        local err = (select(1, ...)) or "?"
        return "ERR: " .. tostring(err)
    end
    local n = select("#", ...)
    if n == 0 then return "ok" end
    local parts = {}
    for i = 1, n do
        local v = select(i, ...)
        local t = type(v)
        if t == "table" then
            -- shallow dump (chave=valor)
            local kvs = {}
            for k, vv in pairs(v) do
                table.insert(kvs, tostring(k) .. "=" .. tostring(vv))
            end
            parts[i] = "{" .. table.concat(kvs, ", ") .. "}"
        else
            parts[i] = tostring(v)
        end
    end
    return table.concat(parts, "\t")
end

local function eval_chunk(src)
    -- "return EXPR" → expression; senão chunk de statements
    local fn, err = load("return (" .. src .. ")", "repl", "t", _G)
    if not fn then
        fn, err = load(src, "repl", "t", _G)
        if not fn then return "ERR-COMPILE: " .. tostring(err) end
    end
    return format_result(pcall(fn))
end

local function poll()
    local src = read_all(IN_FILE)
    if not src or src == "" then return end
    local result = eval_chunk(src)
    write_all(OUT_FILE, result .. "\n")
    write_all(IN_FILE, "")
    -- log opcional
    local lf = io.open(LOG_FILE, "a")
    if lf then
        lf:write(os.date("[%H:%M:%S] ") .. src:gsub("\n", " | ") .. " ⟶ " .. result .. "\n")
        lf:close()
    end
end

-- Inicializa arquivos vazios
write_all(IN_FILE, "")
write_all(OUT_FILE, "")

-- Timer periódico
local ok, err = pcall(function()
    hl.timer(poll, { timeout = 250, type = "repeat" })
end)
if not ok then
    hl.exec_cmd("logger -t hyprland-lua 'repl timer falhou: " .. tostring(err) .. "'")
end
