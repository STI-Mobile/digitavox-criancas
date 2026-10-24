# Distribuição beta

O Digitavox Crianças distribui builds de teste pelos canais oficiais:

- Android: Google Play Internal Testing;
- iOS: TestFlight.

Firebase App Distribution não integra o primeiro ciclo. Os dois canais escolhidos
reduzem o atrito de instalação e atualização para testers e preservam o fluxo
normal de cada plataforma.

## Ambientes

| Ambiente | Como gerar | Catálogo técnico |
| --- | --- | --- |
| Debug | `flutter run` | Habilitado como DEMO |
| Beta | `make build-android-beta` ou `make build-ios-beta` | Habilitado como DEMO |
| Release | Build release sem `APP_ENV=beta` | Desabilitado |

Beta é um build de release assinado com `APP_ENV=beta`. Ele não torna a fixture
técnica conteúdo pedagógico aprovado: o aviso DEMO, inclusive a sua semântica,
deve continuar presente.

Use `BUILD_NUMBER` quando for necessário definir explicitamente o número do
build:

```sh
make build-android-beta BUILD_NUMBER=42
make build-ios-beta BUILD_NUMBER=42
```

## Número do build

O mesmo número é usado como `versionCode` no Android e `CFBundleVersion` no
iOS. O workflow calcula `BUILD_NUMBER_BASE + github.run_number`, com base
`100`. Os números de 1 a 99 ficam reservados para uploads manuais; o primeiro
upload no Play Console deve usar `BUILD_NUMBER=1`.

O `versionCode` é único no app inteiro, em todos os tracks do Play, e não pode
ser reutilizado mesmo após excluir um build. Por isso:

- se um job falhar, use "Re-run failed jobs"; "Re-run all jobs" reutiliza o
  mesmo `run_number` e o Play recusa o job que já tinha publicado;
- renomear ou recriar o workflow reinicia o `run_number`; ajuste a base para
  um valor acima do último build publicado;
- builds beta usam `APP_ENV=beta` e não podem ser promovidos para produção. A
  distribuição de produção precisará de números próprios no mesmo contador,
  definidos junto com o workflow de produção.

Os comandos de beta exigem credenciais de assinatura válidas. O Android recusa
um build release se `storeFile`, `storePassword`, `keyAlias` ou `keyPassword`
não estiverem disponíveis em `android/key.properties` ou como propriedades
Gradle `digitavox.signing.<nome>`.

## GitHub Actions

O workflow [beta-distribution.yml](../.github/workflows/beta-distribution.yml)
é executado após push em `develop` ou manualmente. Os dois jobs usam o
Environment protegido `beta-distribution`, executam `make check` e publicam
independentemente.

Configure os seguintes valores nesse Environment:

| Tipo | Nome | Uso |
| --- | --- | --- |
| Secret | `ANDROID_KEYSTORE_BASE64` | Keystore de upload Android em Base64 |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | Senha do keystore |
| Secret | `ANDROID_KEY_ALIAS` | Alias da chave de upload |
| Secret | `ANDROID_KEY_PASSWORD` | Senha da chave de upload |
| Secret | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON da conta de serviço com acesso ao Play Console |
| Secret | `APPSTORE_CERTIFICATES_FILE_BASE64` | Certificado de distribuição `.p12` em Base64 |
| Secret | `APPSTORE_CERTIFICATES_PASSWORD` | Senha do certificado `.p12` |
| Secret | `APPSTORE_PROVISIONING_PROFILE_BASE64` | Profile App Store `.mobileprovision` em Base64 |
| Variable | `APPSTORE_ISSUER_ID` | Issuer ID da API do App Store Connect |
| Variable | `APPSTORE_API_KEY_ID` | Key ID da API do App Store Connect |
| Secret | `APPSTORE_API_PRIVATE_KEY` | Conteúdo da chave privada `.p8` da API |

As credenciais Apple devem corresponder ao bundle ID
`br.usp.digitavox-criancas`. O app Android usa o application ID
`br.usp.digitavox_criancas`, que também é o `packageName` publicado no Play
Console. Os dois identificadores não podem mudar depois do registro nas lojas.
A chave da App Store Connect deve ter ao
menos a permissão App Manager. A primeira versão Android precisa existir no
Play Console antes de a API poder publicar no track `internal`.

Não registre esses valores, arquivos, perfis, certificados ou keystores no
repositório, em issues ou em logs de CI.

## Piloto acessível

Cada versão beta deve ser validada em ao menos um Android com TalkBack e um iOS
com VoiceOver. O teste manual precisa cobrir instalação/atualização, aviso DEMO,
fluxo de exercício, persistência ao reabrir, teclado físico/Bluetooth, ordem de
foco, anúncios de estado, áudio com e sem leitor de tela e escala de texto.

Os testes de widget automatizam o contrato de semântica, texto, teclado e
contraste. Eles não comprovam a fala emitida pelos leitores de tela nem a
interação deles com o áudio do curso.
