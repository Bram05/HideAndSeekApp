{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell.override { stdenv = pkgs.llvmPackages_16.stdenv; } {
  # buildInputs = with pkgs; [ llvmPackages_16.libclang ];
  packages = with pkgs; [
    zenity # Needed for opening file manager
    # gmp # Required for MPFR
    mpfr
    envsubst
    tracy
  ];

  shellHook = ''
    export LIBCLANG_DIR=${pkgs.llvmPackages_16.libclang.lib}
    export NORMAL_INCLUDE_COMMAND_C=`cat ${pkgs.llvmPackages_16.clang}/nix-support/libc-cflags`
    export NORMAL_INCLUDE_COMMAND_CPP=`cat ${pkgs.llvmPackages_16.clang}/nix-support/libcxx-cxxflags`
    export SPECIAL_INCLUDE_DIR=`clang++ --print-file-name=include`
    export GMP_DIR=${pkgs.gmp.dev}
    export MPFR_DIR=${pkgs.mpfr.dev}
  '';
}
