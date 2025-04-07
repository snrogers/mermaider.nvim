#!/bin/sh

# Set up environment to isolate Neovim config (optional)
export XDG_CONFIG_HOME="$(pwd)/test/xdg/config"
export XDG_DATA_HOME="$(pwd)/test/xdg/data"

# Run Neovim as a Lua interpreter, loading busted
nvim -u NONE -l "$(luarocks path --lr-bin)/busted" "$@"
