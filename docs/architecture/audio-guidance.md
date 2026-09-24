# Audio Guidance

## Objetivo

Audio Guidance é a infraestrutura genérica responsável por executar unidades de áudio fornecidas por qualquer consumidor. Ela não interpreta conteúdo, estado de exercício nem progressão.

> Course decides WHAT and WHEN.
> Audio Guidance decides HOW.

```text
                 Consumer
                    │
                    ▼
                 AudioCue
                    │
                    ▼
          AudioGuidanceCoordinator
             /       |       \
            /        |        \
        Speech      SFX      Music
           │
        ┌──┴──┐
        ▼     ▼
      Asset   TTS
```

## Arquitetura e cues

`AudioCue` é uma classe selada da camada de aplicação. Seus três tipos permitem despacho seguro sem expor plugins:

- `SpeechCue`: possui `id`, texto, asset opcional e `speaker` opcional. `speaker` é metadata opaca e não altera a reprodução.
- `SfxCue`: possui `id` e asset. Efeitos nunca usam TTS.
- `MusicCue`: possui `id` e asset e usa uma fronteira diferente de SFX.

O `AudioGuidanceCoordinator` recebe `TextToSpeechService`, `AssetAudioPlayer`, `SfxPlayer` e `MusicPlayer` por injeção. Ele é o único ponto que escolhe como executar cada cue. A raiz de composição cria implementações concretas independentes; testes fornecem fakes e não acessam áudio real.

## Speech e fallback Asset → TTS

Fala gravada é a primeira opção. Quando um `SpeechCue` possui `audioAsset`, o coordenador aguarda a reprodução terminar. Se o player comunicar uma falha controlada e existir texto não vazio, o coordenador inicializa o TTS e fala o texto. Um cue apenas textual vai diretamente para TTS. Asset indisponível sem texto resulta em `InvalidAudioCueException`.

Essa política existe somente no coordenador. Consumidores não consultam o asset nem implementam fallback.

O TTS usa as APIs dos sistemas operacionais por um `MethodChannel` encapsulado em `PlatformTextToSpeechService`:

- Android 24+: `android.speech.tts.TextToSpeech`;
- iOS 13+: `AVSpeechSynthesizer`.

Não foi adicionada dependência. A implementação nativa preserva Swift Package Manager no iOS; `flutter_tts` não foi adotado porque a versão avaliada não oferece integração SwiftPM. Idioma, velocidade, tom, volume e identificador opcional de voz ficam centralizados em `SpeechConfiguration`, com `pt-BR` como idioma padrão.

## SFX e Music

SFX usa exclusivamente `SfxPlayer`. Uma falha é propagada como `AudioServiceException` e nunca aciona TTS.

Music possui operações básicas de reprodução, pausa, volume e parada por meio de `MusicPlayer`. A implementação inicial reutiliza a tecnologia de assets, mas recebe uma instância própria. Não há playlists, crossfade ou mixagem avançada.

Volumes iniciais estão centralizados em `AudioGuidanceConfiguration`. Eles não representam preferências de um curso.

## Sequenciamento e concorrência

`playSequence` valida todos os cues e os executa estritamente em ordem. Cada serviço completa seu `Future` somente quando a reprodução termina ou é interrompida; por isso, o cue seguinte não começa simultaneamente.

O coordenador usa uma geração monotônica como token simples de cancelamento:

- `play` substitui a execução anterior;
- `stop` interrompe os players e invalida continuações pendentes;
- `cancelSequence` faz o mesmo e registra `audio_sequence_cancelled`;
- uma nova sequência recebe outra geração;
- callbacks de uma geração antiga não iniciam cues posteriores.

Não existe scheduler ou fila global. A semântica é deliberadamente determinística: um novo comando de reprodução substitui o anterior.

## Lifecycle

`dispose` invalida a geração corrente, interrompe os quatro canais, libera players, TTS e subscriptions e é idempotente. Depois disso, `play` e `playSequence` lançam `AudioGuidanceDisposedException`; `stop` e `cancelSequence` não iniciam trabalho novo. O ponto de composição mantém a propriedade e o descarte do coordenador. O curso o consome somente pelo contrato `AudioGuidance`, através do `CourseAudioOrchestrator`; consulte [Integração entre Course Engine e Audio Guidance](course-audio-integration.md).

## Erros e logging

Falhas técnicas dos adaptadores são convertidas em `AudioServiceException`. A exceção de asset de fala é recuperável quando há texto; falhas de SFX, Music ou TTS são propagadas. Cues estruturalmente inválidos falham antes de tocar áudio.

O logger recebe apenas eventos técnicos, como `audio_asset_failed`, `audio_tts_fallback`, `audio_sequence_cancelled` e `audio_service_unavailable`. Texto falado, conteúdo e dados pessoais não são registrados.

## Extensões futuras

A separação entre Speech, SFX e Music permite acrescentar posteriormente, sem implementação antecipada:

- ducking de música durante fala;
- mixagem e prioridades avançadas;
- múltiplas vozes e processamento de voz;
- TTS neural;
- cache e streaming;
- download de pacotes e áudio remoto;
- crossfade e spatial audio.

Essas evoluções devem permanecer genéricas. A orquestração de conteúdo continuará fora do Audio Guidance.
