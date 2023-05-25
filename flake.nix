{
  description = "Nix flake for whisper.cpp";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, ... }@inputs: {}
    // inputs.utils.lib.eachSystem ["x86_64-linux"](system:
      let
        pkgs = import nixpkgs { inherit system; };

        models = {
          tiny = builtins.fetchurl {
            url = "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin";
            sha256 = "sha256:07qbja4m5isssw42prv227gbyrf3nsjms6h8rlyrkpbgd3w4q7lj";
          };
          base = builtins.fetchurl {
            url = "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
            sha256 = "sha256:00nhqqvgwyl9zgyy7vk9i3n017q2wlncp5p7ymsk0cpkdp47jdx0";
          };
          small = builtins.fetchurl {
            url = "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin";
            sha256 = "sha256:0p8yqkwvpl9lyy43yajk305bps0v5z1qgyg0jwh35j7cb1nqs4y6";
          };
          medium = builtins.fetchurl {
            url = "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin";
            sha256 = "sha256:0mj3vbvaiyk5x2ids9zlp2g94a01l4qar9w109qcg3ikg0sfjdyc";
          };
          large = builtins.fetchurl {
            url = "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-large.en.bin";
            sha256 = "";
          };
        };

        whisper-cpp = pkgs.stdenv.mkDerivation {
          pname = "whisper-cpp";
          version = "v1.2.2";
          src = ./.;

          buildInputs = with pkgs; [ SDL2 pkg-config ];

          makeFlags = [ "main" "stream" ];

          installPhase = ''
            mkdir -p $out/bin
            cp ./main $out/bin/main
            cp ./stream $out/bin/stream
          '';
        };

        examples = pkgs.stdenv.mkDerivation {
          name = "whisper-cpp-example";
          buildInputs = [ whisper-cpp ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            echo '#!/usr/bin/env sh' >> $out/bin/whisper-cpp-example
            echo "${whisper-cpp}/bin/main -m ${models.base} \$@" >> $out/bin/whisper-cpp-example
            chmod +x $out/bin/whisper-cpp-example
          '';
        };

        stream = pkgs.stdenv.mkDerivation {
          name = "whisper-cpp-stream";
          buildInputs = [ whisper-cpp ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            echo '#!/usr/bin/env sh' >> $out/bin/whisper-cpp-stream
            echo "${whisper-cpp}/bin/stream -m ${models.base} \$@" >> $out/bin/whisper-cpp-stream
            chmod +x $out/bin/whisper-cpp-stream
          '';
        };

      in rec
      {
        packages.default = examples;
        packages.whisper-cpp-stream = stream;
      }
    );
}
