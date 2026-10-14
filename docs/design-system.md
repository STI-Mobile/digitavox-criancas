# Design System

O sistema visual combina três camadas independentes:

```text
Brand Digitavox/USP + tema do aplicativo + tema do curso
```

## Brand

`BrandColors` é a única fonte das cores institucionais: USP Blue `#1094AB`, USP Light Blue `#64C4D2` e USP Yellow `#FCB421`. Widgets usam preferencialmente `ColorScheme` ou `DvxThemeTokens`, nunca essas constantes diretamente. Open Sans é empacotada como asset local, acompanhada da licença OFL.

## Tema do aplicativo

`DvxAppTheme.resolve` produz um `ThemeData` Material 3 para:

- `standard`: interface clara;
- `dark`: superfícies escuras e interação cyan;
- `highContrast`: preto, branco, cyan e foco amarelo, com bordas reforçadas.

`ColorScheme` representa conceitos Material. `DvxThemeTokens`, uma `ThemeExtension`, contém accent, success, focus, texto secundário, surface variant e espessuras semânticas. `DvxSpacing` e `DvxRadius` evitam medidas repetidas. A escala tipográfica semântica usa o `TextTheme`; o prompt de tecla escolhe `displayLarge` ou `headlineMedium` e permite text scaling.

A preferência `AppThemePreference` integra `AppSettings`. `CourseCatalogViewModel.updateThemePreference` atualiza o mesmo `ProgressRepository` utilizado pelo progresso. O documento de progresso está no schema 4; documentos 1, 2 e 3 são migrados ao carregar (`highContrastEnabled` do schema 1 vira a preferência correspondente). A versão do progresso é independente da versão do catálogo de conteúdo.

## Tema do curso

O catálogo pode declarar um identificador semântico, por exemplo:

```json
"theme": "space"
```

O domínio guarda apenas o identificador. `DvxCourseThemes`, na apresentação, resolve identidades conhecidas. `SpaceCourseTheme` mantém `spaceNavy`, `cosmicPurple` e `star` fora do tema global e produz uma composição para cada tema do aplicativo. Alto contraste mantém a identidade por acentos, mas remove gradiente e estrelas decorativas. Identificadores desconhecidos recebem `NeutralCourseTheme`, sem assumir a ambientação espacial.

## Componentes

- `DvxGameScaffold`: cabeçalho, fundo do curso e decoração excluída da semântica;
- `DvxGameCard`: superfície e espaçamento consistentes;
- `DvxKeyPrompt`: tecla ou sequência responsiva;
- `DvxFeedback`: espera, acerto, erro e conclusão com cor, ícone, texto e live region;
- `DvxProgressIndicator`: progresso textual e visual;
- `DvxStars`: recompensa com rótulo semântico;
- `DvxThemeSelector`: seleção acessível e persistida dos três temas.

Botões continuam nativos. Seus temas garantem alvos mínimos e borda de foco, mais forte em alto contraste; wrappers sem semântica adicional não foram criados.

## Padrões de tela

O fluxo usa `DvxGameScaffold`, tokens, tema do curso e componentes compartilhados. As diferenças entre fases são de informação e composição, sem duplicar regras do curso:

- Curso: ação principal de começar/continuar, progresso por missões obrigatórias e apresentação expansível.
- Módulo: mapa/lista de missões com estados textuais de disponível, em andamento, concluída e bloqueada; bônus separado do progresso obrigatório.
- Apresentação da missão: ilustração local, narrativa de Stella e instrução de ZERO-1; uma ação principal de começar/continuar. A lista de atividades é secundária.
- Prática: cabeçalho compacto, instrução, alvo, posição/repetição, feedback discreto, ajuda e pausa. Não repetir ilustração da missão, retrato do guia, breadcrumb completo, texto de abertura ou seletor de tema dentro da execução.
- Resultado: conquista e ação seguinte; a lista completa de estatísticas abre no Diário de bordo. Um erro de tecla não produz uma tela de reprovação.
- Conclusão do módulo: cena da cerimônia, conquistas e ação de retorno; sem espaço de digitação avaliado.

Personagens e ilustrações são recursos diferentes no catálogo. `CourseScene` resolve a imagem da cena local, e `CourseJourneyEngine.illustration` não herda a imagem de um ancestral para a prática. Texto e narração compartilham referências canônicas. Imagem não transporta uma instrução que esteja ausente dos canais textual e semântico.

Cores literais e medidas específicas ficam nos componentes/tokens. Botões continuam nativos, com destinos e rótulos explícitos. Áudio, teclado, progressão e persistência permanecem fora dos componentes visuais.

Texto ampliado, foco, contraste e ausência de overflow são verificáveis por testes e inspeção das telas. Validação manual com VoiceOver e TalkBack em dispositivo físico e nos três temas continua pendente; screenshots não comprovam operabilidade com leitores de tela.
