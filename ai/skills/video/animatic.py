import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from revisao import Falha, concat, duracoes, exigir, planos, stills

USO = "uso: python3 animatic.py <pasta-do-video>"


def montar(video):
    video = Path(video)
    exigir([video / "roteiro.md", video / "audio" / "duracoes.json"])
    cenas = planos(video)
    exigir(stills(video, cenas) + [video / "audio" / f"{c}.wav" for c, _ in cenas])
    tempos = duracoes(video)

    imagens, sons, total = ["ffconcat version 1.0"], ["ffconcat version 1.0"], 0.0
    for cena, linhas in cenas:
        if cena not in tempos:
            raise Falha(f"{cena}: duracoes.json não tem a cena")
        cortes = list(tempos.get(f"{cena}#planos", [tempos[cena]]))
        if len(cortes) != len(linhas):
            raise Falha(f"{cena}: duracoes.json não tem um tempo por plano do roteiro")
        cortes[-1] += max(0.0, tempos[cena] - sum(cortes))
        for i, t in enumerate(cortes, 1):
            imagens += [concat(video / "storyboard" / f"{cena}-{i}.png"), f"duration {t:.3f}"]
        sons.append(concat(video / "audio" / f"{cena}.wav"))
        total += sum(cortes)
    imagens.append(imagens[-2])

    saida = video / "animatic.mp4"
    with tempfile.TemporaryDirectory() as tmp:
        lista_v, lista_a = Path(tmp) / "v.txt", Path(tmp) / "a.txt"
        lista_v.write_text("\n".join(imagens) + "\n")
        lista_a.write_text("\n".join(sons) + "\n")
        parcial = Path(tmp) / "animatic.mp4"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y",
                        "-f", "concat", "-safe", "0", "-i", str(lista_v),
                        "-f", "concat", "-safe", "0", "-i", str(lista_a),
                        "-vf", "scale=854:480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2,fps=30,format=yuv420p",
                        "-c:v", "libx264", "-c:a", "aac", "-t", f"{total:.3f}", str(parcial)], check=True)
        shutil.move(parcial, saida)
    return saida, total


def main(args):
    if len(args) != 1:
        print(USO, file=sys.stderr)
        return 1
    try:
        saida, total = montar(args[0])
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    print(f"{saida.resolve()} ({total:.1f} s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
