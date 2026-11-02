vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wildignore = { "*/node_modules/*" }

vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})

-- Neovim's built-in package manager clones these on first start.
vim.pack.add({
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/folke/flash.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/stevearc/conform.nvim",
})

require("mini.basics").setup({
  options = { extra_ui = true },
  mappings = { windows = true },
})
for _, module in ipairs({
  "ai",
  "bracketed",
  "bufremove",
  "cmdline",
  "comment",
  "completion",
  "diff",
  "extra",
  "icons",
  "jump",
  "move",
  "notify",
  "pairs",
  "pick",
  "starter",
  "statusline",
  "tabline",
  "trailspace",
}) do
  require("mini." .. module).setup()
end
require("mini.indentscope").setup({ draw = { delay = 0 } })

require("flash").setup({ modes = { char = { jump_labels = true } } })

require("conform").setup({
  formatters_by_ft = {
    nix = { "nixfmt" },
    yaml = { "yamlfmt" },
    json = { "prettier" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

-- The servers are not packaged for Fedora; enable whichever is installed.
for server, executable in pairs({ nixd = "nixd", yamlls = "yaml-language-server" }) do
  if vim.fn.executable(executable) == 1 then
    vim.lsp.enable(server)
  end
end

local function map(mode, key, action)
  vim.keymap.set(mode, key, action, { silent = true, noremap = true })
end
map("n", "X", function() MiniBufremove.delete() end)
map("n", "<leader>f", function() MiniPick.builtin.files() end)
map("n", "<leader>r", function() MiniPick.builtin.grep_live() end)
map("n", "<leader>b", function() MiniPick.builtin.buffers() end)
map("n", "<leader>R", function() MiniPick.builtin.resume() end)
map("n", "<leader>d", function() MiniExtra.pickers.diagnostic() end)
map("n", "<leader>gh", function() MiniExtra.pickers.git_hunks() end)
map("n", "s", function() require("flash").jump() end)
map("o", "r", function() require("flash").remote() end)
