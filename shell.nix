let pkgs = import <nixpkgs> { };
in pkgs.mkShell.override { stdenv = pkgs.llvmPackages_16.stdenv; } {
  # buildInputs = with pkgs; [ llvmPackages_16.libclang ];
  packages = with pkgs; [
    zenity # Needed for opening file manager
    pkgsStatic.pkgsCross.armv7a-android-prebuilt.mpfr
    pkgsStatic.pkgsCross.aarch64-android-prebuilt.mpfr
    mpfr
    android-tools
    jdk
    # pkgs.pkgsCross.i686-embedded.mpfr
    envsubst
    tracy
    flutter
    cmake
  ];

  shellHook = ''
    export GMP_DIR=${pkgs.pkgsCross.armv7a-android-prebuilt.gmp.dev}
    export GMP_LIB_DIR=${pkgs.pkgsCross.armv7a-android-prebuilt.gmp}
    export GMP_LIB_DIR64=${pkgs.pkgsCross.aarch64-android-prebuilt.gmp}
    export MPFR_DIR=${pkgs.pkgsCross.armv7a-android-prebuilt.mpfr.dev}
    export TRACY_DIR=${pkgs.tracy}
    export MPFR_LIB_DIR=${pkgs.pkgsStatic.pkgsCross.armv7a-android-prebuilt.mpfr}
    export MPFR_LIB_DIR64=${pkgs.pkgsStatic.pkgsCross.aarch64-android-prebuilt.mpfr}
    export MPFR_LIB_DIRX86_64=${pkgs.mpfr}
    export LIBCLANG_DIR=${pkgs.llvmPackages_16.libclang.lib}
     export SPECIAL_INCLUDE_DIR=`clang++ --print-file-name=include`
     export NORMAL_INCLUDE_COMMAND_C=`cat ${pkgs.llvmPackages_16.clang}/nix-support/libc-cflags`
     export NORMAL_INCLUDE_COMMAND_CPP=`cat ${pkgs.llvmPackages_16.clang}/nix-support/libcxx-cxxflags`
  '';
  # shellHook = ''
  #   export LIBCLANG_DIR=${pkgs.llvmPackages_16.libclang.lib}
  #   export SPECIAL_INCLUDE_DIR=`clang++ --print-file-name=include`
  #   export GMP_DIR=${pkgs.gmp.dev}
  #   export MPFR_DIR=${pkgs.mpfr.dev}
  #   export TRACY_DIR=${pkgs.tracy}
  #   export MPFR_LIB_DIR=${pkgs.mpfr}
  # '';
}
