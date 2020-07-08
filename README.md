# luashell

This is a small Lua module to help write what would be shell scripts in Lua. It provides easy ways to run commands and check for success, get values of environment variables with optional default value if not set, capture output of commands, run pipelines and run POSIX tests (e.g. if file exists, if directory exists, etc.).

It has a single external dependency, [luaposix], and as such only works on POSIX systems. Otherwise it uses the `os`, `string` and `table` standard libraries.

## Install

Via Luarocks:

```
$ luarocks install luashell
```

Or simply copy the single shell.lua file in your project or your `LUA_PATH`.

## API

Assuming `local sh = require 'shell'`. You can check out `shell_test.lua` for
actual examples of using the API.

### sh.exec(...)

Alias: `sh(...)`.

Run the command specified as first argument, passing along any additional argument. The first argument can be a string, a `Cmd` or a `Pipe`. Returns true or false based on exit code of the command, and the status and code as additional return values. Status is one of 'exited', 'killed' or 'stopped'.

### sh.var(t)

Return the value of the environment variable. If t is a table
instead of a string, then it returns the first non-empty string
value if the initial environment variable name is not set.

### sh.type(v)

Return the type of v, which expands the built-in `type` Lua
function to include 'Shell', 'Cmd' and 'Pipe' instances.

### sh.cmd(...)

Create a 'Cmd' instance using the provided arguments. The first
argument is the command name and the rest are the arguments bound
to that 'Cmd'.

### sh.test(s)

Execute a test with the specified condition. This is a shortcut
for `sh.cmd('test', ...):exec()` and only works for cases where
no quoting is required, as it simply splits the condition on
whitespace to extract the list of arguments. For more complex
cases, using the 'Cmd' is required.

### Cmd:exec(...)

Execute the 'Cmd' with optional additional arguments. Returns a boolean
indicating success (exit code 0), and the status string and code. The
status string is the same as the one in luaposix, that is:
"exited", "killed" or "stopped". The code is the exit code or the signal
number responsible for "killed" or "stopped".

### Cmd:output(...)

This is the same as `Cmd:exec` except that it returns the stdout output as a string
instead of the true/false boolean. The rest of the returned values are the same.
If the command failed and no output was generated on stdout, it returns nil as output,
so that it can be used in an `assert` call.

### Pipe '|' operator

Applying the pipe '|' operator to 'Cmd' or 'Pipe' (or a combination of those)
results in a 'Pipe' with those commands, flattened.

### Pipe:exec(...)

Execute the 'Pipe' with optional additional arguments to be provided to the
first command of the pipeline. Returns a boolean
indicating success (exit code 0), and the status string and code. The
status string is the same as the one in luaposix, that is:
"exited", "killed" or "stopped". The code is the exit code or the signal
number responsible for "killed" or "stopped".

Note that the pipeline succeeds unless the final command fails (that is, there
is no "set -o pipefail" mode, this is a bash-specific feature).

### Pipe:output(...)

This is the same as `Pipe:exec` except that it returns the stdout output as a string
instead of the true/false boolean. The rest of the returned values are the same.
If the pipe failed and no output was generated on stdout, it returns nil as output,
so that it can be used in an `assert` call.

## Development

Clone the project and install the required development dependencies:

* luaposix (actual run-time dependency)
* luaunit (unit test runner)
* luacov (recommended, test coverage)
* inspect (recommended for debugging, pretty-printing of values)

If like me you prefer to keep your dependencies locally, per-project, then I recommend using my [llrocks] wrapper of the `luarocks` cli, which by default uses a local `lua_modules/` tree.

```
$ llrocks install ...
```

To run tests:

```
$ llrocks run shell_test.lua
```

To view code coverage:

```
$ llrocks cover shell_test.lua
```

## License

The [BSD 3-clause][bsd] license.

[luaposix]: https://github.com/luaposix/luaposix
[bsd]: http://opensource.org/licenses/BSD-3-Clause
[llrocks]: https://git.sr.ht/~mna/llrocks
