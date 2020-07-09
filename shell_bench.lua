local bm = require './benchmark'
local reporter = bm.bm(12)

local function nop() end

local function processargs_table(...)
  local args = table.pack(...)
  if args.n == 0 then return end
  local first = args[1]
  if type(first) == 'string' then
    nop(first, table.unpack(args, 2, args.n))
  end
end

local function processargs_select(...)
  local n = select('#', ...)
  if n == 0 then return end
  local first = select(1, ...)
  if type(first) == 'string' then
    nop(first, select(2, ...))
  end
end

reporter:report(function()
  for _ = 1, 1e6 do
    processargs_table('a', 1, true, 'b')
  end
end, 'pack-unpack')

reporter:report(function()
  for _ = 1, 1e6 do
    processargs_select('a', 1, true, 'b')
  end
end, 'select')
