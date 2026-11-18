{
  description = "md5-tools - lightweight Rust MD5/SHA tools (prebuilt binaries from GitHub releases)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.3.0";

      assets = {
        x86_64-linux = {
          name = "md5-tools-linux-x86_64.tar.gz";
          sha256 = "b6b57dbcc99e0f33230f9cd7dc29265df341f73920bc3120305f2e8382f9bbdc";
        };
      };

      systems = builtins.attrNames assets;
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkPackage = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          asset = assets.${system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "md5-tools";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/timabell/md5-tools/releases/download/v${version}/${asset.name}";
            sha256 = asset.sha256;
          };

          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            tar -xzf $src -C $out/bin md5-create md5-diff md5-cpio
            chmod +x $out/bin/*
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Lightweight Rust MD5/SHA tools - create, diff and cpio hash files";
            homepage = "https://github.com/timabell/md5-tools";
            license = licenses.gpl3Plus;
            platforms = systems;
            mainProgram = "md5-create";
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkPackage system;
        md5-tools = mkPackage system;
      });

      apps = forAllSystems (system:
        let pkg = mkPackage system; in
        {
          default = { type = "app"; program = "${pkg}/bin/md5-create"; };
          md5-create = { type = "app"; program = "${pkg}/bin/md5-create"; };
          md5-diff = { type = "app"; program = "${pkg}/bin/md5-diff"; };
          md5-cpio = { type = "app"; program = "${pkg}/bin/md5-cpio"; };
        });
    };
}
