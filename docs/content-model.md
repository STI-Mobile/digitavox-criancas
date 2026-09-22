# Modelo de conteúdo

O conteúdo segue a hierarquia:

```text
Course → Module → Lesson → Exercise
```

O catálogo JSON possui `schemaVersion`; cada curso tem identificador estável, versão, indicação explícita de demo e módulos. IDs devem ser únicos entre irmãos. Listas estruturais não podem ser vazias.

Um exercício contém `id`, `title`, `type` e `prompt`. O harness reconhece tipos conceituais para tecla, sequência, palavra, frase, tempo, repetição e desafio, mas implementa apenas a demonstração de carregamento e conclusão. Campos opcionais atuais são `minimumRepetitions` e `timeLimitSeconds`, ambos inteiros positivos.

Exemplo reduzido:

```json
{
  "schemaVersion": 1,
  "courses": [
    {
      "id": "demo-course",
      "title": "Curso demo",
      "version": "0.1.0-demo",
      "isDemo": true,
      "modules": []
    }
  ]
}
```

O exemplo é apenas ilustrativo; a validação exige ao menos um módulo, uma lição e um exercício. A fixture executável está em `assets/content/demo_course.json`.

## Evolução e pacotes externos

Mudanças incompatíveis exigem nova `schemaVersion`, estratégia de migração e testes. Pacotes externos futuros deverão definir manifesto, integridade/autenticidade, compatibilidade, isolamento de assets e política de atualização antes da implementação. Não presuma que JSON externo é confiável.

Conteúdo pedagógico precisa de revisão própria. Refatorações técnicas não devem reescrever prompts, sequência de exercícios ou critérios pedagógicos incidentalmente.
