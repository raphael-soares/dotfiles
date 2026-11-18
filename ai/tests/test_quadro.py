import sys

sys.dont_write_bytecode = True

import importlib.machinery
import importlib.util
import unittest
from pathlib import Path

CAMINHO = Path(__file__).resolve().parent.parent / ".local" / "bin" / "quadro"
carregador = importlib.machinery.SourceFileLoader("quadro", str(CAMINHO))
especificacao = importlib.util.spec_from_loader("quadro", carregador)
quadro = importlib.util.module_from_spec(especificacao)
carregador.exec_module(quadro)

DONO = "dono"


def issue(estado="OPEN", labels=(), responsaveis=()):
    return {"state": estado, "labels": list(labels), "assignees": list(responsaveis)}


def pr(estado):
    return {"state": estado}


class RegraDeColuna(unittest.TestCase):
    def test_colunas_na_ordem_do_board(self):
        self.assertEqual(
            quadro.COLUNAS,
            ("Backlog", "Investigação", "Pronta", "Fazendo", "Esperando você", "Revisão", "Feita"),
        )

    def test_fechada_vai_para_feita_mesmo_com_label_esquecida(self):
        self.assertEqual(quadro.coluna(issue("CLOSED", ["em-execucao"], [DONO]), DONO, [pr("OPEN")]), "Feita")

    def test_atribuida_ao_dono_vence_pr_aberta(self):
        self.assertEqual(quadro.coluna(issue(labels=["em-execucao"], responsaveis=[DONO]), DONO, [pr("OPEN")]), "Esperando você")

    def test_atribuida_a_outra_pessoa_nao_e_esperando_voce(self):
        self.assertEqual(quadro.coluna(issue(labels=["em-execucao"], responsaveis=["outra"]), DONO, []), "Fazendo")

    def test_pr_aberta_e_revisao(self):
        self.assertEqual(quadro.coluna(issue(labels=["em-execucao"]), DONO, [pr("OPEN")]), "Revisão")

    def test_pr_mesclada_com_issue_aberta_e_revisao(self):
        self.assertEqual(quadro.coluna(issue(labels=["em-execucao"]), DONO, [pr("MERGED")]), "Revisão")

    def test_pr_fechada_sem_merge_nao_conta(self):
        self.assertEqual(quadro.coluna(issue(labels=["em-execucao"]), DONO, [pr("CLOSED")]), "Fazendo")

    def test_pronta(self):
        self.assertEqual(quadro.coluna(issue(labels=["ready-for-agent"]), DONO, []), "Pronta")

    def test_em_execucao_vence_pronta(self):
        self.assertEqual(quadro.coluna(issue(labels=["ready-for-agent", "em-execucao"]), DONO, []), "Fazendo")

    def test_investigando(self):
        self.assertEqual(quadro.coluna(issue(labels=["investigando"]), DONO, []), "Investigação")

    def test_pronta_vence_investigando(self):
        self.assertEqual(quadro.coluna(issue(labels=["investigando", "ready-for-agent"]), DONO, []), "Pronta")

    def test_sem_nada_e_backlog(self):
        self.assertEqual(quadro.coluna(issue(labels=["bug"]), DONO, []), "Backlog")


if __name__ == "__main__":
    unittest.main()
