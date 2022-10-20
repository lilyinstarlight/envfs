{ pkgs, config, lib, ... }:

let
  mounts = {
    "/usr/bin" = {
      device = "none";
      fsType = "envfs";
      options = [
        "fallback-path=${pkgs.runCommand "fallback-path" {} ''
          mkdir -p $out
          ln -s ${config.environment.usrbinenv} $out/env
          ln -s ${config.environment.binsh} $out/sh
        ''}"
      ];
    };
    "/bin" = {
      device = "/usr/bin";
      fsType = "none";
      options = [ "bind" ];
    };
  };
in {
  environment.systemPackages = [ (pkgs.callPackage ../. {}) ];
  fileSystems = if config.virtualisation ? qemu then lib.mkVMOverride mounts else mounts;

  system.activationScripts.envfsfallback = ''
    mkdir -p /run/bindroot
    mount --bind --make-unbindable / /run/bindroot
    mkdir -m 0755 -p /run/bindroot/usr/bin
    ln -sfn ${config.environment.usrbinenv} /run/bindroot/usr/bin/env
    mkdir -m 0755 -p /run/bindroot/bin
    ln -sfn ${config.environment.binsh} /run/bindroot/bin/sh
    umount /run/bindroot
    rmdir /run/bindroot
  '';

  system.activationScripts.usrbinenv = lib.mkForce "";
  system.activationScripts.binsh = lib.mkForce "";
}
