import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ETAPAS = ("roteiro", "storyboard", "animatic", "rascunho", "corte")
USO = "uso: python3 revisao.py <pasta-do-video> <roteiro|storyboard|animatic|rascunho|corte>"


class Falha(Exception):
    pass


def celulas(linha):
    return [c.strip() for c in re.split(r"(?<!\\)\|", linha.strip().strip("|"))]


def concat(caminho):
    return "file '" + str(Path(caminho).resolve()).replace("'", "'\\''") + "'"


def planos(video):
    cenas = []
    cabecalho = None
    for linha in (Path(video) / "roteiro.md").read_text().splitlines():
        if linha.startswith("## "):
            cenas.append((linha[3:].split()[0], []))
            cabecalho = None
        elif cenas and linha.lstrip().startswith("|"):
            cena, valores = cenas[-1][0], celulas(linha)
            if cabecalho is None:
                if not {"#", "Tela", "Fala"} <= set(valores):
                    raise Falha(f"{cena}: a tabela do roteiro precisa das colunas #, Tela e Fala")
                cabecalho = valores
            elif not all(re.fullmatch(r":?-+:?", v) for v in valores):
                if len(valores) != len(cabecalho):
                    raise Falha(f"{cena}#{valores[0]}: a linha tem {len(valores)} células e o cabeçalho {len(cabecalho)}; escreva | dentro do texto como \\|")
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
        publico = secao(texto, "Quem assiste")
    except ValueError as e:
        raise Falha(f"briefing.md sem a seção esperada: {e}")
    if "## Quiz" not in texto.splitlines():
        return "", "\n".join(publico).strip() + "\n"
    quiz = [l for l in secao(texto, "Quiz") if re.match(r"\d+\.\s", l)]
    if not quiz:
        raise Falha("briefing.md sem perguntas numeradas (1. ...) na seção Quiz")
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


def aberturas(video, cenas):
    return [Path(video) / "storyboard" / "inicio" / f"{cena}.png" for cena, _ in cenas]


def recusados(revisao, etapa, k):
    linhas = []
    for j in range(1, k):
        relatorio = revisao / f"{etapa}-{j}.md"
        if not relatorio.is_file():
            continue
        for linha in relatorio.read_text().splitlines():
            if not linha.lstrip().startswith("|"):
                continue
            c = celulas(linha)
            if len(c) >= 3 and "rejeit" in c[-1].lower():
                linhas.append(f"| {j} | {c[0]} | {c[1]} | {c[-1]} |")
    if not linhas:
        return None
    return ("# Achados recusados em rodadas anteriores\n\n"
            "Cada linha já foi levantada e recusada com o motivo ao lado. Não repita sem um fato novo no material.\n\n"
            "| Rodada | Plano | Achado | Decisão |\n|---|---|---|---|\n" + "\n".join(linhas) + "\n")


def duracao(path):
    saida = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                           capture_output=True, text=True, check=True).stdout
    return float(saida)


def quadro(origem, destino, *posicao):
    destino.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *posicao, "-i", str(origem), "-frames:v", "1", "-update", "1", str(destino)], capture_output=True, text=True)
    if r.returncode != 0 or not destino.is_file():
        raise Falha(f"{origem.name}: sem quadro em {' '.join(posicao) or 'início'}\n{r.stderr}")


