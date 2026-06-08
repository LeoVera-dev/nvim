-- Settings
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.signcolumn     = "yes"
vim.opt.wrap           = false
vim.opt.tabstop        = 2
vim.opt.shiftwidth     = 2
vim.opt.expandtab      = true
vim.opt.smartindent    = true
vim.opt.swapfile       = false
vim.opt.undofile       = true
vim.opt.termguicolors  = true
vim.opt.updatetime     = 250
vim.opt.timeoutlen     = 300
vim.opt.completeopt    = { "menu", "menuone", "noselect" }
vim.opt.winborder      = "rounded"
vim.g.mapleader        = " "

-- Keymaps
local map = vim.keymap.set

-- General
map("n", "<leader>o", ":update<CR>",           { desc = "Save" })
map("n", "<leader>w", ":write<CR>",            { desc = "Write" })
map("n", "<leader>q", ":quit<CR>",             { desc = "Quit" })

-- Plugins
map("n", "<leader>O", ":Oil<CR>",              { desc = "Open Oil" })
map("n", "<leader>M", ":Mason<CR>",            { desc = "Open Mason" })
map("n", "<leader>u", vim.cmd.UndotreeToggle,  { desc = "Toggle Undotree" })

-- LSP (buffer-local, set on LspAttach)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    local function lmap(key, fn, desc)
      map("n", key, fn, vim.tbl_extend("force", opts, { desc = desc }))
    end

    lmap("gd",          vim.lsp.buf.definition,                      "Go to definition")
    lmap("K",           vim.lsp.buf.hover,                           "Hover docs")
    lmap("gr",          vim.lsp.buf.references,                      "References")
    lmap("<leader>rn",  vim.lsp.buf.rename,                          "Rename symbol")
    lmap("<leader>ca",  vim.lsp.buf.code_action,                     "Code action")
    lmap("<leader>lf",  function()
      vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
    end, "Format buffer")

    lmap("[d",          vim.diagnostic.goto_prev,                    "Prev diagnostic")
    lmap("]d",          vim.diagnostic.goto_next,                    "Next diagnostic")
    lmap("<leader>e",   vim.diagnostic.open_float,                   "Show diagnostic")
    lmap("<leader>dl",  vim.diagnostic.setloclist,                   "Diagnostic list")
  end,
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({

  -- Colorscheme
  {
    "edeneast/nightfox.nvim",
    lazy     = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("carbonfox")
      vim.cmd(":hi statusline guibg=NONE")
    end,
  },

  -- File explorer
  {
    "stevearc/oil.nvim",
    lazy = false,
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns      = { "permissions", "size", "mtime" },
        view_options = { show_hidden = true },
      })
    end,
  },

  -- Undo history visualizer
  { "mbbill/undotree" },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
      })
      map("n", "<leader>ff", builtin.find_files,           { desc = "Find files" })
      map("n", "<leader>fg", builtin.live_grep,            { desc = "Live grep" })
      map("n", "<leader>fb", builtin.buffers,              { desc = "Buffers" })
      map("n", "<leader>fh", builtin.help_tags,            { desc = "Help tags" })
      map("n", "<leader>fr", builtin.lsp_references,       { desc = "LSP references" })
      map("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "LSP symbols" })
    end,
  },

  -- Icons
  { "nvim-tree/nvim-web-devicons" },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })()
    end,
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      configs.setup({
        ensure_installed = {
          "lua", "python", "c", "go", "rust",
          "bash", "javascript", "typescript",
          "html", "css", "json", "markdown",
        },
        sync_install  = false,
        auto_install  = true,
        highlight     = { enable = true, additional_vim_regex_highlighting = false },
        indent        = { enable = true },
      })
    end,
  },

  -- LSP
  { "neovim/nvim-lspconfig" },

  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "clangd", "rust_analyzer", "bashls", "ts_ls" },
        automatic_installation = true,
      })
    end,
  },

  {
    "echasnovski/mini.icons",
    version = false,
    config = function()
      require("mini.icons").setup()
    end,
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      { "L3MON4D3/LuaSnip", version = "v2.*", build = "make install_jsregexp" },
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    config = function()
      require("render-markdown").setup({})
    end,
  },

  -- Image display (Kitty / Ghostty protocol)
  {
    "3rd/image.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("image").setup({
        backend = "kitty",
        integrations = {
          markdown = {
            enabled                     = true,
            clear_in_insert_mode        = false,
            download_remote_images      = true,
            only_render_image_at_cursor = false,
            filetypes                   = { "markdown", "vimwiki" },
          },
        },
        max_height_window_percentage = 50,
        kitty_method                 = "normal",
      })
    end,
  },

  -- Dashboard
  {
    "goolord/alpha-nvim",
    lazy = false,
    config = function()
      local alpha     = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "███    ██ ███████  ██████  ██    ██ ██ ███    ███",
        "████   ██ ██      ██    ██ ██    ██ ██ ████  ████",
        "██ ██  ██ █████   ██    ██ ██    ██ ██ ██ ████ ██",
        "██  ██ ██ ██      ██    ██  ██  ██  ██ ██  ██  ██",
        "██   ████ ███████  ██████    ████   ██ ██      ██",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file",           ":Telescope find_files<CR>"),
        dashboard.button("e", "  New file",            ":ene <BAR> startinsert<CR>"),
        dashboard.button("r", "  Recently used files", ":Telescope oldfiles<CR>"),
        dashboard.button("o", "  Open Oil",            ":Oil<CR>"),
        dashboard.button("g", "  Find text",           ":Telescope live_grep<CR>"),
        dashboard.button("c", "  Configuration",       ":e ~/.config/nvim/init.lua<CR>"),
        dashboard.button("q", "  Quit Neovim",         ":qa<CR>"),
      }
      dashboard.section.footer.val = '"seek nothing outside yourself"'
      alpha.setup(dashboard.opts)
      vim.cmd("autocmd FileType alpha setlocal nofoldenable")
    end,
  },

}, {
  ui = { border = "rounded" },
})

-- LSP server configuration
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local servers = { "lua_ls", "pyright", "clangd", "rust_analyzer", "bashls", "ts_ls" }

for _, server in ipairs(servers) do
  vim.lsp.config(server, { capabilities = capabilities })
end
vim.lsp.enable(servers)
