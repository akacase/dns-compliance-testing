{
  description = "dns-compliance-testing";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    dns-compliance-testing-src = {
      url = "git+https://gitlab.isc.org/isc-projects/DNS-Compliance-Testing.git?rev=42c384ee05b1c0be51a260f369f5f4ec74a24cd5";
      flake = false;
    };
    utils.url = "github:numtide/flake-utils";
  };


  outputs = { self, nixpkgs, dns-compliance-testing-src, utils }:
    let
      systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        }
      );
    in
    {
      overlay = final: prev: {
        dns-compliance-testing = with final; (stdenv.mkDerivation {
          name = "dns-compliance-testing";
          src = dns-compliance-testing-src;
          nativeBuildInputs = [ autoreconfHook pkg-config autoconf automake ];
          buildInputs = [ pkgconfig autoconf openssl.dev gcc gnumake automake libtool autogen ];

          configurePhase = ''
            autoreconf -fi
            ./configure
          '';

          buildPhase = ''
            OPENSSL_LIBS=$(pkg-config --libs openssl) ./configure
            make
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp genreport $out/bin
          '';

          meta = with lib; {
            description = "DNS protocol compliance of the servers they are delegating zones to.";
            homepage = https://gitlab.isc.org/isc-projects/DNS-Compliance-Testing;
            license = licenses.mpl20;
            platforms = platforms.linux;
            maintainers = with maintainers; [ case ];
          };
        });
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) dns-compliance-testing;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.dns-compliance-testing);

      devShell = forAllSystems (system:
        with nixpkgsFor.${system}; pkgs.mkShell {
          src = dns-compliance-testing-src;
          buildInputs = with pkgs; [
            pkg-config
            autoconf
            openssl
            gcc
            gnumake
            automake
            libtool
            autogen
            glibc
          ];
        });
    };
}
