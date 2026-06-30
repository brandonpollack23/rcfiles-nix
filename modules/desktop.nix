# Desktop environment — imported by hosts that want a GUI.
# Headless/server hosts should omit this.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    gimp
    google-chrome
    libnotify
    discord
    obsidian
    signal-desktop
    vscode
    wl-clipboard # Wayland clipboard (wl-copy/wl-paste)
    xclip # X11 clipboard; kept for X apps / switching back to an X session
  ];

  # GNOME on Wayland via GDM. xserver stays enabled for XWayland and the xkb
  # layout; the display/desktop managers themselves live under the newer
  # services.displayManager / services.desktopManager namespaces.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GSConnect (KDE Connect) needs this port range open in both directions for
  # phone discovery and pairing.
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 1714;
      to = 1764;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 1714;
      to = 1764;
    }
  ];

  services.printing.enable = true;

  # PipeWire replaces PulseAudio; rtkit gives it real-time scheduling priority.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
