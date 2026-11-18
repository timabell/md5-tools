{
  description = "md5-tools - lightweight Rust MD5/SHA tools (prebuilt binaries from GitHub releases)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.4.0";

      assets = {
        x86_64-linux = {
          name = "md5-tools-linux-x86_64.tar.gz";
          sha256 = "8f5b98ff806b86ecf4bea02f639af42419f05ca50c3edec27f43453f3f89cdf8";
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
