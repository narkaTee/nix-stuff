{ lib, ... }:
let
  keyFile = ../../keys/narkatee.pub;
  keyLines = lib.filter (line: line != "") (
    lib.splitString "\n" (lib.strings.trim (builtins.readFile keyFile))
  );
in
{
  users.users.narkatee = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = keyLines;
    hashedPassword = "!";
  };

  security.sudo.extraRules = [
    {
      users = [ "narkatee" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
