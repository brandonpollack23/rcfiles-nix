# GNOME Shell extensions and declarative dconf for brpol.
#
# Values here mirror the live GNOME setup. Only intentional configuration is
# captured; per-session runtime state (cached wallpapers, recently-used lists,
# window-geometry caches, last-connection IPs) is deliberately omitted.
#
# ── Exporting a live (Wayland) setting back into this file ───────────────────
# GNOME keeps all of this in dconf, so the round-trip is: change it in the GUI,
# read the new value out of dconf, paste it here under the matching path.
#
#   1. Tweak it in the running session (e.g. draw a new Tiling Shell layout in
#      its editor, or move a panel element).
#   2. See exactly what changed. Either watch live while you click:
#        dconf watch /
#      or dump one subtree afterwards:
#        dconf dump /org/gnome/shell/extensions/tilingshell/
#   3. Copy the key into the matching "org/gnome/.../path" block below,
#      translating the gvariant type to Nix:
#        true / false   -> true / false        (bool)
#        42             -> 42                   (int32)
#        0.75           -> 0.75                 (double)
#        uint32 40      -> gv.mkUint32 40
#        (true, 25)     -> gv.mkTuple [true 25]
#        ['<Super>w']   -> ["<Super>w"]
#        @as []         -> []                   (empty string array)
#        '{"json":...}' -> a ''-delimited Nix string; "-quotes need no escaping
#   4. Rebuild. home-manager applies these with `dconf load`, which is additive:
#      keys you don't list are left alone, so the GUI and this file coexist.
#
# Whole-subtree shortcut: `pkgs.dconf2nix` converts a `dconf dump` straight into
# this HM format, e.g.
#     dconf dump /org/gnome/shell/extensions/tilingshell/ | nix run nixpkgs#dconf2nix
# Tiling Shell layouts in particular are stored as one JSON blob in the
# `layouts-json` string under org/gnome/shell/extensions/tilingshell — dump that
# key and replace the value below.
{
  pkgs,
  lib,
  ...
}: let
  gv = lib.hm.gvariant;
