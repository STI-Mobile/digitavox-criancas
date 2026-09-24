# Testes

Os testes são organizados por intenção:

- `test/unit`: parsing/validação, avaliação da tecla, interpretação de eventos físicos, padrões sonoros, progressão, persistência e ViewModels;
- `test/widget`: inicialização, eventos de teclado, feedback, conclusão, interação e semântica da interface;
- `integration_test`: smoke tests do app empacotado em dispositivo.

Use `make test` no ciclo normal e `make check` antes de concluir. `make test-integration` requer simulador/emulador ou dispositivo configurado e não faz parte do job Linux inicial de CI. `make coverage` gera `coverage/lcov.info`; não existe meta artificial de cobertura nesta fase.

Ao alterar comportamento, teste a regra no nível mais baixo que forneça confiança e acrescente widget/integração apenas quando a conexão entre camadas for relevante. Evite testes que apenas repetem implementação ou inflacionam cobertura.

A persistência local é validada sem depender do filesystem ou de estado global da plataforma: testes do codec cobrem serialização, round trip, migração do schema 1, JSON inválido, valores inválidos e schema desconhecido; testes do repositório cobrem primeira execução, recuperação segura, restauração e propagação de falhas reais do armazenamento. Um teste de aplicação conclui um exercício e recria ViewModel e repositório sobre o mesmo documento para representar o fechamento e a reabertura do app. O teste de integração repete o fluxo usando `SharedPreferencesAsync` no dispositivo, preservando e restaurando qualquer documento que existia antes do teste. A implementação em memória continua sendo usada quando o objetivo do teste não é verificar durabilidade.

O Design System possui testes unitários para as paletas Standard, Dark e High Contrast, seleção e composição do tema espacial e fallback neutro. Testes de widget cobrem estados de feedback, prompt com texto ampliado, redução decorativa em alto contraste e alternância/persistência da preferência sem golden tests frágeis.

Áudio é testado por uma implementação fake de `ContentAudioService`. Testes unitários cobrem parsing da referência, rejeição de caminhos inválidos, início, substituição, stop, dispose e falha conhecida. Testes do ViewModel demonstram que teclado, avaliação e conclusão continuam funcionando durante reprodução ou falha. O widget test preserva as asserções semânticas e verifica parada ao sair; a integração usa o player e o asset reais, sem tentar provar programaticamente a saída física do alto-falante.

Para regressões de acessibilidade, verifique rótulos/estados semânticos quando útil e complemente com VoiceOver/TalkBack em fluxos afetados. Consulte `docs/accessibility.md`.

O engine de jornada é testado com `docs/examples/journey_course.json`: ordem dos arrays (inclusive reordenação), retomada após recriar estado, avanço automático e parada entre lições/módulos, atividades indisponíveis, personagens herdados/substituídos, áudio por etapa, navegação rápida e falhas de mídia. A sessão cobre avanço após erro, excesso de erros, repetição, estatísticas e atalhos. Testes de widget cobrem navegação hierárquica, retorno do sistema, nomes/ações semânticas dos botões, atalhos F1–F9, retorno por Escape, texto em escala 2 e fallback de imagem ausente. O exemplo usa caminhos de mídia ilustrativos; não comprova a presença desses assets no bundle nem a reprodução física.
