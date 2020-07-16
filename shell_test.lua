local lu = require 'luaunit'
local posix = require 'posix'
local sh = require 'shell'
local unistd = require 'posix.unistd'

local NOSUCH = 'No-sUch_CommANd_ORVAr'

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
  lu.assertErrorMsgContains('must be a table or a string', function()
    sh.var(4)
  end)
end

function TestVar.testExists()
  local got = sh.var('PATH')
  lu.assertTrue(got ~= '')
end

function TestVar.testNotExists()
  local got = sh.var(NOSUCH)
  lu.assertNil(got)
end

function TestVar.testExistsTable()
  local got = sh.var{'PATH'}
  lu.assertTrue(got ~= '')
end

function TestVar.testNotExistsTable()
  local got = sh.var{NOSUCH}
  lu.assertNil(got)
end

function TestVar.testExistsTableDefault()
  local got = sh.var{'PATH', 'zzz'}
  lu.assertTrue(got ~= '' and got ~= 'zzz')
end

function TestVar.testNotExistsTableDefault()
  local got = sh.var{NOSUCH, 'zzz'}
  lu.assertEquals(got, 'zzz')
end

function TestVar.testNotExistsTableDefaultSkipNonString()
  local got = sh.var{NOSUCH, 3, false, 'zzz'}
  lu.assertEquals(got, 'zzz')
end

function TestVar.testComposition()
  local got = sh.var{NOSUCH, sh.var{'Still-' .. NOSUCH, 'zzz'}}
  lu.assertEquals(got, 'zzz')
end

TestExec = {}
function TestExec.testTrue()
  local got = sh.exec('true')
  lu.assertTrue(got)
end

function TestExec.testFalse()
  local got = sh.exec('false')
  lu.assertFalse(got)
end

function TestExec.testNotExists()
  local got, status, code = sh.exec(NOSUCH)
  lu.assertFalse(got)
  lu.assertEquals(status, 'exited')
  lu.assertTrue(code > 0)
end

function TestExec.testWithArgs()
  local got, status, code = sh.exec('echo', 'allo')
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestExec.testWithMetamethod()
  local got, status, code = sh('echo', 'allo2')
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestExec.testWithCmd()
  local cmd = sh.cmd('true')
  local got, status, code = sh.exec(cmd)
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestExec.testWithPipe()
  local p = sh.cmd('echo', 'allo3') | sh.cmd('head', '-c1')
  local got, status, code = sh.exec(p)
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestExec.testWithBadArgument()
  lu.assertErrorMsgContains('must be a string, a Cmd or a Pipe', function()
    sh.exec(42)
  end)
end

TestCmd = {}
function TestCmd.testExec()
  local cmd = sh.cmd('true')
  local got, status, code = cmd:exec()
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestCmd.testExecNotExists()
  local cmd = sh.cmd(NOSUCH)
  local got, status, code = cmd:exec()
  lu.assertFalse(got)
  lu.assertEquals(status, 'exited')
  lu.assertTrue(code > 0)
end

function TestCmd.testOutput()
  local cmd = sh.cmd('echo', '-n', 'allo4')
  local out, status, code = cmd:output()
  lu.assertEquals(out, 'allo4')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestCmd.testOutputNotExists()
  local cmd = sh.cmd(NOSUCH)
  local out, status, code = cmd:output()
  lu.assertNil(out)
  lu.assertEquals(status, 'exited')
  lu.assertTrue(code > 0)
end

function TestCmd.testOutputAssertNotExists()
  lu.assertErrorMsgContains('exited', function()
    local cmd = sh.cmd(NOSUCH)
    assert(cmd:output())
  end)
end

function TestCmd.testExecExtraArgs()
  local cmd = sh.cmd('echo')
  local got, status, code = cmd:exec('a', 'b')
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestCmd.testOutputExtraArgs()
  local cmd = sh.cmd('echo', '-n')
  local out, status, code = cmd:output('a', 'b')
  lu.assertEquals(out, 'a b')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestCmd.testDelayedOutput()
  local cmd = sh.cmd('./testdelayecho.sh', '3', 'allo')
  local out, status, code = cmd:output()
  lu.assertEquals(out, 'allo')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestCmd.testLongOutput()
  local cmd = sh.cmd('cat', './shell_test.lua')
  local out, status, code = cmd:output()
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)

  -- use diff to check if output is the same
  local tmpnm = os.tmpname()
  local tmpf = io.open(tmpnm, "w+"); tmpf:write(out); tmpf:write('\n'); tmpf:close()
  lu.assertTrue(sh('diff', './shell_test.lua', tmpnm), tmpnm)
  os.remove(tmpnm)
