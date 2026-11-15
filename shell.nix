let
  mynix = import ./defs.nix;
  pkgs = mynix.pkgs;

  # 2025-11-30 version
  speedily-dictionary-src = fetchTarball {
    name = "speedily-dictionary";
    url = "https://github.com/pdg137/speedily-dictionary/archive/3ad714e.tar.gz";
    sha256 = "1za9vj91fixsa781qvh1wkfnjc4yasbraqxl7a0d1dxnwxvks6ni";
  };

  speedily-dictionary = import speedily-dictionary-src;

  gemset = import ./build_gemset.nix pkgs {
    # If you update Gemfile.lock, you will need to revise this hash.
    hash = "sha256-Cos6AiUDRyIwVntoI6rkHRkJ/dWipPbBvEVoQNM1yoA=";
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
  };

  our_ruby_env = pkgs.bundlerEnv {
    name = "our_ruby_env";
    ruby = pkgs.ruby;

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
      pkgs.ruby
      pkgs.chromedriver
      pkgs.chromium
      pkgs.fontconfig
      pkgs.sqlite
      pkgs.which
      pkgs.codex
    ];

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
  } // {
    # special environment for JUST the ruby dependency
    bundler = mynix.mkBuildableShell {
      name = "bundler";
      packages = [
        pkgs.ruby
      ];

      shellHook = ''
        echo "This shell is for running bundler to update Gemfile.lock."
        echo "Ruby version:" `ruby --version`
        echo "Bundler verison:" `bundler --version`
      '';
    };
  }
