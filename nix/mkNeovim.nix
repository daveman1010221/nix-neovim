# Function for creating a Neovim derivation
{
  pkgs,
  lib,
  stdenv,
}:
with lib;
  {
    appName ? null, # NVIM_APPNAME - Defaults to 'nvim'
    plugins ? [], # List of plugins
    # List of dev plugins (will be bootstrapped) - useful for plugin developers
    # { name = <plugin-name>; url = <git-url>; }
    devPlugins ? [],
    # Regexes for config files to ignore, relative to the nvim directory.
    # e.g. [ "^plugin/neogit.lua" "^ftplugin/.*.lua" ]
    ignoreConfigRegexes ? [],
    extraPackages ? [], # Extra runtime dependencies (e.g. ripgrep, ...)
    # The below arguments can typically be left as their defaults
    resolvedExtraLuaPackages ? [], # Additional lua packages (not plugins), e.g. from luarocks.org
    extraPython3Packages ? p: [], # Additional python 3 packages
    withPython3 ? true, # Build Neovim with Python 3 support?
    withRuby ? false, # Build Neovim with Ruby support?
    withNodeJs ? false, # Build Neovim with NodeJS support?
    withSqlite ? true, # Add sqlite? This is a dependency for some plugins
    # You probably don't want to create vi or vim aliases
    # if the appName is something different than "nvim"
    viAlias ? appName == "nvim", # Add a "vi" binary to the build output as an alias?
    vimAlias ? appName == "nvim", # Add a "vim" binary to the build output as an alias?
  }: let
    # This is the structure of a plugin definition.
    # Each plugin in the `plugins` argument list can also be defined as this attrset
    defaultPlugin = {
      plugin = null; # e.g. nvim-lspconfig
      config = null; # plugin config
      # If `optional` is set to `false`, the plugin is installed in the 'start' packpath
      # set to `true`, it is installed in the 'opt' packpath, and can be lazy loaded with
      # ':packadd! {plugin-name}
      optional = false;
    };

    externalPackages = extraPackages ++ (optionals withSqlite [pkgs.sqlite]);

    # Map all plugins to an attrset { plugin = <plugin>; config = <config>; optional = <tf>; ... }
    normalizedPlugins = map (x:
      defaultPlugin
      // (
        if x ? plugin
        then x
        else {plugin = x;}
      ))
    plugins;

    # Build wrapper arguments manually
    wrapperArgsList =
      [
        # Python3 support
        (optionals withPython3 (
          let
            python = pkgs.python3;
            sitePackages = map (p: p.${if lib.isDerivation p then "out" else "site-packages"}) (extraPython3Packages pkgs);
          in [
            "--set" "PYTHONPATH" (lib.makeSearchPath "lib/python${python.pythonVersion}/site-packages" sitePackages)
            "--suffix" "PATH" ":" (lib.makeBinPath [ python ])
          ]
        ))
        # External packages
        (optionals (externalPackages != []) [
          "--suffix" "PATH" ":" (lib.makeBinPath externalPackages)
        ])
        # SQLite
        (optionals withSqlite [
          "--set" "LIBSQLITE_CLIB_PATH" "${pkgs.sqlite.out}/lib/libsqlite3.so"
          "--set" "LIBSQLITE" "${pkgs.sqlite.out}/lib/libsqlite3.so"
        ])
        # NVIM_APPNAME
        (optionals (appName != "nvim" && appName != null && appName != "") [
          "--set" "NVIM_APPNAME" appName
        ])
      ];
    
    wrapperArgs = lib.escapeShellArgs (builtins.concatLists wrapperArgsList);

    # This uses the ignoreConfigRegexes list to filter
    # the nvim directory
    nvimRtpSrc = let
      src = ../nvim;
    in
      lib.cleanSourceWith {
        inherit src;
        name = "nvim-rtp-src";
        filter = path: tyoe: let
          srcPrefix = toString src + "/";
          relPath = lib.removePrefix srcPrefix (toString path);
        in
          lib.all (regex: builtins.match regex relPath == null) ignoreConfigRegexes;
      };

    # Split runtimepath into 3 directories:
    # - lua, to be prepended to the rtp at the beginning of init.lua
    # - nvim, containing plugin, ftplugin, ... subdirectories
    # - after, to be sourced last in the startup initialization
    # See also: https://neovim.io/doc/user/starting.html
    nvimRtp = stdenv.mkDerivation {
      name = "nvim-rtp";
      src = nvimRtpSrc;

      buildPhase = ''
        mkdir -p $out/nvim
        mkdir -p $out/lua
        rm init.lua
      '';

      installPhase = ''
        cp -r after $out/after
        rm -r after
        cp -r lua $out/lua
        rm -r lua
        cp -r * $out/nvim
      '';
    };

    # The final init.lua content that we pass to the Neovim wrapper.
    # It wraps the user init.lua, prepends the lua lib directory to the RTP
    # and appends the nvim and after directory to the RTP
    # It also adds logic for bootstrapping dev plugins (for plugin developers)
    initLua =
      ''
        -- prepend lua directory
        vim.opt.rtp:prepend('${nvimRtp}/lua')
      ''
      # Wrap init.lua
      + (builtins.readFile ../nvim/init.lua)
      # Bootstrap/load dev plugins
      + optionalString (devPlugins != []) (
        ''
          local dev_pack_path = vim.fn.stdpath('data') .. '/site/pack/dev'
          local dev_plugins_dir = dev_pack_path .. '/opt'
          local dev_plugin_path
        ''
        + strings.concatMapStringsSep
        "\n"
        (plugin: ''
          dev_plugin_path = dev_plugins_dir .. '/${plugin.name}'
          if vim.fn.empty(vim.fn.glob(dev_plugin_path)) > 0 then
            vim.notify('Bootstrapping dev plugin ${plugin.name} ...', vim.log.levels.INFO)
            vim.cmd('!${pkgs.git}/bin/git clone ${plugin.url} ' .. dev_plugin_path)
          end
          vim.cmd('packadd! ${plugin.name}')
        '')
        devPlugins
      )
      # Append nvim and after directories to the runtimepath
      + ''
        vim.opt.rtp:append('${nvimRtp}/nvim')
        vim.opt.rtp:append('${nvimRtp}/after')
      '';

    # Lua library paths (if any)
    extraMakeWrapperLuaCArgs = optionalString (resolvedExtraLuaPackages != []) ''
      --suffix LUA_CPATH ";" "${
        lib.concatMapStringsSep ";" pkgs.luaPackages.getLuaCPath
        resolvedExtraLuaPackages
      }"'';

    extraMakeWrapperLuaArgs =
      optionalString (resolvedExtraLuaPackages != [])
      ''
        --suffix LUA_PATH ";" "${
          concatMapStringsSep ";" pkgs.luaPackages.getLuaPath
          resolvedExtraLuaPackages
        }"'';

    # Combine wrapper args (including Lua paths) into the final string
    finalWrapperArgs = wrapperArgs + " " + extraMakeWrapperLuaCArgs + " " + extraMakeWrapperLuaArgs;
  in
    # wrapNeovimUnstable is the nixpkgs utility function for building a Neovim derivation.
    pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped ({
      plugins = normalizedPlugins;
      wrapperArgs = finalWrapperArgs;
      wrapRc = true;
      luaRcContent = initLua;
      waylandSupport = false;
    } // (if viAlias then { viAlias = true; } else {}) // (if vimAlias then { vimAlias = true; } else {}))
