# Distribuição

O Digitavox Crianças é publicado como dois apps nas lojas, gerados a partir do
mesmo código por flavors. A decisão e as alternativas estão no
[ADR 0005](adr/0005-apps-separados-dev-prod.md).

| Flavor | Android (`applicationId`) | iOS (bundle ID) | Nome exibido | Canais |
| --- | --- | --- | --- | --- |
| `dev` | `br.usp.digitavox_criancas.dev` | `br.usp.digitavox-criancas.dev` | Digitavox Crianças Dev | Play Internal Testing e TestFlight |
| `prod` | `br.usp.digitavox_criancas` | `br.usp.digitavox-criancas` | Digitavox Crianças | Ainda não publicado |

Os identificadores não podem mudar depois do registro nas lojas. Os IDs `dev`
estão registrados; os de `prod` estão reservados pelo ADR e serão registrados
junto com o workflow de produção.

No Android, os flavors são `productFlavors` com recursos próprios em
`android/app/src/dev`. No iOS, cada flavor tem um scheme (`dev` e `prod`) e as
build configurations `Debug-<flavor>`, `Release-<flavor>` e `Profile-<flavor>`,
que definem bundle ID, nome exibido (`APP_DISPLAY_NAME`), ícone e assinatura.

## Dev × produção

| | Dev | Produção |
| --- | --- | --- |
| Para que serve | Homologação contínua pela equipe e por testers | Uso real pelos alunos |
| Catálogo técnico | Habilitado, com aviso DEMO | Desabilitado em release |
| Origem do build | Push em `develop` | Release candidate (workflow futuro) |
| Saída das lojas | Nunca: só track interno e TestFlight | RC no track interno/TestFlight, depois promoção |
| Dados no aparelho | Isolados do app de produção | Isolados do app dev |

Builds em modo debug expõem o catálogo técnico em qualquer flavor. O build dev
não torna a fixture técnica conteúdo pedagógico aprovado: o aviso DEMO,
inclusive a sua semântica, deve continuar presente.

O app dev nunca recebe track de produção no Play e nunca é submetido à revisão
da App Store, que rejeita versões beta ou demo. Um build dev não pode ser
promovido para produção porque pertence a outro app. No app de produção, o
fluxo esperado é publicar um release candidate nos canais de teste e promover
o mesmo binário.

O release de produção depende de conteúdo pedagógico aprovado: hoje o único
catálogo configurado é o técnico, e um build `prod` em release não teria curso.

### Identificação do app dev

O nome exibido contém "Dev" em texto, porque testers cegos distinguem os apps
pelo nome anunciado por TalkBack e VoiceOver. O ícone dev tem uma faixa com o
texto "DEV" para a distinção visual. Ele é derivado do ícone de produção por
[tool/generate_dev_icons.sh](../tool/generate_dev_icons.sh), que exige
ImageMagick; execute o script novamente sempre que o ícone de produção mudar.

## Desenvolvimento local

O `pubspec.yaml` declara `dev` como `default-flavor`, então `flutter run` usa o
flavor dev. Produção exige `--flavor prod` explícito.

```sh
flutter run                    # flavor dev
flutter run --flavor prod      # flavor prod em debug
make build-android             # APK debug do flavor dev
make build-android-dev BUILD_NUMBER=42
make build-ios-dev BUILD_NUMBER=42
```

## Número do build

Cada app tem o seu contador de `versionCode` (Android) e `CFBundleVersion`
(iOS). No app dev, o workflow calcula `BUILD_NUMBER_BASE + github.run_number`,
com base `100`. Os números de 1 a 99 ficam reservados para uploads manuais; o
primeiro upload no Play Console usa `BUILD_NUMBER=1`. A numeração de produção
será definida com o workflow de produção.

O `versionCode` é único no app inteiro, em todos os tracks do Play, e não pode
ser reutilizado mesmo após excluir um build. Por isso:

- se um job falhar, use "Re-run failed jobs"; "Re-run all jobs" reutiliza o
  mesmo `run_number` e o Play recusa o job que já tinha publicado;
- renomear ou recriar o workflow reinicia o `run_number`; ajuste a base para
  um valor acima do último build publicado.

## Assinatura Android

Cada app tem a sua upload key. O Gradle lê as credenciais de
`android/key-<flavor>.properties` ou das propriedades
`digitavox.signing.<flavor>.<nome>`, e recusa um build release do flavor se
`storeFile`, `storePassword`, `keyAlias` ou `keyPassword` estiverem ausentes.
Os arquivos `key-*.properties`, `*.jks` e `*.keystore` são ignorados pelo git.

```properties
# android/key-dev.properties
storeFile=/caminho/absoluto/digitavox-dev-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Para criar a upload key dev:

```sh
keytool -genkeypair -v -keystore digitavox-dev-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guarde o keystore e as senhas em um cofre da equipe, fora do repositório. A
chave de assinatura final de cada app fica no Play App Signing.

## Assinatura iOS

