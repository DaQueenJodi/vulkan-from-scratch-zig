{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    (pkgs.stdenv.mkDerivation rec {
      name = "zig";
      src = pkgs.fetchurl {
        url = "https://ziglang.org/builds/zig-linux-x86_64-0.11.0-dev.3909+9e0ac4449.tar.xz";
        sha256 = "MY7785+Xjl3O8oDrCuvITOsjVYEnOJl9kcWZKKCa0rk=";
      };
      installPhase = ''
      mkdir -p $out/bin
      mv * $out/bin
      '';
    })
    vulkan-extension-layer
    vulkan-tools
    vulkan-tools-lunarg
    glfw3
    pkgconfig
    vulkan-headers
    vulkan-loader
    shaderc
    spirv-tools
    cglm
  ];
  VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
}
