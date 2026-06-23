# Baseline configuration imported by every host via mkHost.
# Put things here if they should be true on every machine you own.
{
  pkgs,
  rootAuthorizedKeys,
  neovimPkg,
  nixosCliPkg,
  ...
}: {
  nix = {
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://watersucks.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "*-*-* 00:03:30";
      options = "--delete-older-than 7d";
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
    };
    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Base CLI tools available on every host. GUI apps belong in modules/desktop.nix.
  environment.systemPackages = with pkgs;
    [
      alejandra # nix code formatter
      bat # cat with wings
      bitwarden-cli
      curl
      fastfetch
      fzf
      gh # UI to a bad forge
      git
      htop
      jj # version control of the modern times, reminds me of fig
      jq
      ripgrep
      timew-sync-client
      timewarrior # time tracker
      tmux
      tree
      wget
      zsh
    ]
    ++ [
      neovimPkg.${pkgs.stdenv.hostPlatform.system}.default # nightly neovim
      nixosCliPkg.${pkgs.stdenv.hostPlatform.system}.default # nixos CLI tool
    ];

  environment.variables.EDITOR = "nvim";
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake ~/rcfiles-nix";
  };

  # zsh.enable makes zsh available as a login shell system-wide; individual
  # users opt in by setting shell = pkgs.zsh (or bashInteractive) in their nixos.nix.
  programs.zsh.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  users.users.root.openssh.authorizedKeys.keys = rootAuthorizedKeys;
}
