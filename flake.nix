{
  description = "Fuse filesystem that returns symlinks to executables based on the PATH of the requesting process.";

  inputs.utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs, utils }: {
    nixosModules.envfs = import ./modules/envfs.nix;
  } // utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages = {
        envfs = pkgs.callPackage ./default.nix {
          packageSrc = self;
        };
        envfsStatic = pkgs.pkgsStatic.callPackage ./default.nix {
          packageSrc = self;
        };
        default = self.packages.${system}.envfs;
      };
    }) // {
      checks.x86_64-linux = let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        envfsCrossAarch64 = pkgs.pkgsCross.aarch64-multiplatform.callPackage ./default.nix {
          packageSrc = self;
        };
        integration-tests = import ./nixos-test.nix {
          makeTest = import (nixpkgs + "/nixos/tests/make-test-python.nix");
          inherit pkgs;
          inherit (self.packages.${system}) cntr;
        };
      };
  };
}
