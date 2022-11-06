# cmp-bitbake-path

nvim-cmp source for filesystem path to include in SRC\_URI variables.

For example, assuming you have the following structure:

```
recipe
├── files
│   ├── 0001.patch
│   └── 0002.patch
└── recipe_1.0.bb
```

While editing `recipe_1.0.bb`, completion will be available when writing:

![completion](https://user-images.githubusercontent.com/37036499/200187965-27971a01-e66d-46b9-899c-9601387b7405.png)

> Heavily based off [`hrsh7th/cmp-path`](https://github.com/hrsh7th/cmp-path).

# Install

Install with [`packer`](https://github.com/wbthomason/packer.nvim):

```lua
use 'antznin/cmp-bitbake-path'
```

# Setup

```lua
require'cmp'.setup {
  sources = {
    { name = 'bitbake_path' }
  }
}
```

# Configuration

The below source configuration options are available. To set any of
these options, do:

```lua
cmp.setup({
  sources = {
    {
      name = 'bitbake_path',
      option = {
        -- Options go into this table
      },
    },
  },
})
```


## trailing_slash (type: boolean)

_Default:_ `false`

Specify if completed directory names should include a trailing slash.
Enabling this option makes this source behave like Vim's built-in path
completion.

## label_trailing_slash (type: boolean)

_Default:_ `true`

Specify if directory names in the completion menu should include a
trailing slash.

## get_cwd (type: function)

_Default:_ returns the current working directory of the current buffer

Specifies the base directory for relative paths.
