import difflib
import os
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from revisao import Falha, exigir, planos

USO = "uso: python3 ouvir.py <pasta-do-video> [cena...]"
PARECIDO = 0.75
NUMEROS = {"pt": "zero um dois tres quatro cinco seis sete oito nove dez".split(),
           "en": "zero one two three four five six seven eight nine ten".split()}


def palavras(texto, idioma=None):
    sem_acento = unicodedata.normalize("NFKD", texto.lower()).encode("ascii", "ignore").decode()
    ditas = re.findall(r"[a-z0-9]+", sem_acento)
    if idioma:
        ditas = [NUMEROS[idioma][int(w)] if w.isdigit() and int(w) <= 10 else w for w in ditas]
    return ditas


def transcrever(url, idioma, wav):
    r = subprocess.run(["curl", "-sf", f"{url}/asr?language={idioma}&output=txt", "-F", f"audio_file=@{wav}"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise Falha(f"o Whisper não respondeu em {url}")
    return " ".join(l for l in r.stdout.splitlines() if "-->" not in l and not l.strip().isdigit())


def ouvir(video, so):
    video = Path(video)
    idioma = "en" if re.search(r"^- Idioma: *(en|ingl)", (video / "video.md").read_text(), re.M | re.I) else "pt"
    url = os.environ.get("WHISPER_URL", "http://127.0.0.1:9000")
    achados, total = [], 0
    for cena, linhas in planos(video):
        if so and cena not in so:
            continue
        for i, linha in enumerate(linhas, 1):
            wav = video / "audio" / "planos" / f"{cena}-{i}.wav"
            exigir([wav])
            total += 1
            esperado, ouvido = palavras(linha["Fala"]), palavras(transcrever(url, idioma, wav), idioma)
            semelhanca = difflib.SequenceMatcher(None, esperado, ouvido).ratio()
            final = esperado[-1] if esperado else ""
            fim_ok = any(difflib.SequenceMatcher(None, final, w).ratio() >= 0.7 for w in ouvido[-3:])
            if semelhanca < PARECIDO or not fim_ok:
                motivo = "fim cortado" if not fim_ok else f"{semelhanca:.0%} parecido"
                achados.append(f"{cena}#{i}: {motivo}\n  roteiro: {' '.join(esperado)}\n  ouvido:  {' '.join(ouvido)}")
    return achados, total


def main(args):
    if not args:
        print(USO, file=sys.stderr)
        return 1
    try:
        achados, total = ouvir(args[0], args[1:])
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    if achados:
        print("\n".join(achados))
        print(f"{len(achados)} de {total} planos para ouvir", file=sys.stderr)
        return 1
    print(f"voz ok: {total} planos")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
