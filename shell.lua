local posix = require 'posix'
local unistd = require 'posix.unistd'

local Shell, Cmd, Pipe = {OUTPUT_BLOCK_SIZE = 1024}, {_name = 'Cmd'}, {_name = 'Pipe'}

-- Constructor function for new Cmd or Pipe instances.
local function newobj(class, o)
  o = o or {}
  class.__index = class
  setmetatable(o, class)
  return o
end

-- Applying the pipe '|' operator to Cmd or Pipe (or a combination of those)
-- results in a Pipe with those commands, flattened.
local function __bor(l, r)
  local res
  local ltyp, rtyp = Shell.type(l), Shell.type(r)
  if ltyp == 'Pipe' then
    res = l
  elseif ltyp == 'Cmd' then
    res = newobj(Pipe)
    table.insert(res, l)
  else
    error('left operand must be a Pipe or a Cmd')
  end

  if rtyp == 'Pipe' then
    for _, v in ipairs(r) do
      table.insert(res, v)
    end
  elseif rtyp == 'Cmd' then
    table.insert(res, r)
  else
    error('right operand must be a Pipe or a Cmd')
  end
  return res
end

-- set the | operator metamethod on Cmd and Pipe metatables.
Cmd.__bor, Pipe.__bor = __bor, __bor

-- Calling a Shell object executes the value passed to it. If it is a string,
-- then is the equivalent of calling Shell.cmd(...):exec(). If it is a Cmd or
-- a Pipe, then it is the equivalent of calling v:exec(...) on that Cmd or Pipe
-- where v is the first argument and ... is the rest.
local function __call(sh, ...)
  return sh.exec(...)
end

setmetatable(Shell, {_name = 'Shell', __call = __call})

-- Executes the provided command, which may be a string, a Cmd
-- or a Pipe. Extra arguments are passed to the execution of
-- the command (or pipe).
function Shell.exec(...)
  -- TODO: is it better with select?
  local args = table.pack(...)
  if args.n == 0 then return end

  local typ = Shell.type(args[1])
  if typ == 'string' then
    local cmd = Shell.cmd(...)
    return cmd:exec()
  elseif typ == 'Cmd' or typ == 'Pipe' then
    local x = args[1]
    return x:exec(table.unpack(args, 2, args.n))
  else
    error('argument 1 must be a string, a Cmd or a Pipe')
  end
end

-- Returns the type of v, which expands the built-in type Lua
-- function to include Shell, Cmd and Pipe instances.
function Shell.type(v)
  local mt = getmetatable(v)
  if mt and mt._name then return mt._name end
  return type(v)
end

-- Returns the value of the environment variable. If t is a table
-- instead of a string, then it returns the first non-empty string
-- value if the initial environment variable name is not set.
function Shell.var(t)
  if type(t) == 'string' then return os.getenv(t) end
  assert(type(t) == 'table', 'argument 1 must be a table or a string')

  for i = 1, #t do
    local v = t[i]
    if type(v) == 'string' then
      if i == 1 then v = os.getenv(v) end
      if v and v ~= '' then return v end
    end
  end
end

-- Create a Cmd instance using the provided arguments. The first
-- argument is the command name and the rest are the arguments bound
-- to that Cmd.
function Shell.cmd(...)
  assert(select('#', ...) > 0, 'at least one argument required')
  assert(type(select(1, ...)) == 'string', 'argument 1 must be a string')
  return newobj(Cmd, table.pack(...))
end

-- Execute a test with the specified condition. This is a shortcut
-- for Shell.cmd('test', ...):exec() and only works for cases where
-- no quoting is required, as it simply splits the condition on
-- whitespace to extract the list of arguments. For more complex
-- cases, using the cmd is required.
function Shell.test(cond)
  assert(type(cond) == 'string', 'argument 1 must be a string')
  local args = {}
  for w in string.gmatch(cond, '%S+') do
    table.insert(args, w)
  end
  return Shell.exec('test', table.unpack(args))
end

local function cmd_to_task(cmd, ...)
  local task = {table.unpack(cmd, 1, cmd.n)}
  local args = table.pack(...)
  for i = 1, args.n do
    table.insert(task, args[i])
  end
  return task
end

local function pipe_to_tasks(pipe, ...)
  assert(#pipe > 0, 'empty Pipe')

  local tasks = {}
  for i = 1, #pipe do
    local t
    if i == 1 then
      t = cmd_to_task(pipe[i], ...)
    else
      t = cmd_to_task(pipe[i])
    end
    table.insert(tasks, t)
  end
  return tasks
end

local function consume_pfd_output(pfd, drop)
  local out = {}
  local s, err
  while true do
    -- do not use assert here, the pipe needs to be closed
    s, err = unistd.read(pfd.fd, Shell.OUTPUT_BLOCK_SIZE)
    if not s or s == '' then break end
    if not drop then table.insert(out, s) end
  end

  -- do not use assert here, to prevent hiding an error with read
  -- NOTE: documentation for luaposix is wrong here, pclose returns
  -- the status (reason) and code.
  local status, code = posix.pclose(pfd)
  -- first, assert on a possible read error
  assert(s, err)
  -- now we can assert on the result of pclose
  assert(status, code)

  -- if there is no output and it exited with an error, return
  -- nil as output so that it can be combined with assert().
  local res = table.concat(out)
  if res == '' and (status ~= 'exited' or code > 0) then
    res = nil
  end
  return res, status, code
end

-- Execute the Cmd with optional additional arguments. Returns a boolean
-- indicating success (exit code 0), and the status string and code. The
-- status string is the same as the one in luaposix, that is:
-- "exited", "killed" or "stopped". The code is the exit code or the signal
-- number responsible for "killed" or "stopped".
function Cmd:exec(...)
  local task = cmd_to_task(self, ...)
  -- NOTE: documentation for luaposix is wrong here, it doesn't return the same
  -- values as wait, it returns the status code and the status string, and code
  -- is nil if it failed.
  local code, status = assert(posix.spawn(task))
  return (status == 'exited' and code == 0), status, code
end

-- This is the same as Cmd:exec except that it returns the stdout output as a string
-- instead of the true/false boolean. The rest of the returned values are the same.
-- If the command failed and no output was generated on stdout, it returns nil as output,
-- so that it can be used in an assert call.
function Cmd:output(...)
  local task = cmd_to_task(self, ...)
  local pfd = posix.popen(task, 'r')
  return consume_pfd_output(pfd)
end

-- Execute the Pipe with optional additional arguments to be provided to the
-- first command of the pipeline. Returns a boolean
-- indicating success (exit code 0), and the status string and code. The
-- status string is the same as the one in luaposix, that is:
-- "exited", "killed" or "stopped". The code is the exit code or the signal
-- number responsible for "killed" or "stopped".
--
-- Note that the pipeline succeeds unless the final command fails (that is, there
-- is no "set -o pipefail" mode, this is a bash-specific feature).
function Pipe:exec(...)
  local tasks = pipe_to_tasks(self, ...)
  local pfd = posix.popen_pipeline(tasks, 'r')
  local _, status, code = consume_pfd_output(pfd, true)
  return (status == 'exited' and code == 0), status, code
end

-- This is the same as Pipe:exec except that it returns the stdout output as a string
-- instead of the true/false boolean. The rest of the returned values are the same.
-- If the pipe failed and no output was generated on stdout, it returns nil as output,
-- so that it can be used in an assert call.
function Pipe:output(...)
  local tasks = pipe_to_tasks(self, ...)
  local pfd = posix.popen_pipeline(tasks, 'r')
  return consume_pfd_output(pfd)
end

return Shell
