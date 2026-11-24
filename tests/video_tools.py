import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REVISAO = REPO / "ai" / "skills" / "video" / "revisao.py"
ANIMATIC = REPO / "ai" / "skills" / "video" / "animatic.py"

ROTEIRO = """# Roteiro

Nota solta que não é tabela.

## 01-a (cerca de 2 s)

| # | Tela | Fala | Tom | Tempo | Fonte |
|---|---|---|---|---|---|
| 1 | Um disco gira no centro. | O disco guarda os dados. | calmo | 1 s | slide 3 |
| 2 | Uma seta a \\| b liga os dois. | E manda tudo para a memória. | firme | 1 s | slide 4 |

## 02-b (cerca de 1 s)

| # | Tela | Fala | Tom | Tempo | Fonte |
|---|---|---|---|---|---|
| 1 | A memória acende. | Pronto, chegou. | leve | 1 s | slide 5 |
"""

BRIEFING = """# Briefing

## Quem assiste
Estudante do segundo semestre.
Já sabe:
- o que é CPU
Não sabe:
- o que é disco

## A ideia que fica
O disco manda dados para a memória.

## Objetivos
1. Explicar para onde vão os dados.

## Quiz
1. Para onde vão os dados do disco?
   Resposta: para a memória, SEGREDO-UM
2. O que gira?
   resposta: o disco
   SEGREDO-DOIS continua o gabarito

## Ideias erradas
- O disco fala direto com a CPU.
"""

PLANOS = {"01-a": 2.0, "01-a#planos": [1.0, 1.0], "02-b": 1.0, "02-b#planos": [1.0]}


def png(path, cor="red", size="64x36"):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"color={cor}:s={size}", "-frames:v", "1", str(path)], check=True)


def wav(path, segundos):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"sine=frequency=440:sample_rate=24000:duration={segundos}", str(path)], check=True)


def duracao(path):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)], capture_output=True, text=True, check=True)
    return float(r.stdout)


def cor_em(path, segundos):
    r = subprocess.run(["ffmpeg", "-loglevel", "error", "-ss", str(segundos), "-i", str(path), "-frames:v", "1", "-vf", "scale=1:1", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True)
    return "rgb"[max(range(3), key=lambda i: r.stdout[i])]


def video(path, segundos, cor="blue"):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"color={cor}:s=64x36:r=30:d={segundos}", "-pix_fmt", "yuv420p", str(path)], check=True)


def montar(raiz, stills=True):
    v = Path(raiz) / "v"
    (v / "audio").mkdir(parents=True)
    (v / "roteiro.md").write_text(ROTEIRO)
    (v / "briefing.md").write_text(BRIEFING)
    (v / "direcao.md").write_text("direção secreta")
    (v / "video.md").write_text("estado secreto")
    (v / "audio" / "duracoes.json").write_text(json.dumps(PLANOS))
    if stills:
        for nome in ("01-a-1", "01-a-2", "02-b-1"):
            png(v / "storyboard" / f"{nome}.png")
    return v


def rodar(v, etapa):
    tmp = Path(v).parent / "tmp"
    tmp.mkdir(exist_ok=True)
    return subprocess.run([sys.executable, str(REVISAO), str(v), etapa], capture_output=True, text=True, env={**os.environ, "TMPDIR": str(tmp)})


def textos(pasta):
    return "\n".join(p.read_text() for p in pasta.rglob("*.md"))


