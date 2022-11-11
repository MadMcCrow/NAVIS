{
  description = "Navis is a game made with the Godot Engine";
  inputs = {
    # godot engine, master branch
    godot-flake = { 
      url = "github:MadMcCrow/Godot-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = { self, nixpkgs, godot-flake, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs   = import nixpkgs { inherit system; };
    godot  = inputs.godot-flake.packages."${system}".godot;

    in rec {
      packages."${system}" =  {

      navis-game = pkgs.stdenv.mkDerivation rec {
          name = "navis-game";
          buildInputs = [godot];
          runtimeDependencies = with pkgs; [ vulkan-loader libpulseaudio ];
          src = self;
          buildPhase = ''
            ${godot}/bin/godot.bin -e 
          '';
        };

	      default = pkgs.linkFarmFromDrvs "navis" [godot];
      };

      devShells."${system}".default =
        pkgs.mkShell {
          packages = [ godot ];
        };

    };
}
