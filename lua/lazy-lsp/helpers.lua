local function escape_shell_arg(arg)
  return "'" .. string.gsub(arg, "'", "'\"'\"'") .. "'"
end

local function escape_shell_args(args)
  local escaped = {}
  for _, arg in ipairs(args) do
    table.insert(escaped, escape_shell_arg(arg))
  end
  return table.concat(escaped, " ")
end

local function process_config(lang_config, user_config, default_config, nix_pkg)
  local cmd = (user_config and user_config.cmd)
    or (type(nix_pkg) == "table" and nix_pkg.cmd)
    or lang_config.document_config.default_config.cmd
  if nix_pkg ~= "" and cmd then
    local config = vim.tbl_extend("keep", user_config or {}, default_config)
    local nix_pkgs = type(nix_pkg) == "string" and { nix_pkg } or nix_pkg.pkgs
    local nix_cmd = { "nix-shell", "-p" }
    vim.list_extend(nix_cmd, nix_pkgs)
    table.insert(nix_cmd, "--run")
    table.insert(nix_cmd, escape_shell_args(cmd))
    config = vim.tbl_extend("keep", { cmd = nix_cmd }, config)

    -- This method can alter the cmd line, if it does, we merge the new arguments with the binary (since nix-shell does not support --)
    config.on_new_config = function(new_config, root_path)
      local fake_config = vim.tbl_extend("keep", { cmd = {} }, new_config)
      pcall(lang_config.document_config.default_config.on_new_config, fake_config, root_path)

      if #fake_config.cmd ~= 0 then
        local nargs = escape_shell_args({ unpack(cmd), unpack(fake_config.cmd) })
        new_config.cmd[#new_config.cmd] = nargs
      end
    end

    return config
  elseif user_config then
    local config = vim.tbl_extend("keep", user_config, default_config)
    return config
  end

  return nil
end

return {
  escape_shell_arg = escape_shell_arg,
  escape_shell_args = escape_shell_args,
  process_config = process_config,
}
