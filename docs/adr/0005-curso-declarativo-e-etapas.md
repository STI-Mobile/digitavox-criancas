# ADR 0005: curso declarativo e etapas de apresentação, prática e resultado

- Status: aceita
- Data: 2026-10-13
- Complementa: ADR 0004 (jornada JSON) e ADR 0002 (progresso local)

## Contexto

A avaliação do fluxo de Digitavox Crianças mostrou que a ação principal do curso pulava a apresentação da missão, a imagem da lição era herdada durante digitação, todas as lições podiam ser abertas e o resultado permanecia sob contexto visual de exercício. O storyboard fornecido pelo usuário define a história e os parâmetros de Exploradores Espaciais; as referências visuais orientam composição e temas. Ele também descreve funcionalidades do motor adulto que não estavam implementadas automaticamente no Flutter.

O catálogo anterior não representava separadores, soletração por exercício, ajuda por três erros, pré-requisitos, cerimônia única ou bônus opcional. `secChar` era usado com grandezas incorretas e os limites de estrelas não incluíam as fronteiras. A cerimônia era uma lição com espaço avaliado; a Prova era dividida em duas missões e a corrida entrava no progresso obrigatório.

## Decisão

Adotar schema 4 para declarar as escolhas de conteúdo e pedagogia, preservando leitura dos schemas 2/3 e MVVM pragmático. Os modelos e validações permanecem no domínio; o engine e ViewModels executam capacidades conhecidas; apresentação mostra estado e envia comandos. O JSON não contém código executável, widgets, regras arbitrárias de plataforma nem configurações que possam reduzir acessibilidade.

O catálogo passa a declarar prática, dedos/atalhos conhecidos, limites de estrelas, textos canônicos, ilustrações, recursos sonoros, pré-requisitos, separadores, soletração, tempo e recompensas. Configurações desconhecidas no schema 4 são rejeitadas. O schema para ferramentas e o parser em execução devem representar o mesmo contrato; referências, ciclos e consistência pedagógica recebem validações adicionais no domínio.

### Etapas e informação

Separar os padrões visuais:

- **Apresentação:** narrativa de Stella, orientação técnica de ZERO-1, ilustração local e ação de começar/continuar.
- **Prática:** contexto compacto da missão/atividade, instrução, alvo, repetição, feedback discreto, ajuda e pausa. A ilustração e o texto longo da apresentação não são herdados.
- **Resultado:** conclusão da atividade ou missão, conquista e ação seguinte. Estatísticas completas ficam no Diário de bordo.
- **Conclusão de módulo:** cerimônia própria e recompensas identificadas, sem exercício artificial para confirmar áudio.

`JourneyStage` mantém curso, módulo, lição e exercício, acrescentando `moduleCompletion`. Resultado da prática deriva do estado de sessão, sem criar outro roteador. Ação de começar/retomar curso abre a apresentação da missão; as atividades exigem sequência e a próxima missão exige aprovação. A navegação de volta conserva a hierarquia.

### Configuração e execução

Schemas 2/3 preservam defaults de parsing e fixtures técnicas. No schema 4, opções pedagógicas concretas são explícitas. `timeLimitSeconds` substitui `timePerCharacterSeconds`; sem esses campos, `secChar` da missão fornece segundos por caractere. A fórmula derivada segue o storyboard: `(segundos × repetições × (caracteres + 1)) − 1`. Não se aplica uma razão de caracteres por segundo às estrelas.

Precisão atual usa contagens agregadas quando todas as atividades têm medições; progresso antigo sem contagens usa a média dos percentuais existentes. A média mínima, 95% para duas estrelas e 100% para três são inclusivos e configurados. Tempo esgotado não aprova resultados parciais.

A Prova do Cadete é uma missão com três exercícios. `spellOut` por exercício permite código soletrado e mensagens completas sem dividir a conquista. A Corrida de Energia é opcional e liberada após a cerimônia; não participa da conclusão obrigatória.

### Texto, cenas e áudio

