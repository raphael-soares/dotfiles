import http.server
import json
import os
import socket
import subprocess
import sys
import tempfile
import threading
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REVISAO = REPO / "ai" / "skills" / "video" / "revisao.py"
ANIMATIC = REPO / "ai" / "skills" / "video" / "animatic.py"
MARGEM = REPO / "ai" / "skills" / "video" / "margem.py"
NARRAR = REPO / "ai" / "skills" / "video" / "narrar.py"
RASCUNHO = REPO / "ai" / "skills" / "video" / "rascunho.py"

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
            png(v / "storyboard" / f"{nome}.png", "green" if nome == "01-a-2" else "red")
        for cena in ("01-a", "02-b"):
            png(v / "storyboard" / "inicio" / f"{cena}.png", "yellow")
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

    def test_storyboard_shows_continuity_and_fala(self):
        e = self.entrada("storyboard")

        self.assertEqual((e / "fim" / "01-a.png").read_bytes(), (self.v / "storyboard" / "01-a-2.png").read_bytes())
        self.assertEqual((e / "inicio" / "02-b.png").read_bytes(), (self.v / "storyboard" / "inicio" / "02-b.png").read_bytes())
        self.assertTrue((e / "folha.png").is_file())
        self.assertIn("Pronto, chegou.", (e / "fala.md").read_text())

    def test_missing_still_fails_and_creates_nothing(self):
        (self.v / "storyboard" / "01-a-2.png").unlink()

        r = rodar(self.v, "storyboard")

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a-2.png", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_missing_opening_fails(self):
        (self.v / "storyboard" / "inicio" / "02-b.png").unlink()

        r = rodar(self.v, "storyboard")

        self.assertEqual(r.returncode, 1)
        self.assertIn("02-b.png", r.stderr)
        self.assertFalse((self.v / "revisao").exists())

    def test_rejected_findings_reach_next_critic_round(self):
        self.entrada("storyboard")
        (self.v / "revisao" / "storyboard-1.md").write_text(
            "| Plano | Achado | Decisão |\n|---|---|---|\n"
            "| 01-a#1 | Falta a placa. | Rejeitado: a placa emolduraria todos os quadros. |\n"
            "| 02-b#1 | Texto pequeno. | Corrigido: fonte maior. |\n")

        e = self.entrada("storyboard")

        recusados = (e / "rejeitados.md").read_text()
        self.assertIn("a placa emolduraria todos os quadros", recusados)
        self.assertNotIn("Texto pequeno", recusados)

    def test_first_round_has_no_rejections(self):
        self.assertFalse((self.entrada("storyboard") / "rejeitados.md").exists())

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

    def test_render_a_frame_short_still_gives_last_frames(self):
        video(self.v / "cenas" / "render" / "01-a.mp4", 1.95)
        video(self.v / "cenas" / "render" / "02-b.mp4", 0.95)

        e = self.entrada("rascunho")

        for rel in ("quadros/01-a-2.png", "quadros/02-b-1.png"):
            self.assertTrue((e / rel).is_file(), rel)

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


class Margem(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.pasta = Path(self.tmp.name) / "storyboard"
        self.pasta.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def quadro(self, nome, x, y, w, h):
        caixa = f"drawbox=x={x}:y={y}:w={w}:h={h}:c=white:t=fill"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"color=c=0x0F1420:s=200x100,{caixa}",
                        "-frames:v", "1", str(self.pasta / nome)], check=True)

    def rodar(self):
        return subprocess.run([sys.executable, str(MARGEM), self.tmp.name], capture_output=True, text=True)

    def test_content_inside_safe_area_passes(self):
        self.quadro("01-a-1.png", 30, 15, 140, 70)

        r = self.rodar()

        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_content_near_edge_names_frame_and_side(self):
        self.quadro("01-a-1.png", 30, 15, 140, 70)
        self.quadro("01-a-2.png", 60, 30, 135, 40)

        r = self.rodar()

        self.assertEqual(r.returncode, 1)
        self.assertIn("01-a-2.png direita", r.stdout)
        self.assertNotIn("01-a-1.png", r.stdout)


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


