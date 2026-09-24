# Digitavox Crianças

Harness inicial do aplicativo Flutter acessível Digitavox Crianças. O projeto prepara uma base pequena e verificável para evolução incremental; o conteúdo incluído é apenas uma fixture técnica e não constitui material pedagógico final.

## Pré-requisitos

- Flutter 3.47.2 (canal stable) com Dart 3.13.2;
- Xcode com Swift Package Manager para execução em iOS;
- Android Studio ou Android SDK para execução em Android;
- `make` para usar os comandos padronizados.

Confira a instalação com `flutter doctor`.

## Início rápido

```sh
make bootstrap
flutter run
```

Antes de concluir uma alteração:

```sh
make check
```

O comando valida formatação, análise estática com warnings fatais e testes unitários/de widget.

## Comandos

| Comando | Finalidade |
| --- | --- |
| `make bootstrap` ou `make setup` | Baixar/resolver dependências |
| `make format` | Formatar código Dart |
| `make format-check` | Verificar formatação sem alterar arquivos |
| `make analyze` ou `make lint` | Executar análise estática estrita |
| `make test` | Rodar testes unitários e de widget |
| `make test-unit` | Rodar somente testes unitários |
| `make test-widget` | Rodar somente testes de widget |
| `make test-integration` | Rodar integração em um dispositivo disponível |
| `make coverage` | Gerar `coverage/lcov.info` |
| `make build-android` | Gerar APK Android de debug |
| `make check` | Executar a validação principal local |

## Organização

```text
assets/content/       Fixture JSON do catálogo demo
lib/src/application/  ViewModels e coordenação de casos da interface
lib/src/domain/       Conteúdo, progresso e contratos centrais
lib/src/data/         Implementações de persistência
lib/src/infrastructure/Carregamento de assets e integrações técnicas
lib/src/presentation/ Widgets e telas
test/unit/             Testes de domínio, dados e ViewModels
test/widget/           Testes de interface isolados
integration_test/     Smoke tests em dispositivo
docs/                  Decisões e guias de engenharia
```

O fluxo de dependências e os pontos de extensão estão em [Arquitetura](docs/architecture.md). Consulte também:

- [Acessibilidade](docs/accessibility.md)
- [Modelo de conteúdo](docs/content-model.md)
- [Estratégia de testes](docs/testing.md)
- [ADR 0001: Flutter + MVVM](docs/adr/0001-flutter-mvvm.md)
- [ADR 0002: persistência local do progresso](docs/adr/0002-persistencia-local-progresso.md)
- [ADR 0003: arquitetura de áudio](docs/adr/0003-arquitetura-audio.md)
- [Audio Guidance](docs/architecture/audio-guidance.md)
- [Integração Course Audio](docs/architecture/course-audio-integration.md)
- [Contrato para agentes](AGENTS.md)

## Estado atual

Em debug, o app carrega um Demo Course técnico que usa o mesmo parser, engine, ViewModels e progresso da jornada normal. A configuração declarativa produz Speech e SFX via Course Audio Orchestration, incluindo asset, fallback TTS, sequenciamento e cancelamento. Em release, o catálogo técnico fica desabilitado. Áudio narrativo e VoiceOver/TalkBack permanecem canais arquiteturalmente separados. Ainda não há conteúdo pedagógico definitivo, sincronização em nuvem, backend ou importação de pacotes externos.