end

function TestCmd.testReuseCmd()
  local cmd = sh.cmd('echo', '-n', 'abcd')

  local got = cmd:exec()
  lu.assertTrue(got)

  local out = cmd:output('efgh')
  lu.assertEquals(out, 'abcd efgh')

  local p = cmd | sh.cmd('wc', '-c')
  out = p:output()
  lu.assertEquals(out, '4') -- cmd runs with 'abcd' only
end

function TestCmd.testRedirectFunction()
  local cmd = sh.cmd('echo', '-n', 'allo')
  local out = {}
  local got, status, code = cmd:redirect(function(s)
    if not s then return end
    table.insert(out, s)
  end)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(table.concat(out), 'allo')
end

function TestCmd.testRedirectFilename()
  local cmd = sh.cmd('echo', '-n', 'allo')
  local name = os.tmpname()
  local got, status, code = cmd:redirect(name)

  local fh = io.open(name)
  local out = fh:read('a')
  fh:close()
  os.remove(name)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(out, 'allo')
end

function TestCmd.testRedirectFile()
  local cmd = sh.cmd('echo', '-n', 'allo')
  local name = os.tmpname()
  local fh = io.open(name, 'w')

  local got, status, code = cmd:redirect(fh)
  lu.assertEquals(io.type(fh), 'file') -- not closed

  fh:close()
  fh = io.open(name, 'r')
  local out = fh:read('a')
  fh:close()
  os.remove(name)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(out, 'allo')
end

function TestCmd.testRedirectFd()
  local cmd = sh.cmd('echo', '-n', 'allo')
  local name = os.tmpname()
  local fd = assert(posix.open(name, posix.O_CREAT | posix.O_RDWR, 'rw-r-----'))

  local got, status, code = cmd:redirect(fd)

  assert(unistd.lseek(fd, 0, unistd.SEEK_SET))
  local out = assert(unistd.read(fd, 1024))
  assert(unistd.close(fd))
  os.remove(name)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(out, 'allo')
end

TestPipe = {}
function TestPipe.testExec()
  local p = sh.cmd('echo', 'allo') | sh.cmd('wc', '-c')
  local got, status, code = p:exec()
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.xtestExecNotExistsLeft()
  -- NOTE: does not seem possible in POSIX, set -o pipefail is bash
  local p = sh.cmd(NOSUCH, 'allo') | sh.cmd('wc', '-c')
  local got, status, code = p:exec()
  lu.assertFalse(got)
  lu.assertEquals(status, 'exited')
  lu.assertTrue(code > 0)
end

function TestPipe.testExecNotExistsRight()
  local p = sh.cmd('echo', 'allo') | sh.cmd(NOSUCH, '-c')
  local got, status, code = p:exec()
  lu.assertFalse(got)
  lu.assertEquals(status, 'exited')
  lu.assertTrue(code > 0)
end

function TestPipe.testOutput()
  local p = sh.cmd('echo', '-n', 'allo') | sh.cmd('wc', '-c')
  local out, status, code = p:output()
  lu.assertEquals(out, '4')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testOutputDelayedLeft()
  local p = sh.cmd('./testdelayecho.sh', 2, 'allo') | sh.cmd('wc', '-c')
  local out, status, code = p:output()
  lu.assertEquals(out, '4')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testOutputDelayedRight()
  local p = sh.cmd('echo', '-n', 'allo2') | sh.cmd('./testdelayecho.sh')
  local out, status, code = p:output()
  lu.assertEquals(out, 'allo2')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testOutputNotExistsRight()
  local p = sh.cmd('echo', '-n', 'allo') | sh.cmd(NOSUCH)
  local out, status, code = p:output()
  lu.assertNil(out)
  lu.assertEquals(status, 'exited')
  lu.assertTrue(code > 0)
end

