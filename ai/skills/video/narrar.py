import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from revisao import Falha, concat, exigir, planos

USO = "uso: python3 narrar.py <pasta-do-video> [cena | cena#n ...]"
FOLGA = 2.5
VELOCIDADE = 0.9
PASSOS = 16


def guardada(cache, url, voz_id, texto, refazer):
    chave = hashlib.sha256(json.dumps([voz_id, VELOCIDADE, PASSOS, texto]).encode()).hexdigest()[:16]
    som = cache / f"{chave}.wav"
    if refazer or not som.exists():
        parcial = som.with_suffix(".parcial")
        falar(url, voz_id, texto, parcial)
        parcial.rename(som)
    return som


def voz(video):
    m = re.search(r"^- Voz: *(\S+)", (video / "video.md").read_text(), re.M)
    if not m:
        raise Falha("video.md não tem a linha '- Voz: <voz>'")
    return m.group(1)


def falar(url, voz_id, texto, saida):
    pedido = urllib.request.Request(
        f"{url}/v1/audio/speech",
        json.dumps({"model": "omnivoice", "voice": voz_id, "input": texto, "response_format": "wav", "speed": VELOCIDADE, "num_inference_steps": PASSOS}).encode(),
        {"Content-Type": "application/json"},
    )
    try:
        saida.write_bytes(urllib.request.urlopen(pedido, timeout=300).read())
    except (urllib.error.URLError, ConnectionError) as e:
        raise Falha(f"a voz não respondeu em {url} ({e}); suba com docker compose -f ~/.config/audiocpp/compose.yaml up -d")


def dur(caminho):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(caminho)], capture_output=True, text=True, check=True)
    return round(float(r.stdout), 3)


def fora(pedido, tamanho):
    cena, marca, n = pedido.partition("#")
    return cena not in tamanho or bool(marca) and not (n.isdigit() and 1 <= int(n) <= tamanho[cena])


def narrar(video, pedidos):
    video = Path(video)
    exigir([video / "roteiro.md", video / "video.md"])
    cenas = planos(video)
    tamanho = {c: len(ls) for c, ls in cenas}
    so = {p.partition("#")[0] for p in pedidos}
    refazer = {p for p in pedidos if "#" in p}
    faltam = [p for p in pedidos if fora(p, tamanho)]
    if faltam:
        raise Falha("cena ou plano fora do roteiro: " + ", ".join(sorted(faltam)))
    voz_id, url = voz(video), os.environ.get("VOZ_URL", "http://127.0.0.1:8880")
    pasta = video / "audio" / "planos"
    pasta.mkdir(parents=True, exist_ok=True)
    cache = video / "audio" / "cache"
    cache.mkdir(exist_ok=True)
    arq = video / "audio" / "duracoes.json"
    tempos = json.loads(arq.read_text()) if arq.exists() else {}
    relatorio = []
    with tempfile.TemporaryDirectory() as tmp:
        for cena, linhas in cenas:
            if so and cena not in so:
                continue
            partes = []
            for i, linha in enumerate(linhas, 1):
                final = pasta / f"{cena}-{i}.wav"
                bruto = guardada(cache, url, voz_id, linha["Fala"], f"{cena}#{i}" in refazer)
                pausa = ["-af", "apad=pad_dur=0.8"] if "pausa" in linha.get("Tom", "") else []
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(bruto), *pausa, "-ar", "24000", "-ac", "1", str(final)], check=True)
                partes.append(final)
            for velho in pasta.glob(f"{cena}-*.wav"):
                n = velho.stem[len(cena) + 1:]
                if n.isdigit() and int(n) > len(linhas):
                    velho.unlink()
            lista = Path(tmp) / f"{cena}.txt"
            lista.write_text("".join(concat(p) + "\n" for p in partes))
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(lista), "-c", "copy", str(video / "audio" / f"{cena}.wav")], check=True)
            tempos[f"{cena}#planos"] = [dur(p) for p in partes]
            tempos[cena] = dur(video / "audio" / f"{cena}.wav")
            relatorio.append(f"{cena} {tempos[cena]:.1f} s")
            for i, (linha, t) in enumerate(zip(linhas, tempos[f"{cena}#planos"]), 1):
                alvo = re.match(r"[\d.,]+", linha.get("Tempo", ""))
                if alvo and t > float(alvo.group().replace(",", ".")) + FOLGA:
                    relatorio.append(f"  {cena}#{i}: fala {t:.1f} s, alvo {alvo.group()} s")
    arq.write_text(json.dumps(tempos, indent=1, ensure_ascii=False))
    total = sum(v for k, v in tempos.items() if "#" not in k)
    return relatorio + [f"total {total:.1f} s"]


def main(args):
    if not args:
        print(USO, file=sys.stderr)
        return 1
    try:
        print("\n".join(narrar(args[0], args[1:])))
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
