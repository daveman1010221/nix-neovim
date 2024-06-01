<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/nix-community/kickstart-nix.nvim">
    <img src="./nvim-nix.svg" alt="kickstart-nix.nvim">
  </a>
  <p>
    <strong>
      A <a href="https://nixos.org/">Nix</a> flake template
      for <a href="https://neovim.io/">Neovim</a> 
    </strong>
  </p>
</div>
<!-- markdownlint-restore -->

## :grey_question: Why kickstart-nix.nvim

If Nix and Neovim have one thing in common, it's that many new users don't know where to get started. The first thing you'll likely notice is that the normal paradigm for managing add-ons to NeoVim involves using some add-on manager plug-in/framework to extend the editor's default capabilities. This poses a philosophical dilemma for an operating system such as NixOS, as package management is a system-level concern and changes to the software baseline are supposed to be repeatable and immutable, neither of which is possible with ad-hoc package management. The solution presented here is to create a custom NeoVim package that is inclusive of the various add-ons that the user wants with their editor and to deliver the editor with add-ons as a single, managed package.

`kickstart-nix.nvim` makes the migration of Neovim configurations to Nix straightforward.

> [!NOTE]
>
> This repository is meant to make configuration of Neovim on Nix easier.
> Remove the things you don't use and add what you miss.

## The Idea

