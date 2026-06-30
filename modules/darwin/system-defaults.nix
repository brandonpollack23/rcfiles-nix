# Declarative baseline of Stargazer-II macOS settings captured 2026-06-30.
# Only keys nix-darwin exposes are encoded here; the rest remain governed by
# System Settings and are not managed by Nix.
{...}: {
  system.defaults = {
    dock = {
      autohide = true;
      tilesize = 33;
      minimize-to-application = false;
    };
    NSGlobalDomain = {
      # Natural scroll off — swipe direction matches physical movement.
      "com.apple.swipescrolldirection" = false;
      NSAutomaticCapitalizationEnabled = true;
    };
    trackpad = {
      Clicking = true;
      Dragging = false;
    };
  };
}
