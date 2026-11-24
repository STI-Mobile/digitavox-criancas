# Modelo de conteúdo

O catálogo descreve curso → módulo → lição → exercício. Na interface de Exploradores Espaciais, uma lição é apresentada como **missão** e um exercício como **atividade**. `schemaVersion` versiona o formato; `Course.version` versiona o conteúdo editorial. IDs estáveis identificam progresso e referências; os arrays determinam a ordem.

O storyboard **Módulo 1 — Exploradores Espaciais · A Nave Adormecida**, fornecido pelo usuário, é a fonte das decisões pedagógicas e narrativas desta implementação. As imagens fornecidas orientam a composição visual e os temas, mas não definem vocabulário, avaliação, atalhos ou progressão. A descrição do motor adulto no storyboard não é evidência de que o Flutter já possuía essas funcionalidades.

## Contrato e compatibilidade

O contrato para ferramentas está em [course.schema.json](course.schema.json). `AssetCourseCatalog` decodifica o arquivo e usa `CourseCatalogDocument.fromJson`: o parser Dart é a validação em execução, não um executor do arquivo JSON Schema. `course_catalog.dart` e sua parte `course_configuration.dart` definem os modelos e a resolução de referências.

Schemas 2 e 3 continuam aceitos. Eles usam cues embutidos, cenas com `text` e parâmetros opcionais. Defaults de leitura preservados incluem `accuracy: 90`, `secChar: 0` quando ausente, uma repetição, `spellOut: false`, separadores vazios, `optional: false` e listas vazias de pré-requisitos. Os defaults genéricos atuais de prática são comparação sem distinção de maiúsculas, três erros antes da ajuda e estrelas em 95/100. A ausência de mapa de atalhos usa os comandos de compatibilidade da interface. Esses defaults não constituem uma proposta pedagógica para cursos novos.

Schema 4 exige escolhas explícitas de prática, estrelas, teclas, vocabulário, pré-requisitos, optionalidade, repetições, soletração e separadores. Configurações desconhecidas são rejeitadas antes de disponibilizar o curso. Não há scripts, expressões executáveis, código Dart, chamadas de API, definição de widgets ou uma linguagem de regras dentro do JSON.

O catálogo de Exploradores usa schema 4 e mantém `isDemo: false`, conforme a fonte aprovada pelo usuário. Recursos sonoros ainda não produzidos são identificados separadamente por `pending`; esse estado técnico não altera a indicação editorial do curso. As fixtures `demo_course.json`, `integration_demo_course.json` e `docs/examples/journey_course.json` continuam sendo demos técnicas. A composição atual ainda usa `DevelopmentCourseCatalog` com `kDebugMode`, portanto o build release não disponibiliza o catálogo: habilitar a distribuição de cursos é uma decisão de composição separada.

## Escolhas declaradas pelo curso

| Escopo | Configuração | Consumo |
| --- | --- | --- |
| Curso | `practice.excessiveErrorsThreshold`, `caseSensitive`, `keyFingers`, `shortcuts`, `helpCueIds`, `excessiveErrorsCueIds` | Avaliação e ajuda da sessão; comandos e narração |
| Curso | `rewards.twoStarAccuracy`, `threeStarAccuracy`, `announcementCueIds`, `diaryCueIds` | Limites inclusivos, cerimônia de estrelas e abertura do relatório |
| Curso | `audioResources`, `characters`, `illustrations`, `rewardDefinitions`, `theme` | Recursos canônicos, identidade de quem fala, imagens de cenas, conquistas e identidade visual conhecida |
| Módulo | `allowedKeys`, `vocabulary`, `lessons`, `completionEvent` | Validação do corpus, sequência, conclusão e desbloqueios |
| Missão | `accuracy`, `secChar`, `prerequisiteLessonIds`, `prerequisiteEventId`, `optional`, `legacyLessonIds`, `scene` | Aprovação, tempo padrão, liberação, bônus, compatibilidade de progresso e apresentação |
| Atividade | `expectedInput`, `minimumRepetitions`, `spellOut`, `repetitionSeparator`, `trailingSeparator`, `timePerCharacterSeconds`, `timeLimitSeconds`, `prompt` | Fluxo de entrada, leitura, repetições e limite de prática |

