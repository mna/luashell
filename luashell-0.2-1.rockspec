package = "luashell"
version = "0.2-1"
source = {
   url = "git+ssh://git@git.sr.ht/~mna/luashell"
}
description = {
   summary = "This is a small Lua module to help write what would be shell scripts in Lua.",
   detailed = [[
This is a small Lua module to help write what would be shell scripts in Lua.

It provides easy ways to run commands and check for success, get values of
environment variables with optional default value if not set, capture output
of commands, run pipelines and run POSIX tests (e.g. if file exists,
if directory exists, etc.).
]],
   homepage = "https://git.sr.ht/~mna/luashell",
   license = "BSD"
}
dependencies = {
  'lua >= 5.3, < 5.5',
  'luaposix >= 35.0-1',
}
build = {
   type = "builtin",
   modules = {
      shell = "shell.lua"
   }
}