class Revisao(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.v = montar(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def entrada(self, etapa):
        r = rodar(self.v, etapa)
        self.assertEqual(r.returncode, 0, r.stderr)
        return Path(r.stdout.strip())

    def test_roteiro_keeps_only_tela_and_fala(self):
        e = self.entrada("roteiro")

        texto = (e / "roteiro.md").read_text()

        for trecho in ("Um disco gira no centro.", "O disco guarda os dados.", "Pronto, chegou."):
            self.assertIn(trecho, texto)
        for trecho in ("calmo", "slide 3", "1 s"):
            self.assertNotIn(trecho, texto)

    def test_escaped_pipe_stays_in_cell(self):
        e = self.entrada("roteiro")

        linha = next(l for l in (e / "roteiro.md").read_text().splitlines() if "seta" in l)

        self.assertIn("Uma seta a \\| b liga os dois.", linha)
        self.assertIn("E manda tudo para a memória.", linha)

    def test_quiz_never_leaks_answers(self):
        e = self.entrada("roteiro")

        quiz = (e / "quiz.md").read_text()

        self.assertIn("Para onde vão os dados do disco?", quiz)
        self.assertIn("O que gira?", quiz)
        for segredo in ("SEGREDO-UM", "SEGREDO-DOIS", "o disco\n", "esposta"):
            self.assertNotIn(segredo, quiz)

    def test_publico_copied(self):
        e = self.entrada("roteiro")

        publico = (e / "publico.md").read_text()

        self.assertIn("o que é CPU", publico)
        self.assertNotIn("A ideia que fica", publico)

    def test_storyboard_has_stills_and_tela(self):
        e = self.entrada("storyboard")

        nomes = sorted(p.name for p in (e / "quadros").iterdir())

        self.assertEqual(nomes, ["01-a-1.png", "01-a-2.png", "02-b-1.png"])
        self.assertIn("A memória acende.", (e / "tela.md").read_text())
        self.assertNotIn("Pronto, chegou.", (e / "tela.md").read_text())

    def test_missing_still_fails_and_creates_nothing(self):
        (self.v / "storyboard" / "01-a-2.png").unlink()

        r = rodar(self.v, "storyboard")

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a-2.png", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_unknown_stage_fails(self):
        r = rodar(self.v, "montagem")

        self.assertEqual(r.returncode, 1)
        self.assertFalse((self.v / "revisao").exists())

    def test_second_round_new_folder(self):
        self.entrada("roteiro")
        registro = self.v / "revisao" / "roteiro-1" / "entrada" / "roteiro.md"
        antes = registro.read_text()

        self.entrada("roteiro")

        self.assertTrue((self.v / "revisao" / "roteiro-2" / "entrada" / "roteiro.md").is_file())
        self.assertEqual(registro.read_text(), antes)

    def test_printed_path_hides_video_folder(self):
        e = self.entrada("roteiro")

        self.assertNotIn(str(self.v), str(e))
        self.assertNotIn("revisao", str(e))
        self.assertFalse((e.parent / "briefing.md").exists())
        self.assertEqual((e / "quiz.md").read_text(), (self.v / "revisao" / "roteiro-1" / "entrada" / "quiz.md").read_text())

    def test_quiz_without_questions_fails(self):
        (self.v / "briefing.md").write_text(BRIEFING.replace("1. Para onde", "Para onde").replace("2. O que gira", "O que gira"))

        r = rodar(self.v, "roteiro")

        self.assertEqual(r.returncode, 1)
        self.assertIn("Quiz", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_missing_fala_column_fails(self):
        (self.v / "roteiro.md").write_text(ROTEIRO.replace("| Tela | Fala |", "| Tela | Voz |", 1))

        r = rodar(self.v, "roteiro")

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_unescaped_pipe_in_row_fails(self):
        (self.v / "roteiro.md").write_text(ROTEIRO.replace("O disco guarda os dados.", "O disco | guarda os dados."))

        r = rodar(self.v, "roteiro")

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a#1", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_short_render_fails_and_creates_nothing(self):
        video(self.v / "cenas" / "render" / "01-a.mp4", 1.2)
        video(self.v / "cenas" / "render" / "02-b.mp4", 1)

        r = rodar(self.v, "rascunho")

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_rascunho_contact_sheet(self):
        video(self.v / "cenas" / "render" / "01-a.mp4", 2)
        video(self.v / "cenas" / "render" / "02-b.mp4", 1)

        e = self.entrada("rascunho")

        self.assertTrue((e / "folha.png").is_file())
        self.assertFalse((e / "tela.md").exists())

    def test_rascunho_frames(self):
        video(self.v / "cenas" / "render" / "01-a.mp4", 2)
        video(self.v / "cenas" / "render" / "02-b.mp4", 1)

        e = self.entrada("rascunho")

        for rel in ("quadros/01-a-1.png", "quadros/01-a-2.png", "quadros/02-b-1.png", "inicio/02-b.png", "fim/01-a.png"):
            self.assertTrue((e / rel).is_file(), rel)

    def test_rascunho_missing_render_fails(self):
        video(self.v / "cenas" / "render" / "01-a.mp4", 2)

        r = rodar(self.v, "rascunho")

        self.assertEqual(r.returncode, 1)
        self.assertIn("02-b.mp4", r.stderr)

    def test_secret_files_absent(self):
        video(self.v / "cenas" / "render" / "01-a.mp4", 2)
        video(self.v / "cenas" / "render" / "02-b.mp4", 1)

        pastas = [self.entrada(etapa) for etapa in ("roteiro", "storyboard", "animatic", "rascunho")]

        for e in pastas:
            nomes = {p.name for p in e.rglob("*")}
            self.assertFalse(nomes & {"briefing.md", "direcao.md", "video.md"}, e)
            texto = textos(e)
            for segredo in ("esposta", "SEGREDO", "secret", "O disco fala direto"):
                self.assertNotIn(segredo, texto, e)


class Animatic(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.v = montar(self.tmp.name, stills=False)
        (self.v / "audio" / "duracoes.json").write_text(json.dumps({"01-a": 2.5, "01-a#planos": [1.0, 1.5], "02-b": 2.6, "02-b#planos": [2.0]}))
        for nome, cor in (("01-a-1", "red"), ("01-a-2", "green"), ("02-b-1", "blue")):
            png(self.v / "storyboard" / f"{nome}.png", cor)
        wav(self.v / "audio" / "01-a.wav", 2.5)
        wav(self.v / "audio" / "02-b.wav", 2.6)

    def tearDown(self):
        self.tmp.cleanup()

    def rodar(self):
        return subprocess.run([sys.executable, str(ANIMATIC), str(self.v)], capture_output=True, text=True)

    def test_animatic_in_folder_with_apostrophe(self):
        self.v = self.v.rename(Path(self.tmp.name) / "d'água")

        r = self.rodar()

        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertAlmostEqual(duracao(self.v / "animatic.mp4"), 5.1, delta=0.1)

    def test_animatic_length_matches_narration(self):
        r = self.rodar()

        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertAlmostEqual(duracao(self.v / "animatic.mp4"), 5.1, delta=0.1)

    def test_animatic_shows_right_still_at_time(self):
        self.rodar()

        cores = [cor_em(self.v / "animatic.mp4", t) for t in (0.5, 1.2, 2.4, 2.7, 4.9)]

        self.assertEqual(cores, ["r", "g", "g", "b", "b"])

    def test_animatic_missing_wav_fails(self):
        (self.v / "audio" / "02-b.wav").unlink()

        r = self.rodar()

        self.assertEqual(r.returncode, 1)
        self.assertIn("02-b.wav", r.stderr)
        self.assertFalse((self.v / "animatic.mp4").exists())

    def test_animatic_missing_still_fails(self):
        (self.v / "storyboard" / "01-a-2.png").unlink()

        r = self.rodar()

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a-2.png", r.stderr)
        self.assertFalse((self.v / "animatic.mp4").exists())


if __name__ == "__main__":
    unittest.main()
