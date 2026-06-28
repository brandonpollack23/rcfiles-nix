{...}: {
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # User identity secrets — must be added to secrets/secrets.yaml by running edit-nix-secrets.
  sops.secrets.cachix-brandonpollack23 = {};

  # There is a script to warn when age keys are missing in ../../users/brpol/home/secrets.nix
}
