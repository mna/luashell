# luashell

This is a small Lua module to help write what would be shell scripts in Lua. It provides easy ways to run commands and check for success, get values of environment variables with optional default value if not set, capture output of commands, run pipelines and run POSIX tests (e.g. if file exists, if directory exists, etc.).

It has a single external dependency, [luaposix], and as such only works on POSIX systems. Otherwise it uses the `os`, `string` and `table` standard libraries.

## Install

Via Luarocks:

```
$ luarocks install luashell
```

Or simply copy the single shell.lua file in your project or your `LUA_PATH`.

## License

The [BSD 3-clause][bsd] license.

[luaposix]: https://github.com/luaposix/luaposix
[bsd]: http://opensource.org/licenses/BSD-3-Clause
