{
  description = "A global spherical Harmonics transforms library";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
  inputs.ecbuild = {
    url = "github:ecmwf/ecbuild";
    flake = false;
  };
  inputs.fiat.url = "github:knedlsepp/fiat";

  outputs = { self, nixpkgs, ecbuild, fiat }:
    let
      version = builtins.substring 0 8 self.lastModifiedDate;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in

    {
      # A Nixpkgs overlay.
      overlay = final: prev: {

        ectrans = with final; stdenv.mkDerivation rec {
          name = "ectrans-${version}";
          src = self;
          buildInputs = [ fiat.defaultPackage."${system}" openblasCompat fftw fftwSinglePrec openmpi ];
          nativeBuildInputs = [ cmake ecbuild gfortran perl ];
          doInstallCheck = true;
          installCheckPhase = ''
            ctest
          '';
        };
      };

      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) ectrans;
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.ectrans);
    };
}
