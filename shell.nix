let
  # Change to this if you want to use your configured channel
  #  nixpkgs = <nixpkgs>;

  # nixos-25.11 from 2025-11-30:
  nixpkgs = fetchTarball {
    name = "nixpkgs";
    url = "https://github.com/NixOS/nixpkgs/archive/d542db7.tar.gz";
    sha256 = "0x6wjmpzxrrlmwwq8v3znpyr1qs5m1vf9bdgwwlq0lr5fl8l4v67";
  };

  pkgs = import nixpkgs {};

  # 2025-11-30 version
  speedily-dictionary-src = fetchTarball {
    name = "speedily-dictionary";
    url = "https://github.com/pdg137/speedily-dictionary/archive/3ad714e.tar.gz";
    sha256 = "1za9vj91fixsa781qvh1wkfnjc4yasbraqxl7a0d1dxnwxvks6ni";
  };

  speedily-dictionary = import speedily-dictionary-src;

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

    DICTIONARY = "${speedily-dictionary}/dictionary.txt";

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      eval $shellHook

      {
        echo "#!$SHELL"
        for var in PATH SHELL nixpkgs DICTIONARY
        do echo "declare -x $var=\"''${!var}\""
        done
        echo "declare -x PS1='\n\033[1;32m[nix-shell:\w]\$\033[0m '"
        echo "exec \"$SHELL\" --norc --noprofile \"\$@\""
      } > "$out"

      chmod a+x "$out"
    '';
  }
