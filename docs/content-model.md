# Modelo de conteúdo

O conteúdo segue a hierarquia:

```text
Course → Module → Lesson → Exercise
```

O catálogo JSON possui `schemaVersion`; cada curso tem identificador estável, versão, indicação explícita de demo e módulos. IDs devem ser únicos entre irmãos. Listas estruturais não podem ser vazias.

Um exercício contém `id`, `title`, `type` e `prompt`. O schema 2 exige também `expectedInput` para exercícios do tipo `key`; nesse tipo ele deve representar exatamente um caractere imprimível. Outros tipos podem carregar entradas textuais maiores. Os identificadores reconhecidos são `key`, `keySequence`, `word`, `phrase`, `timed`, `repetition` e `challenge`. `key`, `keySequence`, `word` e `phrase` possuem fluxo funcional quando `expectedInput` não está vazio; os demais permanecem desabilitados. Campos opcionais atuais são `minimumRepetitions`, `timeLimitSeconds`, `audio` e `scene`.

O contrato legível por ferramentas está em [course.schema.json](course.schema.json). O parser Dart continua sendo a validação em execução e verifica também unicidade de IDs e referências de personagens, restrições que o JSON Schema não expressa sozinho. Propriedades adicionais são toleradas para compatibilidade; elas não viram comandos executáveis.

`audio` referencia conteúdo gravado controlado pelo Digitavox sem expor tecnologia de player. Quando presente, deve ser um objeto com `asset` textual, não vazio, sem travessia de diretório e sob `assets/audio/`:

```json
"audio": {
  "asset": "assets/audio/demo/instruction_a_demo.wav"
}
```

A ausência do campo continua válida. A existência física do asset é verificada pelo bundle/player; uma falha de reprodução não invalida os canais visual, semântico ou de teclado. Assets em `assets/audio/demo/` são técnicos e não constituem conteúdo pedagógico aprovado.

Exemplo reduzido:

```json
{
  "schemaVersion": 2,
  "courses": [
    {
      "id": "demo-course",
      "title": "Curso demo",
      "version": "0.2.0-demo",
      "isDemo": true,
      "modules": [
        {
          "id": "demo-module",
          "title": "Módulo demo",
          "lessons": [
            {
              "id": "demo-lesson",
              "title": "Lição demo",
              "exercises": [
                {
                  "id": "demo-key-a",
                  "title": "Pressionar a tecla A",
                  "type": "key",
                  "prompt": "Pressione a tecla A no teclado físico.",
                  "expectedInput": "a",
                  "audio": {
                    "asset": "assets/audio/demo/instruction_a_demo.wav"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

O exemplo é apenas ilustrativo e continua sendo conteúdo técnico, não pedagogia aprovada. A fixture executável está em `assets/content/demo_course.json`.

## Evolução e pacotes externos

### Jornada e cenas

`CourseJourneyEngine` percorre módulos, lições e exercícios na ordem dos arrays do JSON. IDs identificam progresso; não definem a ordem. A navegação apresenta curso → módulo → lição → exercício, com retorno ao pai. A retomada abre o primeiro exercício disponível ainda não concluído. Ao terminar as repetições, o engine abre automaticamente o próximo exercício da mesma lição; ao mudar de lição, para em sua introdução antes de iniciar a nova atividade.

### Dinâmica do exercício

O comportamento segue a dinâmica observada no Digitavox adulto, sem reutilizar sua implementação:

- cada caractere digitado consome a posição atual, esteja certo ou errado;
- o erro informa a tecla recebida e a esperada, toca o feedback sonoro e segue para a próxima posição;
- quatro erros consecutivos acrescentam a orientação para seta à direita ou F1; um acerto zera essa contagem;
- ao terminar `expectedInput`, começa automaticamente a próxima de `minimumRepetitions` repetições; sem o campo, há uma repetição;
- ao terminar a última repetição, persiste a conclusão e o engine avança conforme a estrutura do catálogo;
- acertos, erros, percentual e tempo pertencem à sessão e não alteram o contrato persistido atual.

O app adulto acrescenta um espaço separador ao final de cada exercício. O app infantil não cria esse caractere implicitamente: o conteúdo executado é exatamente `expectedInput`, de modo que o JSON permaneça a fonte explícita da jornada.

Durante o exercício, F1 abre a ajuda; F2/seta para baixo informa a próxima tecla; F3/Control + seta para direita soletra o restante; F4/seta para direita informa o restante; F5/seta para cima repete a instrução; F6/Control + seta para cima informa a apresentação da lição; F7/Control + seta para baixo informa a instrução; F8 informa a hora; F9 informa tempo e acertos; seta para esquerda informa a repetição; Control + seta para esquerda informa o percentual. Escape volta um nível em qualquer etapa da jornada. Os resultados são sempre expostos visualmente e em região semântica viva. Áudio gravado continua passando pelo `AudioCoordinator`; atalhos dinâmicos não introduzem TTS.

Curso, módulo, lição e exercício podem declarar uma `scene`:

```json
"scene": {
  "text": "Encontre as marcas das teclas F e J.",
  "characterId": "aurora",
  "audio": { "asset": "assets/audio/demo/sensors.wav" }
}
```

O texto é obrigatório e mantém a narrativa acessível sem som. `characterId` e `audio` são opcionais. Cada cena reproduz somente seu próprio áudio ao entrar na etapa ou acionar “Ouvir novamente”; texto e áudio não são herdados. A retomada direta não reproduz cenas de ancestrais que foram puladas. Em exercícios, `scene.audio` tem precedência sobre o campo legado `audio`. A navegação, a entrada no exercício, “Parar áudio” e a saída do app interrompem a fala pelo `AudioCoordinator`.

Os personagens são definidos por curso:

```json
"characters": [
  {
    "id": "aurora",
    "name": "Aurora",
    "imageAsset": "assets/images/demo/aurora.png",
    "imageDescription": "Personagem guia da jornada de demonstração."
  }
]
```

`characterId` deve existir nessa lista. Sem uma referência local, a etapa herda o personagem do ancestral mais próximo; sem referência em toda a cadeia, nenhuma imagem é exibida. Imagens precisam de nome e descrição acessível e de um caminho local em `assets/images/`, sem travessia de diretório. Imagem ausente usa um ícone de fallback mantendo nome, descrição e navegação.

Declare os arquivos físicos no `pubspec.yaml` para incluí-los no bundle. O [exemplo completo](examples/journey_course.json) é uma fixture técnica usada pelos testes, não um curso aprovado: seus novos áudios e imagens são caminhos ilustrativos e **não estão incluídos**. O catálogo demo de produção e seus prompts não foram alterados para adicionar personagens fictícios.

Esses campos são opcionais e aditivos ao schema 2. Catálogos existentes, inclusive com apenas `exercise.audio`, continuam válidos. A persistência de progresso mantém seu formato e sua versão; a retomada é derivada das conclusões salvas, não de um novo cursor persistido. `minimumRepetitions` controla a execução de tipos textuais suportados; `timed`, `repetition` e `challenge` ainda não possuem executor.

Mudanças incompatíveis exigem nova `schemaVersion`, estratégia de migração e testes. Pacotes externos futuros deverão definir manifesto, integridade/autenticidade, compatibilidade, isolamento de assets e política de atualização antes da implementação. Não presuma que JSON externo é confiável.

Conteúdo pedagógico precisa de revisão própria. Refatorações técnicas não devem reescrever prompts, sequência de exercícios ou critérios pedagógicos incidentalmente.
