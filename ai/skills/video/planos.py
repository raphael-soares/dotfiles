import json
import os
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from revisao import Falha, duracao, duracoes, planos

USO = "uso: python3 planos.py <pasta-do-video> [cena...]"
PARALELO = int(os.environ.get("MANIM_PARALELO", 3))


def identidade(video):
    achado = re.search(r"^- Identidade:.*\((.+)\)", (video / "video.md").read_text(), re.M)
    if not achado:
        raise Falha("video.md sem a linha '- Identidade: <nome> (<pasta>)'")
    return str(Path(achado.group(1)).expanduser())


def renderizar(video, cena, ambiente):
    midia = video / "cenas" / f".manim-{cena}"
    shutil.rmtree(midia / "videos" / cena, ignore_errors=True)
    r = subprocess.run(["manim", "-r", "1920,1080", "--fps", "30", "--save_sections", "--disable_caching",
                        "--media_dir", str(midia), str(video / "cenas" / "manim" / f"{cena}.py"), "C"],
                       env=ambiente, capture_output=True, text=True)
    avisos = [l for l in r.stderr.splitlines() if l.startswith(("fonte pequena", "estourou"))]
    if r.returncode != 0:
        raise Falha(f"{cena}: o manim falhou\n" + "\n".join(r.stderr.splitlines()[-15:]))
    secoes = sorted((midia / "videos" / cena / "1080p30" / "sections").glob(f"C_*_{cena}-*.mp4"))
    if not secoes:
        raise Falha(f"{cena}: nenhuma seção; o Cena da identidade precisa do modo por plano")
    destino = video / "cenas" / "planos"
    destino.mkdir(parents=True, exist_ok=True)
    for velho in destino.glob(f"{cena}-*.mp4"):
        velho.unlink()
    for s in secoes:
        shutil.copyfile(s, destino / (s.stem.split("_", 2)[2] + ".mp4"))
    return avisos


def gerar(video, so):
    video = Path(video).expanduser()
    tempos = duracoes(video)
    cenas = [c for c, _ in planos(video) if not so or c in so]
    ambiente = dict(os.environ, VIDEO_DIR=str(video), IDENTIDADE=identidade(video), PLANOS="1")
    with ThreadPoolExecutor(PARALELO) as pool:
        avisos = list(pool.map(lambda c: renderizar(video, c, ambiente), cenas))
    arq = video / "cenas" / "planos" / "indice.json"
    indice = json.loads(arq.read_text()) if arq.exists() else {}
    relatorio = [a for lista in avisos for a in lista]
    novos = 0
    for cena in cenas:
        falas = tempos.get(f"{cena}#planos", [tempos[cena]])
        falas = falas[:-1] + [tempos[cena] - sum(falas[:-1])]
        if not (video / "cenas" / "planos" / f"{cena}-2.mp4").exists():
            falas = [tempos[cena]]
        for n, fala in enumerate(falas, 1):
            clipe = video / "cenas" / "planos" / f"{cena}-{n}.mp4"
            if not clipe.exists():
                raise Falha(f"{cena}-{n}: sem clipe; a cena chama ate() para todos os planos?")
            mp4 = round(duracao(clipe), 3)
            indice[f"{cena}-{n}"] = {"video": mp4, "fala": round(fala, 3)}
            novos += 1
            if mp4 < fala - 0.05:
                relatorio.append(f"{cena}-{n} CURTO: video {mp4:.2f} fala {fala:.2f}")
    arq.write_text(json.dumps(indice, indent=1, ensure_ascii=False))
    return relatorio + [f"{novos} clipes em {arq.parent}"]


def linha(video):
    arq = video / "cenas" / "planos" / "indice.json"
    if not arq.exists():
        raise Falha(f"falta {arq}; rode planos.py")
    indice = json.loads(arq.read_text())
    tempos = duracoes(video)
    resultado, inicio = [], 0.0
    for cena, linhas in planos(video):
        falas = tempos.get(f"{cena}#planos", [])
        if len(falas) != len(linhas):
            raise Falha(f"{cena}: narração com outro número de planos; rode narrar.py")
        falas = falas[:-1] + [tempos[cena] - sum(falas[:-1])]
        if f"{cena}-2" not in indice:
            falas, linhas = [tempos[cena]], [{"Fala": " ".join(l["Fala"] for l in linhas)}]
        for n, (l, fala) in enumerate(zip(linhas, falas), 1):
            nome = f"{cena}-{n}"
            if nome not in indice:
                raise Falha(f"{nome}: sem clipe; rode planos.py")
            resultado.append({"plano": nome, "cena": cena, "n": n, "inicio": round(inicio, 3), "fala": round(fala, 3),
                              "video": indice[nome]["video"], "renderizado": indice[nome]["fala"], "texto": l["Fala"]})
            inicio += fala
    return resultado


def main(args):
    if not args:
        print(USO, file=sys.stderr)
        return 1
    try:
        print("\n".join(gerar(args[0], args[1:])))
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