class Rascunho(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.v = montar(self.tmp.name, stills=False)
        video(self.v / "cenas" / "render" / "01-a.mp4", 2.0, "red")
        video(self.v / "cenas" / "render" / "02-b.mp4", 1.0, "blue")
        wav(self.v / "audio" / "01-a.wav", 2.4)
        wav(self.v / "audio" / "02-b.wav", 1.2)

    def tearDown(self):
        self.tmp.cleanup()

    def rodar(self):
        return subprocess.run([sys.executable, str(RASCUNHO), str(self.v)], capture_output=True, text=True)

    def test_length_matches_narration(self):
        r = self.rodar()

        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertAlmostEqual(duracao(self.v / "rascunho.mp4"), 3.6, delta=0.15)

    def test_short_scene_holds_last_frame_until_its_narration_ends(self):
        self.rodar()

        cores = [cor_em(self.v / "rascunho.mp4", t) for t in (1.0, 2.2, 2.7)]

        self.assertEqual(cores, ["r", "r", "b"])

    def test_missing_render_fails(self):
        (self.v / "cenas" / "render" / "02-b.mp4").unlink()

        r = self.rodar()

        self.assertEqual(r.returncode, 1)
        self.assertIn("02-b.mp4", r.stderr)
        self.assertFalse((self.v / "rascunho.mp4").exists())


class Kokoro(http.server.BaseHTTPRequestHandler):
    pedidos = []
    som = b""

    def do_POST(self):
        Kokoro.pedidos.append(json.loads(self.rfile.read(int(self.headers["Content-Length"]))))
        self.send_response(200)
        self.send_header("Content-Type", "audio/wav")
        self.end_headers()
        self.wfile.write(Kokoro.som)

    def log_message(self, *args):
        pass


def som(segundos):
    with tempfile.TemporaryDirectory() as tmp:
        wav(Path(tmp) / "s.wav", segundos)
        return (Path(tmp) / "s.wav").read_bytes()


class Narrar(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = http.server.HTTPServer(("127.0.0.1", 0), Kokoro)
        threading.Thread(target=cls.servidor.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def setUp(self):
        Kokoro.pedidos, Kokoro.som = [], som(1.0)
        self.tmp = tempfile.TemporaryDirectory()
        self.v = montar(self.tmp.name, stills=False)
        (self.v / "roteiro.md").write_text(ROTEIRO.replace("| firme |", "| firme; pausa |"))
        (self.v / "video.md").write_text("# Vídeo\n\n- Idioma: pt-BR\n- Voz: pf_dora\n")

    def tearDown(self):
        self.tmp.cleanup()

    def rodar(self, *cenas, porta=None):
        url = f"http://127.0.0.1:{porta or self.servidor.server_port}"
        return subprocess.run([sys.executable, str(NARRAR), str(self.v), *cenas], capture_output=True, text=True, env={**os.environ, "KOKORO_URL": url})

    def test_measures_each_plano_and_pads_pauses(self):
        r = self.rodar()

        self.assertEqual(r.returncode, 0, r.stderr)
        t = json.loads((self.v / "audio" / "duracoes.json").read_text())
        self.assertAlmostEqual(t["01-a#planos"][0], 1.0, delta=0.05)
        self.assertAlmostEqual(t["01-a#planos"][1], 1.8, delta=0.05)
        self.assertAlmostEqual(t["01-a"], 2.8, delta=0.05)
        self.assertAlmostEqual(duracao(self.v / "audio" / "01-a.wav"), 2.8, delta=0.05)
        self.assertEqual([p["input"] for p in Kokoro.pedidos], ["O disco guarda os dados.", "E manda tudo para a memória.", "Pronto, chegou."])
        self.assertEqual({p["voice"] for p in Kokoro.pedidos}, {"pf_dora"})

    def test_named_scene_only_keeps_the_others(self):
        r = self.rodar("02-b")

        self.assertEqual(r.returncode, 0, r.stderr)
        t = json.loads((self.v / "audio" / "duracoes.json").read_text())
        self.assertEqual(t["01-a#planos"], PLANOS["01-a#planos"])
        self.assertAlmostEqual(t["02-b"], 1.0, delta=0.05)
        self.assertEqual(len(Kokoro.pedidos), 1)

    def test_flags_plano_far_over_target(self):
        curto = self.rodar("02-b")
        Kokoro.som = som(4.0)
        longo = self.rodar("02-b")

        self.assertNotIn("02-b#1", curto.stdout)
        self.assertIn("02-b#1", longo.stdout)

    def test_unknown_scene_fails_before_speaking(self):
        r = self.rodar("99-x")

        self.assertEqual(r.returncode, 1)
        self.assertIn("99-x", r.stderr)
        self.assertEqual(Kokoro.pedidos, [])

    def test_kokoro_down_says_how_to_start(self):
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            porta = s.getsockname()[1]

        r = self.rodar(porta=porta)

        self.assertEqual(r.returncode, 1)
        self.assertIn("systemctl --user start kokoro", r.stderr)


if __name__ == "__main__":
    unittest.main()