Preferências pessoais de tema, progresso, estado de pausa, tecnologia de TTS, controle de foco, semântica e APIs de plataforma pertencem ao aplicativo. O curso seleciona uma identidade conhecida por `theme`; não define cores Flutter nem pode reduzir requisitos de acessibilidade.

## Texto canônico, personagens e ilustrações

No schema 4, uma fala é declarada uma única vez em `audioResources`. Sua referência serve tanto à narração quanto ao texto acessível. `scene.narrationCueIds` identifica a apresentação narrativa; `instructionCueIds` identifica a orientação técnica. O parser resolve `ContentScene.text`, `instruction`, `narrationCues`, `instructionCues` e a sequência local `audioGuidance.start`. Não existe uma segunda cópia de `scene.text` no JSON 4.

Fragmentos de declaração:

```json
{
  "id": "m1c1-zero1",
  "type": "speech",
  "text": "Bip! ZERO-1 na escuta. Indicador esquerdo no F, indicador direito no J.",
  "speaker": "zero1",
  "pending": true,
  "fallback": "text"
}
```

```json
{
  "narrationCueIds": ["m1c1-stella"],
  "instructionCueIds": ["m1c1-zero1"],
  "characterId": "stella",
  "illustrationId": "scene-c1"
}
```

Os fragmentos ilustram a estrutura; a fala completa e aprovada está no catálogo. No módulo, Stella apresenta a história e celebra; ZERO-1 dá instruções, ajuda e relatório. `speaker` deve identificar um personagem definido no curso. `characters` identifica personagens; `illustrations` identifica imagens de cenas. Uma imagem da asa energizada ou do console não se torna um personagem que fala.

A cena da introdução não é herdada pela prática. A atividade recebe somente sua própria instrução; a leitura inicial usa a entrada inteira ou a soletração conforme `spellOut`. Ilustrações de cena são resolvidas pela referência local e não reaparecem como retrato do ancestral durante a digitação.

## Dinâmica de prática e tempo

Schema 4 admite capacidades executáveis `key`, `keySequence`, `word` e `phrase`; todas exigem entrada imprimível não vazia. `key` exige exatamente um caractere. Os identificadores legados `timed`, `repetition` e `challenge` continuam reconhecidos nos schemas 2/3, mas sem executor; no schema 4 são rejeitados. Tempo e repetição configuram os quatro tipos executáveis, sem precisar de tipos especiais.

Cada caractere consome a posição atual, certo ou errado. Errar não exige apagar nem abre uma tela de reprovação por tecla. Um acerto é ecoado por fala; ao atingir o limiar configurado de erros consecutivos, o curso oferece ajuda. Para Exploradores, são três erros. A comparação respeita `caseSensitive`; o desenho em maiúsculas não implica exigir Shift.

`minimumRepetitions` mantém o nome legado, mas define o número de repetições executadas. `repetitionSeparator` é acrescentado entre repetições; `trailingSeparator` é acrescentado somente à última. Eles aceitam vazio ou espaço, e esses caracteres também são avaliados. O motor não inventa um espaço que não esteja configurado. Missão 1.0 não pede separadores; nas missões seguintes, a configuração inclui o espaço indicado nas instruções.

`Exercise.inputForRepetition(n)` resolve a entrada de cada repetição; `completeExpectedInput` reúne a sequência. A precedência de tempo é:

1. `timeLimitSeconds`, se explícito na atividade;
2. `timePerCharacterSeconds`, se explícito na atividade;
3. `lesson.secChar`, o padrão em **segundos por caractere**.

Sem tempo explícito ou padrão positivo, não há limite. Para o tempo derivado, a fórmula do storyboard é:

