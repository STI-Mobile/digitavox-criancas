# Contrato operacional para agentes

## Projeto

Digitavox Crianças é um aplicativo Flutter, inicialmente para iOS e Android, destinado à aprendizagem acessível de digitação por crianças cegas ou com baixa visão. Este repositório contém apenas o harness de engenharia e uma fixture de conteúdo; não trate o material demo como pedagogia aprovada.

## Antes de alterar

1. Leia o código, os testes e a documentação ligados à mudança.
2. Confirme `git status` e preserve alterações existentes que não sejam suas.
3. Faça a menor alteração verificável que resolva o objetivo.
4. Preserve a arquitetura existente, salvo justificativa registrada na documentação ou em novo ADR.

## Arquitetura e diretórios

- `lib/src/presentation`: widgets e telas; sem regras de curso ou persistência.
- `lib/src/application`: ViewModels e coordenação de estado da UI.
- `lib/src/domain`: modelos, validações, progressão e contratos nas fronteiras técnicas.
- `lib/src/data`: implementações de persistência.
- `lib/src/infrastructure`: carregamento de assets e integrações com Flutter/plataforma.
- `assets/content`: conteúdo data-driven; atualmente somente fixture demo.
- `test/unit`, `test/widget`, `integration_test`: testes separados por escopo.

A direção esperada é apresentação → aplicação → domínio. Implementações de dados e infraestrutura satisfazem contratos do domínio e são injetadas na composição do app. Não acople widgets diretamente a JSON, banco de dados ou APIs de plataforma.

Use MVVM pragmaticamente. Não crie camadas, interfaces, services, repositories ou frameworks sem um caso concreto. Consulte `docs/architecture.md` e o ADR inicial.

## Comandos

- Setup: `make bootstrap`
- Formatação: `make format`
- Análise: `make analyze`
- Unitários: `make test-unit`
- Widgets: `make test-widget`
- Integração: `make test-integration` (requer dispositivo)
- Cobertura: `make coverage`
- Validação principal: `make check`

## Definição de pronto

Uma alteração só está pronta quando:

- o comportamento está coberto por teste novo ou atualizado quando aplicável;
- documentação e fixtures afetadas estão coerentes;
- acessibilidade foi preservada e validada no escopo possível;
- `make check` termina sem erros, warnings ou alterações de formatação pendentes;
- limitações não verificadas, como teste manual de VoiceOver/TalkBack, são declaradas na entrega.

## Commits

Não crie commits automaticamente ao concluir uma alteração. Aguarde uma solicitação explícita do usuário para preparar e criar commits.

- Quando o usuário solicitar commits, agrupe arquivos por tema coeso e faça um commit por tema; não misture scaffold, funcionalidade, testes, CI, documentação ou refatoração sem necessidade.
- Use exclusivamente os prefixos abaixo, seguidos de dois-pontos e descrição em português do Brasil: `prefixo: resumo no imperativo`.
  - `feat:` para funcionalidade nova;
  - `fix:` para correção de defeito;
  - `a11y:` para melhoria de acessibilidade;
  - `chore:` para build, dependências ou configuração;
  - `docs:` para documentação;
  - `test:` para testes.
- Não use escopo entre parênteses nem outros prefixos. Exemplos: `feat: registra conclusão de exercício`; `test: valida identificadores duplicados`; `docs: define convenção de commits`.
- Antes de cada commit, confira `git status`, revise os arquivos adicionados e execute `git diff --cached --check` quando aplicável. Não inclua artefatos gerados, segredos ou mudanças preexistentes de terceiros.
- Execute `make check` antes do conjunto de commits solicitado quando a mudança afetar código, configuração ou testes. Se não for possível, registre o motivo na entrega.
- Não reescreva histórico publicado e não use commits genéricos como `wip`, `ajustes` ou `atualizações`.

## Acessibilidade

- Use controles nativos e ordem de foco previsível.
- Forneça nomes, papéis, estados e feedback compreensíveis via `Semantics`.
- Não comunique informação apenas por cor, som, animação ou imagem.
- Mantenha contraste, alvos confortáveis e suporte ao escalonamento de texto.
- Mensagens importantes e mudanças de estado devem ser percebidas por VoiceOver e TalkBack.
- Teste a árvore semântica e, em mudanças relevantes de UI, faça verificação manual com leitores de tela.
- Não crie abstrações genéricas de acessibilidade sem casos reais.

Detalhes e checklist estão em `docs/accessibility.md`.

## Conteúdo pedagógico

- Curso → módulo → lição → exercício é conteúdo data-driven, não lógica de widget.
- Valide schema, campos obrigatórios, tipos e IDs antes de expor conteúdo à UI.
- Identifique fixtures inequivocamente como demo.
- Não altere conteúdo pedagógico como consequência incidental de refatoração técnica.
- Uma mudança pedagógica deve ser explícita, revisável e separada sempre que possível.
- Preserve a possibilidade de pacotes externos futuros, sem implementar importação prematuramente.

## Persistência de progresso

- Preserve `ProgressRepository` como fronteira entre aplicação e persistência.
- Use `InMemoryProgressRepository` em testes que não exercitam durabilidade; a composição de produção deve usar a implementação local durável.
- Trate o documento persistido como contrato versionado. Mudanças de formato exigem incremento ou migração explícita, testes de compatibilidade e atualização do ADR correspondente.
- Diferencie ausência ou documento conhecido como inválido de falhas reais de I/O/plataforma; não capture erros indiscriminadamente.
- Não grave novamente quando a ação não mudar o progresso, como a repetição de um exercício já concluído.

## Áudio

- Separe áudio gravado do curso, futura fala dinâmica por TTS e acessibilidade do sistema; VoiceOver/TalkBack não são motores narrativos.
- Nunca remova ou reduza `Semantics` porque uma informação também possui áudio.
- Packages e APIs nativas de áudio ficam na infraestrutura. Eventos do curso passam pelo `CourseAudioOrchestrator`; execução e lifecycle usam `AudioGuidance` e contratos da aplicação.
- Toda fala controlada pelo app deve passar pelo coordenador; não crie sobreposição narrativa fora da política estabelecida.
- Não use TTS para substituir um asset gravado sem uma necessidade explícita de conteúdo dinâmico.
- Falha sonora não pode impedir teclado, avaliação, conclusão, progresso ou acessibilidade.
- Preserve SwiftPM e não introduza CocoaPods para áudio sem necessidade técnica documentada.

## Práticas proibidas

- Não introduza dependências sem necessidade concreta e justificativa.
- Não silencie warnings, lints ou testes para fazer a pipeline passar.
- Não coloque regras de domínio em widgets nem detalhes de plataforma no domínio.
- Não implemente funcionalidades especulativas ou abstrações para cenários hipotéticos.
- Não misture mudanças amplas de arquitetura, conteúdo e interface em uma única alteração.
- Não remova nem reduza requisitos de acessibilidade.

Ao mudar comportamento, atualize ou adicione testes. Antes de concluir, execute `make check`; se o ambiente impedir alguma etapa, execute o restante e informe exatamente o que ficou pendente.

## Dependências nativas Apple

O projeto utiliza Swift Package Manager (SwiftPM) como gerenciador
de dependências nativas para iOS.

- Novos plugins Flutter com código nativo devem suportar SwiftPM.
- Não introduzir CocoaPods, Podfile ou Pods sem necessidade técnica
  explícita e documentada.
- Antes de adicionar um plugin nativo, verificar sua compatibilidade
  com SwiftPM.
- Alterações em dependências nativas devem ser validadas com build iOS.
- Uma exceção que exija CocoaPods deve ser justificada antes da alteração.
