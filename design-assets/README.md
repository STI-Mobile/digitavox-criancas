# Assets de referência das issues — Digitavox Crianças

Coleta em **03/11/2026** no [projeto do Linear](https://linear.app/acme-mobo/project/digitavox-criancas-5b6be49d7b40), após revisão das descrições, Resources e comentários das **60 issues**, incluindo arquivadas.

Esta pasta reúne os arquivos originais anexados às issues, organizados por identificador e tipo. Os arquivos são referências para integração: propostas, alternativas e versões anteriores preservam seu contexto de origem. O catálogo e os assets em execução no app não foram alterados.

## Inventário

| Issue | Conteúdo | Arquivos |
| --- | --- | ---: |
| [STI-11](https://linear.app/acme-mobo/issue/STI-11/adequar-o-fluxo-inicial-para-entrada-no-primeiro-curso) | Adequar o fluxo inicial para entrada no primeiro curso | 3 |
| [STI-16](https://linear.app/acme-mobo/issue/STI-16/produzir-identidade-visual-minima-do-digitavox-criancas) | Produzir identidade visual mínima do Digitavox Crianças | 11 |
| [STI-17](https://linear.app/acme-mobo/issue/STI-17/produzir-kit-piloto-de-audio-da-primeira-missao) | Produzir kit piloto de áudio da primeira missão | 5 |
| [STI-19](https://linear.app/acme-mobo/issue/STI-19/produzir-efeitos-sonoros-e-feedbacks-de-interacao) | Produzir efeitos sonoros e feedbacks de interação | 21 |
| [STI-20](https://linear.app/acme-mobo/issue/STI-20/produzir-assets-visuais-do-universo-exploradores-espaciais) | Produzir assets visuais do universo Exploradores Espaciais | 72 |
| [STI-27](https://linear.app/acme-mobo/issue/STI-27/consolidar-conteudo-pedagogico-do-modulo-1-a-nave-adormecida) | Consolidar conteúdo pedagógico do Módulo 1 · A Nave Adormecida | 1 |

Total: **113 arquivos** — 84 imagens (incluindo SVG), 26 áudios e 3 referências HTML/JSON.

`manifest.json` associa cada arquivo à issue e, quando disponível, ao comentário/anexo de origem, além de tamanho, SHA-256, formato, dimensões ou duração. `SHA256SUMS` permite conferir a integridade com `shasum -a 256 -c SHA256SUMS` a partir desta pasta. URLs de upload são registradas sem assinaturas temporárias; para novo download, abra a issue autenticada ou solicite uma URL atualizada ao Linear.

## Contexto de aprovação e versões

- **STI-16:** três conceitos de ícone e mockup para escolha da equipe; as duas imagens do comentário de Yuri são propostas de combinação. A paleta e os tokens estão em `referencias/`.
- **STI-17:** cinco falas do kit piloto, entregues para validação. Os textos e condições de uso estão no README da issue.
- **STI-19:** 13 SFX/vocalizações entregues para integração; oito músicas de 60 s são propostas, ainda sujeitas à escolha da equipe. Masters WAV das músicas citados nos comentários não estão anexados e não fazem parte desta coleta.
- **STI-20:** 72 imagens: personagens e expressões, Aurora transparente, aliens, 24 cenas e prévias. `historico-2026-10-19/` preserva dez imagens anteriores, incluindo personagens com fundo preto e estudos de composição. A versão transparente da Aurora fica em `imagens/aurora/`. A conferência no Safari autenticado permitiu incluir os 22 anexos que ultrapassam o limite de 50 retornado pelo conector.
- **STI-11:** capturas de referência da implementação, separadas das ilustrações.
- **STI-27:** revisão pedagógica HTML, mantida como referência para os áudios.

Licenças e aprovações devem ser conferidas na origem. Os comentários de STI-17/STI-19 declaram uso comercial pelo plano Creator do ElevenLabs; os SFX procedurais são descritos como síntese própria. Essa declaração não estende automaticamente a licença do código a todos os assets.

Issues sem mídia anexada não recebem diretórios vazios. Material apenas mencionado, ainda não produzido ou não anexado não foi substituído por placeholders. O documento DOCX sobre CI/CD da STI-54 está fora do escopo de som/imagem e foi excluído.
