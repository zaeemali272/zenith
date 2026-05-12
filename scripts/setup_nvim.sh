#!/bin/bash

# --- 1. System Dependencies ---
echo "Installing Neovim and professional dev tools..."
sudo pacman -S --needed --noconfirm \
    neovim git base-devel wl-clipboard \
    ripgrep fd tree-sitter python-pip nodejs npm

# --- 2. Directory Scaffolding ---
echo "Scaffolding Neovim configuration structure..."
NVIM_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_DIR/lua/core"
mkdir -p "$NVIM_DIR/lua/plugins"

# --- 3. Bootstrap (init.lua) ---
cat <<EOF > "$NVIM_DIR/init.lua"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("core.options")
require("core.keymaps")
require("lazy").setup("plugins")
EOF

# --- 4. Core Options (~/lua/core/options.lua) ---
cat <<EOF > "$NVIM_DIR/lua/core/options.lua"
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.clipboard = "unnamedplus" -- Wayland/Hyprland clipboard sync

-- Ensure transparency for diffs
if vim.o.diff then
    vim.cmd([[
        highlight DiffAdd    guifg=#9ece6a guibg=NONE
        highlight DiffChange guifg=#e0af68 guibg=NONE
        highlight DiffDelete guifg=#f7768e guibg=NONE
        highlight DiffText   guifg=#7aa2f7 guibg=NONE
    ]])
end
EOF

# --- 5. Keymaps (~/lua/core/keymaps.lua) ---
cat <<EOF > "$NVIM_DIR/lua/core/keymaps.lua"
vim.g.mapleader = " "
local keymap = vim.keymap

keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Project View" })
keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlights" })
EOF

# --- 6. Transparent UI Config (~/lua/plugins/ui.lua) ---
cat <<EOF > "$NVIM_DIR/lua/plugins/ui.lua"
return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "storm",
                transparent = true,
                styles = {
                    sidebars = "transparent",
                    floats = "transparent",
                },
            })
            vim.cmd([[colorscheme tokyonight]])
            
            -- Manual overrides to ensure Arch/Hyprland transparency
            vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
            vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "tokyonight",
                    component_separators = "|",
                    section_separators = "",
                },
            })
        end,
    }
}
EOF

# --- 7. Tooling Spec (~/lua/plugins/lsp.lua) ---
cat <<EOF > "$NVIM_DIR/lua/plugins/lsp.lua"
return {
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "neovim/nvim-lspconfig" },
    { "williamboman/mason.nvim", config = true },
    { "williamboman/mason-lspconfig.nvim" },
    { "saghen/blink.cmp", version = "*" },
}
EOF

echo "Professional Neovim scaffolded! Launch 'nvim' to finish installation."
