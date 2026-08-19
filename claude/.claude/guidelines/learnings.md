# Learnings

Lições destiladas do uso real que mudaram como eu trabalho. Cada uma: a regra, o
porquê, e como aplicar. Some quando virar hábito ou for superada — este arquivo
encolhe tanto quanto cresce.

---

## Não duplicar: generalizar o existente, não clonar

**Por quê:** ao precisar de uma variante de algo que já existia (uma seção de
lista de usuários, para um segundo contexto), clonei o componente em vez de
generalizá-lo. O clone duplicou a lógica e ainda regrediu — perdeu o
mobile-first, virou tabela crua. Duas cópias divergem com o tempo e a má prática
se propaga.

**Como aplicar:** antes de criar algo "parecido com X", pare e generalize X — um
componente/módulo parametrizado por contexto (uma prop de escopo, um modo) que as
duas situações consomem. Vale para frontend e backend (DTO, serviço, anotação).
Esbarrou em código defasado no caminho? Conserte para o padrão atual (com teste)
em vez de reproduzir a prática ruim. Deixe o código mais saudável do que estava.

---

## Status verde não é prova de pronto; verifique o estado real

**Por quê:** declarei "deployado, verificado" várias vezes em cima de CI/deploy
verde, e mais de uma vez nada tinha ido ao ar: container não recriado (no-op por
digest), deploy disparado na branch errada, masker corrompendo campo estrutural.
O usuário teve que abrir `docker ps` e me mostrar, duas vezes. Verde diz que o
passo rodou, não que a mudança está viva. Um deploy que não muda o que você acha
que mudou é a falha que mais custa, porque a versão antiga responde igual.

**Como aplicar:** confirme o efeito observável na ponta, não o status do job.
Imagem/digest de fato rodando, o que a própria app anuncia de si (git_sha no log
de subida), a linha que devia aparecer, a resposta real do endpoint. Quando o
pipeline não prova o que entregou, faça o pipeline provar (comparar o container
com o digest promovido, falhar alto se divergir), em vez de confiar no health
check. O canário que exercita o caminho com mudança de verdade pega o que o verde
esconde.

---

## Enésimo patch na mesma área: pare e ache a causa raiz

**Por quê:** empilhei quatro correções no resolver de deploy (HEAD^2, depois grep
de subject, depois API da PR, depois asserção pós-deploy), cada uma tratando um
sintoma, sem perguntar por que a pergunta "qual imagem?" existia. O usuário chamou
de gambiarra duas vezes e mandou pesquisar antes de editar. A causa era uma só
(buildar de um commit e deployar outro), e atacá-la derrubou os cinco sintomas de
uma vez, sem guard nenhum.

**Como aplicar:** quando a mudança é o segundo ou terceiro conserto no mesmo
ponto, pare de editar. Mapeie por que o problema existe, ache a causa única,
conserte ela. Meça em vez de supor (consultei a API, cloněi em modo raso, testei
os casos reais antes de propor). Pesquisar e planejar antes de mexer, não depois
de mais um patch.
