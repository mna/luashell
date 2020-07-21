# luashell

This is a small Lua module to help write what would be shell scripts in Lua. It provides easy ways to run commands and check for success, get values of environment variables with optional default value if not set, capture output of commands, run pipelines and run POSIX tests (e.g. if file exists, if directory exists, etc.).

It has a single external dependency, [luaposix], and as such only works on POSIX systems. Otherwise it uses the `os`, `string` and `table` standard libraries.

* Canonical repository: https://git.sr.ht/~mna/luashell
* Issue tracker: https://todo.sr.ht/~mna/luashell

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

### sh.glob(s)

This is the same as the luaposix `posix.glob` function, except that it
expands the resulting table so that it returns each match as a
distinct value, ready to be used in e.g. `Shell.exec`.

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
so that it can be used in an `assert` call. Trailing newlines are removed.

### Cmd:redirect(target, truncate, ...)

This is similar to `Cmd:exec` and `Cmd:output`, but it redirects the stdout output
of the command to the specified target. The target can be:

* a string, in which case this is a filename that will be open in append (default)
  or truncate (if truncate is true) mode and will be closed on return.
* a file handle (`io.type(target) == 'file'`), in which case the truncate argument is
  ignored and the output will be written to that file handle. It is not closed on
  return, as the function did not open it.
* a number, in which case this is a file descriptor to which the output will be
  written, and in which case the truncate argument is ignored. It is not closed on
  return, as the function did not open it.
* a function, in which case it will be called with one argument, a string with each chunk
  of bytes from the output. It will be called a final time with nil to indicate the last
  call. The truncate argument is ignored in that case too.

The rest of the arguments are extra arguments for the command, as for `Cmd:exec` and
`Cmd:output`. It returns true or false as first argument, then the
status and exit code, like `Cmd:exec`.

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
so that it can be used in an `assert` call. Trailing newlines are removed.

### Pipe:redirect(target, truncate, ...)

This is similar to `Pipe:exec` and `Pipe:output`, but it redirects the stdout output
of the pipeline to the specified target. The target can be:

* a string, in which case this is a filename that will be open in append (default)
  or truncate (if truncate is true) mode and will be closed on return.
* a file handle (`io.type(target) == 'file'`), in which case the truncate argument is
  ignored and the output will be written to that file handle. It is not closed on
  return, as the function did not open it.
* a number, in which case this is a file descriptor to which the output will be
  written, and in which case the truncate argument is ignored. It is not closed on
  return, as the function did not open it.
* a function, in which case it will be called with one argument, a string with each chunk
  of bytes from the output. It will be called a final time with nil to indicate the last
  call. The truncate argument is ignored in that case too.

The rest of the arguments are extra arguments for the pipeline, as for `Pipe:exec` and
`Pipe:output`. It returns true or false as first argument, then the
status and exit code, like `Pipe:exec`.

## Development

Clone the project and install the required development dependencies:

* luaposix (the only run-time dependency)
* luaunit (unit test runner)
* luacov (recommended, test coverage)
* inspect (recommended for debugging, pretty-printing of values)
* luabenchmark (to run benchmarks)

If like me you prefer to keep your dependencies locally, per-project, then I recommend using my [llrocks] wrapper of the `luarocks` cli, which by default uses a local `lua_modules/` tree.

```
$ llrocks install ...
```

To run tests and benchmarks:

```
$ llrocks run shell_test.lua
$ llrocks run shell_bench.lua
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
