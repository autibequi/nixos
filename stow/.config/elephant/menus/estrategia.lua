-- ============================================================
--  Estratégia bookmarks — ambientes → pastas → sites
--  Walker: prefixo }  (menus:estrategia)
--
--  Edite DATA abaixo quando tiver URLs reais.
-- ============================================================

Name = "estrategia"
NamePretty = "Estratégia"
Icon = "bookmark-new"
Description = "Bookmarks por ambiente"
SearchName = true
Cache = false
FixedOrder = true
HideFromProviderlist = false

Actions = {
  drill = "lua:DrillDown",
  back = "lua:Back",
  open = "lua:OpenUrl",
}

-- ── DATA (boilerplate — substitua pelos links reais) ─────────

local ENVS = {
  prod = {
    label = "Production",
    subtext = "estrategia.com",
    icon = "network-transmit-receive",
  },
  sandbox = {
    label = "Sandbox",
    subtext = "local.estrategia-sandbox.com.br",
    icon = "network-server",
  },
  global = {
    label = "Global",
    subtext = "ferramentas compartilhadas",
    icon = "network-workgroup",
  },
}

local FOLDERS = {
  vertical = {
    label = "<vertical>",
    subtext = "militares · vestibulares · concursos · …",
    icon = "folder",
  },
  grafana = {
    label = "Grafana",
    subtext = "dashboards",
    icon = "utilities-system-monitor",
  },
  newrelic = {
    label = "New Relic",
    subtext = "APM · logs",
    icon = "utilities-system-monitor",
  },
  metabase = {
    label = "Metabase",
    subtext = "BI / queries",
    icon = "x-office-spreadsheet",
  },
  tc = {
    label = "TC",
    subtext = "teamcity / CI",
    icon = "utilities-terminal",
  },
}

local VERTICALS = {
  militares = { label = "Militares", slug = "militares", icon = "emblem-default" },
  vestibulares = { label = "Vestibulares", slug = "vestibulares", icon = "emblem-default" },
  concursos = { label = "Concursos", slug = "concursos", icon = "emblem-default" },
  smedicina = { label = "Medicina", slug = "medicina", icon = "emblem-default" },
  oab = { label = "OAB", slug = "oab", icon = "emblem-default" },
  ecj = { label = "Carreiras Jurídicas", slug = "carreiras-juridicas", icon = "emblem-default" },
}

-- URLs por ambiente × vertical (portal principal)
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

-- Links extras por vertical (admin, api, etc.)
local VERTICAL_EXTRAS = {
  -- sandbox = {
  --   militares = {
  --     { label = "Admin", url = "http://admin.local.estrategia-sandbox.com.br" },
  --   },
  -- },
}

-- Bookmarks por ambiente × pasta de ferramenta
local TOOL_LINKS = {
  sandbox = {
    grafana = {
      { label = "Overview", subtext = "TODO", url = "https://grafana.sandbox.estrategia.com.br" },
      { label = "API latency", subtext = "TODO", url = "https://grafana.sandbox.estrategia.com.br/d/TODO" },
    },
    newrelic = {
      { label = "APM", subtext = "TODO", url = "https://one.newrelic.com/TODO" },
    },
    metabase = {
      { label = "Home", subtext = "TODO", url = "https://metabase.sandbox.estrategia.com.br" },
    },
    tc = {
      { label = "Builds", subtext = "TODO", url = "https://tc.estrategia.com/TODO" },
    },
  },
  prod = {
    grafana = {
      { label = "Overview", subtext = "TODO", url = "https://grafana.estrategia.com.br" },
    },
    newrelic = {
      { label = "APM", subtext = "TODO", url = "https://one.newrelic.com/TODO" },
    },
    metabase = {
      { label = "Home", subtext = "TODO", url = "https://metabase.estrategia.com.br" },
    },
    tc = {
      { label = "Builds", subtext = "TODO", url = "https://tc.estrategia.com/TODO" },
    },
  },
  global = {
    grafana = {
      { label = "Overview", subtext = "TODO", url = "https://grafana.estrategia.com.br" },
    },
    newrelic = {
      { label = "APM", subtext = "TODO", url = "https://one.newrelic.com/TODO" },
    },
    metabase = {
      { label = "Home", subtext = "TODO", url = "https://metabase.estrategia.com.br" },
    },
    tc = {
      { label = "Builds", subtext = "TODO", url = "https://tc.estrategia.com/TODO" },
    },
  },
}

-- ── helpers ───────────────────────────────────────────────────

