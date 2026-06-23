# Desktop environment — imported by hosts that want a GUI.
# Headless/server hosts should omit this.
{pkgs, ...}: {
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.cinnamon.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

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

  environment.systemPackages = with pkgs; [google-chrome ghostty];
}
