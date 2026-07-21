# Claude Code Neovim Agent Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace legacy-agent-based Neovim agent integration with Claude Code CLI (`claude`) while keeping identical behavior and key workflow.

**Architecture:** Keep existing plugin logic intact and do a strict rename-and-rewire migration. Move plugin module/file from `legacy-agent-cli` to `claude`, update all command/keymap/global symbol/user-facing strings, and switch process launcher from `legacy-agent-cli` to `claude`. Validate no `legacy-agent-cli` mentions remain in repository.

**Tech Stack:** Neovim Lua config, Vim user commands, keymaps, terminal job control (`vim.fn.jobstart`), ripgrep for verification.

## Global Constraints

- Hard switch only: no backward-compatible `Previous*` command aliases.
- No remaining `legacy-agent-cli` mentions anywhere in repository after implementation.
- Launch Claude Code CLI using exact command `claude`.
- Preserve identical runtime behavior and keybindings/workflow.

---

### Task 1: Rename plugin module entrypoint

**Files:**
- Modify: `init.lua`
- Move: `lua/plugins/previous-agent.lua` -> `lua/plugins/claude.lua`

**Interfaces:**
- Consumes: Existing module load `require('plugins.previous_agent')` and plugin implementation file `lua/plugins/previous-agent.lua`.
- Produces: New module load `require('plugins.claude')` and plugin file path `lua/plugins/claude.lua`.

- [ ] **Step 1: Write the failing structural check command (pre-change)**

```bash
rg -n "require\('plugins\.claude'\)|require\('plugins\.legacy_agent'\)" /Users/ergix/.config/nvim/init.lua
```

Expected now: only `require('plugins.previous_agent')` found.

- [ ] **Step 2: Update module require in `init.lua`**

```lua
-- before
require('plugins.previous_agent')

-- after
require('plugins.claude')
```

- [ ] **Step 3: Rename plugin file path**

Run:

```bash
mv /Users/ergix/.config/nvim/lua/plugins/previous-agent.lua /Users/ergix/.config/nvim/lua/plugins/claude.lua
```

- [ ] **Step 4: Run structural check to verify pass**

Run:

```bash
test -f /Users/ergix/.config/nvim/lua/plugins/claude.lua && ! test -f /Users/ergix/.config/nvim/lua/plugins/previous-agent.lua && rg -n "require\('plugins\.claude'\)" /Users/ergix/.config/nvim/init.lua
```

Expected: file exists at `claude.lua`, old file missing, require points to `plugins.claude`.

- [ ] **Step 5: Commit**

```bash
git -C /Users/ergix/.config/nvim add init.lua lua/plugins/claude.lua
git -C /Users/ergix/.config/nvim commit -m "refactor: rename legacy-agent plugin module to claude"
```

---

### Task 2: Rename plugin internals and public commands; switch runtime command to `claude`

**Files:**
- Modify: `lua/plugins/claude.lua`

**Interfaces:**
- Consumes: Existing state/job flow, completion callback, prompt config, filetype, user commands, launcher command in current plugin logic.
- Produces:
  - `_G.claude_context_completion` global completion function
  - `completion = 'customlist,v:lua.claude_context_completion'`
  - `prompt = 'ask claude: '`
  - `vim.bo[state.buf].filetype = 'claude'`
  - `vim.fn.jobstart('claude', { ... })`
  - user commands: `ClaudeToggle`, `ClaudeClose`, `ClaudeFocus`

- [ ] **Step 1: Write failing grep checks (pre-change)**

Run:

```bash
rg -n "previous_agent_context_completion|customlist,v:lua\.previous_agent_context_completion|ask legacy-agent:|filetype = 'legacy-agent'|jobstart('legacy-agent-cli'|PreviousToggle|PreviousClose|PreviousFocus|legacy-agent instance|interrupt legacy-agent" /Users/ergix/.config/nvim/lua/plugins/claude.lua
```

Expected now: matches found.

- [ ] **Step 2: Apply exact string/identifier replacements in `lua/plugins/claude.lua`**

```lua
-- completion symbol
_G.claude_context_completion = function(_, cmdline)

-- input completion usage
completion = 'customlist,v:lua.claude_context_completion'

-- prompt
prompt = 'ask claude: '

-- filetype
vim.bo[state.buf].filetype = 'claude'

-- launcher
state.job = vim.fn.jobstart('claude', {

-- comments
-- Keep pending messages queued when opening a fresh Claude instance.

-- user commands
vim.api.nvim_create_user_command('ClaudeToggle', function()
  require('plugins.claude').toggle()
end, {})

vim.api.nvim_create_user_command('ClaudeClose', function()
  require('plugins.claude').close()
end, {})

vim.api.nvim_create_user_command('ClaudeFocus', function()
  require('plugins.claude').focus()
end, {})
```

- [ ] **Step 3: Verify no old plugin tokens remain in this file**

Run:

