# STI-16 — Produzir identidade visual mínima do Digitavox Crianças

Origem: [STI-16](https://linear.app/acme-mobo/issue/STI-16/produzir-identidade-visual-minima-do-digitavox-criancas) · Coleta: 03/11/2026.

## Arquivos

| Arquivo | Descrição original |
| --- | --- |
| [44a5a49a-ae40-4ff2-82aa-198bb33ce549.png](imagens/44a5a49a-ae40-4ff2-82aa-198bb33ce549.png) | 44a5a49a-ae40-4ff2-82aa-198bb33ce549.png |
| [c617d697-ae43-4879-aba6-1ee56e4ad94b.jpeg](imagens/c617d697-ae43-4879-aba6-1ee56e4ad94b.jpeg) | c617d697-ae43-4879-aba6-1ee56e4ad94b.jpeg |
| [icone_A_aurora.png](imagens/icone_A_aurora.png) | Conceito A · Nave Aurora · 1024×1024 |
| [icone_A_aurora.svg](imagens/icone_A_aurora.svg) | Arquivo-fonte vetorial · conceito A |
| [icone_B_tecla.png](imagens/icone_B_tecla.png) | Conceito B · Tecla com estrela · 1024×1024 |
| [icone_B_tecla.svg](imagens/icone_B_tecla.svg) | Arquivo-fonte vetorial · conceito B |
| [icone_C_zero1.png](imagens/icone_C_zero1.png) | Conceito C · ZERO-1 · 1024×1024 |
| [icone_C_zero1.svg](imagens/icone_C_zero1.svg) | Arquivo-fonte vetorial · conceito C |
| [icones_conceitos_mockup.jpg](imagens/icones_conceitos_mockup.jpg) | Simulação · iPhone, Android (máscara circular) e splash |
| [digitavox_identidade_tokens.json](referencias/digitavox_identidade_tokens.json) | Tokens da identidade visual (JSON) |
| [digitavox_identidade_visual.html](referencias/digitavox_identidade_visual.html) | Proposta de identidade visual · Paleta Vinho Estelar (HTML) |

## Contexto dos comentários

### 2026-10-17 — Claudia

[Comentário original](https://linear.app/acme-mobo/issue/STI-16/produzir-identidade-visual-minima-do-digitavox-criancas#comment-9331f347)

**Proposta de identidade visual (17/10/2026)**

Esta é uma sugestão para o app e está aberta a conversa: se algo não funcionar do lado de vocês (cores, fontes, contraste em algum dispositivo), podemos conversar e ajustar juntos.

Anexei dois arquivos nesta tarefa (Resources):
- `digitavox_identidade_tokens.json`: os valores para o código (cores dos três modos, fontes e regras)
- `digitavox_identidade_visual.html`: a página visual com a tela de exemplo da Missão 1.5 nos modos escuro e claro e o contraste de cada cor

**Paleta sugerida: "Vinho Estelar"**
- Escuro (padrão): fundo #2B0B1E · painel/teclas #4A1634 · texto #FFF6EC · tecla-alvo/estrelas #FFC42E · acerto #3DF2FF · erro #FF9F43
- Claro: fundo #FFF4F7 · painel #F6D9E3 · texto #2B0B1E · tecla-alvo #FFC42E com contorno #2B0B1E · acerto #00707F · erro #B34700
- Alto contraste: fundo #000000, texto #FFFFFF, destaque #FFFF00

Todas as combinações de texto passam em WCAG AA; texto, tecla-alvo e acerto no escuro chegam a AAA.

**Fontes sugeridas:** Open Sans no texto (a que já está no app) e Fredoka nos títulos.

**Personagens:** uniforme vinho da Stella; aliens em desenho chapado; o segundo alien do hangar é o Zorp (com Blib-Blub e Nebulon); o Comandante não entra no Módulo 1.

Ainda faltam nesta tarefa o ícone do app e a tela de abertura, que vou produzir a partir desta paleta.

### 2026-10-25 — Claudia

[Comentário original](https://linear.app/acme-mobo/issue/STI-16/produzir-identidade-visual-minima-do-digitavox-criancas#comment-af240d93)

## Conceitos de ícone e splash para escolha da equipe — 25/10/2026

**Contexto:** para concluir a STI-16, faltam o ícone principal do aplicativo e a definição da splash/launch screen. Propomos três conceitos de ícone e pedimos que a equipe indique qual seguir. Após a escolha, produziremos as exportações finais para Android e iOS.

### Anexos (Resources)
| Arquivo | Conteúdo |
|---|---|
| `icone_A_aurora.png` · `.svg` | **Conceito A · Nave Aurora**: a nave-escola em vista frontal simplificada, com as cores da Aurora aprovada (branco, azul-marinho, vinho, ciano) e estrela dourada |
| `icone_B_tecla.png` · `.svg` | **Conceito B · Tecla com estrela**: tecla vinho com contorno dourado, estrela central e marcação tátil ciano, em referência às saliências de F e J usadas na orientação no teclado |
| `icone_C_zero1.png` · `.svg` | **Conceito C · ZERO-1**: rosto simplificado do computador de bordo |
| `icones_conceitos_mockup.jpg` | Simulação dos três conceitos em tamanho real numa tela inicial de iPhone, numa de Android (máscara circular) e na splash |

### Especificação dos conceitos
- **Formato:** PNG 1024 × 1024 para visualização, e SVG vetorial como arquivo-fonte editável.
- **Paleta Vinho Estelar:** fundo #2B0B1E com gradiente para #5A1A3F, dourado #FFC42E, ciano #3DF2FF e texto/estrelas #FFF6EC.
- **Desenho:** chapado, sem texto embutido e sem sombras prontas, com elementos centrais dentro da área segura do ícone adaptativo do Android (66 dp em 108 dp).
- **Leitura em tamanho reduzido:** na simulação, os conceitos B e C mantêm melhor a forma em tamanho real. O conceito A perde detalhes, como as luzes e a cabine.

### Splash / launch screen
A proposta segue o comportamento padrão da Splash Screen API (Android 12 ou superior) e da launch screen do iOS:
- fundo sólido #2B0B1E;
- ícone escolhido centralizado (240 × 240 dp, dentro do círculo de 160 dp);
- sem imagem de marca inferior e sem texto;
- animação opcional, com até 1.000 ms, se a equipe considerar adequado.

### Entregas após a escolha
- **Android:** camadas `foreground` e `background` do adaptive icon em vetor, camada `monochrome` para ícones temáticos (Android 13 ou superior) e ícone da Google Play em 512 × 512 PNG.
- **iOS:** ícone 1024 × 1024, com variantes para os modos claro, escuro e tingido.
- **Splash:** asset vetorial do ícone para `windowSplashScreenAnimatedIcon` e cor de fundo para `windowSplashScreenBackground`.
- **Documentação:** nomes de arquivo e organização prontos para incorporação ao repositório.

### Solicitação
Pedimos que a equipe indique **um dos conceitos (A, B ou C)**, ou uma combinação de elementos entre eles. Também são bem-vindas observações sobre restrições técnicas no pipeline atual de ícones (por exemplo, uso de `flutter_launcher_icons` / `flutter_native_splash`) que devamos considerar nas exportações.

**Status:** em avaliação. As exportações finais seguem após a indicação da equipe.

### 2026-10-26 — Yuri Dirickson

[Comentário original](https://linear.app/acme-mobo/issue/STI-16/produzir-identidade-visual-minima-do-digitavox-criancas#comment-addfd20d)

@claudia.mori sobre o ícone de celular, nos fez falta a alusão ao teclado que o original tem, aí peguei ambos o ícone original e o seu e pedi uma mescla para o Gemini. Dá uma olhada no que você acha… eu tenho a impressão que ainda está muito carregado de cores, mas dado que é uma espécie de jogo, talvez seja o caminho

![c617d697-ae43-4879-aba6-1ee56e4ad94b.jpeg](https://uploads.linear.app/28dc51e8-b13a-4548-82c8-4c2eb50e41d8/b5233b08-d261-4d4d-9e12-fa39a209636c/5286f3d0-6ebb-458d-8a59-3599384b4c0f)

![44a5a49a-ae40-4ff2-82aa-198bb33ce549.png](https://uploads.linear.app/28dc51e8-b13a-4548-82c8-4c2eb50e41d8/95dfa27b-aecc-4090-be78-c68d46a89352/47208a62-8d44-4d76-b74b-911072366e3d)
