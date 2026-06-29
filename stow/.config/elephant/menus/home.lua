-- ============================================================
--  Home — árvore de bookmarks navegável (landing do Walker)
--
--  Estado vazio do launcher (MOD3+Space). Drill-down estilo
--  filesystem: Enter entra numa pasta, "← Voltar" sobe um nível,
--  Enter num link abre no browser. Digitar qualquer letra troca
--  para a busca de apps (provider `default` no config.toml).
--
--  Estratégia deixou de ser provider próprio: virou o branch
--  `estrategia` desta árvore (mesmo motor de navegação).
--
--  Edite CURATED (links pessoais) e os DATA da Estratégia abaixo.
-- ============================================================

Name = "home"
NamePretty = "Home"
Icon = "view-grid-symbolic"
Description = "Explore"
SearchName = true
Cache = false
FixedOrder = true
HideFromProviderlist = true

local HOME = os.getenv("HOME")
local LAUNCHER = HOME .. "/.config/hypr/walker-launch.sh"
local TODO_FILE = HOME .. "/.ovault/Work/TODO.md"

-- `After` por entry: launch/link fecham o walker; drill/back recarregam
-- o provider com o novo estado (mantêm o walker aberto).
local AFTER_CLOSE = "Close"
local AFTER_RELOAD = "AsyncClearReload"

local BACK_VALUE = "__back__"
local ESTRATEGIA_BRANCH = "estrategia"
local VERTICAL_FOLDER = "vertical"

Actions = {
  open = "lua:OpenUrl",
  drill = "lua:DrillDown",
  back = "lua:Back",
  launch = "lua:Launch",
}

-- ── DATA: bookmarks pessoais (edite à vontade) ────────────────
-- Pasta = tem `children`. Link = tem `url`. `estrategia=true` delega
-- ao motor da Estratégia (DATA logo abaixo).

local CURATED = {
  {
    key = "estrategia",
    label = "Estratégia",
    subtext = "ambientes · pastas · sites",
    icon = "emblem-system",
    estrategia = true,
  },
  {
    key = "dev",
    label = "Dev",
    subtext = "repositórios e CI",
    icon = "folder-development",
    children = {
      { label = "Coruja", subtext = "github.com/estrategiahq/coruja", icon = "folder-remote", url = "https://github.com/estrategiahq/coruja" },
      { label = "PRs do Coruja", subtext = "review pendente", icon = "folder-remote", url = "https://github.com/estrategiahq/coruja/pulls" },
    },
  },
  {
    key = "pessoal",
    label = "Pessoal",
    subtext = "edite CURATED em home.lua",
    icon = "user-bookmarks",
    children = {
      { label = "Adicione seus links aqui", subtext = "home.lua › CURATED › pessoal", icon = "bookmark-new", url = "https://github.com" },
    },
  },
}

-- ── DATA: Estratégia (ambiente × pasta × vertical) ────────────
-- Migrado de estrategia.lua. Substitua os "TODO" por URLs reais.

local ENVS = {
  prod = { label = "Production", subtext = "estrategia.com", icon = "network-transmit-receive" },
  sandbox = { label = "Sandbox", subtext = "local.estrategia-sandbox.com.br", icon = "network-server" },
  global = { label = "Global", subtext = "ferramentas compartilhadas", icon = "network-workgroup" },
}

local FOLDERS = {
  vertical = { label = "Verticais", subtext = "militares · vestibulares · concursos · …", icon = "folder" },
  grafana = { label = "Grafana", subtext = "dashboards", icon = "utilities-system-monitor" },
  newrelic = { label = "New Relic", subtext = "APM · logs", icon = "utilities-system-monitor" },
  metabase = { label = "Metabase", subtext = "BI / queries", icon = "x-office-spreadsheet" },
  tc = { label = "TC", subtext = "teamcity / CI", icon = "utilities-terminal" },
}

local VERTICALS = {
  militares = { label = "Militares", slug = "militares", icon = "emblem-default" },
  vestibulares = { label = "Vestibulares", slug = "vestibulares", icon = "emblem-default" },
  concursos = { label = "Concursos", slug = "concursos", icon = "emblem-default" },
  smedicina = { label = "Medicina", slug = "medicina", icon = "emblem-default" },
  oab = { label = "OAB", slug = "oab", icon = "emblem-default" },
  ecj = { label = "Carreiras Jurídicas", slug = "carreiras-juridicas", icon = "emblem-default" },
}

