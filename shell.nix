let
  # Change to this if you want to use your configured channel
  #  nixpkgs = <nixpkgs>;

  # nixos-25.05 from 2025-05-29:
  nixpkgs = fetchTarball {
    name = "nixpkgs";
    url = "https://github.com/NixOS/nixpkgs/archive/7c815e5.tar.gz";
    sha256 = "0nysdk5i3arc88k5ibx3rgl0ihd7km52hr61l8qx280nf7sjf6zm";
  };

  pkgs = import nixpkgs {};

  gemset = import ./build_gemset.nix pkgs {
    # If you update Gemfile.lock, you will need to revise this hash.
    hash = "sha256-+aAFCXtwutb+AdRVNdR8nwjFHrqwTtAen492l3IWpA0=";
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
  };

  our_ruby_env = pkgs.bundlerEnv {
    name = "our_ruby_env";
    ruby = pkgs.ruby_3_3;

    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = gemset.outPath;
  };

in

  pkgs.stdenvNoCC.mkDerivation {
    name = "shell";
    dontUnpack = "true";
    buildInputs = [
      our_ruby_env
      pkgs.ruby_3_3
      pkgs.chromedriver
      pkgs.chromium
      pkgs.fontconfig
      pkgs.sqlite
      pkgs.which
      pkgs.codex
    ];

    # prevent nixpkgs from being garbage-collected
    inherit nixpkgs;

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      eval $shellHook

      {
        echo "#!$SHELL"
        for var in PATH SHELL nixpkgs
        do echo "declare -x $var=\"''${!var}\""
        done
        echo "declare -x PS1='\n\033[1;32m[nix-shell:\w]\$\033[0m '"
        echo "exec \"$SHELL\" --norc --noprofile \"\$@\""
      } > "$out"

      chmod a+x "$out"
    '';
  }
