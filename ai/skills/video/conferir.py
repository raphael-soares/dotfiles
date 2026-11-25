import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from revisao import Falha, concat, duracao, duracoes, exigir, planos

USO = "uso: python3 conferir.py <pasta-do-video> [cena...]"
COLUNAS = 3


def rotulado(render, t, rotulo, destino):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", f"{max(0, t):.3f}", "-i", str(render), "-frames:v", "1",
                    "-vf", "scale=636:358,pad=640:400:2:2:color=0x5B6475,"
                           f"drawtext=text='{rotulo}':x=12:y=366:fontsize=24:fontcolor=white",
                    str(destino)], check=True)


def fontes(video, cena, voz, falas):
    clipes = [video / "cenas" / "planos" / f"{cena}-{i}.mp4" for i in range(1, len(falas) + 1)]
    if clipes[0].exists():
        exigir(clipes)
        return True, list(zip(clipes, falas))
    render = video / "cenas" / "render" / f"{cena}.mp4"
    exigir([render])
    return False, [(render, sum(falas[:i])) for i in range(1, len(falas))] + [(render, voz)]


def conferir(video, so):
    video = Path(video)
    tempos = duracoes(video)
    cenas = [c for c, _ in planos(video) if not so or c in so]
    pasta = video / "revisao" / "folhas"
    pasta.mkdir(parents=True, exist_ok=True)
    relatorio = []
    for cena in cenas:
        voz = tempos[cena]
        falas = tempos.get(f"{cena}#planos", [voz])
        por_plano, alvos = fontes(video, cena, voz, falas)
        if por_plano:
            relatorio += [f"{cena}-{i} video {duracao(c):.2f} fala {f:.2f}  CURTO"
                          for i, (c, f) in enumerate(alvos, 1) if duracao(c) < f - 0.05]
            relatorio.append(f"{cena} {len(alvos)} planos, voz {voz:.2f}")
        else:
            mp4 = duracao(alvos[0][0])
            relatorio.append(f"{cena} video {mp4:.2f} voz {voz:.2f}" + ("  CURTO" if mp4 < voz - 0.05 else ""))
        with tempfile.TemporaryDirectory() as tmp:
            quadros, soma = [], 0.0
            for i, ((fonte, t), fala) in enumerate(zip(alvos, falas), 1):
                soma += fala
                q = Path(tmp) / f"{i:03}.png"
                rotulado(fonte, min(t, duracao(fonte)) - 0.1, f"{cena}-{i}  {soma:.1f} s", q)
                quadros.append(q)
            lista = Path(tmp) / "lista.txt"
            lista.write_text("".join(concat(q) + "\n" for q in quadros))
            linhas_folha = -(-len(quadros) // COLUNAS)
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(lista),
                            "-vf", f"tile={COLUNAS}x{linhas_folha}", "-frames:v", "1", str(pasta / f"{cena}.png")], check=True)
    return relatorio + [f"folhas em {pasta}"]


def main(args):
    if not args:
        print(USO, file=sys.stderr)
        return 1
    try:
        print("\n".join(conferir(args[0], args[1:])))
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
