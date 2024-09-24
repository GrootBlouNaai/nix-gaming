{
  inputs,
  self,
  pins,
  lib,
  build,
  pkgs,
  pkgsCross,
  pkgsi686Linux,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  moltenvk,
  supportFlags,
  stdenv_32bit,
}: let
  # Path filtering function
  # This function filters the nixpkgs repository to include only the Wine-related files.
  # It ensures that only the necessary parts of the repository are included in the build,
  # reducing the overall size and complexity of the build environment.
  nixpkgs-wine = builtins.path {
    path = inputs.nixpkgs;
    name = "source";
    filter = path: type: let
      wineDir = "${inputs.nixpkgs}/pkgs/applications/emulators/wine/";
    in (
      (type == "directory" && (lib.hasPrefix path wineDir))
      || (type != "directory" && (lib.hasPrefix wineDir path))
    );
  };

  # Default configuration for Wine builds
  # This section defines the default settings and dependencies for building Wine.
  # It includes support flags, build scripts, configuration flags, and other necessary components.
  defaults = let
    sources = (import "${inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
  in {
    inherit supportFlags moltenvk;
    patches = [];
    buildScript = "${nixpkgs-wine}/pkgs/applications/emulators/wine/builder-wow.sh";
    configureFlags = ["--disable-tests"];
    geckos = with sources; [gecko32 gecko64];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
    monos = with sources; [mono];
    pkgArches = [pkgs pkgsi686Linux];
    platforms = ["x86_64-linux"];
    stdenv = stdenv_32bit;
    wineRelease = "unstable";
  };

  # Function to generate package names
  # This function generates the package name based on the build type (e.g., "full" or default).
  # It appends "-full" to the package name if the build type is "full".
  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  # Wine-GE package definition
  # This section defines the Wine-GE package, which is a custom build of Wine optimized for gaming.
  # It uses the base configuration with additional overrides for specific attributes.
  wine-ge =
    (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
      // {
        pname = pnameGen "wine-ge";
        version = pins.proton-wine.branch;
        src = pins.proton-wine;
      }))
    .overrideAttrs (old: {
      meta = old.meta // {passthru.updateScript = ./update-wine-ge.sh;};
    });

  # Wine-TKG package definition
  # This section defines the Wine-TKG package, which is another custom build of Wine optimized for gaming.
  # It uses the base configuration with additional overrides for specific attributes.
  wine-tkg = callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (lib.recursiveUpdate defaults
    rec {
      pname = pnameGen "wine-tkg";
      version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile "${src}/VERSION"));
      src = pins.wine-tkg;
    });
