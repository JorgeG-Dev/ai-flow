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

          # Vendor-neutral tooling, shared by every agent shell.
          common = with pkgs; [
            openspec
            gh
            git
            ctx7
          ];

          # One shell per agent vendor. To add another, define it here on the
          # same `common ++ [ ... ]` pattern and expose it in the attrset below.
          claude = pkgs.mkShell {
            packages =
              with pkgs;
              common
              ++ [ claude-code ]
              # Claude Code's sandbox (enabled in .claude/settings.json) shells
              # out to bubblewrap on Linux — load-bearing, not optional. Darwin
              # neither ships it nor needs it.
              ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ];
          };
        in
        {
          inherit claude;
          default = claude;
        }
      );
    };
}
