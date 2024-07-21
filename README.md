# turbo, aka: `g`, `321`, `$`, `my`

Finds a copy, *any copy*, of that binary on your machine, and runs it. The idea is to prefer offline existing binaries.

## Example
```shell
$ g hello
Hello World!
$ $ hello
Hello World!
$ $ python3
INFO /nix/var/nix/gcroots/auto/107x662c7phh7k0rpm1ki4g7j8w847ck ->
INFO   /home/tom/nix-runner/p39 ->
INFO     /nix/store/v7h4276ij0sj48qwrf4g4cm3pfc86mmw-python3-3.9.16/bin/python3 ->
INFO       /nix/store/v7h4276ij0sj48qwrf4g4cm3pfc86mmw-python3-3.9.16/bin/python3.9
Python 3.9.16 (main, Dec  6 2022, 18:36:13)
[GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

## Usage
```
Search and run a binary

Usage:
  g [options] ( local | remote | index ) <arg>...
  g clear
  g [options] <command> [<args>]...

Subcommands:
  local   Find file in local db
  remote  Find file using nix-locate
  index   Index paths (/nix/store, /nix/var/nix/profiles/*)
  clear   Clear cache at ~/.cache/turbo

Options:
  -m, --minimal        Minimal output
  -d, --debug          Debug output
  -h, --help           Show this screen
  -v, --version        Print version
```

## Search Precedence
- searches in `~/.cache/turbo/*/bin`
- searches in $PATH
- searches in `~/.cache/turbo/locate.db`
- generates `~/.cache/turbo/locate.db` by indexing from:
    - /nix/var/nix/profiles
    - /nix/var/nix/gcroots
- searches in `~/.cache/turbo/locate.db`
- searches using `nix-locate`

## Credits
@nicklewis
@ysndr
