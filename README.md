## Install


```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles && \
cd ~/.dotfiles && \
./bootstrap.sh
```

## Modulos opcionais

Fora do `bootstrap.sh` porque sao especificos de hardware/desktop, nao
agnosticos. Rode so onde fizer sentido.

- `./bootstrap_audio.sh`: forca todo dispositivo Bluetooth a so usar A2DP
  (estereo, alta fidelidade), removendo o handsfree HSP/HFP do WirePlumber.
  Resolve caixa/soundbar BT que conecta como "headset" mono 16 kHz.