local VERTICAL_URLS = {
  sandbox = {
    militares = "http://militares.local.estrategia-sandbox.com.br",
    vestibulares = "http://vestibulares.local.estrategia-sandbox.com.br",
    concursos = "http://concursos.local.estrategia-sandbox.com.br",
    smedicina = "http://medicina.local.estrategia-sandbox.com.br",
    oab = "http://oab.local.estrategia.com",
    ecj = "http://carreiras-juridicas.local.estrategia-sandbox.com.br",
  },
  prod = {
    militares = "https://militares.estrategia.com.br",
    vestibulares = "https://vestibulares.estrategia.com.br",
    concursos = "https://concursos.estrategia.com.br",
    smedicina = "https://medicina.estrategia.com.br",
    oab = "https://oab.estrategia.com.br",
    ecj = "https://carreiras-juridicas.estrategia.com.br",
  },
  global = {
    militares = "https://militares.estrategia.com.br",
    vestibulares = "https://vestibulares.estrategia.com.br",
    concursos = "https://concursos.estrategia.com.br",
    smedicina = "https://medicina.estrategia.com.br",
    oab = "https://oab.estrategia.com.br",
    ecj = "https://carreiras-juridicas.estrategia.com.br",
  },
}

local VERTICAL_EXTRAS = {}

local TOOL_LINKS = {
  sandbox = {
    grafana = {
      { label = "Overview", subtext = "TODO", url = "https://grafana.sandbox.estrategia.com.br" },
      { label = "API latency", subtext = "TODO", url = "https://grafana.sandbox.estrategia.com.br/d/TODO" },
    },
    newrelic = { { label = "APM", subtext = "TODO", url = "https://one.newrelic.com/TODO" } },
    metabase = { { label = "Home", subtext = "TODO", url = "https://metabase.sandbox.estrategia.com.br" } },
    tc = { { label = "Builds", subtext = "TODO", url = "https://tc.estrategia.com/TODO" } },
  },
  prod = {
    grafana = { { label = "Overview", subtext = "TODO", url = "https://grafana.estrategia.com.br" } },
    newrelic = { { label = "APM", subtext = "TODO", url = "https://one.newrelic.com/TODO" } },
    metabase = { { label = "Home", subtext = "TODO", url = "https://metabase.estrategia.com.br" } },
    tc = { { label = "Builds", subtext = "TODO", url = "https://tc.estrategia.com/TODO" } },
  },
  global = {
    grafana = { { label = "Overview", subtext = "TODO", url = "https://grafana.estrategia.com.br" } },
    newrelic = { { label = "APM", subtext = "TODO", url = "https://one.newrelic.com/TODO" } },
    metabase = { { label = "Home", subtext = "TODO", url = "https://metabase.estrategia.com.br" } },
    tc = { { label = "Builds", subtext = "TODO", url = "https://tc.estrategia.com/TODO" } },
  },
}

-- ── helpers ───────────────────────────────────────────────────

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function slice(list, from)
  local out = {}
  for i = from, #list do
    table.insert(out, list[i])
  end
  return out
end

function find_curated(key)
  for _, top in ipairs(CURATED) do
    if top.key == key then
      return top
    end
  end
  return nil
end

function child_key(child)
  if child.key then
    return child.key
  end
  return child.label
end

function find_child(node, key)
  if not node or not node.children then
    return nil
  end
  for _, child in ipairs(node.children) do
    if child_key(child) == key then
      return child
    end
  end
  return nil
end

function launch_cmd(provider, theme)
  local extra = ""
  if theme then
    extra = " --theme " .. theme
  end
  return LAUNCHER .. extra .. " --provider " .. provider
end

function todo_count()
  local f = io.open(TODO_FILE, "r")
  if not f then
    return 0
  end
  local pending = 0
  for line in f:lines() do
    if line:match("^%- %[ %]") then
      pending = pending + 1
    end
  end
  f:close()
  return pending
end

-- ── entry builders ────────────────────────────────────────────

function folder_entry(label, subtext, icon, key)
  return {
    Text = label,
    Subtext = subtext,
    Icon = icon,
    Value = key,
    After = AFTER_RELOAD,
    Actions = { open = "lua:DrillDown" },
  }
end

