# STI-19 — Produzir efeitos sonoros e feedbacks de interação

Origem: [STI-19](https://linear.app/acme-mobo/issue/STI-19/produzir-efeitos-sonoros-e-feedbacks-de-interacao) · Coleta: 03/11/2026.

## Arquivos

| Arquivo | Descrição original |
| --- | --- |
| [sfx-asa-dir-on.wav](audio/efeitos/sfx-asa-dir-on.wav) | Missão 1.2 · asa direita (canal direito) · 1,25 s |
| [sfx-asa-esq-on.wav](audio/efeitos/sfx-asa-esq-on.wav) | Missão 1.1 · asa esquerda (canal esquerdo) · 1,25 s |
| [sfx-banco-completo.wav](audio/efeitos/sfx-banco-completo.wav) | Missão 1.5 · banco de energia completo · 1,9 s |
| [sfx-banco-on.wav](audio/efeitos/sfx-banco-on.wav) | Missão 1.4 · banco de energia carregando · 1,2 s |
| [sfx-decolagem.wav](audio/efeitos/sfx-decolagem.wav) | Conclusão do módulo · decolagem da Aurora · 4,0 s |
| [sfx-fanfarra.wav](audio/efeitos/sfx-fanfarra.wav) | Conclusão do módulo · distintivo · 2,8 s |
| [sfx-sensor-on.wav](audio/efeitos/sfx-sensor-on.wav) | Missão 1.0 · sensor liga · 1,1 s |
| [sfx-sincronia.wav](audio/efeitos/sfx-sincronia.wav) | Missão 1.3 · sincronização das asas · 1,9 s |
| [sfx-tecla-incorreta.wav](audio/efeitos/sfx-tecla-incorreta.wav) | audioGuidance.incorrectInput · bip neutro do ZERO-1 · 0,3 s |
| [sfx-transmissao.wav](audio/efeitos/sfx-transmissao.wav) | Missão 1.6 · mensagem para a base · 2,0 s |
| [corrida_A1_calma.mp3](audio/musicas-propostas/corrida_A1_calma.mp3) | Proposta de música · musica-corrida · direção A (calma) · opção 1 |
| [corrida_A2_calma.mp3](audio/musicas-propostas/corrida_A2_calma.mp3) | Proposta de música · musica-corrida · direção A (calma) · opção 2 |
| [corrida_B1_aventura.mp3](audio/musicas-propostas/corrida_B1_aventura.mp3) | Proposta de música · musica-corrida · direção B (aventura) · opção 1 |
| [corrida_B2_aventura.mp3](audio/musicas-propostas/corrida_B2_aventura.mp3) | Proposta de música · musica-corrida · direção B (aventura) · opção 2 |
| [tema_A1_calma.mp3](audio/musicas-propostas/tema_A1_calma.mp3) | Proposta de música · musica-tema · direção A (calma) · opção 1 |
| [tema_A2_calma.mp3](audio/musicas-propostas/tema_A2_calma.mp3) | Proposta de música · musica-tema · direção A (calma) · opção 2 |
| [tema_B1_aventura.mp3](audio/musicas-propostas/tema_B1_aventura.mp3) | Proposta de música · musica-tema · direção B (aventura) · opção 1 |
| [tema_B2_aventura.mp3](audio/musicas-propostas/tema_B2_aventura.mp3) | Proposta de música · musica-tema · direção B (aventura) · opção 2 |
| [alien-blib-blub.wav](audio/vocalizacoes/alien-blib-blub.wav) | Vocalização não verbal · Blib-Blub · 2,0 s |
| [alien-nebulon.wav](audio/vocalizacoes/alien-nebulon.wav) | Vocalização não verbal · Nebulon · 2,5 s |
| [alien-zorp.wav](audio/vocalizacoes/alien-zorp.wav) | Vocalização não verbal · Zorp · 2,0 s |

## Contexto dos comentários

### 2026-10-20 — Claudia

[Comentário original](https://linear.app/acme-mobo/issue/STI-19/produzir-efeitos-sonoros-e-feedbacks-de-interacao#comment-36108970)

## Entrega dos efeitos sonoros do Módulo 1 — 20/10/2026

**Escopo entregue:** 13 arquivos WAV anexados nesta issue (Resources). Eles correspondem aos 13 recursos `type: sfx` declarados em `audioResources` do `assets/content/exploradores_espaciais.json` (commit `8130b85`): 10 efeitos funcionais e narrativos e 3 vocalizações não verbais. Os nomes de arquivo são iguais aos IDs do catálogo, para permitir a substituição direta de `pending: true` e do fallback.

### Mapa evento → asset → função sonora
| ID / arquivo | Evento no catálogo | Função | Duração | Origem |
|---|---|---|---|---|
| `sfx-sensor-on` | `m1-0-despertar` · `audioGuidance.completed` | SFX narrativo | 1,1 s | síntese própria |
| `sfx-asa-esq-on` | `m1-1-asa-esquerda` · `completed` | SFX narrativo, canal esquerdo | 1,25 s | síntese própria |
| `sfx-asa-dir-on` | `m1-2-asa-direita` · `completed` | SFX narrativo, canal direito | 1,25 s | síntese própria |
| `sfx-sincronia` | `m1-3-sincronizacao` · `completed` | SFX narrativo | 1,9 s | síntese própria |
| `sfx-banco-on` | `m1-4-palavras-i` · `completed` | SFX narrativo | 1,2 s | síntese própria |
| `sfx-banco-completo` | `m1-5-palavras-ii` · `completed` | SFX narrativo | 1,9 s | síntese própria |
| `sfx-transmissao` | `m1-6-mensagem` · `completed` | SFX narrativo | 2,0 s | ElevenLabs Sound Effects |
| `sfx-decolagem` | `completionEvent.scene` · cue 1 | SFX de evento | 4,0 s | ElevenLabs Sound Effects |
| `alien-blib-blub` | `completionEvent.scene` · cue 3 | vocalização não verbal | 2,0 s | ElevenLabs Sound Effects |
| `alien-zorp` | `completionEvent.scene` · cue 4 | vocalização não verbal | 2,0 s | ElevenLabs Sound Effects |
| `alien-nebulon` | `completionEvent.scene` · cue 5 | vocalização não verbal | 2,5 s | ElevenLabs Sound Effects |
| `sfx-fanfarra` | `completionEvent.scene` · cue 6 | SFX de conquista | 2,8 s | síntese própria |
| `sfx-tecla-incorreta` | `audioGuidance.incorrectInput` | SFX funcional de erro | 0,3 s | síntese própria |

### Especificação técnica
- **Formato:** WAV PCM, 48 kHz, 24 bits, estéreo (masters sem perdas). Versões de distribuição (MP3/AAC/OGG) podem ser geradas a partir deles conforme o pipeline Flutter/iOS/Android.
- **Volume integrado** (a narração está a −18 LUFS):
  - `sfx-decolagem`: −17 LUFS (evento principal do módulo, toca sem narração sobreposta);
  - aliens: −20 LUFS;
  - demais efeitos: entre −22 e −24 LUFS;
  - `sfx-tecla-incorreta`: −26 LUFS (ocorre com alta frequência).
- **Pico máximo:** −1 dBFS.
- **Filtro passa-alta de 60 Hz** nos arquivos de origem ElevenLabs.
- **Estéreo funcional:** `sfx-asa-esq-on` soa majoritariamente no canal esquerdo e `sfx-asa-dir-on` no direito, em correspondência com as mãos. A informação não depende só disso: as duas asas usam notas diferentes e continuam distinguíveis em mono.

### Direção sonora
- Efeitos de "acender" usam notas ascendentes em escala pentatônica, sem dissonância.
- `sfx-tecla-incorreta` é o "apito" do ZERO-1: dois bips neutros, curtos e sem caráter punitivo.
- Vocalizações alienígenas são não verbais, com timbre de filhote, e não substituem instruções acessíveis.

### Licença e fontes
- **Síntese própria:** gerada por script Python (procedural, sem amostras de terceiros). O script é o arquivo-fonte editável.
- **ElevenLabs Sound Effects:** plano Creator, que permite uso comercial; compartilhamento público das gerações desativado.

### Pendências e limites
- `musica-tema` e `musica-corrida` (`type: music`) ainda não foram produzidas.
- O catálogo não declara SFX de acerto por tecla; hoje só existe `incorrectInput`. A definição pedagógica será alinhada com o professor Paulo antes de incluir ou não esse recurso.
- Ficam para a integração e validação (STI-32/STI-33): mixagem e ducking com narração/TTS, VoiceOver e TalkBack, interrupção, e teste físico em dispositivos.

**Status:** entrega dos 13 SFX para integração, aberta a ajustes.

### 2026-10-25 — Claudia

[Comentário original](https://linear.app/acme-mobo/issue/STI-19/produzir-efeitos-sonoros-e-feedbacks-de-interacao#comment-0c719346)

## Propostas de música do Módulo 1 para avaliação da equipe — 25/10/2026

**Contexto:** faltam as duas faixas `type: music` declaradas em `audioResources` do `assets/content/exploradores_espaciais.json`:

| ID | Onde toca no catálogo |
|---|---|
| `musica-tema` | `scene.narrationCueIds[1]`, na abertura, junto com a fala `m1c0-stella` |
| `musica-corrida` | `modules[0].lessons[8].scene`, no minijogo "Corrida de Energia" |

Antes de fechar a produção, gostaríamos da avaliação de vocês sobre o estilo musical mais adequado ao produto. Por isso anexamos (Resources) duas direções diferentes, com duas opções para cada faixa.

### Opções anexadas
| Arquivo | Faixa | Direção |
|---|---|---|
| `tema_A1_calma.mp3` · `tema_A2_calma.mp3` | `musica-tema` | **A · calma**: instrumentação suave (caixinha de música, celesta, cordas), andamento lento |
| `tema_B1_aventura.mp3` · `tema_B2_aventura.mp3` | `musica-tema` | **B · aventura**: trilha cinematográfica de exploração espacial (sintetizadores, cordas, melodia heroica), andamento médio |
| `corrida_A1_calma.mp3` · `corrida_A2_calma.mp3` | `musica-corrida` | **A · calma**: pulso leve de marimba e pizzicato |
| `corrida_B1_aventura.mp3` · `corrida_B2_aventura.mp3` | `musica-corrida` | **B · aventura**: corrida espacial em estilo arcade moderno (pulso eletrônico, sintetizadores, percussão leve), cerca de 125 BPM |

**Nossa avaliação inicial:** a direção A ficou pouco adequada à faixa etária de 8 a 12 anos, porque soa infantil. A direção B parece mais coerente com a proposta de aventura espacial. Mesmo assim, preferimos ouvir a equipe antes de definir.

### Especificação dos arquivos
- **Prévias para audição:** MP3 192 kbps, 60 s, instrumentais, todas normalizadas em −16 LUFS para comparação justa.
- **Masters:** WAV 48 kHz, guardados na pasta do projeto.
- **Volume na entrega final:** a faixa escolhida será nivelada abaixo da narração (−18 LUFS), para não competir com a voz nem com os efeitos.
- **Geração:** ElevenLabs Music (plano Creator, uso comercial).

### Solicitação
Pedimos que, para cada faixa, a equipe indique uma das opções abaixo:
1. **Uma das opções anexadas**, informando o nome do arquivo.
2. **Uma referência de como a música deveria ser**, caso nenhuma atenda. Pode ser um jogo, um filme ou um link, ou a descrição de estilo, instrumentos, andamento e intensidade.

Também seria útil saber se há alguma restrição técnica para a reprodução das músicas:
- loop contínuo;
- duração mínima ou máxima;
- ducking durante as falas.

**Status:** em avaliação. A produção final das duas faixas segue após a indicação da equipe.
