# Integração entre curso e áudio

## Fronteiras

Conteúdo define o que narrar e os eventos pedagógicos. `CourseJourneyEngine` define quando esses eventos ocorrem a partir do estado validado. `CourseAudioOrchestrator` converte intenção em `AudioCue`; `AudioGuidance` e seu coordenador executam, cancelam e isolam tecnologia de plataforma. Players, TTS e APIs nativas não entram em widgets, domínio ou regras do curso.

Áudio narrativo não substitui `Semantics`, VoiceOver ou TalkBack. Texto acessível, teclado, avaliação e progresso devem continuar funcionando quando áudio não existe ou falha.

## Conteúdo e texto canônico

Schemas 2/3 preservam cues embutidos em `audioGuidance` e cenas textuais. Schema 4 declara recursos em `Course.audioResources` e usa listas de IDs nos eventos. Cada fala exige texto canônico; cenas referenciam apresentação narrativa e instrução técnica. O parser resolve os mesmos textos para tela e narração, antes de expor conteúdo ao engine.

No Módulo 1, Stella apresenta/celebra; ZERO-1 instrui, oferece ajuda e abre o relatório. `speaker` referencia um personagem, mas não comprova a gravação ou a identidade sonora final. Ilustrações de cenas pertencem a `illustrations`, separadas dos personagens.

Eventos suportados:

| Evento | Contexto |
| --- | --- |
| `start` | Apresentação local da etapa ou repetição solicitada |
| `correctInput` | Tecla avaliada como correta, incluindo eco dinâmico |
| `incorrectInput` | Tecla incorreta e eventual convite configurado para ajuda |
| `completed` | Conclusão local da atividade, missão ou evento, emitida no contexto correspondente |

`correctInput`/`incorrectInput` podem ser herdados entre curso, módulo, missão e atividade; o mais específico substitui o evento correspondente. `start`/`completed` não são herdados entre ancestrais. Assim, a prática não toca apresentação ou som de conclusão da missão a cada atividade. A cena pode fornecer `start` na mesma etapa, preservando seus demais eventos locais.

`CourseAudioConfiguration.inheritFrom()` combina eventos; o engine limita a herança entre ancestrais ao feedback por entrada. A regra é contextual e não deve ser substituída por escolher o primeiro objeto de áudio não nulo.

## Mídia pendente e fallback

Recursos ainda não produzidos declaram `pending: true` e não apontam para um asset supostamente pronto. O fallback é explícito:

```json
{
  "id": "sfx-tecla-incorreta",
  "type": "sfx",
  "pending": true,
  "fallback": "systemClick"
}
```

- `text`: permitido para fala pendente com texto; o coordenador usa TTS.
- `silent`: efeitos narrativos, música e sons de aliens pendentes não são executados.
- `systemClick`: permitido somente para SFX pendente; gera feedback técnico pelo som nativo do sistema. No erro, usa o padrão de clique duplo existente, sem fingir um asset de bipe ou som narrativo já produzido.

O fallback de erro é útil à prática sem visão, mas continua acompanhado por feedback textual e semântico. Volume/silenciamento do sistema e reprodução física exigem verificação no dispositivo. Música/aliens/sensores não recebem esse clique técnico como substituição.

Ao incorporar mídia pronta, remover o estado pendente e incluir um asset real em `assets/audio/`, declarado no bundle. Fala conserva texto acessível mesmo com gravação. Falha de um asset pronto pode usar a política de fallback do coordenador; o catálogo não implementa players. O conteúdo não pode injetar caminhos fora da raiz permitida nem código executável.

`CourseAudioOrchestrator.resolve` converte recursos em `SpeechCue`, `SfxCue`, `MusicCue` ou `ClickCue` técnico autorizado. Se um evento de input não possui configuração alguma, o fallback genérico do orquestrador permanece disponível. Um recurso declarado com `silent` é uma escolha explícita e não deve cair nesse fallback por ter sido filtrado. Lista de reprodução vazia não impede a ação pedagógica.

## Ajuda, resultado e cerimônia