function link_entry(label, subtext, icon, url)
  return {
    Text = label,
    Subtext = subtext or url,
    Icon = icon or "emblem-symbolic-link",
    Value = url,
    After = AFTER_CLOSE,
    Actions = { open = "lua:OpenUrl" },
  }
end

function launch_entry(label, subtext, icon, cmd)
  return {
    Text = label,
    Subtext = subtext,
    Icon = icon,
    Value = cmd,
    After = AFTER_CLOSE,
    Actions = { open = "lua:Launch" },
  }
end

function back_entry(crumb)
  return {
    Text = "← Voltar",
    Subtext = crumb,
    Icon = "go-previous",
    Value = BACK_VALUE,
    After = AFTER_RELOAD,
    Actions = { open = "lua:Back" },
  }
end

function separator()
  return {
    Text = "────────",
    Subtext = "",
    Icon = "separator",
    Value = "",
    After = AFTER_RELOAD,
    Actions = { open = "lua:Noop" },
  }
end

function empty_warning(message)
  return {
    Text = "Sem links configurados",
    Subtext = message,
    Icon = "dialog-warning",
    Value = "",
    After = AFTER_RELOAD,
    Actions = { open = "lua:Noop" },
  }
end

-- ── navigation actions ────────────────────────────────────────

function DrillDown(value)
  if value == BACK_VALUE then
    Back()
    return
  end
  local s = state() or {}
  table.insert(s, value)
  setState(s)
end

function Back()
  local s = state() or {}
  if #s > 0 then
    table.remove(s)
  end
  setState(s)
end

function OpenUrl(value)
  if not value or value == "" then
    return
  end
  os.execute("xdg-open " .. quote(value) .. " >/dev/null 2>&1 &")
end

function Launch(value)
  if not value or value == "" then
    return
  end
  os.execute(value .. " >/dev/null 2>&1 &")
end

function Noop()
end

-- ── breadcrumb ────────────────────────────────────────────────

function estrategia_crumb(parts, sub)
  local env_key = sub[1]
  if env_key and ENVS[env_key] then
    table.insert(parts, ENVS[env_key].label)
  end
  local folder_key = sub[2]
  if folder_key == VERTICAL_FOLDER then
    table.insert(parts, FOLDERS.vertical.label)
  elseif folder_key and FOLDERS[folder_key] then
    table.insert(parts, FOLDERS[folder_key].label)
  end
  local vertical_key = sub[3]
  if folder_key == VERTICAL_FOLDER and vertical_key and VERTICALS[vertical_key] then
    table.insert(parts, VERTICALS[vertical_key].label)
  end
end

function curated_crumb(parts, top, sub)
  local node = top
  for _, key in ipairs(sub) do
    node = find_child(node, key)
    if not node then
      return
    end
    table.insert(parts, node.label)
  end
end

function breadcrumb(s)
  if #s == 0 then
    return "Explore · Enter entra · digite para apps"
  end
  local top = find_curated(s[1])
  if not top then
    return "Explore"
  end
  local parts = { top.label }
  local sub = slice(s, 2)
  if top.estrategia then
    estrategia_crumb(parts, sub)
  else
    curated_crumb(parts, top, sub)
  end
  return table.concat(parts, " › ")
end

-- ── levels: root + curated ────────────────────────────────────

function root_level()
  local entries = {}
  for _, top in ipairs(CURATED) do
    table.insert(entries, folder_entry(top.label, top.subtext, top.icon, top.key))
  end
  table.insert(entries, separator())

  local pending = todo_count()
  local todo_subtext = "vazio · Enter cria"
  if pending > 0 then
    todo_subtext = pending .. " pendente(s) · Enter abre"
  end
  table.insert(entries, launch_entry("TODO", todo_subtext, "checkbox-checked-symbolic", launch_cmd("menus:todo")))
  table.insert(entries, launch_entry("Bookmarks do browser", "b: · favoritos do Chrome", "bookmark", launch_cmd("bookmarks")))
  table.insert(entries, launch_entry("Arquivos", "/ · downloads e screenshots", "folder-recent", launch_cmd("files")))
  table.insert(entries, launch_entry("Janelas", "w: · trocar de janela", "window-restore", launch_cmd("windows")))
  table.insert(entries, launch_entry("Clipboard", ": · histórico de cópias", "edit-copy", launch_cmd("clipboard")))
  table.insert(entries, launch_entry("Hub", "! · status e atalhos", "view-grid-symbolic", launch_cmd("menus:dash")))
  return entries