- Manage plugins + external dependencies using Nix
  (managing plugins shouldn't be the responsibility of a plugin).
- Configuration entirely in Lua[^1] (Vimscript is also possible).
  This makes it easy to migrate from non-nix dotfiles.
- Use Neovim's built-in loading mechanisms. See:
    - [`:h initialization`](https://neovim.io/doc/user/starting.html#initialization)
    - [`:h runtimepath`](https://neovim.io/doc/user/options.html#'runtimepath')
    - [`:h packadd`](https://neovim.io/doc/user/repeat.html#%3Apackadd)
- Use Neovim's built-in LSP client, with Nix managing language servers.

[^1]: The absence of a Nix module DSL for Neovim configuration is deliberate.
      If you were to copy the `nvim` directory to `$XDG_CONFIG_HOME`,
      and install the plugins, it would work out of the box.

## :star2: Features

- Use either nixpkgs or flake inputs as plugin sources.
- Usable on any device with Neovim and Nix installed.
- Create multiple derivations with different sets of plugins,
  and simple regex filters to exclude config files.
- Uses Nix to generate a `.luarc.json` in the devShell's `shellHook`.
  This sets up lua-language-server to recognize all plugins
  and the Neovim API.

## :books: Usage

1. Click on [Use this template](https://github.com/nix-community/kickstart-nix.nvim/generate)
to start a repo based on this template. **Do _not_ fork it**.
1. Add/remove plugins to/from the [Neovim overlay](./nix/neovim-overlay.nix).
1. Add/remove plugin configs to/from the `nvim/plugin` directory.
1. Modify as you wish (you will probably want to add a color theme, ...).
   See: [Design](#design).
1. You can create more than one package using the `mkNeovim` function by
    - Passing different plugin lists.
    - Adding `ignoreConfigRegexes` (e.g. `= [ "^ftplugin/.*.lua" ]`).

> [!TIP]
>
> The nix and lua files contain comments explaining
> what everything does in detail.

## :zap: Installation

### :snowflake: NixOS (with flakes)

1. Add your flake to you NixOS flake inputs.
1. Add the overlay provided by this flake.

```nix
nixpkgs.overlays = [
    # replace <kickstart-nix-nvim> with the name you chose
    <kickstart-nix-nvim>.overlays.default
];
```

You can then add the overlay's output(s) to the `systemPackages`:

```nix
environment.systemPackages = with pkgs; [
    nvim-pkg # The default package added by the overlay
];
```

### :penguin: Non-NixOS

With Nix installed (flakes enabled), from the repo root:

```console
nix profile install .#nvim
```

## :robot: Design

Directory structure:

```sh
── flake.nix
── nvim # Neovim configs (lua), equivalent to ~/.config/nvim
── nix # Nix configs
```

### :open_file_folder: Neovim configs

- Set options in `init.lua`.
- Source autocommands, user commands, keymaps,
  and configure plugins in individual files within the `plugin` directory.
- Filetype-specific scripts (e.g. start LSP clients) in the `ftplugin` directory.
- Library modules in the `lua/user` directory.

Directory structure:

```sh
── nvim
  ├── ftplugin # Sourced when opening a file type
  │  └── <filetype>.lua
  ├── init.lua # Always sourced
  ├── lua # Shared library modules
  │  └── user
  │     └── <lib>.lua
  ├── plugin # Automatically sourced at startup
  │  ├── autocommands.lua
  │  ├── commands.lua
  │  ├── keymaps.lua
  │  ├── plugins.lua # Plugins that require a `setup` call
  │  └── <plugin-config>.lua # Plugin configurations
  └── after # Empty in this template
     ├── plugin # Sourced at the very end of startup (rarely needed)
     └── ftplugin # Sourced when opening a filetype, after sourcing ftplugin scripts
```

> [!IMPORTANT]
>
> - Configuration variables (e.g. `vim.g.<plugin_config>`) should go in `nvim/init.lua`
>   or a module that is `require`d in `init.lua`.
> - Configurations for plugins that require explicit initialization
>   (e.g. via a call to a `setup()` function) should go in `nvim/plugin/<plugin>.lua`
>   or `nvim/plugin/plugins.lua`.
> - See [Initialization order](#initialization-order) for details.

### :open_file_folder: Nix

You can declare Neovim derivations in `nix/neovim-overlay.nix`.

There are two ways to add plugins:

- The traditional way, using `nixpkgs` as the source.
- By adding plugins as flake inputs (if you like living on the bleeding-edge).
  Plugins added as flake inputs must be built in `nix/plugin-overlay.nix`.

Directory structure:

```sh
── flake.nix
── nix
  ├── mkNeovim.nix # Function for creating the Neovim derivation
  └── neovim-overlay.nix # Overlay that adds Neovim derivation
```

### :mag: Initialization order

This derivation creates an `init.lua` as follows:

1. Add `nvim/lua` to the `runtimepath`.
1. Add the content of `nvim/init.lua`.
1. Add `nvim/*` to the `runtimepath`.
1. Add `nvim/after` to the `runtimepath`.

This means that modules in `nvim/lua` can be `require`d in `init.lua` and `nvim/*/*.lua`.

Modules in `nvim/plugin/` are sourced automatically, as if they were plugins.
Because they are added to the runtime path at the end of the resulting `init.lua`,
Neovim sources them _after_ loading plugins.

## :electric_plug: Pre-configured plugins

This configuration comes with [a few plugins pre-configured](./nix/neovim-overlay.nix).

You can add or remove plugins by

- Adding/Removing them in the [Nix list](./nix/neovim-overlay.nix).
- Adding/Removing the config in `nvim/plugin/<plugin>.lua`.

## :anchor: Syncing updates

If you have used this template and would like to fetch updates
that were added later...

Add this template as a remote:

```console
git remote add upstream git@github.com:nix-community/kickstart-nix.nvim.git
```

Fetch and merge changes:

```console
git fetch upstream
git merge upstream/main --allow-unrelated-histories
```

## :pencil: Editing your config

When your neovim setup is a nix derivation, editing your config
demands a different workflow than you are used to without nix.
Here is how I usually do it:

- Perform modifications and stage any new files[^2].
- Run `nix run /path/to/neovim/#nvim`
  or `nix run /path/to/neovim/#nvim -- <nvim-args>`

[^2]: When adding new files, nix flakes won't pick them up unless they
      have been committed or staged.

This requires a rebuild of the `nvim` derivation, but has the advantage
that if anything breaks, it's only broken during your test run.

If you want an impure, but faster feedback loop,
you can use `$XDG_CONFIG_HOME/$NVIM_APPNAME`[^3], where `$NVIM_APPNAME` 
defaults to `nvim` if the `appName` attribute is not set 
in the `mkNeovim` function.

[^3]: Assuming Linux. Refer to `:h initialization` for Darwin.

This has one caveat: The wrapper which nix generates for the derivation
calls `nvim` with `-u /nix/store/path/to/generated-init.lua`.
So it won't source a local `init.lua` file.
To work around this, you can put scripts in the `plugin` or `after/plugin` directory.

<!-- MARKDOWN LINKS & IMAGES -->
[neovim-shield]: https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white
[neovim-url]: https://neovim.io/
[nix-shield]: https://img.shields.io/badge/nix-0175C2?style=for-the-badge&logo=NixOS&logoColor=white
[nix-url]: https://nixos.org/
[lua-shield]: https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[license-shield]: https://img.shields.io/github/license/nix-community/kickstart-nix.nvim.svg?style=for-the-badge
[license-url]: https://github.com/nix-community/kickstart-nix.nvim/blob/master/LICENSE
[issues-shield]: https://img.shields.io/github/issues/nix-community/kickstart-nix.nvim.svg?style=for-the-badge
[issues-url]: https://github.com/nix-community/kickstart-nix.nvim/issues
[license-shield]: https://img.shields.io/github/license/nix-community/kickstart-nix.nvim.svg?style=for-the-badge
[license-url]: https://github.com/nix-community/kickstart-nix.nvim/blob/master/LICENSE