```text
tempo = (segundosPorCaractere × repetições × (caracteresDaEntrada + 1)) − 1
```

Caracteres são contados por Unicode runes. A fórmula é independente dos separadores aceitos na entrada e não confunde segundos por caractere com caracteres por segundo. `Exercise.effectiveTimeLimitSeconds(defaultSecondsPerCharacter: lesson.secChar)` resolve o orçamento para a sessão.

O relógio começa na primeira entrada da prática. Pausa e ajuda suspendem contagem e entrada. `ExerciseSessionViewModel.pause()`/`resume()` e `CourseJourneyEngine.pausePractice()`/`resumePractice()` preservam a posição somente na sessão em memória. Ao expirar o limite, a tentativa termina sem aprovação e oferece nova prática com linguagem encorajadora; acertos parciais não concedem estrelas.

F1 abre/fecha ajuda; F2 informa próxima tecla e dedo; F3 soletra o restante; F4 informa o restante; F7 repete o exercício. No catálogo atual, F5 repete a apresentação e F6 as instruções; F8 informa a hora e F9 consulta estatísticas. A aplicação só aceita os nomes de comandos conhecidos de F1 a F9. Escape cancela a prática e retorna à missão; o botão **Pausar** é a ação de pausa. Tab e os controles nativos mantêm a navegação de interface.

## Aprovação, estrelas e diário

A aprovação da missão requer completar suas atividades dentro dos limites e atingir `lesson.accuracy`, inclusive na fronteira. Com medições de todas as atividades, a precisão é `100 × totalCorretas / totalDigitadas`, agregando as contagens; não é a mediana nem a média não ponderada dos percentuais. Resultados antigos sem contagens usam a média dos percentuais existentes, sem inventar medições retroativas.

Uma estrela exige atingir a média; duas exigem pelo menos `twoStarAccuracy`; três exigem pelo menos `threeStarAccuracy`. Exploradores declara 95% e 100%. Tempo não é usado como razão incompatível no cálculo de estrelas. Uma tentativa sem aprovação não libera a próxima missão. A melhor conquista histórica permanece salva, enquanto os resultados atuais determinam a aprovação da tentativa.

O resultado principal mostra a conquista e a ação seguinte. O **Diário de bordo** oferece precisão, tempo ativo, tentativas, teclas digitadas/corretas, letras por minuto, palavras por minuto e trocas esperado → recebido. `diaryCueIds` declara somente a abertura de ZERO-1; os números são produzidos a partir das medições reais. A estimativa de palavras por minuto usa grupos convencionais de cinco caracteres, não uma contagem de palavras do corpus.

## Progressão e evento de módulo

Pré-requisitos são referências de lições aprovadas ou de evento concluído. O engine aplica essas condições também às aberturas diretas; botões desabilitados não são a fronteira de validação. Antes da aprovação, atividades da mesma missão seguem a sequência; missões aprovadas podem ser revisitadas.

O módulo contém oito missões obrigatórias: 1.0 a 1.7. A Prova do Cadete reúne três exercícios, com `spellOut` próprio: código soletrado e duas mensagens completas. Assim, ganha estrelas uma única vez, por missão.

`completionEvent` é um `ContentEvent`, com ID, título, `prerequisiteLessonId`, `rewardIds` e cena. A cerimônia da decolagem depende da aprovação da Prova e não tem digitação, média, repetição nem estrelas próprias. Ao entrar em `JourneyStage.moduleCompletion`, a concessão do evento e das recompensas é registrada uma única vez antes da narração. A reprodução inicial não se repete automaticamente após o evento salvo; a criança pode pedir **Ouvir cerimônia novamente**, sem conceder outra recompensa. Fala/sons que falhem não removem conquistas nem impedem continuar.

A Corrida de Energia declara `optional: true` e `prerequisiteEventId: "m1-decolagem"`. É repetível e não entra na aprovação ou na contagem de missões obrigatórias. Não existem Poeira Estelar nem loja de upgrades nesta configuração.

## Áudio local e herança por evento

