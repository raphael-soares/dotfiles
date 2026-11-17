import sys

sys.dont_write_bytecode = True

import importlib.machinery
import importlib.util
import unittest
from pathlib import Path

CAMINHO = Path(__file__).resolve().parent.parent / ".local" / "bin" / "fila"
carregador = importlib.machinery.SourceFileLoader("fila", str(CAMINHO))
especificacao = importlib.util.spec_from_loader("fila", carregador)
fila = importlib.util.module_from_spec(especificacao)
carregador.exec_module(fila)


def issue(numero, titulo="x", marco=None):
    return {"number": numero, "title": titulo, "milestone": {"title": marco} if marco else None}


def numeros(issues):
    return [i["number"] for i in fila.ordenar_fila(issues)]


class OrdemDaFila(unittest.TestCase):
    def test_milestone_por_titulo_e_sem_milestone_no_fim(self):
        issues = [issue(1), issue(2, marco="01. B"), issue(3, marco="00. A")]
        self.assertEqual(numeros(issues), [3, 2, 1])

    def test_prefixo_lido_como_numeros(self):
        issues = [
            issue(1, "[18.10] dez", "M"),
            issue(2, "[18.2] dois", "M"),
            issue(3, "[9.1] nove", "M"),
        ]
        self.assertEqual(numeros(issues), [3, 2, 1])

    def test_sem_prefixo_vem_depois_dos_prefixados_e_por_numero(self):
        issues = [issue(9, "sem prefixo", "M"), issue(5, "outra sem", "M"), issue(20, "[1.1] com", "M")]
        self.assertEqual(numeros(issues), [20, 5, 9])

    def test_milestone_vence_prefixo(self):
        issues = [issue(1, "[1.1] a", "01. B"), issue(2, "[99.9] z", "00. A")]
        self.assertEqual(numeros(issues), [2, 1])

    def test_empate_total_desempata_pelo_numero(self):
        self.assertEqual(numeros([issue(8, "[1.1] a", "M"), issue(3, "[1.1] b", "M")]), [3, 8])


class LinhaRepos(unittest.TestCase):
    def test_extrai_nomes(self):
        self.assertEqual(fila.repos_da_issue("## Problema\nx\n\nRepos: api, frontend\n"), ["api", "frontend"])

    def test_um_nome_e_barra(self):
        self.assertEqual(fila.repos_da_issue("Repos: api"), ["api"])
        self.assertEqual(fila.repos_da_issue("Repos: api | frontend"), ["api", "frontend"])

    def test_ausente(self):
        self.assertIsNone(fila.repos_da_issue("sem a linha"))
        self.assertIsNone(fila.repos_da_issue(None))

    def test_validacao(self):
        repos = {"api": 1, "frontend": 2}
        self.assertIsNone(fila.motivo_de_repos_invalidos(["api"], repos))
        self.assertIn("backend", fila.motivo_de_repos_invalidos(["api", "backend"], repos))
        self.assertIn("Repos:", fila.motivo_de_repos_invalidos(None, repos))


class DecisaoDepoisDaEspera(unittest.TestCase):
    def test_verde(self):
        self.assertEqual(fila.decidir_ci(0, 0, 0), fila.VERDE)

    def test_vermelho_conserta_ate_o_limite_e_depois_dono(self):
        self.assertEqual(fila.decidir_ci(1, 0, 0), fila.CONSERTAR)
        self.assertEqual(fila.decidir_ci(1, fila.RODADAS_VERMELHAS - 1, 0), fila.CONSERTAR)
        self.assertEqual(fila.decidir_ci(1, fila.RODADAS_VERMELHAS, 0), fila.DONO)

    def test_infra_repete_uma_vez(self):
        self.assertEqual(fila.decidir_ci(2, 0, 0), fila.REPETIR)
        self.assertEqual(fila.decidir_ci(2, 0, 1), fila.DONO)

    def test_fechada_reavalia(self):
        self.assertEqual(fila.decidir_ci(5, 0, 0), fila.REAVALIAR)

    def test_demais_codigos_vao_para_o_dono(self):
        for codigo in (3, 4, 6, 7, 64, 124):
            self.assertEqual(fila.decidir_ci(codigo, 0, 0), fila.DONO, codigo)


class DonoRespondeu(unittest.TestCase):
    def comentarios(self, *corpos):
        return [{"body": c} for c in corpos]

    def test_respondeu_quando_ultimo_nao_e_da_fila(self):
        cs = self.comentarios(fila.MARCA_DONO + "\nmotivo", "pode seguir")
        self.assertTrue(fila.dono_respondeu(["eu"], "eu", cs))

    def test_nao_respondeu_quando_ultimo_e_marcador_da_fila(self):
        self.assertFalse(fila.dono_respondeu(["eu"], "eu", self.comentarios("ok", fila.MARCA_DONO + "\nmotivo")))
        self.assertFalse(fila.dono_respondeu(["eu"], "eu", self.comentarios("ok", fila.MARCA_PERGUNTA + "\n?")))

    def test_sem_assignee_dono_ou_sem_comentario_nao_retoma(self):
        self.assertFalse(fila.dono_respondeu([], "eu", self.comentarios("oi")))
        self.assertFalse(fila.dono_respondeu(["outro"], "eu", self.comentarios("oi")))
        self.assertFalse(fila.dono_respondeu(["eu"], "eu", []))

    def test_marcador_com_espaco_antes_ainda_e_da_fila(self):
        self.assertFalse(fila.dono_respondeu(["eu"], "eu", self.comentarios("\n  <!-- fila:dono -->\nx")))

    def test_sessao_pediu_dono(self):
        self.assertTrue(fila.sessao_pediu_dono(self.comentarios("a", fila.MARCA_PERGUNTA + "\nposso?")))
        self.assertFalse(fila.sessao_pediu_dono(self.comentarios(fila.MARCA_PERGUNTA, "resposta")))
        self.assertFalse(fila.sessao_pediu_dono([]))


