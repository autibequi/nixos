Name = "todo"
NamePretty = "TODO"
Icon = "checkbox-checked-symbolic"
Description = "Work TODO · ~/Ovault/Work/TODO.md"
SearchName = false
Cache = false
FixedOrder = false
HideFromProviderlist = false

local TODO_FILE = os.getenv("HOME") .. "/.ovault/Work/TODO.md"

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function sed_escape(s)
  -- escapa / \ & para uso dentro de sed s//
  return s:gsub("([/\\&])", "\\%1")
end

function ensure_file()
  local f = io.open(TODO_FILE, "r")
  if f then f:close(); return end
  local dir = TODO_FILE:match("(.+)/[^/]+$")
  if dir then os.execute("mkdir -p " .. quote(dir)) end
  f = io.open(TODO_FILE, "w")
  if f then f:write("# Work TODO\n\n"); f:close() end
end

function read_pending()
  local tasks = {}
  local f = io.open(TODO_FILE, "r")
  if not f then return tasks end
  for line in f:lines() do
    local task = line:match("^%- %[ %] (.+)$")
    if task then table.insert(tasks, task) end
  end
  f:close()
  return tasks
end

function done_cmd(task)
  local esc = sed_escape(task)
  return "sed -i " .. quote("s/^- \\[ \\] " .. esc .. "$$/- [x] " .. esc .. "/") .. " " .. quote(TODO_FILE)
    .. " && notify-send -i emblem-ok-symbolic 'TODO' " .. quote("✅ " .. task:sub(1, 60))
end

local TODO_SH = "/workspace/yaa/yaa/cli-agents/claude/scripts/todo.sh"

function add_cmd(task)
  return "bash " .. quote(TODO_SH) .. " " .. quote(task)
    .. " && notify-send -i checkbox-checked-symbolic 'TODO' " .. quote("➕ " .. task:sub(1, 60))
end

-- elephant passa a query quando GetEntries tem 1 argumento
function GetEntries(query)
  ensure_file()

  local pending = read_pending()
  local q = (query or ""):match("^%s*(.-)%s*$")  -- trim

  -- com query: filtrar tarefas existentes
  if q ~= "" then
    local matches = {}
    local ql = q:lower()
    for _, task in ipairs(pending) do
      if task:lower():find(ql, 1, true) then
        table.insert(matches, task)
      end
    end

    if #matches > 0 then
      -- mostra as que casam; Enter marca como done
      local entries = {}
      for _, task in ipairs(matches) do
        table.insert(entries, {
          Text    = task,
          Subtext = "Enter → marcar concluída",
          Icon    = "checkbox-symbolic",
          Actions = { activate = done_cmd(task) },
        })
      end
      return entries
    else
      -- nada casou → oferecer criar
      return {
        {
          Text    = "➕ Criar: " .. q,
          Subtext = "nenhuma tarefa existente · Enter → adicionar",
          Icon    = "list-add",
          Actions = { activate = add_cmd(q) },
        },
      }
    end
  end

  -- sem query: lista todas as pendentes
  local entries = {}
  if #pending == 0 then
    table.insert(entries, {
      Text    = "✓ Tudo limpo!",
      Subtext = "nenhuma tarefa pendente · comece a digitar para criar",
      Icon    = "emblem-ok-symbolic",
      Actions = { activate = "true" },
    })
  else
    for _, task in ipairs(pending) do
      table.insert(entries, {
        Text    = task,
        Subtext = "Enter → marcar concluída · ou filtre para criar nova",
        Icon    = "checkbox-symbolic",
        Actions = { activate = done_cmd(task) },
      })
    end
  end

  return entries
end