As configurações `Debug-*` e `Profile-*` usam assinatura automática do time
`D2Z83QUW73`, para executar o app em aparelhos de desenvolvimento. As
configurações `Release-*` usam assinatura manual com o certificado Apple
Distribution e um provisioning profile App Store por bundle ID:

| Configuração | Bundle ID | Nome exato do profile |
| --- | --- | --- |
| `Release-dev` | `br.usp.digitavox-criancas.dev` | `Digitavox Criancas Dev App Store` |
| `Release-prod` | `br.usp.digitavox-criancas` | `Digitavox Criancas App Store` |

O nome do profile no Apple Developer precisa ser idêntico ao
`PROVISIONING_PROFILE_SPECIFIER` do projeto; o workflow confere o nome antes do
build. O `flutter build ipa` gera o ExportOptions de assinatura manual a partir
dessas configurações e procura o profile em
`~/Library/Developer/Xcode/UserData/Provisioning Profiles`. Para gerar um IPA
localmente, instale o certificado e o profile nesse Mac.

## Primeiro build do app dev no TestFlight

1. No Apple Developer, confirme o App ID `br.usp.digitavox-criancas.dev`, crie
   ou reutilize o certificado Apple Distribution do time e crie o profile App
   Store `Digitavox Criancas Dev App Store` para esse App ID.
2. No App Store Connect, crie o app com esse bundle ID, se ainda não existir.
3. Crie uma chave da API do App Store Connect com permissão App Manager.
4. Cadastre os valores no Environment `distribution-dev` e publique pelo
   workflow; o TestFlight aceita o primeiro build pela API.
5. Crie o grupo de testers internos e preencha as informações de teste. Testers
   externos exigem Beta App Review.

## Primeiro upload do app dev no Play

O Play só aceita publicação pela API depois que o app recebeu um primeiro
build pelo Play Console, e é esse primeiro AAB que vincula o package name ao
app no console.

1. Crie a upload key dev e o `android/key-dev.properties`.
2. Gere o AAB: `make build-android-dev BUILD_NUMBER=1`.
3. No app dev do Play Console, crie uma versão em Testes internos e envie
   `build/app/outputs/bundle/devRelease/app-dev-release.aab`. Confirme que o
   console mostra o package `br.usp.digitavox_criancas.dev`.
4. Aceite o Play App Signing e preencha as declarações exigidas para app
   infantil: público-alvo, política de Famílias, segurança de dados e política
   de privacidade.
5. Cadastre os testers na lista do track interno.
6. Conceda à conta de serviço do workflow acesso ao app dev.

## GitHub Actions

O workflow [dev-distribution.yml](../.github/workflows/dev-distribution.yml) é
executado após push em `develop` ou manualmente. A execução manual só aparece
no GitHub depois que o workflow existir no branch padrão. Os dois jobs usam o
Environment protegido `distribution-dev`, executam `make check` e publicam
independentemente.

Configure os seguintes valores nesse Environment:

| Tipo | Nome | Uso |
| --- | --- | --- |
| Secret | `ANDROID_KEYSTORE_BASE64` | Upload key dev em Base64 |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | Senha do keystore |
| Secret | `ANDROID_KEY_ALIAS` | Alias da chave de upload |
| Secret | `ANDROID_KEY_PASSWORD` | Senha da chave de upload |
| Secret | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON da conta de serviço com acesso ao app dev no Play Console |
| Secret | `APPSTORE_CERTIFICATES_FILE_BASE64` | Certificado Apple Distribution `.p12` em Base64 |
| Secret | `APPSTORE_CERTIFICATES_PASSWORD` | Senha do certificado `.p12` |
| Secret | `APPSTORE_PROVISIONING_PROFILE_BASE64` | Profile `Digitavox Criancas Dev App Store` em Base64 |
| Variable | `APPSTORE_ISSUER_ID` | Issuer ID da API do App Store Connect |
| Variable | `APPSTORE_API_KEY_ID` | Key ID da API do App Store Connect |
| Secret | `APPSTORE_API_PRIVATE_KEY` | Conteúdo da chave privada `.p8` da API |

O certificado Apple Distribution pertence ao time e é compartilhado entre os
apps; cada bundle ID tem o seu profile. A chave da App Store Connect deve ter
ao menos a permissão App Manager. O Environment `distribution-prod` usará os
mesmos nomes, com valores de produção e revisores obrigatórios.

Não registre esses valores, arquivos, perfis, certificados ou keystores no
repositório, em issues ou em logs de CI.

## Piloto acessível

Cada versão dev deve ser validada em ao menos um Android com TalkBack e um iOS
com VoiceOver. O teste manual precisa cobrir instalação/atualização, nome
anunciado do app, aviso DEMO, fluxo de exercício, persistência ao reabrir,
teclado físico/Bluetooth, ordem de foco, anúncios de estado, áudio com e sem
leitor de tela e escala de texto.

Os testes de widget automatizam o contrato de semântica, texto, teclado e
contraste. Eles não comprovam a fala emitida pelos leitores de tela nem a
interação deles com o áudio do curso.
