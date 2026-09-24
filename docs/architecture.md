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
- A persistência implementa `ProgressRepository`. A composição principal usa `LocalProgressRepository`, com um documento JSON versionado salvo por `SharedPreferencesAsync`; a implementação em memória permanece disponível para testes.
- `StudentProgressCodec` valida explicitamente cursos, lições, exercícios concluídos, estrelas e configurações. Documento ausente, corrompido ou com schema desconhecido resulta em progresso vazio; falhas do armazenamento não são silenciadas.
- Modelos de progresso são imutáveis para tornar transições previsíveis e testáveis.
- O catálogo possui `schemaVersion`, versão do curso e validação na entrada.
- O Design System reside na apresentação e combina tokens institucionais, um dos três temas acessíveis do aplicativo e uma identidade de curso resolvida por identificador semântico. O domínio conhece somente `themeId` e a preferência persistida, nunca cores ou tipos Flutter. Consulte `docs/design-system.md`.
- `CourseJourneyEngine` interpreta a hierarquia e a ordem do catálogo, mantém a etapa atual e coordena retomada, avanço, retorno, sessão de exercício, cena e personagem. As telas enviam comandos ao engine; o conteúdo não é convertido em regras de widgets. Consulte o ADR 0004 e `docs/course.schema.json`.
- Eventos de teclado físico são filtrados na infraestrutura, avaliados por uma regra de domínio e coordenados por `ExerciseSessionViewModel`; widgets apenas encaminham a entrada e apresentam o estado.
- A sessão de exercício distingue espera, erro, acerto e conclusão. A conclusão delega a atualização ao ViewModel do catálogo, preservando a infraestrutura existente de progresso.
- `ExerciseSoundFeedback` mantém o ViewModel testável e desacoplado da plataforma. A implementação atual usa um clique do sistema para acerto e dois para erro, sem pacote externo; som sempre complementa texto e semântica.
- Áudio de conteúdo segue `ContentAudioReference` → `AudioCoordinator` → `ContentAudioService` → `AudioplayersContentAudioService`. O coordenador mantém somente uma fala narrativa ativa, interrompe ao receber entrada ou sair da tela e contém falhas conhecidas sem bloquear o exercício.
- Áudio gravado do curso, futura fala dinâmica e acessibilidade do sistema são responsabilidades distintas. `Semantics`, VoiceOver e TalkBack não são mecanismos narrativos do curso.
- `AudioGuidanceCoordinator` oferece cues genéricos tipados, sequenciamento, cancelamento e fallback de fala gravada para TTS nativo. A infraestrutura ainda não está integrada ao conteúdo do curso. Consulte `docs/architecture/audio-guidance.md`.
- Cada primeira conclusão ainda concede uma estrela pela regra mínima do harness. Essa regra é provisória e não representa pontuação baseada em desempenho.

## Pontos de extensão

- Evolução do progresso: incrementar o schema, definir migração ou fallback e cobrir compatibilidade antes de alterar o formato persistido.
- Pacotes de escola: implementar outro `CourseCatalog`, incluindo segurança, migração e origem do pacote quando os requisitos existirem.
- Exercícios: estender o schema e o domínio, depois criar apresentação especializada por tipo.
- Fala dinâmica: integrar cues ao orquestrador de conteúdo somente quando os contratos dessa etapa estiverem definidos; o serviço de TTS permanece uma infraestrutura genérica.
- Política de áudio: revisar foco, ducking e coexistência depois de testes empíricos com VoiceOver e TalkBack em dispositivos físicos.

Mudanças estruturais relevantes devem receber um ADR em `docs/adr`.
