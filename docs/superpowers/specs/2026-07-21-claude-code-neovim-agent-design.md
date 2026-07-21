# Claude Code Neovim Agent Migration Design

## Goal
Replace current in-editor AI terminal integration with Claude Code CLI (`claude`) while keeping behavior and workflow identical.

## Constraints
- Hard switch to Claude naming only.
- No backward-compatible old command aliases.
- No leftover legacy-agent naming in repository after implementation.
- Keep keybindings and runtime behavior unchanged unless name text/command names require update.

## Selected Approach
In-place rename and wiring swap (minimal-risk path):
- Rename plugin module file to Claude-named module.
- Swap all require paths, command names, prompt text, completion function names, comments, and filetype labels to Claude.
- Keep control flow/state/job management logic unchanged.
- Swap spawned terminal command from legacy CLI to `claude`.

This gives identical functionality with smallest behavior risk and no leftover old naming.

## Affected Files
1. `init.lua`
   - `require('plugins.pi')` -> `require('plugins.claude')`

2. `lua/plugins/pi.lua` -> `lua/plugins/claude.lua`
   - Rename file.
   - Keep logic same.
   - Update all user-facing/internal identifiers:
     - `_G.pi_context_completion` -> `_G.claude_context_completion`
     - input completion binding string to new global symbol
     - prompt text `ask ...` to Claude wording
     - filetype label to `claude`
     - terminal job command: `jobstart('claude', ...)`
     - user commands:
       - `PiToggle` -> `ClaudeToggle`
       - `PiClose` -> `ClaudeClose`
       - `PiFocus` -> `ClaudeFocus`
     - comments and strings using old naming -> Claude naming

3. `lua/core/keymaps.lua`
   - Require path `plugins.pi` -> `plugins.claude`
   - Update keymap descriptions/comments to Claude naming
   - Keep key combos and functional behavior unchanged:
     - `<C-a>` normal/insert ask flow
     - `<C-a>` visual ask-with-selection
     - `<C-x>` visual send-selection
     - `<C-.>` toggle terminal pane
     - terminal `<Esc>` leave terminal mode
     - terminal `<C-c>` interrupt foreground process

## Behavior/Data Flow (unchanged)
- Prompt flow resolves context placeholders and queues/sends input.
- Visual selection capture and auto-attach behavior remains same.
- Pending queue flush/retry remains same.
- Split-window lifecycle remains same (open/toggle/focus/close).
- Job liveness checks remain same.
- On process exit, plugin clears state and closes pane as before.

## Error Handling (unchanged)
- Keep non-blocking retry loop for delayed job startup flush.
- Keep guarded job-status checks before send.
- Keep cleanup on terminal process exit.

## Verification Plan
### Static checks
- Ensure no old-name residue:
  - case-insensitive grep over repo for legacy tokens
  - command names and require paths only Claude-named

### Runtime smoke checks
1. `:ClaudeToggle` opens split and runs `claude`.
2. `<C-a>` prompt appears with Claude wording and sends input.
3. Visual `<C-a>` and `<C-x>` behave same as before.
4. `:ClaudeFocus` focuses terminal and enters insert mode.
5. `:ClaudeClose` closes and clears state.
6. Terminal `<Esc>` exits terminal mode without killing process.
7. Terminal `<C-c>` interrupts foreground process.

## Risks
- Missed rename in string-based callback/completion name can break completion.
- Missed require rename can break keymaps/commands at startup.

## Mitigations
- Use repository-wide search after edits for legacy tokens.
- Run startup/runtime smoke checks above.

## Out of Scope
- Refactor plugin architecture.
- Keybinding changes beyond naming text.
- Behavioral feature additions.
