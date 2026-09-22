# ADR 0002: persistência local do progresso

- Status: aceita
- Data: 2026-09-22

## Contexto

O progresso atual contém poucos dados estruturados: cursos, lições, identificadores de exercícios concluídos, estrelas e configurações. O fluxo básico precisa funcionar offline em iOS e Android, restaurar o estado antes de apresentar o catálogo pronto e permitir evolução controlada do formato. A solução também precisa ser testável sem dispositivo e manter `ProgressRepository` como fronteira do domínio.

## Alternativas consideradas

- Manter somente memória: é simples e útil em testes, mas perde todo o progresso ao encerrar o processo.
- Arquivo JSON gerenciado diretamente: atende ao volume, porém exige definir localização, gravação atômica e integração própria por plataforma.
- SQLite ou outro banco local: oferece consultas e transações, mas adiciona schema, migrações e infraestrutura desnecessários para um único agregado pequeno lido por inteiro.
- Preferências do sistema com um documento JSON versionado: usa armazenamento local já integrado às plataformas, mantém o formato explícito e reduz a infraestrutura atual.

## Decisão

Usar `shared_preferences` 2.5.5 por meio da API assíncrona `SharedPreferencesAsync`. Salvar um único texto na chave `digitavox.student_progress`, usando no Android o backend padrão DataStore Preferences e no iOS `NSUserDefaults`.

O texto contém JSON no schema 1:

```json
{
  "schemaVersion": 1,
  "progress": {
    "courses": {
      "course-1": {
        "lessons": {
          "lesson-1": {
            "completedExerciseIds": ["exercise-1"],
            "stars": 1
          }
        }
      }
    },
    "settings": {
      "spokenFeedbackEnabled": true,
      "highContrastEnabled": true
    }
  }
}
```

`StudentProgressCodec` é responsável por serialização e validação. `LocalProgressRepository` converte documento ausente, JSON inválido, conteúdo inválido ou versão desconhecida em `StudentProgress` vazio. A captura é restrita a erros conhecidos do formato; falhas do armazenamento continuam sendo propagadas. Uma conclusão já registrada não gera nova gravação.

`ProgressDocumentStore` isola o mecanismo chave-valor para testes determinísticos. `SharedPreferencesProgressStore` é o adaptador de produção e `InMemoryProgressRepository` permanece como implementação simples do contrato para testes não relacionados à durabilidade.

## Consequências

- O progresso sobrevive a reinicializações do processo sem backend ou conta de usuário.
- O documento pode evoluir por versão, com migração ou fallback explicitamente definidos antes de aceitar um novo schema.
- Todo o agregado é lido e gravado de uma vez; isso é adequado ao volume atual, mas deve ser revisto se o progresso crescer muito ou exigir consultas/transações parciais.
- Preferências não são armazenamento para dados críticos: a própria dependência informa que uma gravação pode ser persistida em disco de forma assíncrona sem garantia após o retorno. Perda excepcional de progresso ainda é possível, e não há sincronização, backup controlado pelo app ou recuperação em nuvem.
- Documento inválido não impede a inicialização, mas o app começa vazio e preserva o valor inválido até a próxima alteração válida sobrescrevê-lo.
