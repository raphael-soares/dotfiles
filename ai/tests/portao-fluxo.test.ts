import { test } from "node:test";
import assert from "node:assert/strict";
import { avaliar, type Contexto, decidir, type Sh } from "../.omp/agent/extensions/portao-fluxo.ts";

type Resposta = { code: number; out: string };

function falso(respostas: Record<string, Resposta> = {}, chamadas: string[] = []): Sh {
  return (args) => {
    const chave = args.join(" ");
    chamadas.push(chave);
    for (const [prefixo, r] of Object.entries(respostas)) {
      if (chave.startsWith(prefixo)) return r;
    }
    return { code: 1, out: "" };
  };
}

const ramo = (nome: string): Record<string, Resposta> => ({
  "git rev-parse --abbrev-ref HEAD": { code: 0, out: `${nome}\n` },
});

const comPortao: Record<string, Resposta> = {
  "git rev-parse --show-toplevel": { code: 0, out: "/repo\n" },
  "test -f /repo/scripts/portao": { code: 0, out: "" },
};

const semPortao: Record<string, Resposta> = {
  "git rev-parse --show-toplevel": { code: 0, out: "/repo\n" },
};

function pr(base: string, checks: Record<string, string>[], extra: Record<string, unknown> = {}): Resposta {
  return {
    code: 0,
    out: JSON.stringify({
      url: "https://github.com/TEAjudo/api/pull/7",
      baseRefName: base,
      ...extra,
      statusCheckRollup: checks,
    }),
  };
}

const verde = [{ conclusion: "SUCCESS", status: "COMPLETED" }, { conclusion: "SKIPPED" }, { state: "SUCCESS" }];

function ficha(producao: string): Resposta {
  const conteudo = Buffer.from(JSON.stringify({ producao })).toString("base64");
  return { code: 0, out: JSON.stringify({ content: conteudo }) };
}

const roda = (comando: string, respostas: Record<string, Resposta> = {}) =>
  decidir(comando, "/repo", falso(respostas));

test("regra 1: --no-verify em commit, push e merge", () => {
  assert.match(roda("git commit --allow-empty -m x --no-verify") ?? "", /--no-verify/);
  assert.match(roda("git push --no-verify origin fila/1") ?? "", /--no-verify/);
  assert.match(roda("git merge --no-verify dev") ?? "", /--no-verify/);
  assert.equal(roda("git commit --allow-empty -m x"), undefined);
  assert.equal(roda('git commit -m "explica o --no-verify"'), undefined);
});

test("regra 2: push em dev, main, master", () => {
  assert.match(roda("git push origin main") ?? "", /PR/);
  assert.match(roda("git push origin HEAD:main") ?? "", /PR/);
  assert.match(roda("git push origin +dev") ?? "", /PR/);
  assert.match(roda("git push --force origin master") ?? "", /PR/);
  assert.match(roda("git push origin HEAD:refs/heads/dev") ?? "", /PR/);
  assert.match(roda("git push", ramo("main")) ?? "", /PR/);
  assert.match(roda("git push -u origin HEAD", ramo("dev")) ?? "", /PR/);
  assert.equal(roda("git push origin fila/12"), undefined);
  assert.equal(roda("git push --force-with-lease origin fila/12", ramo("fila/12")), undefined);
  assert.equal(roda("git push --force-with-lease", ramo("fila/12")), undefined);
  assert.equal(roda("git push origin HEAD", ramo("fila/12")), undefined);
});

test("regra 3: gh pr merge --admin", () => {
  assert.match(roda("gh pr merge 7 --admin --merge") ?? "", /CI/);
});

test("regra 4: gh pr merge consulta o estado da PR", () => {
  const consultaVerde = (base: string, checks = verde) => ({
    "gh pr view 7 --json": pr(base, checks),
    "gh api repos/TEAjudo/api/contents/ficha.json": ficha("main"),
  });

  assert.equal(roda("gh pr merge 7 --merge --delete-branch", consultaVerde("dev")), undefined);
  assert.match(roda("gh pr merge 7 --merge", consultaVerde("main")) ?? "", /produção/);
  assert.equal(
    roda("gh pr merge 7", {
      "gh pr view 7 --json": pr("dev", verde, { labels: [{ name: "revisar-dono" }] }),
      "gh api repos/TEAjudo/api/contents/ficha.json": ficha("main"),
    }),
    undefined,
  );
  assert.match(
    roda("gh pr merge 7", consultaVerde("dev", [{ conclusion: "FAILURE" }])) ?? "",
    /checks/,
  );
  assert.match(
    roda("gh pr merge 7", consultaVerde("dev", [{ conclusion: "SUCCESS" }, { status: "IN_PROGRESS" }])) ?? "",
    /checks/,
  );
  assert.match(roda("gh pr merge 7", consultaVerde("dev", [])) ?? "", /nenhum check/);
});

test("regra 4: sem ficha, main e master são produção; ficha manda quando existe", () => {
  const semFicha = (base: string) => ({ "gh pr view 7 --json": pr(base, verde) });
  assert.match(roda("gh pr merge 7", semFicha("master")) ?? "", /produção/);
  assert.equal(roda("gh pr merge 7", semFicha("dev")), undefined);
  const fichaProd = (base: string) => ({
    "gh pr view 7 --json": pr(base, verde),
    "gh api": ficha("release"),
  });
  assert.match(roda("gh pr merge 7", fichaProd("release")) ?? "", /produção/);
  assert.equal(roda("gh pr merge 7", fichaProd("main")), undefined);
});

