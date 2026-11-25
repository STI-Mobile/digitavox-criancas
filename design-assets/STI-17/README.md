# STI-17 — Produzir kit piloto de áudio da primeira missão

Origem: [STI-17](https://linear.app/acme-mobo/issue/STI-17/produzir-kit-piloto-de-audio-da-primeira-missao) · Coleta: 03/11/2026.

## Arquivos

| Arquivo | Descrição original |
| --- | --- |
| [m1c0-stella.wav](audio/falas/m1c0-stella.wav) | Kit piloto · Stella · abertura da história (26 s) |
| [m1c0-zero1.wav](audio/falas/m1c0-zero1.wav) | Kit piloto · ZERO-1 · instruções gerais (30 s) |
| [m1c1-zero1.wav](audio/falas/m1c1-zero1.wav) | Kit piloto · ZERO-1 · instrução da missão 1, F e J (25 s) |
| [stella-1estrela.wav](audio/falas/stella-1estrela.wav) | Kit piloto · Stella · anúncio de 1 estrela (4,6 s) |
| [zero1-ajuda-erros.wav](audio/falas/zero1-ajuda-erros.wav) | Kit piloto · ZERO-1 · fala após erros consecutivos (16 s) |

## Contexto dos comentários

### 2026-10-19 — Claudia

[Comentário original](https://linear.app/acme-mobo/issue/STI-17/produzir-kit-piloto-de-audio-da-primeira-missao#comment-6fdc8e27)

## Entrega do kit piloto de áudio — 19/10/2026

**Escopo entregue:** 5 assets de fala gravados para a primeira missão real do Módulo 1, cobrindo os três tipos previstos na issue: narrativa de introdução, instrução principal da missão e fala de conclusão. Foram incluídas duas falas adicionais do ZERO-1 (instrução da missão 1 e fala após erros consecutivos) para validar falas curtas durante a prática e o cenário de interrupção. Os arquivos estão anexados nesta issue, em Resources, nomeados pelos IDs canônicos de `audioResources` em `assets/content/exploradores_espaciais.json` (commit `8130b85`).

| Arquivo | ID canônico | Speaker | Duração |
|---|---|---|---|
| `m1c0-stella.wav` | `m1c0-stella` | stella | 26,2 s |
| `m1c0-zero1.wav` | `m1c0-zero1` | zero1 | 30,0 s |
| `m1c1-zero1.wav` | `m1c1-zero1` | zero1 | 24,5 s |
| `zero1-ajuda-erros.wav` | `zero1-ajuda-erros` | zero1 | 15,9 s |
| `stella-1estrela.wav` | `stella-1estrela` | stella | 4,6 s |

**Especificação técnica:** WAV PCM, 44,1 kHz, mono. Geração no ElevenLabs, modelo Eleven v4, com vozes próprias criadas para o projeto (Stella e zero-1). As falas do ZERO-1 passam por um pós-processamento padronizado: pitch ×1,26, modulação em anel a 240 Hz, vibrato, bipes de entrada e saída, time-stretch de 0,85 (fala 15% mais lenta) e normalização de loudness em −18 LUFS. As falas da Stella não têm efeito.

**Textos gravados (fonte de verdade do áudio):**

1. `m1c0-stella`: "Uma tempestade solar varreu a galáxia... e espalhou quinze aliens amigáveis para longe de casa. A Academia Galáctica lançou a Operação Grande Resgate! E toda comunicação espacial passa pelo console de navegação... o teclado! Você chegou à Academia no dia em que a tempestade desligou a nossa nave-escola... a Aurora. Eu sou a Comandante Stella. E preciso de um par de mãos novas. Bem-vindo a bordo, cadete!"
2. `m1c0-zero1`: "Bip! Zero Um na escuta, computador de bordo da Aurora! Digite as teclas... com toques suaves e precisos. Sem força... e sem deixar a tecla pressionada. Se eu apitar... foi tecla errada. Siga em frente! Não tente apagar. E, se precisar de ajuda, tecle... F1. Para eu soletrar o que falta, tecle... F3. E para repetir o exercício, tecle... F7."
3. `m1c1-zero1`: "Bip-bop! Zero Um na escuta! Meus sensores estão... quase acordados. Indicador esquerdo... no F. Indicador direito... no J. Os outros dedos descansam nas teclas vizinhas, da mesma linha. Ninguém fica de fora! Para testar os sensores do console... digite F e J quando eu pedir. Bip!"
4. `zero1-ajuda-erros`: "Bip... bip?! Ops... meus parafusos tremeram! Calma, circuitos... calma. Vamos com calma. Continue sem apagar. Se precisar de ajuda... tecle... F1. Bip-bop!"
5. `stella-1estrela`: "Missão cumprida, cadete. Uma estrela no seu histórico de voo."

**Diferenças em relação ao catálogo:** os itens 1 a 4 diferem do campo `text` atual no JSON. Na gravação, a fala da Stella recebeu pausas e ênfases, e as falas do ZERO-1 receberam o tom cômico definido para o personagem. O item 4 já inclui a troca de "pressione" por "tecle", decidida na revisão do Módulo 1 (STI-27). Para manter legenda e texto alternativo alinhados ao áudio, sugerimos, quando for possível, atualizar o `text` desses quatro recursos com as versões acima. Caso haja alguma restrição técnica, ficamos à disposição para combinar a melhor solução.

**Decisão de personagem:** o ZERO-1 terá sempre tom cômico, de robô simpático e um pouco estranho, que reage aos erros com uma preocupação engraçada e nunca com tom de alarme. Esse padrão vale também para a produção completa (STI-18).

**Licença:** áudios gerados no plano Creator do ElevenLabs, que inclui licença de uso comercial.

**Critérios de aceite:**
- roteiro/texto aprovado antes da gravação: textos revisados e aprovados por Claudia;
- arquivos finais identificados de forma inequívoca: nomes iguais aos IDs canônicos;
- volume e qualidade consistentes: mesmo formato em todos; ZERO-1 normalizado em −18 LUFS;
- licença/autorização de uso definida: plano Creator, uso comercial;
- material para testar reprodução, interrupção, pausa, retomada e repetição: duas falas longas (`m1c0-stella`, `m1c0-zero1`), uma fala curta de interrupção durante a prática (`zero1-ajuda-erros`) e repetição via F7.

**Pendências e limites:** a validação física da reprodução no app continua dependente de STI-13, e o registro de eventuais gaps sonoros fica em STI-14. Efeitos sonoros e música não fazem parte deste kit. As demais falas do Módulo 1 seguem para STI-18.

**Status:** kit entregue para validação. É uma proposta inicial: ajustes de texto, ritmo ou volume podem ser conversados a partir dos testes de integração.
