--[[
-- local sh = require 'luashell'
--
-- Get the value of an exported environment variable:
--   sh.v('name') or sh.v'name'
-- Use a default value if variable is unset or empty:
--   sh.v({'name', 'defaultval'}) or sh.v{'name', 'value'}
-- Also, this can compose well:
--   sh.v{'name', sh.v{'other', 'value'}}
--
-- Execute a command, returns true on success, false (nil) and
-- an error message on failure:
--   sh('cmd') or sh.exec('cmd') or sh'cmd'
--
-- This is just a wrapper over creating a command and exec'ing it:
--   sh.cmd('cmd'[, args]):exec([args])
--
-- Piping commands is supported and returns a new command, that can
-- be executed:
--   local pipe = sh.cmd('echo', 'allo') | sh.cmd('wc', '-c'); pipe:exec()
-- Or equivalently:
--   sh(sh.cmd('echo', 'allo') | sh.cmd('wc', '-c'))
--
-- To capture the stdout or the stderr of a command, call its
-- output method:
--   local out, exit = sh.cmd('echo', 'allo'):output()
-- Works on pipelines too:
--   local out, exit = (sh.cmd('echo', 'allo') | sh.cmd('wc', '-c')):output()
--
-- POSIX tests are just a wrapper around sh.exec:
--   sh.test[[-f /path/to/file]]
--]]

local Shell, Cmd, Pipe = {}, {_name = 'Cmd'}, {_name = 'Pipe'}

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
  if type(l) == 'Pipe' then
    res = l
  else
    res = newobj(Pipe)
    table.insert(res, l)
  end

  local rtyp = type(r)
  if rtyp == 'Pipe' then
    for _, v in ipairs(r) do
      table.insert(res, v)
    end
  else
    table.insert(res, r)
  end
  return res
end
Cmd.__bor, Pipe.__bor = __bor, __bor

-- Calling a Shell object executes the value passed to it. If it is a string,
-- then is the equivalent of calling Shell.cmd(...):exec(). If it is a Cmd or
-- a Pipe, then it is the equivalent of calling v:exec(...) on that Cmd or Pipe
-- where v is the first argument and ... is the rest.
local function __call(sh, ...)
  return sh.exec(...)
end

setmetatable(Shell, {_name = 'Shell', __call = __call})

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

function Shell.type(v)
  local mt = getmetatable(v)
  if mt and mt._name then return mt._name end
  return type(v)
end

function Shell.var(t)
  if type(t) == 'string' then return os.getenv(t) end
  assert(type(t) == 'table', 'argument 1 must be a table or a string')

  for i = 1, #t do
    local v = t[i]
    if type(v) == 'string' then
      if i == 1 then v = os.getenv(v) end
      if v ~= '' then return v end
    end
  end
end

function Shell.cmd(...)
  assert(select('#', ...) > 0, 'at least one argument required')
  assert(type(select(1, ...)) == 'string', 'argument 1 must be a string')
  return newobj(Cmd, table.pack(...))
end

function Shell.test(cond)
  assert(type(cond) == 'string', 'argument 1 must be a string')
  return Shell.exec('test ' .. cond)
end

function Cmd:exec(...)

end

function Cmd:output(...)

end

function Pipe:exec(...)

end

function Pipe:output(...)

end

return Shell
