# Testes

Os testes são organizados por intenção:

- `test/unit`: catálogo, configuração, sessão, progressão, áudio, interpretação de teclas e persistência;
- `test/widget`: conexão entre estados/controles, foco, semântica, navegação, resultados e temas;
- `integration_test`: app empacotado e adaptadores em dispositivo.

Use `make test` no ciclo normal e `make check` antes de concluir. `make check` executa formatação, análise com avisos fatais e testes de unidade/widgets. `make test-integration` exige simulador/emulador ou dispositivo e não integra o job Linux inicial. `make coverage` gera `coverage/lcov.info`; não há meta artificial de cobertura.

## Conteúdo e configuração

`course_catalog_test.dart` e `course_scene_test.dart` preservam o contrato legado. `course_configuration_test.dart` carrega o JSON real de Exploradores e verifica os oito conjuntos de exercícios, parâmetros do storyboard, Prova unificada, separadores, fórmula de tempo, ajuda, dedos, estrelas e bônus. Mudar uma fala canônica deve atualizar texto e narração resolvidos juntos.

O parser é testado contra campos desconhecidos, tipo de dado inválido, capacidades sem executor, referências ausentes, ciclos, alias em conflito, teclas fora da linha base, palavra fora do corpus, mídia pendente com asset fictício e fallback incompatível. O JSON Schema também deve validar os catálogos 2/3/4 quando houver mudança no contrato; suas restrições estruturais não substituem a validação de referências e ciclos pelo Dart.

## Jornada e sessão

`course_journey_engine_test.dart` mantém a fixture genérica de jornada; `storyboard_journey_test.dart` cobre o fluxo configurado de Exploradores. `course_practice_configuration_test.dart` e `exercise_session_view_model_test.dart` cobrem configuração consumida, avanço após erro, três erros/ajuda, soletração, dedos, separadores, relógio ativo, pausa, expiração e estatísticas.

Regressões essenciais incluem entrada pela apresentação da missão, desbloqueio somente após aprovação, reentrada direta recusada quando bloqueada, fronteiras de precisão mínima/95/100, continuação explícita entre atividades, resultados parciais não aprovados após tempo expirado, conclusão idempotente do módulo e bônus fora da contagem obrigatória. Testes devem distinguir melhor conquista histórica e resultado da tentativa atual.

Retomada testa atividades concluídas salvas, não checkpoint de caractere. A pausa conserva sessão em memória; sair e reabrir uma atividade a reinicia. Aliases editoriais da Prova precisam preservar resultados existentes ao reunir 7A/7B, sem inventar métricas ou cerimônia. Uma falha real ao salvar deve manter a operação recuperável e não publicar conquista ainda não persistida.

## Persistência

Codec/repositórios são testados sem depender do estado global da plataforma. Cobrir schemas de progresso 1/2/3/4, round trip, documento ausente/corrompido/versão desconhecida, contagens incoerentes, duração negativa, pares de erros esperado → recebido, eventos/recompensas e propagação de falhas de armazenamento. Dados legados sem medições não recebem estatísticas inventadas.

A implementação em memória serve a testes sem requisito de durabilidade. Testes de reabertura usam um documento compartilhado entre instâncias; a integração em dispositivo usa `SharedPreferencesAsync`, preservando/restaurando o documento anterior quando aplicável.

## Interface, teclado e áudio

Testes de widget cobrem rótulos/estados de missões, ausência da imagem/texto longo da introdução durante prática, resultado sem a moldura antiga de exercício, abertura do Diário de bordo, navegação de volta, focos de entrada/continuação, ajuda, atalhos declarados e pausa. Texto em escala 2, tela estreita e tema de alto contraste verificam layout e acesso às ações.

A navegação por setas/Tab percorre ações habilitadas de forma previsível e traz a seleção para a área visível. Enter/espaço dos menus não contam como digitação. F7 repete o exercício conforme o curso; Escape sai e volta à missão. A ajuda interrompe o relógio e não perde posição. Confirme retorno de foco ao fechar ajuda/diário e destino após conclusão.

Fakes de `AudioGuidance` verificam cues, referências resolvidas, ordem, cancelamento, falhas e metadata, sem reproduzir som real. A herança de `correctInput`/`incorrectInput` não pode importar `start`/`completed` de ancestrais. Resultado de atividade, resultado de missão e cerimônia têm eventos distintos. O texto dinâmico de estatísticas não deve repetir a abertura canônica de ZERO-1.

Mídia pendente usa `text`, `silent` ou `systemClick` conforme o contrato. `systemClick` é fallback técnico nativo de SFX, não asset narrativo. Sons de aliens/música pendentes permanecem silenciosos. Testes do adaptador interceptam `SystemSound.play`, incluindo clique duplo, cancelamento e falha de plataforma; isso não comprova a saída sonora física.

## Verificação manual pendente

Testes automatizados e screenshots não substituem VoiceOver/TalkBack, teclado físico real, pronúncia de cê-cedilha/nomes, coexistência de narração e leitor, volume da música/efeitos, interrupção por lifecycle ou avaliação com crianças. Registrar dispositivo, tema, leitor ativo e resultado de cada etapa realmente executada.

A meta pedagógica de 5–10 minutos por missão precisa de sessões reais; não decorre apenas da fórmula máxima de tempo. Até a produção, efeitos e música declarados pendentes não podem ser relatados como ouvidos/validados. Consulte [accessibility.md](accessibility.md) e [architecture/course-audio-integration.md](architecture/course-audio-integration.md) para os roteiros.
