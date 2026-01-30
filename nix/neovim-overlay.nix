# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{inputs}: final: prev:
with final.pkgs.lib; let
  pkgs = final;

  # Use this to create a plugin from a flake input
  mkNvimPlugin = src: pname:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = src.lastModifiedDate;
    };

  # Work around nixpkgs treesitter packaging/runtimepath regressions by pinning
  # upstream nvim-treesitter as a standard vim plugin derivation.
  #
  # NOTE: Replace the hash with the one Nix prints on the first build attempt.
  nvim-treesitter-upstream = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-treesitter";
    version = "0.9.2";
    src = pkgs.fetchFromGitHub {
      owner = "nvim-treesitter";
      repo = "nvim-treesitter";
      rev = "v0.9.2";
      hash = "sha256-zAyiitJIgOCZTB0CmgNt0MHENM70SOHLIoWrVwOJKFg=";
    };
  };

  # This is the helper function that builds the Neovim derivation.
  mkNeovim = pkgs.callPackage ./mkNeovim.nix {};

  # A plugin can either be a package or an attrset, such as
  # { plugin = <plugin>; # the package, e.g. pkgs.vimPlugins.nvim-cmp
  #   config = <config>; # String; a config that will be loaded with the plugin
  #   # Boolean; Whether to automatically load the plugin as a 'start' plugin,
  #   # or as an 'opt' plugin, that can be loaded with `:packadd!`
  #   optional = <true|false>; # Default: false
  #   ...
  # }
  all-plugins = with pkgs.vimPlugins; [
    cmp-nvim-lsp
    ctrlp-vim
    dhall-vim
    vim-fugitive
    gruvbox-nvim
    intero-neovim
    markdown-preview-nvim
    neoconf-nvim
    lazydev-nvim
    nvim-cmp
    nvim-lspconfig
    nvim-navic
    nvim-tree-lua
  
    # Treesitter core
    nvim-treesitter-upstream
    nvim-treesitter-context
    nvim-treesitter-textobjects
    nvim-ts-context-commentstring
  
    # Treesitter parsers (explicit, stable)
    nvim-treesitter-parsers.bash
    nvim-treesitter-parsers.c
    nvim-treesitter-parsers.cpp
    nvim-treesitter-parsers.dhall
    nvim-treesitter-parsers.fish
    nvim-treesitter-parsers.json
    nvim-treesitter-parsers.json5
    nvim-treesitter-parsers.lua
    nvim-treesitter-parsers.markdown
    nvim-treesitter-parsers.markdown_inline
    nvim-treesitter-parsers.nix
    nvim-treesitter-parsers.python
    nvim-treesitter-parsers.regex
    nvim-treesitter-parsers.rust
    nvim-treesitter-parsers.toml
    nvim-treesitter-parsers.yaml
  
    nvim-web-devicons
    rustaceanvim
    vim-tmux
    which-key-nvim
  ];

  extraPackages = with pkgs; [
    # language servers, etc.
    lua-language-server
    tree-sitter
    nil # nix LSP

    # LSP servers for neoconf and python
    nodePackages.vscode-langservers-extracted  # provides jsonls (and more)

    # pyright packaging varies across nixpkgs revisions.
    (if pkgs ? nodePackages && pkgs.nodePackages ? pyright
     then pkgs.nodePackages.pyright
     else pkgs.pyright)
  ];
in {
  # This is the neovim derivation
  # returned by the overlay
  nvim-pkg = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
  };

  # This can be symlinked in the devShell's shellHook
  nvim-luarc-json = final.mk-luarc-json {
    plugins = all-plugins;
  };

  # You can add as many derivations as you like.
  # Use `ignoreConfigRegexes` to filter out config
  # files you would not like to include.
  #
  # For example:
  #
  # nvim-pkg-no-telescope = mkNeovim {
  #   plugins = [];
  #   ignoreConfigRegexes = [
  #     "^plugin/telescope.lua"
  #     "^ftplugin/.*.lua"
  #   ];
  #   inherit extraPackages;
  # };
}
