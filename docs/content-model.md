# Modelo de conteúdo

O conteúdo segue a hierarquia:

```text
Course → Module → Lesson → Exercise
```

O catálogo JSON possui `schemaVersion`; cada curso tem identificador estável, versão, indicação explícita de demo e módulos. IDs devem ser únicos entre irmãos. Listas estruturais não podem ser vazias.

Um exercício contém `id`, `title`, `type` e `prompt`. O schema 2 exige também `expectedInput` para exercícios do tipo `key`; ele deve representar exatamente um caractere imprimível. O harness reconhece tipos conceituais para sequência, palavra, frase, tempo, repetição e desafio, mas somente o exercício de uma tecla possui fluxo funcional. Campos opcionais atuais são `minimumRepetitions` e `timeLimitSeconds`, ambos inteiros positivos.

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
                  "expectedInput": "a"
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

Mudanças incompatíveis exigem nova `schemaVersion`, estratégia de migração e testes. Pacotes externos futuros deverão definir manifesto, integridade/autenticidade, compatibilidade, isolamento de assets e política de atualização antes da implementação. Não presuma que JSON externo é confiável.

Conteúdo pedagógico precisa de revisão própria. Refatorações técnicas não devem reescrever prompts, sequência de exercícios ou critérios pedagógicos incidentalmente.
