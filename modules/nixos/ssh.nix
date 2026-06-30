{rootAuthorizedKeys, ...}: {
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      # Root may log in by SSH key only (rootAuthorizedKeys), never by password.
      PermitRootLogin = "prohibit-password";
      # No user, root or otherwise, may authenticate with a password.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    openFirewall = true;
  };

  users.users.root.openssh.authorizedKeys.keys = rootAuthorizedKeys;
}
