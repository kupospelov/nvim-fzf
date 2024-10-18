# nvim-fzf

A minimalistic `fzf` plugin.

This project is heavily inspired by
[fzf.vim](https://github.com/junegunn/fzf.vim), but has a few differences:

* Pure Lua implementation
* Much smaller codebase
* No dependencies

## Installation

[packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua

require('packer').startup(function(use)
    use('kupospelov/nvim-fzf')
end)

```

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua

require('lazy').setup({
    { 'kupospelov/nvim-fzf' },
})

```

## Configuration

The default configuration:

```lua
local config = {
    options = {},
    layout = {
        tmux = { '-p90%,60%' },
        window = { width = 0.9, height = 0.6 },
    },
}
```

Settings can be changed using the `setup` function that accepts a table with the following fields:
* `options` contains options for `fzf`.
* `layout` configures the size and position of the `fzf` window.
  * `tmux` contains additional options for `fzf-tmux`.
  * `window` contains the `width` and `height` of the popup window in the range from `0.0` to `1.0`.

The plugin uses a tmux popup when used in a tmux session. The tmux popup can be disabled by setting a `layout` that only has `window` set:


```lua

local fzf = require('fzf')
fzf.setup({
    layout = {
        window = {
            width = 0.9,
            height = 0.6,
        },
    },
})

```

### Functions

The plugin exports functions that you can use to create custom
mappings or commands:

```lua

vim.keymap.set('n', '<C-P>', fzf.files)

vim.keymap.set('n', '<C-P>', function()
    fzf.files('ls')
end)

```

| Function | Description |
| ---------| ------------|
| `buffers`| Open buffers.|
| `files`  | Files to open. An optional `source` command can be passed as a parameter to be used as input instead of `$FZF_DEFAULT_COMMAND`.|
