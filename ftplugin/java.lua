local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.expand("~/.cache/jdtls/workspace/") .. project_name

local config = {
    cmd = {
        "jdtls",
        "-data", workspace_dir,
    },
    root_dir = vim.fs.root(0, { "pom.xml", "mvnw", ".git" }),
    settings = {
        java = {
            import = {
                maven = { enabled = true }
            },
            maven = {
                downloadSources = true,
            },
            completion = {
                importOrder = { "java", "javax", "org", "com" }
            },
        }
    },
    init_options = {
        bundles = {}
    },
}

require("jdtls").start_or_attach(config)