A sessão produz o estado da tecla, posição, excesso de erros e estatísticas. O engine usa `practice.helpCues` e `excessiveErrorsCues` para ajuda canônica. No módulo, o limiar é três erros consecutivos e F7 repete o exercício. Não usar falas desatualizadas de quatro erros ou F5 como repetição.

Ao concluir uma missão aprovada, o engine executa o efeito `lesson.audioGuidance.completed`, a fala da faixa de estrelas e a abertura de ZERO-1 seguida das medições reais. As faixas são inclusivas em 95% e 100%; as estatísticas não reutilizam uma frase narrativa independente no widget. O resultado visual permanece curto e permite abrir/ouvir o Diário de bordo.

`completionEvent` do módulo fornece a cerimônia após aprovação da Prova. Seu evento/recompensas são persistidos de modo idempotente antes da narração inicial. Reabrir uma etapa já concedida não toca novamente por iniciativa do app; **Ouvir cerimônia novamente** é uma reprodução explícita sem novo desbloqueio. Uma interrupção de áudio não cria exercício artificial nem pune a criança.

O catálogo declara as falas e os recursos de decolagem, aliens e fanfarra. Enquanto esses sons estiverem pendentes, somente as falas de fallback são audíveis; não descrever a sequência sonora completa como produzida ou validada.

## Cancelamento e lifecycle

Cada mudança de localização atualiza o token do engine, cancela a sequência anterior e só inicia a nova fala se ainda estiver no contexto válido. O token do coordenador protege continuações obsoletas dentro da reprodução; o do engine protege navegação e eventos.

Voltar, sair, parar áudio, pausar e navegar durante a narração devem interromper o contexto anterior. O relógio de prática é responsabilidade da sessão, separado da reprodução. Fala não deve iniciar o relógio antes da entrada, nem bloquear avaliação/conclusão quando falha. A ajuda pausa a prática e preserva a posição; Escape cancela e retorna à missão.

## Fixtures e validação

`integration_demo_course.json` é um harness técnico: áudio com asset válido, asset ausente para fallback e texto sem asset. `exploradores_espaciais.json` é o conteúdo configurado pelo storyboard, com mídia pendente explícita. O catálogo de composição atual usa Exploradores no modo debug; a fixture técnica é carregada em testes e não deve ser anunciada como opção existente no menu sem uma composição específica.

Fakes e testes verificam referências, ordem, speakers, fallback, herança restrita, cancelamento e funcionamento da jornada durante falha sonora. Testes da plataforma interceptam chamadas nativas; nenhum desses testes comprova som físico.

## Roteiro manual pendente

Em iPhone e Android com teclado físico, e depois com VoiceOver/TalkBack ativos:

1. Abrir perfil e curso; ouvir a apresentação, alcançar a missão e começar a prática.
2. Confirmar que narrativa de Stella e instruções de ZERO-1 seguem o conteúdo e que texto equivalente está disponível.
3. Digitar acertos e erros; ouvir eco de tecla e o sinal técnico de erro. Após três erros, ouvir convite à ajuda sem bloqueio.
4. Abrir ajuda, conferir pausa e usar F2/F3/F4/F7; fechar e continuar da mesma posição.
5. Pausar, retomar, sair por Escape e reabrir; conferir distinção entre pausa em memória e reinício da atividade após saída.
6. Concluir missão, conferir fronteiras de estrelas e abrir/ouvir o diário sem falas concorrentes.
7. Navegar rapidamente durante fala e mudar lifecycle; confirmar ausência de áudio obsoleto.
8. Aprovar a Prova; conferir cerimônia inicial, desbloqueios únicos, reprodução manual e bônus opcional.
9. Confirmar que sons/música pendentes permanecem ausentes e que um erro de player não impede continuar.
10. Quando a produção de áudio existir, validar cada asset, voz, pronúncia, pausas, mixagem e volume antes de retirar seu estado pendente.

Registrar o que foi realmente executado. Esta documentação não declara concluídos os testes físicos, leitores de tela, produção sonora ou teste pedagógico com crianças.
