{ pkgs ? (import <nixpkgs> {}) }:

{
  python3Env = pkgs.stdenv.mkDerivation {
    name = "python3-env";
    buildInputs = with pkgs; [
      python3Packages.virtualenv
    ];
  };
}