end

function curated_level(top, sub, crumb)
  local node = top
  for _, key in ipairs(sub) do
    node = find_child(node, key)
    if not node then
      break
    end
  end

  local entries = { back_entry(crumb) }
  if not node or not node.children then
    return entries
  end
  for _, child in ipairs(node.children) do
    if child.children then
      table.insert(entries, folder_entry(child.label, child.subtext, child.icon, child_key(child)))
    else
      table.insert(entries, link_entry(child.label, child.subtext, child.icon, child.url))
    end
  end
  return entries
end

-- ── levels: Estratégia (sub = estado sem o prefixo "estrategia") ──

function sorted_keys(map)
  local keys = {}
  for k in pairs(map) do
    table.insert(keys, k)
  end
  table.sort(keys, function(a, b)
    return (map[a].label or a) < (map[b].label or b)
  end)
  return keys
end

function estrategia_envs(crumb)
  local entries = { back_entry(crumb) }
  for _, key in ipairs(sorted_keys(ENVS)) do
    local env = ENVS[key]
    table.insert(entries, folder_entry(env.label, env.subtext, env.icon, key))
  end
  return entries
end

function estrategia_folders(crumb)
  local entries = { back_entry(crumb) }
  for _, key in ipairs(sorted_keys(FOLDERS)) do
    local folder = FOLDERS[key]
    table.insert(entries, folder_entry(folder.label, folder.subtext, folder.icon, key))
  end
  return entries
end

function estrategia_verticals(crumb)
  local entries = { back_entry(crumb) }
  for _, key in ipairs(sorted_keys(VERTICALS)) do
    local vertical = VERTICALS[key]
    table.insert(entries, folder_entry(vertical.label, vertical.slug, vertical.icon, key))
  end
  return entries
end

function estrategia_vertical_sites(env_key, vertical_key, crumb)
  local entries = { back_entry(crumb) }
  local urls = VERTICAL_URLS[env_key] or {}
  local portal = urls[vertical_key]
  if portal then
    table.insert(entries, link_entry("Portal", portal, "internet-services", portal))
  end
  local extras = (VERTICAL_EXTRAS[env_key] or {})[vertical_key] or {}
  for _, item in ipairs(extras) do
    table.insert(entries, link_entry(item.label, item.subtext or item.url, "web-browser", item.url))
  end
  if #entries == 1 then
    table.insert(entries, empty_warning("edite VERTICAL_URLS em home.lua"))
  end
  return entries
end

function estrategia_tool_links(env_key, folder_key, crumb)
  local entries = { back_entry(crumb) }
  local links = ((TOOL_LINKS[env_key] or {})[folder_key]) or {}
  for _, item in ipairs(links) do
    table.insert(entries, link_entry(item.label, item.subtext or item.url, "internet-services", item.url))
  end
  if #entries == 1 then
    table.insert(entries, empty_warning("edite TOOL_LINKS em home.lua"))
  end
  return entries
end

function estrategia_level(sub, crumb)
  if #sub == 0 then
    return estrategia_envs(crumb)
  end

  local env_key = sub[1]
  if not ENVS[env_key] then
    setState({ ESTRATEGIA_BRANCH })
    return estrategia_envs(crumb)
  end
  if #sub == 1 then
    return estrategia_folders(crumb)
  end

  local folder_key = sub[2]
  if folder_key == VERTICAL_FOLDER then
    if #sub == 2 then
      return estrategia_verticals(crumb)
    end
    return estrategia_vertical_sites(env_key, sub[3], crumb)
  end
  if FOLDERS[folder_key] then
    return estrategia_tool_links(env_key, folder_key, crumb)
  end

  setState({ ESTRATEGIA_BRANCH, env_key })
  return estrategia_folders(crumb)
end

-- ── entry point ───────────────────────────────────────────────

function GetEntries()
  local s = state() or {}
  local crumb = breadcrumb(s)
  Description = crumb

  if #s == 0 then
    return root_level()
  end

  local top = find_curated(s[1])
  if not top then
    setState({})
    return root_level()
  end

  local sub = slice(s, 2)
  if top.estrategia then
    return estrategia_level(sub, crumb)
  end
  return curated_level(top, sub, crumb)
end
