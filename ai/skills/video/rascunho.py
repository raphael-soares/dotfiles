import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from revisao import Falha, concat, duracao, exigir, planos

USO = "uso: python3 rascunho.py <pasta-do-video> [--final]"


def montar(video, final=False):
    video = Path(video)
    exigir([video / "roteiro.md"])
    cenas = [c for c, _ in planos(video)]
    renders = [video / "cenas" / "render" / f"{c}.mp4" for c in cenas]
    falas = [video / "audio" / f"{c}.wav" for c in cenas]
    exigir(renders + falas)

    saida, total = video / ("final.mp4" if final else "rascunho.mp4"), 0.0
    fps, crf, preset = ("30", "18", "medium") if final else ("15", "20", "veryfast")
    with tempfile.TemporaryDirectory() as tmp:
        lista = ["ffconcat version 1.0"]
        for cena, render, fala in zip(cenas, renders, falas):
            t = duracao(fala)
            parte = Path(tmp) / f"{cena}.mp4"
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(render), "-i", str(fala),
                            "-filter_complex", f"[0:v]tpad=stop_mode=clone:stop_duration=2,fps={fps},format=yuv420p[v]",
                            "-map", "[v]", "-map", "1:a", "-t", f"{t:.3f}",
                            "-c:v", "libx264", "-preset", preset, "-crf", crf, "-c:a", "aac", "-ar", "48000",
                            str(parte)], check=True)
            lista.append(concat(parte))
            total += t
        indice = Path(tmp) / "cenas.txt"
        indice.write_text("\n".join(lista) + "\n")
        parcial = Path(tmp) / "rascunho.mp4"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(indice),
                        "-c", "copy", str(parcial)], check=True)
        shutil.move(parcial, saida)
    return saida, total


def main(args):
    if not args or args[1:] not in ([], ["--final"]):
        print(USO, file=sys.stderr)
        return 1
    try:
        saida, total = montar(args[0], final=args[1:] == ["--final"])
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    print(f"{saida.resolve()} ({total:.1f} s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
