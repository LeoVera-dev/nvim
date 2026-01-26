-- Bootstrap packer.nvim
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Suppress vim.tbl_islist deprecation warnings (temporary fix for plugin compatibility)
vim.deprecate = function() end

-- Basic Settings
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.swapfile = false
vim.opt.smartindent = true
vim.g.mapleader = " "
vim.o.winborder = "rounded"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- Key Mappings
vim.keymap.set('n', '<leader>o', ':update<CR>:source<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('n', '<leader>O', ":Oil<CR>")
vim.keymap.set('n', '<leader>M', ":Mason<CR>")
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)

-- LSP Attach Keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  end,
})

-- Plugin Setup
require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  
  -- Colorscheme
  use 'sainnhe/gruvbox-material'
  
  -- File Explorer
  use {
    'stevearc/oil.nvim',
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = {
          "permissions",
          "size",
          "mtime",
        },
        view_options = {
          show_hidden = true,
        },
      })
    end,
  }
  
  -- Fuzzy Finder
  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          mappings = {
            i = {
              ['<C-j>'] = require('telescope.actions').move_selection_next,
              ['<C-k>'] = require('telescope.actions').move_selection_previous,
            },
          },
        },
      })
      
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
      vim.keymap.set('n', '<leader>fr', builtin.lsp_references, {})
      vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, {})
    end,
  }
  
  -- Icons
  use 'nvim-tree/nvim-web-devicons'
  
  -- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
  }
  
  -- LSP
  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  
  -- Completion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'
  
  -- Dashboard
  use {
    'goolord/alpha-nvim',
    config = function()
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')
      
      dashboard.section.header.val = {
      "███    ██ ███████  ██████  ██    ██ ██ ███    ███",
      "████   ██ ██      ██    ██ ██    ██ ██ ████  ████",
      "██ ██  ██ █████   ██    ██ ██    ██ ██ ██ ████ ██",
      "██  ██ ██ ██      ██    ██  ██  ██  ██ ██  ██  ██",
      "██   ████ ███████  ██████    ████   ██ ██      ██"
      }
      
      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
        dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
        dashboard.button("o", "  Open Oil", ":Oil <CR>"),
        dashboard.button("g", "  Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", "  Configuration", ":e ~/.config/nvim/init.lua <CR>"),
        dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
      }
      
      dashboard.section.footer.val = "\"seek nothing outside yourself\""
      
      alpha.setup(dashboard.opts)
      vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
    end,
  }
  
  -- Automatically set up configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- Auto-reload config on save
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost init.lua source <afile> | PackerSync
  augroup end
]])

-- Treesitter setup (protected call in case it's not installed yet)
local status_ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if status_ok then
  treesitter.setup({
    ensure_installed = {
      "lua",
      "python",
      "c",
      "go",
      "rust",
      "bash",
      "javascript",
      "typescript",
      "html",
      "css",
      "json",
      "markdown",
    },
    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
  })
end

-- Mason setup (protected call)
local mason_ok, mason = pcall(require, 'mason')
if mason_ok then
  mason.setup()
end

local mason_lsp_ok, mason_lspconfig = pcall(require, 'mason-lspconfig')
if mason_lsp_ok then
  mason_lspconfig.setup({
    ensure_installed = {
      "lua_ls",
      "pyright",
      "clangd",
      "rust_analyzer",
      "bashls",
      "ts_ls",
    },
    automatic_installation = true
  })
end

-- LSP Configuration (using new vim.lsp.config API for Neovim 0.11+)
local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')

if cmp_nvim_lsp_ok then
  local cmp_capabilities = cmp_nvim_lsp.default_capabilities()
  
  -- Configure LSP servers using the new API
  local servers = { "lua_ls", "pyright", "clangd", "rust_analyzer", "bashls", "ts_ls" }
  
  for _, server in ipairs(servers) do
    vim.lsp.config(server, {
      capabilities = cmp_capabilities,
    })
  end
  
  -- Enable the configured servers
  vim.lsp.enable(servers)
end

-- Completion setup (protected call)
local cmp_ok, cmp = pcall(require, 'cmp')
local luasnip_ok, luasnip = pcall(require, 'luasnip')

if cmp_ok and luasnip_ok then
  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }),
  })
end

-- Colorscheme
vim.cmd(":hi statusline guibg=NONE")
vim.cmd("colorscheme gruvbox-material")
-- Transparent background
vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
-- Optional: fix background for other elements
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })

