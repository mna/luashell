local lu = require 'luaunit'
local sh = require 'shell'

TestType = {}
function TestType.testNil()
  local got = sh.type(nil)
  lu.assertEquals(got, 'nil')
end

function TestType.testBoolean()
  local got = sh.type(true)
  lu.assertEquals(got, 'boolean')
end

function TestType.testString()
  local got = sh.type('s')
  lu.assertEquals(got, 'string')
end

function TestType.testNumber()
  local got = sh.type(42)
  lu.assertEquals(got, 'number')
end

function TestType.testTable()
  local got = sh.type({})
  lu.assertEquals(got, 'table')
end

function TestType.testFunction()
  local got = sh.type(function() end)
  lu.assertEquals(got, 'function')
end

function TestType.testUserdata()
  local got = sh.type(io.output())
  lu.assertEquals(got, 'userdata')
end

function TestType.testThread()
  local th = coroutine.create(function() end)
  local got = sh.type(th)
  lu.assertEquals(got, 'thread')
end

function TestType.testShell()
  local got = sh.type(sh)
  lu.assertEquals(got, 'Shell')
end

function TestType.testCmd()
  local got = sh.type(sh.cmd('x'))
  lu.assertEquals(got, 'Cmd')
end

function TestType.testPipe()
  local p = sh.cmd('x') | sh.cmd('y')
  local got = sh.type(p)
  lu.assertEquals(got, 'Pipe')
end

TestVar = {}
function TestVar.testBadArgument()
  lu.assertErrorMsgMatches('.-must be a table or a string.*', function()
    sh.var(4)
  end)
end

function TestVar.testExists()
  local got = sh.var('PATH')
  lu.assertTrue(got ~= '')
end

function TestVar.testNotExists()
  local got = sh.var('NO-SUCH_VARIABLE')
  lu.assertNil(got)
end

function TestVar.testExistsTable()
  local got = sh.var{'PATH'}
  lu.assertTrue(got ~= '')
end

function TestVar.testNotExistsTable()
  local got = sh.var{'NO-SUCH_VARIABLE'}
  lu.assertNil(got)
end

function TestVar.testExistsTableDefault()
  local got = sh.var{'PATH', 'zzz'}
  lu.assertTrue(got ~= '' and got ~= 'zzz')
end

function TestVar.testNotExistsTableDefault()
  local got = sh.var{'NO-SUCH_VARIABLE', 'zzz'}
  lu.assertEquals(got, 'zzz')
end

function TestVar.testNotExistsTableDefaultSkipNonString()
  local got = sh.var{'NO-SUCH_VARIABLE', 3, false, 'zzz'}
  lu.assertEquals(got, 'zzz')
end

function TestVar.testComposition()
  local got = sh.var{'NO-SUCH_VARIABLE', sh.var{'Still-NO-SUCH_VARIABLE', 'zzz'}}
  lu.assertEquals(got, 'zzz')
end

TestExec = {}
function TestExec.testTrue()
  local got = sh.exec('true')
  lu.assertTrue(got)
end

os.exit(lu.LuaUnit.run())
