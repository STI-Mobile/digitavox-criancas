# Arquitetura

## Direção

O projeto adota MVVM pragmático. A arquitetura separa responsabilidades que já existem, sem reproduzir todas as camadas de Clean Architecture.

```text
presentation → application → domain
       composition ↘ data / infrastructure → domain contracts
```

- **Presentation** renderiza estado, coleta ações e mantém acessibilidade dos widgets.
- **Application** contém ViewModels, estado observável e coordenação de operações.
- **Domain** define conteúdo, validação, progressão e contratos mínimos para fronteiras externas.
- **Data** implementa persistência sem vazar tecnologia ao domínio.
- **Infrastructure** integra assets, plataforma e formatos externos.
- **Content** vive em dados versionados, não em árvores de widgets.

`main.dart` é a raiz de composição: escolhe implementações concretas e as injeta no app.

## Decisões atuais

- `ChangeNotifier` do SDK sustenta o primeiro ViewModel; não há necessidade concreta de gerenciador de estado externo.
- O catálogo implementa `CourseCatalog`, pois carregamento por asset e um futuro pacote externo são uma fronteira real.
- A persistência implementa `ProgressRepository`; hoje é volátil e poderá ser trocada sem mudar domínio ou widgets.
- Modelos de progresso são imutáveis para tornar transições previsíveis e testáveis.
- O catálogo possui `schemaVersion`, versão do curso e validação na entrada.
- Eventos de teclado físico são filtrados na infraestrutura, avaliados por uma regra de domínio e coordenados por `ExerciseSessionViewModel`; widgets apenas encaminham a entrada e apresentam o estado.
- A sessão de exercício distingue espera, erro, acerto e conclusão. A conclusão delega a atualização ao ViewModel do catálogo, preservando a infraestrutura existente de progresso.
- `ExerciseSoundFeedback` mantém o ViewModel testável e desacoplado da plataforma. A implementação atual usa um clique do sistema para acerto e dois para erro, sem pacote externo; som sempre complementa texto e semântica.
- Cada primeira conclusão ainda concede uma estrela pela regra mínima do harness. Essa regra é provisória e não representa pontuação baseada em desempenho.

## Pontos de extensão

- Persistência durável: adicionar implementação em `data/persistence` e trocar a composição.
- Pacotes de escola: implementar outro `CourseCatalog`, incluindo segurança, migração e origem do pacote quando os requisitos existirem.
- Exercícios: estender o schema e o domínio, depois criar apresentação especializada por tipo.
- Feedback falado: criar integração de infraestrutura quando tecnologia, interrupção e políticas de áudio estiverem definidas.

Mudanças estruturais relevantes devem receber um ADR em `docs/adr`.
