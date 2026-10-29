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

O texto contém JSON no schema 4:

```json
{
  "schemaVersion": 4,
  "progress": {
    "courses": {
      "course-1": {
        "lessons": {
          "lesson-1": {
            "completedExerciseIds": ["exercise-1"],
            "stars": 2,
            "tries": 1,
            "exerciseAccuracies": {
              "exercise-1": 95
            },
            "exerciseStatistics": {
              "exercise-1": {
                "elapsedMilliseconds": 5000,
                "totalInputs": 20,
                "correctInputs": 19,
                "errorPairs": {"f→j": 1}
              }
            }
          }
        },
        "completedEventIds": ["cerimonia-decolagem"],
        "unlockedRewardIds": ["cadete-bronze", "blib-blub", "zorp", "nebulon"]
      }
    },
    "settings": {
      "spokenFeedbackEnabled": true,
      "themePreference": "highContrast"
    }
  }
}
```

`StudentProgressCodec` é responsável por serialização, validação e pela migração dos schemas 1, 2 e 3 para schema 4. Na migração, `highContrastEnabled: true` vira `themePreference: "highContrast"`; `false` vira `"standard"`. Os schemas 1 e 2 não continham tentativas por lição nem precisão por exercício; esses campos iniciam em zero e vazios, preservando conclusões e estrelas existentes. O schema 3 também preserva tentativas e precisões. Em todas as migrações, estatísticas detalhadas, eventos concluídos e recompensas desbloqueadas iniciam vazios: não se inventam medições nem conquistas retroativas. `LocalProgressRepository` converte documento ausente, JSON inválido, conteúdo inválido ou versão desconhecida em `StudentProgress` vazio. A captura é restrita a erros conhecidos do formato; falhas do armazenamento continuam sendo propagadas. Uma pontuação repetida sem mudança não gera nova gravação.

O schema 4 acrescenta medições por exercício da tentativa atual ou da última tentativa reprovada: duração em milissegundos, teclas digitadas/corretas e pares de erro esperado → recebido. A precisão da missão usa as contagens agregadas quando todos os resultados têm medições; resultados antigos sem contagens continuam usando a média das precisões por exercício. Contagens e tempos negativos, acertos maiores que o total e pares de erro inconsistentes são rejeitados. Não há checkpoint de caractere nem cópia do conteúdo/configuração pedagógica do curso no progresso.

Um resultado interrompido pelo limite de tempo registra as medições com `countsTowardCompletion: false`: remove o ID de conclusão da atividade e não concede novas estrelas, mesmo com 100% das teclas parciais corretas. O engine é responsável por reiniciar a tentativa e não disparar eventos de conclusão a partir desse resultado parcial. A flag é intenção da operação, não uma cópia do conteúdo do curso no documento salvo.

`stars` guarda a melhor conquista histórica, enquanto a aprovação de uma tentativa é calculada com seus resultados. A média mínima e as faixas de duas/três estrelas são inclusivas e vêm do curso; `secChar` legado não participa do cálculo de estrelas. Limpar uma tentativa reprovada remove os IDs concluídos, preservando medições e precisões para o diário. Ao iniciar a repetição com os IDs vazios, esses resultados são limpos; na retomada de uma tentativa parcial, os resultados concluídos são mantidos. A repetição integral de uma missão aprovada deve limpar os IDs antes de iniciar a nova tentativa.

Eventos de curso e recompensas são conjuntos de IDs estáveis por curso e perfil. A gravação de um evento concede suas recompensas na mesma alteração do agregado; repetir um evento já concedido não grava novamente. A reprodução de cerimônia é independente dessa concessão. O ViewModel serializa mutações concorrentes, publica o novo estado somente após `save` bem-sucedido e propaga falhas reais de I/O, permitindo repetir a operação sem declarar conquistas que não foram salvas.

Migrações de identidade do conteúdo são declaradas pelo curso com `legacyLessonIds`, independentemente do schema do progresso. Durante a inicialização, se a lição alvo ainda não existir, o ViewModel combina resultados dos aliases existentes e conserva somente exercícios presentes no alvo; tentativas são somadas. A conquista da nova missão é recalculada pelas contagens/precisões e faixas do curso somente quando todas as atividades possuem conclusão e dados, sem herdar a melhor estrela de uma parte isolada. Agregados completos reprovados têm seus IDs concluídos limpos para oferecer repetição, conservando o diário. Registros antigos permanecem para preservar história. O agregado só é publicado após salvar a migração, que é idempotente e não escreve quando nenhum alias tem progresso. Confirmações antigas de cerimônia por digitação não inferem o novo evento ou suas recompensas.

`ProgressDocumentStore` isola o mecanismo chave-valor para testes determinísticos. `SharedPreferencesProgressStore` é o adaptador de produção e `InMemoryProgressRepository` permanece como implementação simples do contrato para testes não relacionados à durabilidade.

## Consequências

- O progresso sobrevive a reinicializações do processo sem backend ou conta de usuário.
- O documento pode evoluir por versão, com migração ou fallback explicitamente definidos antes de aceitar um novo schema.
- Todo o agregado é lido e gravado de uma vez; isso é adequado ao volume atual, mas deve ser revisto se o progresso crescer muito ou exigir consultas/transações parciais.
- Preferências não são armazenamento para dados críticos: a própria dependência informa que uma gravação pode ser persistida em disco de forma assíncrona sem garantia após o retorno. Perda excepcional de progresso ainda é possível, e não há sincronização, backup controlado pelo app ou recuperação em nuvem.
- Documento inválido não impede a inicialização, mas o app começa vazio e preserva o valor inválido até a próxima alteração válida sobrescrevê-lo.

Novos perfis usam `themePreference: "dark"` por padrão. O tema apresentado como Claro conserva o valor `"standard"`; preferências existentes e a migração do schema 1 continuam iguais. A mudança do padrão e do nome visível não altera o contrato persistido nem exige nova versão do schema.