in {
  home.packages = with pkgs.gnomeExtensions; [
    # Keyboard-driven window tiling with snap layouts and gaps.
    tiling-shell # tilingshell@ferrarodomenico.com
    # Restores the legacy app-indicator / system tray for status icons.
    appindicator # appindicatorsupport@rgcjonas.gmail.com
    # Turns the top bar into a configurable taskbar/dock (window list, panel position).
    dash-to-panel # dash-to-panel@jderose9.github.com
    # KDE Connect for GNOME: phone integration (notifications, clipboard, file share, SMS).
    gsconnect # gsconnect@andyholmes.github.io
    # Sets the daily Bing image of the day as the desktop wallpaper.
    bing-wallpaper-changer # BingWallpaper@ineffable-gmail.com
    # Application menu / start-menu replacement for the panel.
    arcmenu # arcmenu@arcmenu.com
    # Workspace indicator/switcher shown in the panel.
    space-bar # space-bar@luchrioh
    # Tweaks to hide/adjust shell UI elements (notifications, animations, etc.).
    just-perfection # just-perfection-desktop@just-perfection
    # Panel readout of system sensors: CPU, memory, network, temps, GPU.
    vitals # Vitals@CoreCoding.com
  ];

  # Nautilus and GTK file choosers share this list of custom bookmarks.
  xdg.configFile."gtk-4.0/bookmarks" = {
    text = ''
      file:///mnt/Memory_Alpha/Downloads
      file:///home/brpol/mnt/gdrive
    '';
    force = true;
  };

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "tilingshell@ferrarodomenico.com"
        "dash-to-panel@jderose9.github.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "gsconnect@andyholmes.github.io"
        "BingWallpaper@ineffable-gmail.com"
        "arcmenu@arcmenu.com"
        "space-bar@luchrioh"
        "just-perfection-desktop@just-perfection"
        "Vitals@CoreCoding.com"
      ];
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = false;
      overlay-key = "Super_L";
    };

    # Tiling Shell owns Super+Left/Right, so the mutter defaults are cleared.
    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [];
      toggle-tiled-right = [];
    };

    "org/gnome/desktop/interface" = {
      enable-hot-corners = false;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      speed = 0.48085106382978715;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = ["<Super>w"];
      # Cleared because Tiling Shell handles (un)maximize via Super+Up/Down.
      maximize = [];
      unmaximize = [];
      switch-applications = ["<Alt>Tab"];
      switch-applications-backward = ["<Shift><Alt>Tab"];
      switch-panels = [];
      switch-panels-backward = [];
      switch-to-workspace-left = ["<Control><Super>Left"];
      switch-to-workspace-right = ["<Control><Super>Right"];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      calculator = ["<Super>c"];
      home = ["<Super>e"];
      custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "ghostty";
      name = "Ghostty";
    };

    "org/gnome/shell/keybindings" = {
      toggle-overview = ["<Super>Tab"];
    };

    "org/gnome/shell/extensions/appindicator" = {
      icon-brightness = 0.0;
      icon-contrast = 0.0;
      icon-opacity = 240;
      icon-saturation = 0.0;
      icon-size = 0;
      legacy-tray-enabled = true;
    };

    "org/gnome/shell/extensions/arcmenu" = {
      hide-overview-on-arcmenu-open = true;
      hide-overview-on-startup = true;
      menu-button-icon-size = 20;
      multi-monitor = false;
      search-entry-border-radius = gv.mkTuple [true 25];
      show-activities-button = true;
    };

    "org/gnome/shell/extensions/bingwallpaper" = {
      download-folder = "~/Pictures/BingWallpaper/";
    };

    "org/gnome/shell/extensions/dash-to-panel" = {
      appicon-margin = 1;
      appicon-padding = 4;
      appicon-style = "NORMAL";
      dot-position = "BOTTOM";
      dot-style-focused = "METRO";
      dot-style-unfocused = "METRO";
      group-apps = false;
      group-apps-label-font-size = 13;
      group-apps-label-font-weight = "inherit";
      hotkeys-overlay-combo = "TEMPORARILY";
      isolate-monitors = true;
      isolate-workspaces = true;
      # Monitor-keyed panel layout; non-matching monitors fall back to defaults.
      panel-anchors = ''{"GSM-103NTJJKH252":"MIDDLE"}'';
      panel-element-positions = ''{"GSM-103NTJJKH252":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'';
      panel-lengths = "{}";
      panel-positions = "{}";
      panel-sizes = ''{"GSM-103NTJJKH252":28}'';
      show-apps-icon-file = "";
      stockgs-panelbtn-click-only = false;
      trans-panel-opacity = 0.75;
      trans-use-border = false;
      trans-use-custom-bg = false;
      trans-use-custom-opacity = true;
      window-preview-title-position = "TOP";
    };

    "org/gnome/shell/extensions/gsconnect" = {
      missing-openssl = false;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      notification-banner-position = 5;
    };

    "org/gnome/shell/extensions/space-bar/appearance" = {
      application-styles = ''
        .space-bar {
          -natural-hpadding: 12px;
        }

        .space-bar-workspace-label.active {
          margin: 0 4px;
          background-color: rgba(255,255,255,0.3);
          color: rgba(255,255,255,1);
          border-color: rgba(0,0,0,0);
          font-weight: 700;
          border-radius: 4px;
          border-width: 0px;
          padding: 3px 8px;
        }

        .space-bar-workspace-label.inactive {
          margin: 0 4px;
          background-color: rgba(0,0,0,0);
          color: rgba(255,255,255,1);
          border-color: rgba(0,0,0,0);
          font-weight: 700;
          border-radius: 4px;
          border-width: 0px;
          padding: 3px 8px;
        }

        .space-bar-workspace-label.inactive.empty {
          margin: 0 4px;
          background-color: rgba(0,0,0,0);
          color: rgba(255,255,255,0.5);
          border-color: rgba(0,0,0,0);
          font-weight: 700;
          border-radius: 4px;
          border-width: 0px;
          padding: 3px 8px;
        }'';
    };

    "org/gnome/shell/extensions/space-bar/behavior" = {
      always-show-numbers = true;
      indicator-style = "workspaces-bar";
      position = "right";
      smart-workspace-names = true;
    };

    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      open-menu = ["<Super>d"];
    };

    "org/gnome/shell/extensions/tilingshell" = {
      active-screen-edges = false;
      edge-tiling-mode = "default";
      enable-blur-selected-tilepreview = true;
      enable-blur-snap-assistant = true;
      enable-snap-assist = false;
      inner-gaps = gv.mkUint32 0;
      layouts-json = ''[{"id":"Layout 1","tiles":[{"x":0.24869791666666666,"y":0,"width":0.5023437500000001,"height":1,"groups":[3,2]},{"x":0.7510416666666667,"y":0.6677275620623806,"width":0.24895833333333328,"height":0.3322724379376194,"groups":[4,3]},{"x":0,"y":0,"width":0.24869791666666666,"height":0.33290897517504775,"groups":[2,5]},{"x":0,"y":0.33290897517504775,"width":0.24869791666666666,"height":0.33481858688733285,"groups":[5,2,6]},{"x":0,"y":0.6677275620623806,"width":0.24869791666666666,"height":0.3322724379376194,"groups":[6,2]},{"x":0.7510416666666667,"y":0.33290897517504775,"width":0.24895833333333328,"height":0.33481858688733285,"groups":[7,4,3]},{"x":0.7510416666666667,"y":0,"width":0.24895833333333328,"height":0.33290897517504775,"groups":[7,3]}]},{"id":"Layout 3","tiles":[{"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},{"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}]},{"id":"491621654","tiles":[{"x":0,"y":0,"width":0.41302083333333334,"height":1,"groups":[2]},{"x":0.41302083333333334,"y":0,"width":0.5869791666666659,"height":1,"groups":[2]}]}]'';
      outer-gaps = gv.mkUint32 0;
      overridden-settings = ''{"org.gnome.mutter.keybindings":{"toggle-tiled-right":"['<Super>Right']","toggle-tiled-left":"['<Super>Left']"},"org.gnome.desktop.wm.keybindings":{"maximize":"['<Super>Up']","unmaximize":"['<Super>Down', '<Alt>F5']"}}'';
      quarter-tiling-threshold = gv.mkUint32 40;
      selected-layouts = [
        ["Layout 1"]
        ["Layout 3"]
        ["491621654"]
        ["491621654"]
      ];
      snap-assistant-animation-time = gv.mkUint32 100;
      tile-preview-animation-time = gv.mkUint32 100;
      window-use-custom-border-color = false;
    };

    "org/gnome/shell/extensions/vitals" = {
      hot-sensors = [
        "_memory_usage_"
        "_system_load_1m_"
        "__network-rx_max__"
        "_memory_allocated_"
        "_processor_usage_"
      ];
      icon-style = 0;
      position-in-panel = 2;
      show-gpu = true;
    };
  };

  # Default browser: route web schemes and HTML to Google Chrome.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = ["google-chrome.desktop"];
      "x-scheme-handler/http" = ["google-chrome.desktop"];
      "x-scheme-handler/https" = ["google-chrome.desktop"];
      "x-scheme-handler/about" = ["google-chrome.desktop"];
      "x-scheme-handler/unknown" = ["google-chrome.desktop"];
    };
  };
}