function TestPipe.testCombinePipeLeft()
  local p = sh.cmd('echo', '-n', 'allo12345678') | sh.cmd('wc', '-c') | sh.cmd('cat')
  local p2 = p | sh.cmd('wc', '-c')
  local out, status, code = p2:output()
  lu.assertEquals(out, '3')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testCombineLeftInvalid()
  lu.assertErrorMsgContains('left operand', function()
    local _ = 3 | sh.cmd('true')
  end)
end

function TestPipe.testCombinePipeRight()
  local p = sh.cmd('wc', '-c') | sh.cmd('head', '-c1')
  local p2 = sh.cmd('echo', '-n', 'allo') | p | sh.cmd('wc', '-c')
  local out, status, code = p2:output()
  lu.assertEquals(out, '1')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testCombineRightInvalid()
  lu.assertErrorMsgContains('right operand', function()
    local _ = sh.cmd('true') | 3
  end)
end

function TestPipe.testExecExtraArgs()
  local p = sh.cmd('echo', '-n') | sh.cmd('wc', '-c')
  local got, status, code = p:exec('allo')
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testOutputExtraArgs()
  local p = sh.cmd('echo', '-n') | sh.cmd('wc', '-c')
  local out, status, code = p:output('allo', 'you')
  lu.assertEquals(out, '8')
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestPipe.testRedirectFunction()
  local p = sh.cmd('echo', '-n', 'allo') | sh.cmd('wc', '-c')
  local out = {}
  local got, status, code = p:redirect(function(s)
    if not s then return end
    table.insert(out, s)
  end)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(table.concat(out), '4\n')
end

function TestPipe.testRedirectFilename()
  local p = sh.cmd('echo', '-n', 'allo') | sh.cmd('wc', '-c')
  local name = os.tmpname()
  local got, status, code = p:redirect(name)

  local fh = io.open(name)
  local out = fh:read('a')
  fh:close()
  os.remove(name)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(out, '4\n')
end

function TestPipe.testRedirectFile()
  local p = sh.cmd('echo', '-n', 'allo') | sh.cmd('wc', '-c')
  local name = os.tmpname()
  local fh = io.open(name, 'w')

  local got, status, code = p:redirect(fh)
  lu.assertEquals(io.type(fh), 'file') -- not closed

  fh:close()
  fh = io.open(name, 'r')
  local out = fh:read('a')
  fh:close()
  os.remove(name)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(out, '4\n')
end

function TestCmd.testRedirectFd()
  local p = sh.cmd('echo', '-n', 'allo') | sh.cmd('wc', '-c')
  local name = os.tmpname()
  local fd = assert(posix.open(name, posix.O_CREAT | posix.O_RDWR, 'rw-r-----'))

  local got, status, code = p:redirect(fd)

  assert(unistd.lseek(fd, 0, unistd.SEEK_SET))
  local out = assert(unistd.read(fd, 1024))
  assert(unistd.close(fd))
  os.remove(name)

  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
  lu.assertEquals(out, '4\n')
end

TestTest = {}
function TestTest.testFileExists()
  local got, status, code = sh.test[[-f shell_test.lua]]
  lu.assertTrue(got)
  lu.assertEquals(status, 'exited')
  lu.assertEquals(code, 0)
end

function TestTest.testBadArgument()
  lu.assertErrorMsgContains('must be a string', function()
    sh.test(9)
  end)
end

TestGlob = {}
function TestGlob.testCurrentDirMatches()
  local a, b, c, d = sh.glob('shell*.lua')
  lu.assertEquals(a, 'shell.lua')
  lu.assertEquals(b, 'shell_bench.lua')
  lu.assertEquals(c, 'shell_test.lua')
  lu.assertNil(d)
end

function TestGlob.testCurrentDirNoMatch()
  local a, b = sh.glob(NOSUCH .. '*')
  lu.assertNil(a)
  lu.assertNil(b)
end

function TestGlob.testOtherDirMatches()
  local got = table.pack(sh.glob('lua_modules/*'))
  lu.assertTrue(got.n == 4)
end

function TestGlob.testOtherDirNoMatches()
  local got = sh.glob('lua_modules/' .. NOSUCH .. '*')
  lu.assertNil(got)
end

function TestGlob.testInExec()
  local p = sh.cmd('cat', sh.glob('shell*.lua')) | sh.cmd('wc', '-c')
  local out = string.gsub(p:output(), '%s', '')
  lu.assertTrue(tonumber(out) > 1000, out)
end

os.exit(lu.LuaUnit.run())