def folha(quadros, destino):
    with tempfile.TemporaryDirectory() as tmp:
        lista = Path(tmp) / "lista.txt"
        lista.write_text("".join(concat(q) + "\n" for q in quadros))
        linhas = -(-len(quadros) // 4)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(lista),
                        "-vf", f"scale=427:240:force_original_aspect_ratio=decrease,pad=427:240:(ow-iw)/2:(oh-ih)/2,tile=4x{linhas}",
                        "-frames:v", "1", str(destino)], check=True, capture_output=True)


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
    if etapa == "storyboard":
        exigir(aberturas(video, cenas))
    if etapa == "rascunho":
        exigir([video / "audio" / "duracoes.json"] + [video / "cenas" / "render" / f"{c}.mp4" for c, _ in cenas])
        tempos = duracoes(video)
        for cena, linhas in cenas:
            planos_cena = tempos.get(f"{cena}#planos", [])
            if len(planos_cena) != len(linhas):
                raise Falha(f"{cena}: duracoes.json não tem um tempo por plano do roteiro")
            render = video / "cenas" / "render" / f"{cena}.mp4"
            if duracao(render) < sum(planos_cena) - 0.1:
                raise Falha(f"{render.name}: render de {duracao(render):.2f} s, mais curto que a narração de {sum(planos_cena):.2f} s")
    if etapa == "corte":
        corte, marcas = video / "corte-1.mp4", video / "corte-1.json"
        exigir([corte, marcas])
        fins = json.loads(marcas.read_text())
        faltam = [f"{c}-{i}" for c, linhas in cenas for i in range(1, len(linhas) + 1) if f"{c}-{i}" not in fins]
        if faltam:
            raise Falha(f"corte-1.json sem o fim de: {', '.join(faltam)}")
        limite = duracao(corte)

    revisao = video / "revisao"
    k = 1
    while (revisao / f"{etapa}-{k}").exists():
        k += 1

    with tempfile.TemporaryDirectory() as tmp:
        entrada = Path(tmp) / "entrada"
        entrada.mkdir()
        if etapa == "roteiro":
            (entrada / "roteiro.md").write_text(tabela(cenas, ["Tela", "Fala"]))
        if etapa == "storyboard":
            (entrada / "tela.md").write_text(tabela(cenas, ["Tela"]))
            for cena, linhas in cenas:
                (entrada / "inicio").mkdir(exist_ok=True)
                (entrada / "fim").mkdir(exist_ok=True)
                shutil.copy(video / "storyboard" / "inicio" / f"{cena}.png", entrada / "inicio" / f"{cena}.png")
                shutil.copy(video / "storyboard" / f"{cena}-{len(linhas)}.png", entrada / "fim" / f"{cena}.png")
            folha(stills(video, cenas), entrada / "folha.png")
        if etapa in ("storyboard", "animatic"):
            (entrada / "quadros").mkdir()
            for s in stills(video, cenas):
                shutil.copy(s, entrada / "quadros" / s.name)
        if etapa != "roteiro":
            (entrada / "fala.md").write_text(tabela(cenas, ["Fala"]))
        if texto := recusados(revisao, etapa, k):
            (entrada / "rejeitados.md").write_text(texto)
        if etapa == "rascunho":
            ordem = []
            for cena, _ in cenas:
                render = video / "cenas" / "render" / f"{cena}.mp4"
                limite = duracao(render)
                fim = 0.0
                for i, t in enumerate(tempos[f"{cena}#planos"], 1):
                    fim += t
                    ordem.append(entrada / "quadros" / f"{cena}-{i}.png")
                    quadro(render, ordem[-1], "-ss", f"{max(0.0, min(fim, limite) - 0.1):.3f}")
                quadro(render, entrada / "inicio" / f"{cena}.png")
                quadro(render, entrada / "fim" / f"{cena}.png", "-sseof", "-0.2")
            folha(ordem, entrada / "folha.png")
        if etapa == "corte":
            ordem = []
            for cena, linhas in cenas:
                for i in range(1, len(linhas) + 1):
                    ordem.append(entrada / "quadros" / f"{cena}-{i}.png")
                    quadro(corte, ordem[-1], "-ss", f"{max(0.0, min(fins[f'{cena}-{i}'], limite) - 0.1):.3f}")
            folha(ordem, entrada / "folha.png")
        if etapa != "storyboard":
            if quiz:
                (entrada / "quiz.md").write_text(quiz)
            (entrada / "publico.md").write_text(publico)

        registro = revisao / f"{etapa}-{k}" / "entrada"
        shutil.copytree(entrada, registro)
        cego = Path(tempfile.mkdtemp(prefix="rodada-")) / "entrada"
        shutil.copytree(entrada, cego)
    return cego


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
