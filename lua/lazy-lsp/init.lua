local lspconfig = require("lspconfig")
local servers = require("lazy-lsp.servers")
local process_config = require("lazy-lsp.helpers").process_config

local function setup(opts)
  opts = opts or {}
  local excluded_servers = opts.excluded_servers or {}
  local default_config = opts.default_config or {}
  local configs = opts.configs or {}

  for lsp, nix_pkg in pairs(servers) do
    -- Check if a server is excluded first, so that we don't look up the config
    -- and for deprecated servers we won't get a warning message.
    if not vim.tbl_contains(excluded_servers, lsp) and lspconfig[lsp] then
      local lang_config = lspconfig[lsp]
      local user_config = configs[lsp]

      local config = process_config(lang_config, user_config, default_config, nix_pkg)
      if config then
        lang_config.setup(config)
      end
    end
  end
end

return {
  setup = setup,
}
