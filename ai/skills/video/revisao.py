import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ETAPAS = ("roteiro", "storyboard", "animatic", "rascunho")
USO = "uso: python3 revisao.py <pasta-do-video> <roteiro|storyboard|animatic|rascunho>"


class Falha(Exception):
    pass


def celulas(linha):
    return [c.strip() for c in re.split(r"(?<!\\)\|", linha.strip().strip("|"))]


def planos(video):
    cenas = []
    cabecalho = None
    for linha in (Path(video) / "roteiro.md").read_text().splitlines():
        if linha.startswith("## "):
            cenas.append((linha[3:].split()[0], []))
            cabecalho = None
        elif cenas and linha.lstrip().startswith("|"):
            valores = celulas(linha)
            if cabecalho is None:
                cabecalho = valores
            elif not all(re.fullmatch(r":?-+:?", v) for v in valores):
                cenas[-1][1].append(dict(zip(cabecalho, valores)))
    return [(cena, linhas) for cena, linhas in cenas if linhas]


def duracoes(video):
    return json.loads((Path(video) / "audio" / "duracoes.json").read_text())


def secao(texto, nome):
    linhas = texto.splitlines()
    inicio = linhas.index(f"## {nome}")
    fim = next((i for i in range(inicio + 1, len(linhas)) if linhas[i].startswith("## ")), len(linhas))
    return linhas[inicio:fim]


def briefing(video):
    caminho = Path(video) / "briefing.md"
    if not caminho.is_file():
        raise Falha(f"falta {caminho}")
    texto = caminho.read_text()
    try:
        quiz = [l for l in secao(texto, "Quiz") if re.match(r"\d+\.\s", l)]
        publico = secao(texto, "Quem assiste")
    except ValueError as e:
        raise Falha(f"briefing.md sem a seção esperada: {e}")
    return "\n".join(quiz) + "\n", "\n".join(publico).strip() + "\n"


def tabela(cenas, colunas):
    partes = []
    for cena, linhas in cenas:
        partes.append(f"## {cena}\n")
        partes.append("| # | " + " | ".join(colunas) + " |")
        partes.append("|---" * (len(colunas) + 1) + "|")
        for l in linhas:
            partes.append("| " + " | ".join([l.get("#", ""), *(l.get(c, "") for c in colunas)]) + " |")
        partes.append("")
    return "\n".join(partes)


def exigir(caminhos):
    faltam = [str(c) for c in caminhos if not c.is_file()]
    if faltam:
        raise Falha("faltam:\n" + "\n".join(faltam))


def stills(video, cenas):
    return [Path(video) / "storyboard" / f"{cena}-{i}.png" for cena, linhas in cenas for i in range(1, len(linhas) + 1)]


def quadro(origem, destino, *posicao):
    destino.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *posicao, "-i", str(origem), "-frames:v", "1", "-update", "1", str(destino)], check=True)


def preparar(video, etapa):
    video = Path(video)
    if etapa not in ETAPAS:
        raise Falha(f"etapa desconhecida: {etapa}\n{USO}")
    exigir([video / "roteiro.md"])
    cenas = planos(video)
    if etapa != "storyboard":
        quiz, publico = briefing(video)
    if etapa in ("storyboard", "animatic"):
        exigir(stills(video, cenas))
    if etapa == "rascunho":
        exigir([video / "audio" / "duracoes.json"] + [video / "cenas" / "render" / f"{c}.mp4" for c, _ in cenas])
        tempos = duracoes(video)
        for cena, linhas in cenas:
            if len(tempos.get(f"{cena}#planos", [])) != len(linhas):
                raise Falha(f"{cena}: duracoes.json não tem um tempo por plano do roteiro")

    revisao = video / "revisao"
    k = 1
    while (revisao / f"{etapa}-{k}").exists():
        k += 1
    entrada = revisao / f"{etapa}-{k}" / "entrada"
    entrada.mkdir(parents=True)

    if etapa == "roteiro":
        (entrada / "roteiro.md").write_text(tabela(cenas, ["Tela", "Fala"]))
    if etapa == "storyboard":
        (entrada / "tela.md").write_text(tabela(cenas, ["Tela"]))
    if etapa in ("storyboard", "animatic"):
        (entrada / "quadros").mkdir()
        for s in stills(video, cenas):
            shutil.copy(s, entrada / "quadros" / s.name)
    if etapa in ("animatic", "rascunho"):
        (entrada / "fala.md").write_text(tabela(cenas, ["Fala"]))
    if etapa == "rascunho":
        for cena, _ in cenas:
            render = video / "cenas" / "render" / f"{cena}.mp4"
            fim = 0.0
            for i, t in enumerate(tempos[f"{cena}#planos"], 1):
                fim += t
                quadro(render, entrada / "quadros" / f"{cena}-{i}.png", "-ss", f"{max(0.0, fim - 0.1):.3f}")
            quadro(render, entrada / "inicio" / f"{cena}.png")
            quadro(render, entrada / "fim" / f"{cena}.png", "-sseof", "-0.2")
    if etapa != "storyboard":
        (entrada / "quiz.md").write_text(quiz)
        (entrada / "publico.md").write_text(publico)
    return entrada


def main(args):
    if len(args) != 2:
        print(USO, file=sys.stderr)
        return 1
    try:
        print(preparar(args[0], args[1]).resolve())
    except Falha as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
