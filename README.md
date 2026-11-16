# My tiny tool for keeping track of Hyprland keybinds

Note, this was one of my earlier Odin projects, so I will most
definitely rewrite this sometime in the future, with updated Repo to come.

In the meanwhile:

## Usage

```txt
Usage: hyprbind [-s] [-m <mode> ]

-s -> View list of submaps && their respective bind count
-m -> Create runner menu. Mode can be either 'subkey' or 'key'
      ('subkey' creates a menu of all submaps, then keys for
      selected map. 'key' uses all binds for menu)
```

Config is generated on use, if missing. Hyprbind supports any
``dmenu`` esque runner, that takes line separated stdin, and
returns selected entry to stdout. Default config has arguments
supplied for ``Wofi``.

## Config location

```bash
$HOME/.config/hyprbind/config.json
```
