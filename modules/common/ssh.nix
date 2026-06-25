{rootAuthorizedKeys, ...}: {
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
