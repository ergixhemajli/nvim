-- reuse the same jdtls setup for kotlin files
local ok, _ = pcall(require, "jdtls")
if ok then
    vim.cmd("runtime ftplugin/java.lua")
end
