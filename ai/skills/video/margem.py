import subprocess
import sys
from collections import Counter
from pathlib import Path

USO = "uso: python3 margem.py <pasta-do-video | pasta de quadros | quadro.png>..."
MINIMO = 0.10
TOLERANCIA = 40
ALTURA_MIN, LARGURA_MIN, DESVIO_MAX = 0.45, 0.65, 0.12


class Falha(Exception):
    pass


def quadros(caminho):
    caminho = Path(caminho)
    if caminho.is_file():
        return [caminho]
    if (caminho / "storyboard").is_dir():
        caminho = caminho / "storyboard"
    if not caminho.is_dir():
        raise Falha(f"não existe: {caminho}")
    achados = sorted(caminho.glob("*.png"))
    if not achados:
        raise Falha(f"nenhum .png em {caminho}")
    return achados


def pixels(png):
    r = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                        "-of", "csv=p=0:s=x", str(png)], capture_output=True, text=True)
    if r.returncode != 0:
        raise Falha(f"{png.name}: {r.stderr.strip()}")
    w, h = map(int, r.stdout.strip().split("x"))
    dados = subprocess.run(["ffmpeg", "-v", "error", "-i", str(png), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                           capture_output=True, check=True).stdout
    return w, h, dados


def extensao(w, h, dados):
    linha = w * 3
    cantos = [dados[i:i + 3] for i in (0, linha - 3, (h - 1) * linha, h * linha - 3)]
    fundo = Counter(cantos).most_common(1)[0][0]

    def conteudo(i):
        return abs(dados[i] - fundo[0]) + abs(dados[i + 1] - fundo[1]) + abs(dados[i + 2] - fundo[2]) > TOLERANCIA

    vazia = fundo * w
    esq, dir_, topo, base = w, -1, None, None
    for y in range(h):
        ini = y * linha
        if dados[ini:ini + linha] == vazia:
            continue
        cols = [x for x in range(w) if conteudo(ini + x * 3)]
        if not cols:
            continue
        topo = y if topo is None else topo
        base = y
        esq, dir_ = min(esq, cols[0]), max(dir_, cols[-1])
    if topo is None:
        return None
    return {"esquerda": esq / w, "direita": (w - 1 - dir_) / w, "topo": topo / h, "base": (h - 1 - base) / h}


def main(args):
    if not args:
        print(USO, file=sys.stderr)
        return 1
    try:
        todos = [q for a in args for q in quadros(a)]
        ruins = 0
        for q in todos:
            lados = extensao(*pixels(q))
            if lados is None:
                continue
            problemas = [f"{lado} {v:.1%}" for lado, v in lados.items() if v < MINIMO]
            altura = 1 - lados["topo"] - lados["base"]
            largura = 1 - lados["esquerda"] - lados["direita"]
            desvio = (lados["topo"] - lados["base"]) / 2
            if altura < ALTURA_MIN and largura < LARGURA_MIN:
                problemas.append(f"pequeno {altura:.0%}x{largura:.0%} do quadro")
            if abs(desvio) > DESVIO_MAX:
                problemas.append(f"descentrado {'para baixo' if desvio > 0 else 'para cima'} {abs(desvio):.0%}")
            if problemas:
                ruins += 1
                print(q.name, " ".join(problemas))
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    if ruins:
        print(f"{ruins} de {len(todos)} quadros fora da regra (borda, tamanho ou centro)", file=sys.stderr)
        return 1
    print(f"margem ok: {len(todos)} quadros")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
