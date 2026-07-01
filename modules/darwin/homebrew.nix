# nix-homebrew wires Nix management over the existing /opt/homebrew prefix.
# mutableTaps = true lets Homebrew manage homebrew/core and homebrew/cask without
# pinning them as flake inputs, keeping flake.lock lean.
{enableSteam, ...}: {
  nix-homebrew = {
    enable = true;
    enableRosetta = false; # M4 is native arm64; no Rosetta brew needed
    user = "brpol";
    mutableTaps = true;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # zap removes unlisted formulae and casks on activation.
      cleanup = "zap";
    };
    casks =
      [
        "bitwarden"
        "discord"
        "ghostty"
        "google-drive"
        "middleclick"
        "obsidian"
        "signal"
        "ngrok"
        "thaw" # menu bar manager (Ice fork)
        "visual-studio-code"
        "whatsapp"
      ]
      ++ (
        if enableSteam
        then ["steam"]
        else []
      );
    # Formulae kept in Homebrew because no nix-darwin equivalent is clean or
    # because they are managed by mise for runtime version switching.
    brews = [
      "nvm" # node version manager — mise alternative pending
      "pnpm"
      "deno"
      "postgresql@17"
      "podman"
      "ollama"
      "mlx" # apple ml framework (no nixpkgs package)
      "mlx-c" # c bindings for mlx
    ];
  };
}
