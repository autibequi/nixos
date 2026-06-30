-- Home — bookmarks curáveis + atalhos de lançamento
-- Landing acessível via providerlist (;) ou prefixo futuro.

Name = "home"
NamePretty = "Home"
Icon = "view-grid-symbolic"
Description = "Bookmarks"
SearchName = true
Cache = false
FixedOrder = true
HideFromProviderlist = true

local HOME      = os.getenv("HOME")
local LAUNCHER  = HOME .. "/.config/hypr/walker-launch.sh"
local FLAG_BASE = "/workspace/.cache/yaa-state/skill-flags"

local AFTER_CLOSE  = "Close"
local AFTER_RELOAD = "AsyncClearReload"
local BACK_VALUE   = "__back__"

Actions = {
  open   = "lua:OpenUrl",
  drill  = "lua:DrillDown",
  back   = "lua:Back",
  launch = "lua:Launch",
}

local CURATED = {
  {
    key     = "estrategia",
    label   = "Estratégia",
    subtext = "estrategia.com",
    icon    = "emblem-system",
    url     = "https://estrategia.com",
  },
  {
    key      = "dev",
    label    = "Dev",
    subtext  = "repositórios e CI",
    icon     = "folder-development",
    children = {
      { label = "Coruja",      subtext = "github.com/estrategiahq/coruja",       icon = "folder-remote", url = "https://github.com/estrategiahq/coruja" },
      { label = "PRs do Coruja", subtext = "review pendente",                   icon = "folder-remote", url = "https://github.com/estrategiahq/coruja/pulls" },
    },
  },
  {
    key      = "pessoal",
    label    = "Pessoal",
    subtext  = "edite CURATED em home.lua",
    icon     = "user-bookmarks",
    children = {
      { label = "Adicione seus links aqui", subtext = "home.lua › CURATED › pessoal", icon = "bookmark-new", url = "https://github.com" },
    },
  },
}

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
  return child.key or child.label
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
  local extra = theme and (" --theme " .. theme) or ""
  return LAUNCHER .. extra .. " --provider " .. provider
end

function todo_count()
  local h = io.popen("find " .. quote(FLAG_BASE) .. " -maxdepth 2 -name 'todo.md' 2>/dev/null")
  if not h then
    return 0
  end
  local files = {}
  for line in h:lines() do
    table.insert(files, line)
  end
  h:close()

  local count = 0
  for _, path in ipairs(files) do
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        if line:match("^%- %[ %]") then
          count = count + 1
        end
      end
      f:close()
    end
  end
  return count
end

function folder_entry(label, subtext, icon, key)
  return {
    Text    = label,
    Subtext = subtext,
    Icon    = icon,
    Value   = key,
    After   = AFTER_RELOAD,
    Actions = { open = "lua:DrillDown" },
  }
end

function link_entry(label, subtext, icon, url)
  return {
    Text    = label,
    Subtext = subtext or url,
    Icon    = icon or "emblem-symbolic-link",
    Value   = url,
    After   = AFTER_CLOSE,
    Actions = { open = "lua:OpenUrl" },
  }
end

function launch_entry(label, subtext, icon, cmd)
  return {
    Text    = label,
    Subtext = subtext,
    Icon    = icon,
    Value   = cmd,
    After   = AFTER_CLOSE,
    Actions = { open = "lua:Launch" },
  }
end

function back_entry(label)
  return {
    Text    = "← Voltar",
    Subtext = label,
    Icon    = "go-previous",
    Value   = BACK_VALUE,
    After   = AFTER_RELOAD,
    Actions = { open = "lua:Back" },
  }
end

function separator()
  return {
    Text    = "────────",
    Subtext = "",
    Icon    = "separator",
    Value   = "",
    After   = AFTER_RELOAD,
    Actions = { open = "lua:Noop" },
  }
end

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

function Noop() end

function root_level()
  local entries = {}

  for _, top in ipairs(CURATED) do
    if top.url then
      table.insert(entries, link_entry(top.label, top.subtext, top.icon, top.url))
    else
      table.insert(entries, folder_entry(top.label, top.subtext, top.icon, top.key))
    end
  end

  table.insert(entries, separator())

  local pending = todo_count()
  local todo_sub = pending > 0 and (pending .. " pendente(s) · Enter abre") or "vazio · Enter cria"
  table.insert(entries, launch_entry("TODO",              todo_sub,                       "checkbox-checked-symbolic", launch_cmd("menus:todo")))
  table.insert(entries, launch_entry("Bookmarks",         "b: · favoritos do Chrome",     "bookmark",                  launch_cmd("bookmarks")))
  table.insert(entries, launch_entry("Arquivos",          "/ · downloads e screenshots",  "folder-recent",             launch_cmd("files")))
  table.insert(entries, launch_entry("Janelas",           "w: · trocar de janela",        "window-restore",            launch_cmd("windows")))
  table.insert(entries, launch_entry("Clipboard",         ": · histórico de cópias",      "edit-copy",                 launch_cmd("clipboard")))

  return entries
end

function curated_level(top, sub)
  local node = top
  for _, key in ipairs(sub) do
    node = find_child(node, key)
    if not node then
      break
    end
  end

  local entries = { back_entry(top.label) }
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

function GetEntries()
  local s = state() or {}

  if #s == 0 then
    return root_level()
  end

  local top = find_curated(s[1])
  if not top then
    setState({})
    return root_level()
  end

  return curated_level(top, slice(s, 2))
end
