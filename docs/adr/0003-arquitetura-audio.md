# ADR 0003: arquitetura de áudio controlado pelo aplicativo

- Status: aceita
- Data: 2026-09-22

## Contexto

O curso Exploradores Espaciais terá falas gravadas de personagens, narrativa e instruções pedagógicas. O aplicativo também poderá sintetizar informações dinâmicas no futuro. Esses canais pertencem ao Digitavox, mas não substituem Flutter Semantics, VoiceOver ou TalkBack, que tornam a interface operável e compreensível.

A primeira implementação precisa reproduzir um asset local, evitar sobreposição de falas, respeitar o ciclo de vida da tela e continuar funcional quando o áudio falhar. Ela não precisa de streaming, playlists, música, mixagem complexa ou TTS.

## Modelo conceitual

```text
                         Digitavox
              ┌─────────────┼─────────────┐
              │             │             │
        Content Audio   Dynamic Speech   Accessibility
              │             │             │
      assets gravados    TTS futuro      Semantics
      narrativa/efeitos                  VoiceOver/TalkBack
```

- **Content Audio** é conteúdo controlado pelo app: personagens, narrativa, instruções gravadas e futuramente efeitos.
- **Dynamic Speech** será reservado a valores e informações variáveis que não façam sentido pré-gravar. Nenhum TTS foi adicionado agora.
- **Accessibility** permanece independente. Leitores de tela não são players narrativos e áudio do curso não autoriza remover semântica.

## Alternativas consideradas

- `SystemSound`: já atende aos cliques simples de acerto/erro, mas não reproduz assets narrativos nem oferece o ciclo de vida necessário.
- Implementação nativa própria por MethodChannel: daria controle direto, porém duplicaria código iOS/Android e manutenção sem necessidade atual.
- `just_audio`: é maduro e cobre assets, interrupções e sessão por `audio_session`, mas sua superfície inclui streaming, playlists, composição e reprodução avançada além do requisito atual.
- `audioplayers`: oferece player único, assets, play/stop/dispose, eventos de conclusão, configuração de contexto e implementações iOS/Android com uma API menor.

## Decisão

Usar `audioplayers` 6.8.1 atrás de `ContentAudioService`. Somente `AudioplayersContentAudioService`, na infraestrutura, importa o package. O conteúdo armazena apenas `ContentAudioReference` com um caminho sob `assets/audio/`; domínio, ViewModels e widgets não conhecem tipos do player.

`AudioCoordinator` aplica a política inicial de uma fala de conteúdo por vez. Toda nova solicitação interrompe a anterior antes de iniciar, uma entrada válida interrompe a instrução e o descarte da tela solicita parada. O app raiz descarta o coordenador e o player. Não há prioridades, múltiplos canais ou mixer.

Falhas esperadas do plugin, carregamento de asset e timeout são convertidas em `ContentAudioPlaybackException`. O coordenador registra a última falha e mantém o fluxo funcional; erros inesperados não são capturados indiscriminadamente.

## Sessão de áudio

- No iOS, usar `AVAudioSessionCategory.ambient`, que respeita o modo silencioso e permite mistura com outras sessões sem categoria exclusiva.
- No Android, marcar o conteúdo como fala, usar saída de mídia, não solicitar foco de áudio e não manter o dispositivo acordado.
- Usar a rota escolhida pelo sistema, sem forçar alto-falante ou fone.
- Manter o `ReleaseMode.release` padrão, liberando recursos ao concluir, além de `stop` e `dispose` explícitos no ciclo de vida.
- Não adicionar configuração nativa customizada. A coexistência real com leitores de tela deve ser observada antes de escolher ducking, foco ou interrupção de fala.

O plugin declara Swift Package Manager e é resolvido no target gerado do Flutter como `audioplayers_darwin`. Não foram introduzidos Podfile, Podfile.lock ou diretório Pods.

## Detecção de acessibilidade

Flutter expõe `AccessibilityFeatures.accessibleNavigation`, ativado por serviços que alteram o modelo de interação, como VoiceOver e TalkBack. `SystemAccessibilityStatus` encapsula essa leitura. O sinal não é usado para desligar áudio automaticamente e não deve ser tratado como identificação específica ou infalível de um leitor de tela.

## Consequências e limitações

- Conteúdo, coordenação e tecnologia do player evoluem separadamente.
- Um futuro serviço de fala dinâmica poderá ser coordenado no mesmo ponto, sem ser criado antecipadamente nesta feature.
- Instrução visual e semântica continua disponível quando o áudio está silencioso, ausente ou falha.
- `audioplayers` traz implementações federadas e utilitários transitivos, incluindo `path_provider`, `http`, `synchronized` e `uuid`.
- O asset atual é técnico e não define conteúdo pedagógico, personagem ou direção de voz.
- Sobreposição, volume, rota, interrupções e foco ainda precisam de observação em dispositivos físicos com e sem VoiceOver/TalkBack.
