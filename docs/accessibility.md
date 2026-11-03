# Acessibilidade

Acessibilidade é uma restrição de arquitetura e critério de aceite. A interface deve funcionar com VoiceOver e TalkBack e continuar compreensível sem visão, cor ou áudio.

## Convenções

- Prefira widgets nativos com semântica e foco corretos.
- Defina `Semantics` quando o widget padrão não comunicar nome, papel, valor, estado ou ação suficientes.
- Marque títulos importantes como headers e mantenha a ordem semântica coerente com a leitura.
- Use regiões vivas com parcimônia para carregamento, erro e feedback importante.
- Cada ação deve ser alcançável por foco e possuir rótulo que descreva resultado, não aparência.
- Estado concluído, bloqueado, erro, pausa e progresso devem ter texto/semântica além de cor e ícone. Missão bloqueada informa o motivo; imagem de cena não contém instrução exclusiva.
- Respeite escala de texto; evite alturas fixas que cortem conteúdo.
- Mantenha contraste mínimo conforme WCAG AA e valide os estados normal, pressionado, focado e desabilitado.
- Não reproduza instruções apenas por som. Feedback falado deve ter alternativa textual/semântica.
- Sinais sonoros de acerto e erro devem ser distintos e sempre acompanhados por estado textual e semântico equivalente.
- Evite mudanças automáticas de foco. Quando necessárias, documente e teste o destino.

## Navegação com teclado físico

- Nos menus de perfis, curso, módulo e lição, seta para baixo/Tab avança e seta para cima/Shift + Tab retorna, em ordem de controles. A navegação é circular, ignora ações desabilitadas e traz a seleção para a área visível, inclusive com texto ampliado. Enter e espaço acionam os controles nativos.
- Começar/retomar curso abre a apresentação da missão, com foco na ação principal. Ao iniciar a atividade, o foco vai explicitamente à entrada após o layout; não é necessário ativar um teclado por ação adicional.
- Setas e F1–F9 consultam a atividade somente enquanto a entrada possui foco primário. F2 informa letra e dedo; F3 soletra o restante; F4 fala o restante; F7 repete a atividade. O mapa conhecido do curso define F5/F6 e demais consultas, e a ajuda usa os mesmos dados. Tab acessa os controles; nessas ações, setas navegam e espaço/Enter não contam como digitação.
- Ao concluir, foco sai da entrada para a ação principal do resultado: próxima atividade/missão, conclusão do módulo ou praticar novamente. Estatísticas completas ficam no Diário de bordo, cuja abertura/fechamento deve preservar foco previsível. Escape cancela a prática e retorna à missão; o botão Pausar conserva a sessão em memória. Sair informa que a atividade atual recomeçará ao retornar.
- A seleção por teclado anuncia nome/estado do controle pelo `CourseAudioOrchestrator`, substituindo a fala anterior. Consultas também substituem a fala; entrada de digitação interrompe narrativa. F1 abre ajuda e pausa entrada/relógio, preservando posição. Ao fechar, restaura o estado de pausa anterior. A semântica nativa e o feedback textual permanecem disponíveis.
- Combinações com Alt/Meta não são capturadas; as consultas com Control + seta permanecem disponíveis na entrada do exercício. Diálogos e o menu de temas mantêm o comportamento de teclado nativo do Flutter. No seletor, cada opção focada anuncia seu nome antes da confirmação, mantendo o estado selecionado em `Semantics`; navegar ou cancelar não muda a preferência.

O foco de teclado não equivale ao cursor de leitura de VoiceOver/TalkBack. A coexistência da fala do app com o leitor de tela ainda requer validação manual nos dois sistemas, incluindo entrada, conclusão, navegação rápida, diálogos e retorno por Escape.

## Áudio e leitores de tela

Áudio do curso não substitui acessibilidade. No schema 4, fala canônica alimenta texto e intenção sonora pela mesma referência; `Semantics` continua independente do sucesso do player. VoiceOver e TalkBack tornam a interface operável e não são motores de personagem ou narrativa. Fala pendente usa texto/TTS; sons de aliens/música pendentes são silenciosos. O erro usa fallback nativo `systemClick`, além de texto/semântica; saída física e coexistência com leitor continuam pendentes de verificação.

Flutter expõe `accessibleNavigation` quando um serviço como VoiceOver ou TalkBack altera o modelo de interação. O app encapsula esse sinal em `SystemAccessibilityStatus`, mas ainda não o usa para desligar ou alterar áudio. A interrupção entre falas controladas pelo app segue a política de navegação acima. Sobreposição com o leitor de tela, volume e foco de acessibilidade dependem de testes em dispositivos reais.

## Apresentação, prática e resultado

A apresentação oferece história e instrução técnica com imagem local. A prática mantém somente contexto compacto, alvo, repetição, feedback e ações de apoio; não herda retrato/cena nem texto longo da missão. Uma caixa ao fim da prática mostra ajuda e consultas de próxima letra/dedo ou exercício inteiro. As consultas pelas setas trazem a caixa para a área visível e preservam o foco da entrada, inclusive quando a prática está pausada. Resultado usa um título semântico próprio e conquista compreensível; estatísticas não precisam ser percorridas antes de continuar. Cerimônia é evento, sem digitação artificial. Todos os temas preservam essas informações e a ordem de leitura.

Erro consome a posição, sem exigir apagar. Três erros consecutivos oferecem ajuda configurada. Não usar apenas cor vermelha ou um painel punitivo. Pausa e tempo expirado têm mensagens compreensíveis; aprovação e faixas de estrelas são inclusivas, sem exigência visual para descobrir progresso.

## Checklist de mudança de UI

1. Navegar por todas as ações apenas com foco/leitor de tela.
2. Ouvir nome, papel, estado e dica de cada controle.
3. Confirmar ordem de leitura e anúncio das mudanças de estado.
4. Testar texto ampliado e orientação/tamanhos suportados.
5. Verificar contraste e que nenhuma informação depende apenas de cor.
6. Executar testes de widget relacionados.
7. Para fluxos relevantes, registrar verificação manual em VoiceOver e TalkBack.

Em mudanças de áudio, valide adicionalmente a instrução com e sem leitor de tela, teclado físico durante a fala, interrupção ao sair da tela e funcionamento completo quando o asset falhar.

Testes automatizados ajudam a prevenir regressões, mas não substituem a verificação nos dois leitores de tela.
