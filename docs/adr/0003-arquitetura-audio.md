# ADR 0003: arquitetura de Audio Guidance

- Status: aceita
- Data: 2026-09-22
- Atualizada: 2026-09-24

## Contexto

O aplicativo precisa executar fala gravada, TTS nativo, efeitos e música sem acoplar o Course Engine, ViewModels ou widgets a players e APIs de plataforma. O áudio controlado pelo aplicativo também não substitui Flutter Semantics, VoiceOver ou TalkBack.

O conteúdo deve declarar intenção e ordem. A aplicação traduz eventos da jornada em cues genéricos. A infraestrutura escolhe e opera o mecanismo físico de reprodução. Falhas de áudio não podem impedir teclado, avaliação, conclusão, progresso ou acessibilidade.

## Decisão

Adotar um único fluxo de áudio de curso:

```text
Course Content
      │
      ▼
Course Engine
      │
      ▼
CourseAudioOrchestrator
      │ AudioCue
      ▼
AudioGuidance
      │
      ▼
AudioGuidanceCoordinator
      │
 ┌────┼────┐
 ▼    ▼    ▼
Speech SFX Music
      │
      ▼
Platform Audio
```

Course decides WHAT and WHEN. CourseAudioOrchestrator translates course events into AudioCue. AudioGuidance decides HOW.

O conteúdo usa exclusivamente `audioGuidance`, organizado pelos eventos `start`, `correctInput`, `incorrectInput` e `completed`. Cada evento contém uma sequência ordenada de `speech`, `sfx` e `music`. Speech aceita texto, asset opcional e speaker opcional; SFX e Music exigem asset. O conteúdo não declara engine TTS, voz nativa, player ou política de plataforma.

`CourseJourneyEngine` seleciona o evento e a configuração da etapa. `CourseAudioOrchestrator` resolve `ContentAudioCue` em `AudioCue` e chama apenas o contrato `AudioGuidance`. `AudioGuidanceCoordinator` coordena sequência, cancelamento e fallback asset → TTS. O composition root injeta as implementações concretas.

## Infraestrutura e sessão de áudio

- `audioplayers` fica restrito a `AudioplayersGuidancePlayer`, usado internamente para fala gravada, SFX e Music.
- TTS usa `AVSpeechSynthesizer` no iOS e Android `TextToSpeech`, encapsulados por `PlatformTextToSpeechService` e seu MethodChannel.
- O iOS usa `AVAudioSessionCategory.ambient`, respeitando o modo silencioso e permitindo mistura sem categoria exclusiva.
- O Android usa saída de mídia e não mantém o dispositivo acordado.
- A rota é escolhida pelo sistema; não se força alto-falante ou fone.
- Swift Package Manager permanece como gerenciador nativo Apple; não há CocoaPods.

O `generation token` do coordenador impede continuações de uma sequência cancelada. O engine possui uma geração local para impedir que uma troca rápida de atividade inicie uma solicitação já obsoleta. Suspensão, saída da atividade e descarte cancelam a sequência.

## Acessibilidade

Semantics e leitores de tela permanecem independentes da narração controlada pelo app. Informação necessária à operação continua disponível visualmente e na árvore semântica mesmo quando o áudio está ausente, silencioso ou falha. Coexistência, foco, ducking e interrupções precisam de validação manual com VoiceOver e TalkBack em dispositivos físicos.

## Consequências

- Domínio e conteúdo descrevem intenção, sem conhecer tecnologia de reprodução.
- Engine, sessão, ViewModels e widgets não importam players ou APIs TTS.
- Texto visual e texto falado podem divergir sem acoplamento.
- Um único coordenador aplica sequência e cancelamento para os canais de áudio.
- Falhas esperadas são contidas na fronteira de Audio Guidance e não bloqueiam a jornada.
- O Demo Course técnico valida asset, TTS, fallback, SFX, sequência e lifecycle sem definir pedagogia.
- Prioridade avançada, mixer, foco e política de coexistência permanecem decisões futuras baseadas em testes reais.