test("regra 4: consulta falhando bloqueia", () => {
  assert.match(roda("gh pr merge 7 --merge") ?? "", /bloqueado/);
  assert.match(roda("gh pr merge 7", { "gh pr view": { code: 0, out: "não é json" } }) ?? "", /bloqueado/);
});

test("regra 4: passa -R e usa a PR da branch atual quando não há número", () => {
  const chamadas: string[] = [];
  const sh = falso({ "gh pr view": pr("dev", verde) }, chamadas);
  assert.equal(decidir("gh pr merge -R TEAjudo/api --merge", "/repo", sh), undefined);
  assert.ok(chamadas.includes("gh pr view -R TEAjudo/api --json url,baseRefName,statusCheckRollup"));
});

test("regra 6: gh run watch e gh pr checks --watch", () => {
  assert.match(roda("gh run watch 123") ?? "", /pr-watch/);
  assert.match(roda("gh pr checks 5 --watch") ?? "", /pr-watch/);
  assert.equal(roda("gh pr checks 5"), undefined);
  assert.equal(roda("gh run list"), undefined);
});

test("regra 7: laço com sleep e gh", () => {
  assert.match(roda("while true; do gh pr view 5 --json state; sleep 30; done") ?? "", /pr-watch/);
  assert.match(roda("until gh run view 9 --exit-status; do sleep 10; done") ?? "", /pr-watch/);
  assert.equal(roda("for f in a b; do echo $f; done"), undefined);
  assert.equal(roda("sleep 5 && gh pr view 5"), undefined);
});

test("regra 8: Maven sem filtro com scripts/portao na raiz", () => {
  assert.match(roda("./mvnw -B test", comPortao) ?? "", /scripts\/portao/);
  assert.match(roda("mvn clean verify", comPortao) ?? "", /scripts\/portao/);
  assert.match(roda("./mvnw -B package -pl x", comPortao) ?? "", /scripts\/portao/);
  assert.equal(roda("./mvnw -B -q -DskipTests test-compile", comPortao), undefined);
  assert.equal(roda("./mvnw -B test -Dtest=FooTest", comPortao), undefined);
  assert.equal(roda("./mvnw -B verify -DskipTests", comPortao), undefined);
  assert.equal(roda("./mvnw -B test -Dmaven.test.skip=true", comPortao), undefined);
  assert.equal(roda("./mvnw -B test -Dgroups=rapido", comPortao), undefined);
  assert.equal(roda("./mvnw -B test-compile", comPortao), undefined);
  assert.equal(roda("./mvnw -B org.pitest:pitest-maven:mutationCoverage test", comPortao), undefined);
  assert.equal(roda("./mvnw -B test", semPortao), undefined);
  assert.equal(roda("./mvnw -B test"), undefined);
});

test("diretório efetivo vem do primeiro cd", () => {
  const chamadas: string[] = [];
  const sh: Sh = (args, cwd) => {
    chamadas.push(`${cwd}|${args.join(" ")}`);
    return { code: 1, out: "" };
  };
  decidir("cd /tmp/outro && ./mvnw test", "/repo", sh);
  assert.ok(chamadas.some((c) => c.startsWith("/tmp/outro|git rev-parse --show-toplevel")));
});

test("comando com prefixo rtk também é avaliado", () => {
  assert.match(roda("rtk git commit -m x --no-verify") ?? "", /--no-verify/);
  assert.match(roda("rtk gh run watch 1") ?? "", /pr-watch/);
  assert.match(roda("rtk ./mvnw test", comPortao) ?? "", /scripts\/portao/);
  assert.match(roda("cd /repo && rtk git push origin main") ?? "", /PR/);
});

test("comando dentro de bash -c também é avaliado", () => {
  assert.match(roda("bash -c 'git push origin main'") ?? "", /PR/);
});

test("exceção da própria avaliação libera o comando", () => {
  const quebra: Sh = () => {
    throw new Error("sh quebrou");
  };
  assert.equal(decidir("git push", "/repo", quebra), undefined);
  assert.equal(decidir("./mvnw test", "/repo", quebra), undefined);
});

function contexto(hasUI: boolean, kind: string, resposta: boolean) {
  const mensagens: string[] = [];
  const ctx: Contexto = {
    hasUI,
    agent: { kind },
    ui: {
      confirm: async (_titulo, mensagem) => {
        mensagens.push(mensagem);
        return resposta;
      },
    },
  };
  return { ctx, mensagens };
}

test("avaliar pergunta ao dono só na sessão principal com UI", async () => {
  const liberou = contexto(true, "main", true);
  assert.equal(await avaliar("git push origin main", "/repo", falso(), liberou.ctx), undefined);
  assert.equal(liberou.mensagens.length, 1);
  assert.match(liberou.mensagens[0], /Push direto em `main`/);

  const recusou = contexto(true, "main", false);
  assert.match((await avaliar("git push origin main", "/repo", falso(), recusou.ctx)) ?? "", /recusou/);

  const semUI = contexto(false, "main", true);
  assert.match((await avaliar("git push origin main", "/repo", falso(), semUI.ctx)) ?? "", /PR/);
  assert.equal(semUI.mensagens.length, 0);

  const sub = contexto(true, "sub", true);
  assert.match((await avaliar("git push origin main", "/repo", falso(), sub.ctx)) ?? "", /PR/);
  assert.equal(sub.mensagens.length, 0);

  const livre = contexto(true, "main", true);
  assert.equal(await avaliar("git status", "/repo", falso(), livre.ctx), undefined);
  assert.equal(livre.mensagens.length, 0);
});
