{ ... }:
{
  users.groups.openclaw = { };

  users.users.openclaw = {
    isNormalUser = true;
    group = "openclaw";
    home = "/home/openclaw";
    linger = true;
    openssh.authorizedKeys.keys = [ ];
  };
}
