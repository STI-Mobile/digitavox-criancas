# ADR 0004: engine de jornada guiado pelo catálogo

- Status: aceita
- Data: 2026-09-23

## Contexto

A lista plana de exercícios não comunica a estrutura do curso e exige voltar à lista para continuar. A jornada deve seguir a ordem do JSON e selecionar narrativa e personagem por etapa, sem colocar regras de progressão em widgets.

## Decisão

Adicionar `CourseJourneyEngine` na aplicação. Ele interpreta o catálogo validado, mantém a localização curso/módulo/lição/exercício, calcula retomada e próximos destinos, verifica disponibilidade e cria/descarta a sessão de exercício. O catálogo e `ProgressRepository` continuam responsáveis pelo progresso; o avaliador existente continua responsável pela resposta. Widgets renderizam estado e enviam comandos ao engine.

As cenas opcionais (`scene`) contêm texto, áudio gravado e referência a personagem. Personagens são definidos em `course.characters`, com imagem local e descrição acessível. Referências são validadas antes de abrir o curso. A imagem herda a referência do ancestral mais próximo; áudio e texto pertencem apenas à etapa atual. O áudio legado do exercício continua aceito.

Toda transição descarta a sessão antiga antes de solicitar a nova narrativa ao `AudioCoordinator`. O widget de exercício não possui nem descarta a sessão. Isso evita que o descarte atrasado de um widget interrompa o áudio da próxima etapa. A entrada válida continua interrompendo a narração. Navegação rápida aproveita o cancelamento de solicitações obsoletas já existente no coordenador. Saída para segundo plano interrompe o áudio, sem reinício automático.

O avanço é automático entre exercícios executáveis da mesma lição, depois que todas as repetições definidas pelo conteúdo terminam. Entre lições, o engine apresenta a introdução da próxima lição e aguarda uma ação explícita. Tipos ainda sem executor ficam visíveis como indisponíveis e não recebem conclusão. Todas as lições permanecem consultáveis pela hierarquia, inclusive as sem atividades executáveis. A retomada usa o progresso salvo e não toca narrativas de etapas que não foram abertas.

O executor textual cobre `key`, `keySequence`, `word` e `phrase`. Ele consome uma posição mesmo quando a tecla está errada, preserva estatísticas da sessão e expõe os atalhos de consulta F1–F9 e setas adotados pelo Digitavox adulto. O JSON determina texto, repetições, ordem, cenas, áudio e personagens. A camada de apresentação apenas encaminha teclas e renderiza o estado.

## Consequências

- Conteúdo e ordem podem mudar no JSON sem alterar telas ou engine.
- O schema 2 recebe campos opcionais compatíveis; não há mudança no formato persistido.
- Não há interpretação de scripts, roteador externo, TTS, importação remota nem novas dependências.
- JSON Schema documenta a estrutura; o parser Dart valida também referências e IDs.
- Imagem/áudio ausentes não bloqueiam navegação, avaliação ou persistência.
- A UI sinaliza localização e posição, usa controles nativos e textos de estado. O retorno do sistema percorre a hierarquia pelo estado do engine.
- Ao entrar em exercício, o foco de teclado vai à área de entrada. Nas outras etapas, a ordem segue a leitura. A etapa tem um escopo semântico nomeado para comunicar contexto aos leitores de tela.
- Testes com VoiceOver/TalkBack e reprodução física continuam necessários antes de validar a experiência final.
