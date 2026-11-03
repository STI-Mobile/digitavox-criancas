# Arquitetura

## Direção

O projeto adota MVVM pragmático: apresentação → aplicação → domínio. A composição injeta implementações de dados e infraestrutura que satisfazem contratos do domínio. Não há um framework adicional de regras ou navegação.

- **Presentation** renderiza estado, encaminha ações e mantém semântica/foco dos widgets.
- **Application** contém ViewModels, `CourseJourneyEngine`, coordenação de sessões e eventos.
- **Domain** define modelos de conteúdo, validação, regras de progresso e contratos das fronteiras técnicas.
- **Data** implementa persistência e compatibilidade do documento salvo.
- **Infrastructure** carrega assets e integra teclado, áudio e APIs de plataforma.
- **Content** contém escolhas pedagógicas e narrativas em dados versionados, sem código de widget.

`main.dart` é a raiz de composição. A seleção de perfil entrega um `ProgressRepository` local durável por perfil; testes sem requisito de durabilidade usam `InMemoryProgressRepository`.

## Conteúdo e jornada

`CourseCatalogDocument` lê schemas 2, 3 e 4. Schema 4 exige configuração concreta da prática, referências canônicas, critérios, pré-requisitos e optionalidade. Campos desconhecidos, capacidades sem executor, referências inválidas, ciclos e conteúdo fora das teclas/corpus declarados são rejeitados antes da UI. Consulte [content-model.md](content-model.md), [course.schema.json](course.schema.json) e ADR 0005.

O storyboard fornecido pelo usuário é a autoridade para Exploradores Espaciais; as imagens são referências visuais. Assets sonoros em produção são explicitamente pendentes. Fixtures técnicas permanecem distintas do conteúdo do curso. A composição atual ainda limita o catálogo ao modo debug por `DevelopmentCourseCatalog`; esta alteração não habilita distribuição release nem importação remota.

`CourseJourneyEngine` interpreta curso → módulo → missão/lição → atividade/exercício, preservando ordem dos arrays, pré-requisitos e aprovação. `resume()` abre a apresentação da missão do primeiro exercício obrigatório pendente. A conclusão de módulo usa `JourneyStage.moduleCompletion` e `ContentEvent`; não exige exercício artificial. Concessão de recompensas é idempotente, e bônus opcionais não participam da conclusão obrigatória.

`ExerciseSessionViewModel` recebe exercício e configuração da prática. Mantém posição, repetição, acertos/erros, tempo ativo, pausa, ajuda e conclusão. Teclado físico é interpretado na infraestrutura. Erro consome uma posição sem exigir apagar; ajuda/pausa interrompem entrada e relógio. Um limite expirado não aprova uma tentativa parcial. Widgets não decidem estrelas, desbloqueios ou persistência.

A apresentação usa padrões distintos para introdução, prática e resultado. A prática não herda ilustração nem texto longo do ancestral. Resultado deriva da sessão concluída; estatísticas completas são expostas pelo Diário de bordo. Acessibilidade, controles nativos, foco e escalonamento de texto continuam requisitos transversais.

## Progresso

`CourseCatalogViewModel` coordena alterações através de `ProgressRepository`; infraestrutura de armazenamento não entra nos widgets. `StudentProgressCodec` versiona e valida o documento independente do schema de conteúdo. O progresso schema 4 preserva tentativas, medições por exercício, eventos concluídos e recompensas desbloqueadas; schemas 1/2/3 são migrados sem inventar medições.

A precisão da missão agrega acertos e teclas digitadas quando existem contagens para todos os resultados. Dados antigos sem contagens usam a média das precisões existentes. A média mínima e as faixas de duas/três estrelas são inclusivas e vêm do curso; `secChar` é tempo por caractere e não participa da fórmula de estrelas. A melhor conquista histórica é distinta da aprovação de uma nova tentativa.

Persistem resultados de atividades concluídas; caractere, repetição e tempo em andamento permanecem em memória. `legacyLessonIds` é compatibilidade editorial declarativa: a aplicação pode reunir resultados de IDs substituídos antes da apresentação. O engine não contém IDs especiais do curso. A antiga confirmação por espaço da cerimônia não autoriza recompensas retroativas. Consulte ADR 0002 e ADR 0005.

## Áudio e identidade visual

Áudio segue `CourseAudioConfiguration` → `CourseAudioOrchestrator` → `AudioCue` → `AudioGuidance`. Somente adaptadores concretos conhecem players e TTS. Texto canônico de `audioResources` fornece tanto a cena acessível quanto a fala; números e eco de tecla derivam do estado real.

`correctInput` e `incorrectInput` podem ser herdados entre ancestrais. `start` e `completed` permanecem locais ao contexto narrativo. Pendentes de fala usam texto/TTS; música, aliens e efeitos narrativos pendentes usam silêncio. O erro usa `systemClick` declarado como fallback técnico nativo, sem fingir um asset de efeito já produzido. Falha sonora não bloqueia teclado, avaliação, progresso ou semântica. Consulte [architecture/course-audio-integration.md](architecture/course-audio-integration.md).

Áudio narrativo e leitores de tela têm finalidades diferentes: `Semantics`, VoiceOver e TalkBack não são motores de personagem. A política do coordenador evita sobreposição entre falas controladas pelo app; coexistência com leitores e foco sonoro requer validação física.

O Design System combina identidade institucional, tema acessível do aplicativo e identidade de curso por `themeId`. O domínio conhece identificadores, não cores Flutter. Personagem, ilustração de cena e decoração são conceitos separados. Consulte [design-system.md](design-system.md).

## Evolução

Mudanças no documento salvo exigem versão, migração e testes próprios. Mudanças de conteúdo preservam IDs ou declaram aliases; novas capacidades começam no schema/domínio e precisam de executor. Pacotes externos, sincronização e abstrações adicionais só devem ser introduzidos quando houver requisitos concretos.

`make check` cobre formatação, análise e testes de unidade/widgets. Verificação com VoiceOver/TalkBack, saída sonora física e calibração pedagógica com crianças permanece fora da evidência automatizada. Mudanças estruturais relevantes recebem ADR em `docs/adr`.
