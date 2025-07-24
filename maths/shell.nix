{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  # buildInputs = with pkgs; [ llvmPackages_16.libclang ];
  packages = with pkgs; [
    zenity # Needed for opening file manager
    # gmp # Required for MPFR
    mpfr
    envsubst
  ];
}

