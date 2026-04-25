
-- Todo list highlighting in Neovim
local function setup_todo_highlights()
    -- Highlight groups for different todo states
    vim.api.nvim_set_hl(0, 'TodoPending', { fg = '#A0A0A0' })        -- Gray for pending tasks
    vim.api.nvim_set_hl(0, 'TodoInProgress', { fg = '#4169E1' })     -- Royal Blue for in-progress tasks
    vim.api.nvim_set_hl(0, 'TodoDone', { fg = '#228B22', strikethrough = true }) -- Dark Green for completed tasks
    
    -- Syntax matching for different todo markers
    vim.cmd [[
        syntax match TodoPending /^\s*-\s.*$/
        syntax match TodoInProgress /^\s*\*\s.*$/
        syntax match TodoDone /^\s*+\s.*$/
    ]]
end

-- Call the setup function
setup_todo_highlights()

-- Optional: Autocommand to apply highlights when opening .md or .txt files
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = {"*.md", "*.txt"},
    callback = setup_todo_highlights
})
