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

A preferência `AppThemePreference` integra `AppSettings`. `CourseCatalogViewModel.updateThemePreference` atualiza o mesmo `ProgressRepository` utilizado pelo progresso. O documento persistido está no schema 2; documentos schema 1 são migrados ao carregar (`highContrastEnabled` vira a preferência correspondente).

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

## Migração atual

O fluxo de curso, módulo, lição e exercício usa `DvxGameScaffold`, tokens, tema do curso e componentes compartilhados. Cores literais e `TextStyle` com tamanhos próprios permanecem somente dentro da implementação do Design System. Áudio narrativo, teclado físico, engine, persistência de progresso e semântica existente não foram movidos para componentes visuais.

Validação manual com VoiceOver e TalkBack, em dispositivo físico e nos três temas, continua necessária antes de considerar a experiência pedagógica aprovada.
