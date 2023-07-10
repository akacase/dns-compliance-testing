{
  description = "dns-compliance-testing";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    dns-compliance-testing-src = {
      url = "git+https://gitlab.isc.org/isc-projects/DNS-Compliance-Testing.git?rev=42c384ee05b1c0be51a260f369f5f4ec74a24cd5";
      flake = false;
    };
    utils.url = "github:numtide/flake-utils";
  };


  outputs = { self, nixpkgs, dns-compliance-testing-src, utils }: utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
        genreport = with pkgs; stdenv.mkDerivation {
          name = "genreport";
          src = dns-compliance-testing-src;
          nativeBuildInputs = [ autogen autoreconfHook pkg-config autoconf automake gcc pkgconfig libtool ];
          buildInputs = [ openssl.dev ldns ];

          configurePhase = ''
            autoreconf -fi
            OPENSSL_LIBS=$(pkg-config --libs openssl ldns) ./configure
          '';

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp genreport $out/bin/genreport
          '';

          meta = with lib; {
            description = "DNS protocol compliance of the servers they are delegating zones to.";
            homepage = https://gitlab.isc.org/isc-projects/DNS-Compliance-Testing;
            license = licenses.mpl20;
            maintainers = with maintainers; [ case ];
          };
        };
      in
      rec
      {
        packages.${system} = genreport;
        defaultPackage = genreport;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkg-config
            autoconf
            openssl
            gcc
            gnumake
            automake
            libtool
            autogen
          ];
          shellHook = ''
            ln -s "${dns-compliance-testing-src}" ./src
          '';
        };
      }) // {
    overlay = final: prev: {
      genreport = with final; (stdenv.mkDerivation {
        name = "genreport";
        src = dns-compliance-testing-src;
        nativeBuildInputs = [ autogen autoreconfHook pkg-config autoconf automake gcc pkgconfig libtool ];
        buildInputs = [ openssl.dev ];

        configurePhase = ''
          autoreconf -fi
          OPENSSL_LIBS=$(pkg-config --libs openssl) ./configure
        '';

        buildPhase = ''
          make
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp genreport $out/bin/genreport
        '';

        meta = with lib; {
          description = "DNS protocol compliance of the servers they are delegating zones to.";
          homepage = https://gitlab.isc.org/isc-projects/DNS-Compliance-Testing;
          license = licenses.mpl20;
          maintainers = with maintainers; [ case ];
        };
      });
    };
  };
}
