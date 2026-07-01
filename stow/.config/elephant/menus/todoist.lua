-- Todoist · Inbox no Walker (via todoist-panel.sh — REST v1, reaproveita login do CLI)
-- Lista tarefas do Inbox · digitar cria nova · Enter numa tarefa conclui.

Name = "todoist"
NamePretty = "Todoist"
Icon = "checkbox-checked-symbolic"
Description = "Todoist · Inbox"
SearchName = false
Cache = false
FixedOrder = false
HideFromProviderlist = false

local SCRIPT = os.getenv("HOME") .. "/.config/quickshell/modules/todoist/todoist-panel.sh"
local SEP = "|||"

Actions = {
  activate = "lua:Activate",
}

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function read_inbox()
  local h = io.popen("bash " .. quote(SCRIPT) .. " menu-inbox 2>/dev/null")
  if not h then
    return {}
  end
  local tasks = {}
  for line in h:lines() do
    local id, content = line:match("^([^\t]+)\t(.+)$")
    if id then
      table.insert(tasks, { id = id, text = content })
    end
  end
  h:close()
  return tasks
end

function AddTask(task)
  os.execute("bash " .. quote(SCRIPT) .. " add " .. quote(task) .. " >/dev/null 2>&1")
end

function DoneTask(id)
  os.execute("bash " .. quote(SCRIPT) .. " done " .. quote(id) .. " >/dev/null 2>&1")
end

function Activate(value)
  local sep_pos = value:find(SEP, 1, true)
  if sep_pos then
    DoneTask(value:sub(1, sep_pos - 1))
  elseif value ~= "" then
    AddTask(value)
  end
end

function GetEntries(query)
  local q = (query or ""):match("^%s*(.-)%s*$")
  local inbox = read_inbox()

  if q ~= "" then
    local entries = {}
    local ql = q:lower()
    for _, item in ipairs(inbox) do
      if item.text:lower():find(ql, 1, true) then
        table.insert(entries, {
          Text    = item.text,
          Subtext = "Enter → concluir",
          Icon    = "checkbox-symbolic",
          Value   = item.id .. SEP,
          After   = "AsyncClearReload",
          Actions = { activate = "lua:Activate" },
        })
      end
    end
    table.insert(entries, {
      Text    = "➕ Criar: " .. q,
      Subtext = "Enter → adicionar ao Inbox",
      Icon    = "list-add",
      Value   = q,
      After   = "AsyncClearReload",
      Actions = { activate = "lua:Activate" },
    })
    return entries
  end

  local entries = {}
  if #inbox == 0 then
    table.insert(entries, {
      Text    = "✓ Inbox vazio",
      Subtext = "digite para criar uma tarefa",
      Icon    = "emblem-ok-symbolic",
      Value   = "",
      Actions = { activate = "lua:Activate" },
    })
  else
    for _, item in ipairs(inbox) do
      table.insert(entries, {
        Text    = item.text,
        Subtext = "Enter → concluir · ou digite para criar",
        Icon    = "checkbox-symbolic",
        Value   = item.id .. SEP,
        After   = "AsyncClearReload",
        Actions = { activate = "lua:Activate" },
      })
    end
  end
  return entries
end
