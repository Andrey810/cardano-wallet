############################################################################
# Packages for jormungandr and jcli.
#
# These use the functions from iohk-nix to build the version that we
# require for cardano-wallet.
#
# To change the version:
# 1. Adjust the "version" and/or "rev" variables below.
# 2. Then invert the first digit in *both* sha256 and
#    cargoSha256. That is, change 0 to 1 and 1 to 0. It's important
#    that you change them to something different than before,
#    otherwise you may get the previous version from your local cache.
# 3. Run "nix-build -A jormungandr.src" (or let CI do it for you).
#    It will say that the hash is wrong. Update sha256 to the value it got.
# 4. Run "nix-build -A jormungandr". After some time downloading
#    crates, it should say that the vendor hash is wrong.
#    Update cargoSha256 with the value it got.
# 5. Run "nix-build -A jormungandr". It should complete the build.
# 6. Test that "nix-build -A jormungandr-cli" also works.
# 7. If you now run "nix-shell" you should have updated versions of
#    jormungandr and jcli.
#
############################################################################

{ iohkLib ? import ./iohk-common.nix {}
, pkgs ? iohkLib.pkgs
}:

let
  release = rec {
    version = "0.5.0";
    # Git revision of input-output-hk/jormungandr repo.
    rev = "v${version}";
    # Hash of git repo and all of its submodules.
    sha256 = "19jqnja4mxyfgg79m4ak4815wjxvkg6qn04gk21c15xl3i8b4zf6";
    # Hash of all Cargo dependencies.
    cargoSha256 = "1kdrx4k6d3jx7d67vnmwp37vflzz9ngl2fnwsjl02vacs4g932cf";
  };

in {
  jormungandr = iohkLib.rust-packages.pkgs.makeJormungandr release;
  jormungandr-cli = iohkLib.rust-packages.pkgs.makeJcli release;
}