Os arrays de `audioGuidance` do schema 4 contêm IDs de `audioResources`, resolvidos antes da apresentação. Eventos são `start`, `correctInput`, `incorrectInput` e `completed`; os eventos de conclusão são emitidos no nível correto pelo engine. `lesson.audioGuidance.completed` celebra a missão, não cada exercício.

Somente `correctInput` e `incorrectInput` podem ser herdados entre curso → módulo → lição → exercício, com o mais específico substituindo o evento correspondente. `start` e `completed` permanecem locais: abrir uma atividade não repete a introdução ou a celebração do pai. Na mesma etapa, a cena fornece a apresentação local, preservando outros eventos locais. `CourseAudioConfiguration.inheritFrom()` combina eventos, mas a política do engine limita a herança entre ancestrais ao feedback por entrada.

Recursos não produzidos declaram `pending: true`, não declaram um `asset` pronto e exigem fallback:

- `speech`: `fallback: "text"`, com texto canônico acessível; execução por TTS até a gravação existir;
- `sfx`/`music`: `fallback: "silent"`; omitidos até existir mídia, sem substituir por um falso som de alien ou efeito aprovado;
- `sfx` pendente de erro: `fallback: "systemClick"`, o sinal técnico nativo do sistema. Esse fallback só é permitido para SFX pendente e não se apresenta como um asset narrativo produzido.

Para incorporar mídia produzida, remover o estado pendente, declarar o asset real sob `assets/audio/` e incluí-lo no bundle. Fala continua exigindo texto acessível no schema 4. Caminhos não podem atravessar diretórios. A ausência de áudio preserva texto, semântica, teclado, avaliação e progresso. Vozes diferentes e qualidade de pronúncia exigem teste físico; `speaker` sozinho não comprova uma voz final produzida.

## Retomada e evolução do progresso

A persistência salva resultados de atividades concluídas. Reabrir o app apresenta a missão do primeiro exercício obrigatório pendente; a criança pode ouvir orientações antes de continuar. Sair da atividade descarta caracteres, repetição e tempo ainda não concluídos; a própria interface comunica que essa atividade recomeçará. Não há checkpoint persistido de caractere. A pausa em memória não deve ser apresentada como retomada exata depois de encerrar o processo.

`legacyLessonIds` declara IDs editoriais substituídos, distintos dos IDs ativos e não reutilizados por outra lição. A Prova declara `m1-7a-prova-codigo` e `m1-7b-prova-mensagens`, permitindo à aplicação reunir progresso preexistente na missão unificada sem IDs especiais dentro do engine. A transformação ocorre antes da apresentação e usa o contrato de progresso, com gravação verificada. A antiga lição de confirmação por espaço da cerimônia não prova execução narrativa nem autoriza concessão retroativa de aliens ou distintivo.

Schema de conteúdo e schema de progresso são contratos independentes, ainda que ambos usem versão 4 atualmente. Mudanças em dados salvos exigem migração/testes próprios; mudanças editoriais exigem manter IDs ou declarar sua compatibilidade. Pacotes externos, sincronização e uma linguagem genérica de regras permanecem fora do escopo.

## Validações e limites de verificação

O parser rejeita campos desconhecidos no schema 4, valores de tipo incorreto, IDs duplicados no curso, referências ausentes, ciclos entre lições/eventos, dependência obrigatória de bônus, recompensa ou voz inexistente, teclas fora de `allowedKeys`, palavras fora do corpus, separadores não suportados, faixas inválidas e capacidades sem executor. A existência e a reprodução de mídia pronta são verificadas no bundle/player; referências pendentes não simulam arquivos presentes.

Testes automatizados cobrem os parâmetros do storyboard, referências canônicas, capacidades e fronteiras de estrelas/tempo. `make check` verifica código e testes; não comprova VoiceOver/TalkBack, som físico, conforto infantil nem calibração de 5–10 minutos. Essas verificações continuam manuais e não foram declaradas concluídas por esta alteração.
