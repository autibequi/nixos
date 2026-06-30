-- TODO · agrega todos os todo.md do flagdir yaa (todas as sessões)
-- Adições novas vão para _global/todo.md (sem SID disponível no Elephant).
-- Actions via lua: para evitar problemas com && em shells do Walker.

Name = "todo"
NamePretty = "TODO"
Icon = "checkbox-checked-symbolic"
Description = "TODO · sessões yaa"
SearchName = false
Cache = false
FixedOrder = false
HideFromProviderlist = false

local FLAG_BASE  = "/workspace/.cache/yaa-state/skill-flags"
local GLOBAL_ARQ = FLAG_BASE .. "/_global/todo.md"
local SEP        = "|||"

Actions = {
  activate = "lua:Activate",
}

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function flagdir_files()
  local h = io.popen("find " .. quote(FLAG_BASE) .. " -maxdepth 2 -name 'todo.md' 2>/dev/null")
  if not h then
    return {}
  end
  local files = {}
  for line in h:lines() do
    table.insert(files, line)
  end
  h:close()
  return files
end

function read_pending()
  local tasks = {}
  for _, path in ipairs(flagdir_files()) do
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        local task = line:match("^%- %[ %] (.+)$")
        if task then
          table.insert(tasks, { text = task, file = path })
        end
      end
      f:close()
    end
  end
  return tasks
end

function AddTask(task)
  os.execute("mkdir -p " .. quote(FLAG_BASE .. "/_global"))
  local f = io.open(GLOBAL_ARQ, "a")
  if f then
    f:write("- [ ] " .. task .. "\n")
    f:close()
  end
end

function MarkDone(file, task)
  local f = io.open(file, "r")
  if not f then
    return
  end
  local lines = {}
  for line in f:lines() do
    if line == "- [ ] " .. task then
      table.insert(lines, "- [x] " .. task)
    else
      table.insert(lines, line)
    end
  end
  f:close()

  f = io.open(file, "w")
  if f then
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()
  end
end

function Activate(value)
  local sep_pos = value:find(SEP, 1, true)
  if sep_pos then
    local file = value:sub(1, sep_pos - 1)
    local task = value:sub(sep_pos + #SEP)
    MarkDone(file, task)
  else
    AddTask(value)
  end
end

function GetEntries(query)
  local pending = read_pending()
  local q = (query or ""):match("^%s*(.-)%s*$")

  if q ~= "" then
    local matches = {}
    local ql = q:lower()
    for _, item in ipairs(pending) do
      if item.text:lower():find(ql, 1, true) then
        table.insert(matches, item)
      end
    end

    if #matches > 0 then
      local entries = {}
      for _, item in ipairs(matches) do
        table.insert(entries, {
          Text    = item.text,
          Subtext = "Enter → marcar concluída",
          Icon    = "checkbox-symbolic",
          Value   = item.file .. SEP .. item.text,
          After   = "AsyncClearReload",
          Actions = { activate = "lua:Activate" },
        })
      end
      return entries
    else
      return {
        {
          Text    = "➕ Criar: " .. q,
          Subtext = "Enter → adicionar",
          Icon    = "list-add",
          Value   = q,
          After   = "AsyncClearReload",
          Actions = { activate = "lua:Activate" },
        },
      }
    end
  end

  local entries = {}
  if #pending == 0 then
    table.insert(entries, {
      Text    = "✓ Tudo limpo!",
      Subtext = "nenhuma tarefa pendente · comece a digitar para criar",
      Icon    = "emblem-ok-symbolic",
      Value   = "",
      Actions = { activate = "lua:Activate" },
    })
  else
    for _, item in ipairs(pending) do
      table.insert(entries, {
        Text    = item.text,
        Subtext = "Enter → marcar concluída · ou filtre para criar nova",
        Icon    = "checkbox-symbolic",
        Value   = item.file .. SEP .. item.text,
        After   = "AsyncClearReload",
        Actions = { activate = "lua:Activate" },
      })
    end
  end

  return entries
end
