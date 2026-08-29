{
  description = "AI Flow Devshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                claude-code
                openspec
                gh
                git
                ctx7
              ]
              # bubblewrap is Linux-only; Darwin neither ships it nor needs it.
              # Load-bearing on Linux: it backs the sandbox enabled in
              # .claude/settings.json. Drop it and that confinement goes away.
              ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ];
          };
        }
      );
    };
}
