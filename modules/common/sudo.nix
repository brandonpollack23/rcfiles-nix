# Sudo policy shared by every host regardless of platform.
{...}: {
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=10
  '';

  # pay-respects: corrects the previous command (thefuck successor). Hooks into
  # interactiveShellInit for bash/zsh/fish so every user gets `f` automatically.
  programs.pay-respects.enable = true;
}