Uma fala canônica vive em `audioResources`. Cenas referenciam narrativas/instruções; o parser resolve o texto visível e a intenção sonora da mesma fonte. Personagens que falam e ilustrações de cena são coleções distintas.

Somente feedback `correctInput`/`incorrectInput` é herdado dos ancestrais. `start` e `completed` são locais à etapa: introdução de missão não toca a cada atividade e efeito de missão não toca a cada exercício. Ajuda, estrelas e abertura do diário usam referências canônicas. Números, eco de tecla e consulta do restante são fala dinâmica gerada a partir do estado real.

Áudio ainda não produzido declara `pending: true` sem asset pronto. Speech usa fallback `text`; sons narrativos e música usam fallback `silent`. O SFX pendente de erro declara `systemClick`, feedback técnico nativo permitido somente para SFX pendente; não simula um asset narrativo pronto. Não gerar um falso som de alien, música ou efeito narrativo para preencher a ausência. O caminho de mídia pronta é aceito somente depois da produção e inclusão no bundle. Sem som, a experiência preserva texto, semântica, teclado e progresso.

A cerimônia é um `ContentEvent` com pré-requisito de aprovação e IDs de recompensas. Concessão é idempotente por perfil; reprodução manual é independente de conceder conquistas novamente. A persistência de evento precede a narração para impedir concessões repetidas após reabertura, mesmo que a fala seja interrompida.

### Pausa, retomada e compatibilidade editorial

Salvar resultados de atividades concluídas; não adicionar checkpoint persistido de caracteres. Pausa e ajuda conservam posição/repetição/tempo na sessão em memória. Sair por Escape cancela a prática e volta à missão; o exercício em andamento reinicia ao retornar. A interface deve informar esse limite. Background, leitores de tela e reabertura exigem verificar lifecycle separadamente.

`legacyLessonIds` descreve compatibilidade editorial por dados. A nova Prova declara os antigos IDs `m1-7a-prova-codigo` e `m1-7b-prova-mensagens`. A aplicação transforma resultados existentes antes de mostrar a jornada, sem IDs específicos de Exploradores no engine. Não inventa contagens ausentes, estrelas adicionais ou recompensas. A transformação e suas gravações precisam de testes de preservação e idempotência. A antiga confirmação por espaço da cerimônia não atesta que a narrativa ocorreu: não deve conceder aliens/distintivo retroativamente.

O schema do progresso evolui separadamente para medições e conjuntos de evento/recompensas, conforme ADR 0002. A coincidência do número 4 não acopla os dois formatos.

## Alternativas descartadas

- Transportar escolhas pedagógicas para widgets: impediria revisão completa pelo JSON e criaria divergência entre aparência e progressão.
- Executar scripts/fórmulas arbitrárias do JSON: não é necessário para as capacidades concretas do storyboard.
- Preservar cerimônia como exercício: confunde aprovação e narrativa, e exige entrada artificial.
- Tratar a imagem da missão como personagem herdável na prática: produz distração e aumenta a ordem de leitura.
- Adicionar checkpoint de caractere agora: aumenta o contrato salvo e exige decisões de retomada ainda desnecessárias para esta etapa.

## Consequências e validação

Conteúdo e fluxo podem ser revisados separadamente da apresentação. O domínio rejeita configuração sem capacidade executável e referências inválidas antes da UI. Schemas legados continuam carregáveis; alterações editoriais mantêm IDs ou declaram aliases revisáveis.

Testes precisam cobrir parâmetros do storyboard, fronteiras de média/95/100, formulação de tempo, pausas, ausência de mídia, pré-requisitos e tentativas, optionalidade, concessão única, compatibilidade de progresso e semântica das etapas. A UI deve continuar operável por teclado físico, com texto ampliado e nos três temas.

VoiceOver, TalkBack, som físico, pronúncia/identidade das vozes, duração real das missões e testes com crianças permanecem verificações manuais. Screenshots e testes de widget comprovam somente seu escopo; não representam aprovação desses itens.