```bash
rg -n -i "\blegacy-agent\b|PreviousToggle|PreviousClose|PreviousFocus|plugins\.legacy_agent|previous_agent_context_completion|ask legacy-agent:" /Users/ergix/.config/nvim/lua/plugins/claude.lua
```

Expected: no matches.

- [ ] **Step 4: Commit**

```bash
git -C /Users/ergix/.config/nvim add lua/plugins/claude.lua
git -C /Users/ergix/.config/nvim commit -m "refactor: switch plugin internals and commands to claude"
```

---

### Task 3: Rewire keymaps and user-facing keymap text to Claude module

**Files:**
- Modify: `lua/core/keymaps.lua`

**Interfaces:**
- Consumes: Existing key combos and function behavior.
- Produces:
  - `require('plugins.claude')` for all related mappings
  - descriptions/comments renamed to Claude wording
  - unchanged key combos: `<C-a>`, `<C-x>`, `<C-.>`, terminal `<Esc>`, terminal `<C-c>`

- [ ] **Step 1: Write failing grep check (pre-change)**

Run:

```bash
rg -n "plugins\.legacy_agent|Ask legacy-agent|selection to legacy-agent|Toggle legacy-agent|interrupt legacy-agent|Legacy-agent keymaps" /Users/ergix/.config/nvim/lua/core/keymaps.lua
```

Expected now: matches found.

- [ ] **Step 2: Update keymap module references and descriptions/comments**

```lua
-- before examples
keymap('n', '<C-a>', function() require('plugins.previous_agent').ask_input() end, { desc = 'Ask legacy-agent' })
keymap('x', '<C-x>', function() require('plugins.previous_agent').send_visual_selection() end, { desc = 'Send selection to legacy-agent' })
keymap({ 'n', 't' }, '<C-.>', function() require('plugins.previous_agent').toggle() end, { desc = 'Toggle legacy-agent' })
-- Legacy-agent keymaps
-- Interrupt legacy-agent (or any foreground terminal process)

-- after examples
keymap('n', '<C-a>', function() require('plugins.claude').ask_input() end, { desc = 'Ask claude' })
keymap('x', '<C-x>', function() require('plugins.claude').send_visual_selection() end, { desc = 'Send selection to claude' })
keymap({ 'n', 't' }, '<C-.>', function() require('plugins.claude').toggle() end, { desc = 'Toggle claude' })
-- Claude keymaps
-- Interrupt claude (or any foreground terminal process)
```

- [ ] **Step 3: Verify rewiring complete in keymaps file**

Run:

```bash
rg -n "plugins\.claude|Ask claude|selection to claude|Toggle claude|Claude keymaps|Interrupt claude" /Users/ergix/.config/nvim/lua/core/keymaps.lua
```

Expected: matches found for Claude variants only.

- [ ] **Step 4: Commit**

```bash
git -C /Users/ergix/.config/nvim add lua/core/keymaps.lua
git -C /Users/ergix/.config/nvim commit -m "refactor: rewire keymaps to claude plugin"
```

---

### Task 4: End-to-end verification and residue sweep

**Files:**
- Verify: repository-wide

**Interfaces:**
- Consumes: Completed file/module/command rewiring from Tasks 1-3.
- Produces: Verified behavior parity and verified zero `legacy-agent-cli` mentions.

- [ ] **Step 1: Run residue sweep for old naming**

Run:

```bash
rg -n -i "\blegacy-agent\b|plugins\.legacy_agent|PreviousToggle|PreviousClose|PreviousFocus|previous_agent_context_completion|ask legacy-agent:" /Users/ergix/.config/nvim
```

Expected: no matches.

- [ ] **Step 2: Run startup sanity check**

Run:

```bash
nvim --headless "+lua require('plugins.claude')" "+qall"
```

Expected: exits successfully with no Lua error output.

- [ ] **Step 3: Run command existence check**

Run:

```bash
nvim --headless "+lua local cmds=vim.api.nvim_get_commands({}); assert(cmds.ClaudeToggle); assert(cmds.ClaudeClose); assert(cmds.ClaudeFocus)" "+qall"
```

Expected: exits successfully with no assertion failure.

- [ ] **Step 4: Manual smoke checklist in interactive Neovim**

Run interactive checks:

```text
:ClaudeToggle      -> opens split and starts `claude`
<C-a> (normal)     -> prompt says "ask claude:"
<C-a> (visual)     -> asks with visual selection context
<C-x> (visual)     -> sends raw selected text
:ClaudeFocus       -> focuses split and enters insert mode
:ClaudeClose       -> closes split, clears state
<Esc> in terminal  -> exits terminal mode only
<C-c> in terminal  -> interrupts foreground process
```

Expected: behavior same as pre-migration except naming and CLI command changed.

- [ ] **Step 5: Commit verification-safe cleanup if needed**

```bash
git -C /Users/ergix/.config/nvim add -A
git -C /Users/ergix/.config/nvim commit -m "chore: verify claude migration and remove legacy-agent residue"
```

(Only if additional edits were needed during verification.)
