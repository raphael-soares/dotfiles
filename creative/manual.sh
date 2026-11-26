# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
# audiocpp runs in Docker, which the media module installs and enables.
have docker || note "audiocpp needs Docker: run missing.sh media"
[[ -x $HOME/.local/bin/manim ]] || step "uv tool install manim"
omni=$HOME/.cache/audiocpp/models/OmniVoice-GGUF/omnivoice-f16.gguf
[[ -f $omni ]] || step "curl -fL --create-dirs -o ${omni/#"$HOME"/\~} https://huggingface.co/audio-cpp/audio.cpp-gguf/resolve/main/OmniVoice-GGUF/omnivoice-f16.gguf"
