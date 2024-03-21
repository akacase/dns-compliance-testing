{
  description = "dns-compliance-testing";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
    dns-compliance-testing-src = {
      url = "git+https://gitlab.isc.org/isc-projects/DNS-Compliance-Testing.git?rev=4aea40ba0310de10560ba6deaa2d2e6eebbe8f48";
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
          nativeBuildInputs = [ autogen autoreconfHook pkg-config autoconf automake gcc pkg-config libtool ];
          buildInputs = [ openssl.dev ];
          configurePhase = ''
            autoreconf -fvi 
            LDFLAGS="-lresolv" OPENSSL_LIBS=$(pkg-config --libs openssl) ./configure
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
            nixpkgs-fmt
            pkg-config
            autoconf
            openssl
            ldns
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
          autoreconf -fvi 
          LDFLAGS="-lresolv" OPENSSL_LIBS=$(pkg-config --libs openssl) ./configure
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