class Merge(unittest.TestCase):
    def pr(self, estado="OPEN"):
        return {"state": estado}

    def test_todas_mescladas_exige_ao_menos_uma(self):
        self.assertFalse(fila.todas_mescladas([]))
        self.assertTrue(fila.todas_mescladas([self.pr("MERGED"), self.pr("MERGED")]))
        self.assertFalse(fila.todas_mescladas([self.pr("MERGED"), self.pr("OPEN")]))
        self.assertFalse(fila.todas_mescladas([self.pr("MERGED"), self.pr("CLOSED")]))


class MarcoVazio(unittest.TestCase):
    def test_faixa_00_nunca_fecha(self):
        self.assertFalse(fila.fecha_marco_vazio({"number": 1, "title": "00. Saúde técnica"}))

    def test_milestone_de_resultado_fecha(self):
        self.assertTrue(fila.fecha_marco_vazio({"number": 2, "title": "09. Troca da centralizada"}))

    def test_sem_milestone_nao_fecha(self):
        self.assertFalse(fila.fecha_marco_vazio(None))


class SessaoEPrompts(unittest.TestCase):
    def test_ambiente_sem_credenciais_da_aws(self):
        env = {
            "PATH": "/bin", "AWS_PROFILE": "p", "AWS_ACCESS_KEY_ID": "a", "AWS_SECRET_ACCESS_KEY": "s",
            "AWS_SESSION_TOKEN": "t", "AWS_PAGER": "",
        }
        novo = fila.ambiente_da_sessao(env)
        for var in fila.VARS_AWS_REMOVIDAS:
            self.assertNotIn(var, novo)
        self.assertEqual(novo["AWS_CONFIG_FILE"], "/dev/null")
        self.assertEqual(novo["AWS_SHARED_CREDENTIALS_FILE"], "/dev/null")
        self.assertEqual(novo["PATH"], "/bin")
        self.assertIn("AWS_PROFILE", env)

    def test_duracao(self):
        self.assertEqual(fila.segundos("90m"), 5400)
        self.assertEqual(fila.segundos("1h"), 3600)
        self.assertEqual(fila.segundos("600"), 600)

    def test_slug_do_remote(self):
        self.assertEqual(fila.slug_do_remote("git@github-raphael:TEAjudo/api.git\n"), "TEAjudo/api")
        self.assertEqual(fila.slug_do_remote("https://github.com/TEAjudo/frontend"), "TEAjudo/frontend")

    def test_prompts_preenchem_todos_os_campos(self):
        itens = [("/w/api/fila-7", "TEAjudo/api", "dev"), ("/w/frontend/fila-7", "TEAjudo/frontend", "dev")]
        integ = {"api": "dev", "frontend": "dev"}
        execucao = fila.prompt_execucao("TEAjudo/teajudo", 7, itens, integ)
        continuacao = fila.prompt_continuacao("TEAjudo/teajudo", 7, itens, integ)
        conserto = fila.PROMPT_CONSERTO.format(repo="TEAjudo/api", pr=3, fila="TEAjudo/teajudo", n=7, arquivo="/x/ci.txt")
        for texto in (execucao, continuacao, conserto):
            self.assertNotRegex(texto, r"\{[a-z_]+\}")
        self.assertIn("gh issue view 7 -R TEAjudo/teajudo --comments", execucao)
        self.assertIn("/w/api/fila-7 (TEAjudo/api, base dev); /w/frontend/fila-7", execucao)
        self.assertIn("gh pr create --base dev --head fila/7", execucao)
        self.assertIn("git log origin/dev..HEAD", continuacao)
        self.assertIn("Faça só o que a issue pede", continuacao)
        self.assertTrue(continuacao.endswith("Termine."))
        self.assertIn("/x/ci.txt", conserto)

    def test_texto_de_integracao_divergente(self):
        self.assertEqual(fila.texto_integracao({"a": "dev", "b": "dev"}), "dev")
        self.assertIn("a: dev", fila.texto_integracao({"a": "dev", "b": "main"}))

    def test_espera_de(self):
        pr = lambda estado: {"state": estado}
        self.assertTrue(fila.espera_de([], "eu", [pr("MERGED")], []).startswith("fechar"))
        self.assertIn("motivo", fila.espera_de(["eu"], "eu", [], [{"body": "<!-- fila:dono -->\nmotivo"}]))
        self.assertIn("respondeu", fila.espera_de(["eu"], "eu", [], [{"body": "vai"}]))
        self.assertIn("CI", fila.espera_de([], "eu", [pr("OPEN")], []))


if __name__ == "__main__":
    unittest.main()