function breadcrumb()
  local s = state() or {}
  if #s == 0 then
    return "escolha o ambiente"
  end
  local parts = {}
  for i, key in ipairs(s) do
    if i == 1 and ENVS[key] then
      table.insert(parts, ENVS[key].label)
    elseif i == 2 and FOLDERS[key] then
      table.insert(parts, FOLDERS[key].label)
    elseif i == 2 and key == "vertical" then
      table.insert(parts, "<vertical>")
    elseif i == 3 and VERTICALS[key] then
      table.insert(parts, VERTICALS[key].label)
    else
      table.insert(parts, key)
    end
  end
  return table.concat(parts, " › ")
end

function back_entry()
  return {
    Text = "← Voltar",
    Subtext = breadcrumb(),
    Icon = "go-previous",
    Value = "__back__",
    Actions = { open = "lua:Back", activate = "lua:Back" },
  }
end

function drill_entry(text, subtext, icon, value)
  return {
    Text = text,
    Subtext = subtext,
    Icon = icon,
    Value = value,
    Actions = { open = "lua:DrillDown", activate = "lua:DrillDown" },
  }
end

function url_entry(text, subtext, icon, url)
  return {
    Text = text,
    Subtext = subtext,
    Icon = icon,
    Value = url,
    Actions = { activate = "lua:OpenUrl", open = "lua:OpenUrl" },
  }
end

function sorted_keys(map)
  local keys = {}
  for k in pairs(map) do
    table.insert(keys, k)
  end
  table.sort(keys, function(a, b)
    local la = map[a].label or a
    local lb = map[b].label or b
    return la < lb
  end)
  return keys
end

-- ── navigation actions ────────────────────────────────────────

function DrillDown(value)
  if value == "__back__" then
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

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- ── levels ────────────────────────────────────────────────────

function level_env()
  local entries = {}
  for _, key in ipairs(sorted_keys(ENVS)) do
    local env = ENVS[key]
    table.insert(entries, drill_entry(env.label, env.subtext, env.icon, key))
  end
  return entries
end

function level_folders(env_key)
  local entries = { back_entry() }
  for _, key in ipairs(sorted_keys(FOLDERS)) do
    local folder = FOLDERS[key]
    table.insert(entries, drill_entry(folder.label, folder.subtext, folder.icon, key))
  end
  return entries
end

function level_verticals(env_key)
  local entries = { back_entry() }
  for _, key in ipairs(sorted_keys(VERTICALS)) do
    local v = VERTICALS[key]
    table.insert(entries, drill_entry(v.label, v.slug, v.icon, key))
  end
  return entries
end

function level_vertical_sites(env_key, vertical_key)
  local entries = { back_entry() }
  local urls = VERTICAL_URLS[env_key] or {}
  local portal = urls[vertical_key]
  if portal then
    table.insert(entries, url_entry("Portal", portal, "internet-services", portal))
  end
  local extras = (VERTICAL_EXTRAS[env_key] or {})[vertical_key] or {}
  for _, item in ipairs(extras) do
    table.insert(entries, url_entry(item.label, item.subtext or item.url, "web-browser", item.url))
  end
  if #entries == 1 then
    table.insert(entries, {
      Text = "Sem links configurados",
      Subtext = "edite VERTICAL_URLS em estrategia.lua",
      Icon = "dialog-warning",
      Actions = { activate = "true" },
    })
  end
  return entries
end

function level_tool_links(env_key, tool_key)
  local entries = { back_entry() }
  local links = ((TOOL_LINKS[env_key] or {})[tool_key]) or {}
  for _, item in ipairs(links) do
    table.insert(entries, url_entry(item.label, item.subtext or item.url, "internet-services", item.url))
  end
  if #entries == 1 then
    table.insert(entries, {
      Text = "Sem links configurados",
      Subtext = "edite TOOL_LINKS em estrategia.lua",
      Icon = "dialog-warning",
      Actions = { activate = "true" },
    })
  end
  return entries
end

function GetEntries()
  Description = breadcrumb()

  local s = state() or {}
  if #s == 0 then
    return level_env()
  end

  local env_key = s[1]
  if not ENVS[env_key] then
    setState({})
    return level_env()
  end

  if #s == 1 then
    return level_folders(env_key)
  end

  local folder_key = s[2]
  if folder_key == "vertical" then
    if #s == 2 then
      return level_verticals(env_key)
    end
    if #s == 3 then
      return level_vertical_sites(env_key, s[3])
    end
  end

  if FOLDERS[folder_key] and folder_key ~= "vertical" then
    if #s == 2 then
      return level_tool_links(env_key, folder_key)
    end
  end

  setState({ env_key })
  return level_folders(env_key)
end
