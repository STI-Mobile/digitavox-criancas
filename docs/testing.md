# Testes

Os testes são organizados por intenção:

- `test/unit`: parsing/validação, avaliação da tecla, interpretação de eventos físicos, padrões sonoros, progressão, persistência e ViewModels;
- `test/widget`: inicialização, eventos de teclado, feedback, conclusão, interação e semântica da interface;
- `integration_test`: smoke tests do app empacotado em dispositivo.

Use `make test` no ciclo normal e `make check` antes de concluir. `make test-integration` requer simulador/emulador ou dispositivo configurado e não faz parte do job Linux inicial de CI. `make coverage` gera `coverage/lcov.info`; não existe meta artificial de cobertura nesta fase.

Ao alterar comportamento, teste a regra no nível mais baixo que forneça confiança e acrescente widget/integração apenas quando a conexão entre camadas for relevante. Evite testes que apenas repetem implementação ou inflacionam cobertura.

Para regressões de acessibilidade, verifique rótulos/estados semânticos quando útil e complemente com VoiceOver/TalkBack em fluxos afetados. Consulte `docs/accessibility.md`.
