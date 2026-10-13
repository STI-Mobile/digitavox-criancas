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

## Navegação com teclado físico

- Nos menus de perfis, curso, módulo e lição, seta para baixo/Tab avança e seta para cima/Shift + Tab retorna, em ordem de controles. A navegação é circular, ignora ações desabilitadas e traz a seleção para a área visível, inclusive com texto ampliado. Enter e espaço acionam os controles nativos.
- Cada etapa começa com foco na ação principal disponível. Ao abrir um exercício, o foco é solicitado explicitamente na entrada de digitação após o layout; não é necessário acionar “Ativar teclado”.
- As setas e F1–F9 consultam o exercício somente enquanto a entrada possui foco primário. Tab permite sair da entrada para os controles; nesses controles, as setas voltam a navegar e espaço/Enter não são contabilizados como digitação. “Ativar teclado” devolve o foco à execução.
- Ao concluir, o foco sai da entrada e vai para “Próximo exercício”, “Próxima lição”, “Voltar à lição” ou “Tentar lição novamente”, conforme o resultado. Esses destinos são explícitos para permitir continuar sem procurar o botão. Escape preserva o retorno pela hierarquia.
- A seleção por teclado anuncia o nome/estado do controle pelo `CourseAudioOrchestrator`, substituindo a fala anterior. Consultas do exercício também substituem a fala; a primeira entrada de digitação interrompe a narrativa. A semântica nativa dos controles e o feedback textual permanecem disponíveis.
- Combinações com Alt/Meta não são capturadas; as consultas com Control + seta permanecem disponíveis na entrada do exercício. Diálogos e o menu de temas mantêm o comportamento de teclado nativo do Flutter.

O foco de teclado não equivale ao cursor de leitura de VoiceOver/TalkBack. A coexistência da fala do app com o leitor de tela ainda requer validação manual nos dois sistemas, incluindo entrada, conclusão, navegação rápida, diálogos e retorno por Escape.

## Áudio e leitores de tela

Áudio gravado do curso não substitui acessibilidade. Uma instrução pode e deve existir simultaneamente como texto, `Semantics` e asset narrativo porque esses canais têm finalidades diferentes. VoiceOver e TalkBack tornam a interface operável; não são motores de personagem ou narrativa.

Flutter expõe `accessibleNavigation` quando um serviço como VoiceOver ou TalkBack altera o modelo de interação. O app encapsula esse sinal em `SystemAccessibilityStatus`, mas ainda não o usa para desligar ou alterar áudio. A interrupção entre falas controladas pelo app segue a política de navegação acima. Sobreposição com o leitor de tela, volume e foco de acessibilidade dependem de testes em dispositivos reais.

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
