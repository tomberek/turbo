# turbo, aka: `g`, `321`, `$`, `my`

Finds a copy, *any copy*, of that binary on your machine, and runs it. The idea is to prefer offline existing binaries.

Example:
```shell
$ g hello
Hello World!
$ 321 hello
Hello World!
$ $ hello
Hello World!
```

Note: searches in your Nix store profiles and gcroots.

## Maintenance
The resolved packages/binaries are cached into ~/.cache/turbo, so you can remove all of those to reset them.
