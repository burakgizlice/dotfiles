-- save by pressing Escape
vim.keymap.set('n', '<Esc>', ':w<CR>', { desc = 'Save' })
-- select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- --- LSP (Snacks picker based, matches LazyVim muscle memory) ---
-- Goto definition already mapped via <gd> in plugins/navigation.lua
vim.keymap.set('n', 'gr', function() Snacks.picker.lsp_references() end, { desc = 'Goto References' })
vim.keymap.set('n', 'gI', function() Snacks.picker.lsp_implementations() end, { desc = 'Goto Implementation' })
vim.keymap.set('n', 'gy', function() Snacks.picker.lsp_type_definitions() end, { desc = 'Goto Type Definition' })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Docs' })
vim.keymap.set({ 'n', 'i' }, '<C-s>', function() Snacks.picker.lsp_workspace_symbols() end, { desc = 'Search Symbol (workspace)' })

-- --- Diagnostics (LazyVim style) ---
vim.keymap.set('n', '<leader>ld', function() Snacks.picker.diagnostics() end, { desc = 'Diagnostics' })
vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, { desc = 'Code Action' })
vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = 'Rename Symbol' })

-- --- Search (LazyVim style, extra) ---
vim.keymap.set('n', '<leader>/', function() Snacks.picker.grep() end, { desc = 'Search in Buffer' })
vim.keymap.set('n', '<leader>fg', function() Snacks.picker.grep() end, { desc = 'Live Grep' })
vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files() end, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fb', function() Snacks.picker.buffers() end, { desc = 'Buffers' })

