# Integração entre Course Engine e Audio Guidance

## Objetivo e fronteiras

Esta integração prova que conteúdo declarativo pode produzir áudio durante a jornada sem expor plugins ao domínio, ao engine ou aos ViewModels.

```text
Course Content
      │
      ▼
Course Engine
      │
      │ state/events
      ▼
Course Audio Orchestration
      │
      │ AudioCue
      ▼
Audio Guidance
      │
      ▼
Audio Guidance Coordinator
      │
 ┌────┼────┐
 ▼    ▼    ▼
Speech SFX Music
      │
      ▼
Platform Audio
```

> Course decides WHAT and WHEN. CourseAudioOrchestrator translates course events into AudioCue. AudioGuidance decides HOW.

> Demo validates architecture. Demo does not define pedagogy.

O `CourseJourneyEngine` conhece estado, navegação e eventos. O `CourseAudioOrchestrator` conhece a configuração sonora declarada e a converte em cues. O contrato `AudioGuidance` executa esses cues. Somente a infraestrutura concreta conhece `audioplayers`, `AVSpeechSynthesizer` e Android `TextToSpeech`.

## Declaração pelo conteúdo

Curso, módulo, lição, exercício e cena podem declarar `audioGuidance`. Cada evento contém uma lista ordenada de intenções:

```json
"audioGuidance": {
  "start": [
    {
      "id": "test-instruction",
      "type": "speech",
      "text": "Pressione a tecla A.",
      "asset": "assets/audio/demo/instruction_a_demo.wav",
      "speaker": "demo-speaker"
    }
  ],
  "incorrectInput": [
    {
      "id": "test-incorrect",
      "type": "sfx",
      "asset": "assets/audio/demo/technical_signal_demo.wav"
    }
  ]
}
```

Eventos suportados nesta etapa:

- `start`: entrada na etapa ou repetição manual da instrução;
- `correctInput`: input avaliado como correto;
- `incorrectInput`: input avaliado como incorreto;
- `completed`: conclusão persistida do exercício.

`speech` aceita texto, asset opcional e speaker opcional. `sfx` e `music` exigem asset e não aceitam texto. O array preserva a ordem de uma sequência. O `prompt` visual continua independente de `audioGuidance.start[].text`.

## Course Audio Orchestration

`CourseAudioOrchestrator.resolve` transforma `ContentAudioCue` em `SpeechCue`, `SfxCue` ou `MusicCue`. `play` envia a lista completa a `AudioGuidance.playSequence`; um evento sem configuração interrompe áudio anterior e não inventa feedback. Falhas controladas de Audio Guidance são contidas para não impedir input, conclusão ou persistência.

`ExerciseSessionViewModel` apenas informa `onInputEvaluated(bool)` e `onCompleted()`. Ele não armazena fala, não constrói cues e não importa Audio Guidance. O engine escolhe o evento e entrega a configuração corrente ao orquestrador.

## Lifecycle e cancelamento

Cada mudança de localização incrementa um token local do engine, chama `cancelSequence()` e só inicia a nova instrução se a localização ainda for atual. Isso fecha a janela assíncrona entre cancelar a etapa A e iniciar a etapa B. Saída, Escape, botão voltar, suspensão do app e descarte também interrompem o canal.

O generation token interno de Audio Guidance não foi alterado. Ele continua responsável por impedir continuações obsoletas dentro da reprodução; o token do engine protege apenas a troca de contexto do curso.

## Demo Course

`assets/content/integration_demo_course.json` é um harness técnico com um módulo e três lições:

1. tecla A: fala com asset válido, texto de fallback e speaker técnico;
2. tecla F: asset propositalmente inexistente com texto para validar fallback TTS;
3. sequência AF: fala somente textual e conclusão Speech → SFX → Speech.

Todos os textos são neutros. O sinal WAV não contém voz. Não existem personagens, narrativa, ajuda pedagógica, recompensas ou regras específicas de curso na configuração.

`DevelopmentCourseCatalog` envolve o mesmo `AssetCourseCatalog` usado por qualquer conteúdo. A composição passa `kDebugMode`: debug carrega a demo; release retorna lista vazia. Não há flavor ou sistema de feature flags adicional, e o mesmo parser, engine, ViewModels, repositório de progresso e telas continuam sendo usados.

## Testes

Testes unitários verificam resolução de Speech, asset + texto, texto sem asset, SFX, ausência de configuração, ordem da sequência, separação visual/falada e propagação de speaker. O catálogo condicional prova que a fonte nem é consultada quando a demo está desabilitada.

O teste de widget carrega o JSON real, navega pelo engine, envia teclas e observa um `RecordingAudioGuidance`. Ele cobre início, instrução, input correto, input incorreto, conclusão sequencial e cancelamento ao sair, sem reproduzir áudio real.

## Roteiro manual

Em um iPhone real e em um Android real:

1. execute um build debug e abra **Demo de Integração**;
2. confirme a fala “Teste de início”;
3. inicie o primeiro teste e confirme a instrução da tecla A pelo asset gravado;
4. pressione A e confirme o feedback correto e a conclusão;
5. inicie o segundo teste e confirme que o asset ausente usa TTS para a tecla F;
6. pressione uma tecla diferente de F e confirme o SFX técnico sem bloqueio da jornada;
7. inicie o teste AF e confirme a instrução somente por TTS;
8. saia pelo botão voltar durante uma fala e confirme que ela é interrompida;
9. reabra o teste, pressione A e F e confirme Speech → SFX → Speech na conclusão;
10. troque rapidamente entre lição e exercício e confirme que nenhuma fala anterior reaparece;
11. faça um build release e confirme que o catálogo não apresenta a demo.

VoiceOver e TalkBack podem permanecer ativos para validar a árvore semântica, mas não substituem nem controlam a narração desta demo.

## Extensões futuras

Cursos reais poderão reutilizar os mesmos eventos e cues depois de validação própria. Permanecem fora desta etapa: texto pedagógico, personagens, regras de ajuda, pronúncia completa de teclas, recompensas, estatísticas narradas, prioridades avançadas, Music no fluxo e definição de quando feedback por input deve ser falado em conteúdo oficial.
