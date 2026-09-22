# Acessibilidade

Acessibilidade é uma restrição de arquitetura e critério de aceite. A interface deve funcionar com VoiceOver e TalkBack e continuar compreensível sem visão, cor ou áudio.

## Convenções

- Prefira widgets nativos com semântica e foco corretos.
- Defina `Semantics` quando o widget padrão não comunicar nome, papel, valor, estado ou ação suficientes.
- Marque títulos importantes como headers e mantenha a ordem semântica coerente com a leitura.
- Use regiões vivas com parcimônia para carregamento, erro e feedback importante.
- Cada ação deve ser alcançável por foco e possuir rótulo que descreva resultado, não aparência.
- Estado concluído, bloqueado, erro e progresso devem ter texto/semântica além de cor e ícone.
- Respeite escala de texto; evite alturas fixas que cortem conteúdo.
- Mantenha contraste mínimo conforme WCAG AA e valide os estados normal, pressionado, focado e desabilitado.
- Não reproduza instruções apenas por som. Feedback falado deve ter alternativa textual/semântica.
- Sinais sonoros de acerto e erro devem ser distintos e sempre acompanhados por estado textual e semântico equivalente.
- Evite mudanças automáticas de foco. Quando necessárias, documente e teste o destino.

## Checklist de mudança de UI

1. Navegar por todas as ações apenas com foco/leitor de tela.
2. Ouvir nome, papel, estado e dica de cada controle.
3. Confirmar ordem de leitura e anúncio das mudanças de estado.
4. Testar texto ampliado e orientação/tamanhos suportados.
5. Verificar contraste e que nenhuma informação depende apenas de cor.
6. Executar testes de widget relacionados.
7. Para fluxos relevantes, registrar verificação manual em VoiceOver e TalkBack.

Testes automatizados ajudam a prevenir regressões, mas não substituem a verificação nos dois leitores de tela.
