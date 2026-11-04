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
- se a falha ocorrer depois de o upload ser recebido, confira o console antes
  de repetir: o build pode estar publicado/processando mesmo com o job vermelho.
  Nesse caso, não reenvie o mesmo número; uma nova execução recebe outro número;
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
`SYF585KJR7`, para executar o app em aparelhos de desenvolvimento. As
configurações `Release-*` usam assinatura manual com o certificado Apple
Distribution e um provisioning profile App Store por bundle ID:

| Configuração | Bundle ID | Nome exato do profile |
| --- | --- | --- |
| `Release-dev` | `br.usp.digitavox-criancas.dev` | `Digitavox Criancas Dev App Store` |
| `Release-prod` | `br.usp.digitavox-criancas` | `Digitavox Criancas App Store` |

O nome do profile no Apple Developer precisa ser idêntico ao
`PROVISIONING_PROFILE_SPECIFIER` do projeto; o Fastlane lê esse nome da
configuração nativa selecionada pelo flavor. O `flutter build ipa` gera o ExportOptions de assinatura manual a partir
dessas configurações e procura o profile em
`~/Library/Developer/Xcode/UserData/Provisioning Profiles`. Para gerar um IPA
localmente, instale o certificado e o profile nesse Mac.

### Fluxo local com Fastlane Match

O Fastlane é uma dependência de ferramentas, fixada em `Gemfile.lock`; não é
dependência embarcada no aplicativo. Ele prepara a assinatura e publica o IPA.
O build continua sendo executado pelo Flutter, com SwiftPM.

```sh
make setup-ios
make test-ios-tooling
make ios-sign FLAVOR=dev
make check
make ios-build FLAVOR=dev BUILD_NUMBER=1
make ios-testflight FLAVOR=dev IPA="/caminho/arquivo.ipa"
```

Escolha um build number ainda não enviado à Apple. O envio é uma ação separada:
`ios-build` não publica, e `ios-testflight` envia o IPA existente sem reconstruir.
O upload espera o processamento do TestFlight, mas não submete o app à revisão
da App Store nem distribui para testers externos. Configure os grupos internos
no App Store Connect e confirme a instalação em aparelho.

O argumento `FLAVOR` é obrigatório e corresponde ao `--flavor` do Flutter.
Bundle ID, time e nome do profile são lidos de `Release-<flavor>` no projeto
Xcode; não são definidos pelo `.env`. O envio recusa um IPA de outro flavor.
O catálogo de produção continua sem conteúdo aprovado; estes comandos não
representam autorização para publicar o app prod.

No Mac, o Fastlane carrega o `.env` da raiz, ignorado pelo Git. No CI, esse
carregamento é desabilitado e os valores devem vir do Environment:

| Campo | Uso |
| --- | --- |
| `MATCH_GIT_URL`, `MATCH_GIT_BRANCH` | Repo privado e branch dos materiais de assinatura |
| `MATCH_PASSWORD` | Senha de criptografia do armazenamento Match |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Autenticação HTTPS do Git privado, se necessária |
| `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` | Identificadores da chave de API da equipe |
| `APP_STORE_CONNECT_KEY` | Chave `.p8`; Base64 quando `APP_STORE_CONNECT_KEY_BASE64=true` |
| `APP_STORE_CONNECT_KEY_PATH` | Alternativa local: caminho para `.p8`, quando o conteúdo não foi fornecido |

As credenciais de guarda da equipe ficam no vault. O Git privado contém os
certificados e profiles criptografados. Não copie os valores para documentação,
commits ou logs. A chave de API precisa permitir as operações usadas; somente
a execução real comprova seu acesso ao app.

`ios-sign` e `ios-build` usam Match somente leitura. Para criar/renovar o profile
de um flavor na Apple e armazená-lo no repo privado, use a operação administrativa
explícita, com as permissões de escrita correspondentes:

```sh
make ios-prepare-signing FLAVOR=dev
```

O CI usa as mesmas lanes de build e envio, com Match somente leitura e keychain
temporário. Criação/renovação pelo comando administrativo é recusada em CI.
Certificados e profiles não precisam ser duplicados como secrets individuais.

## Primeiro build do app dev no TestFlight

1. No Apple Developer, confirme o App ID `br.usp.digitavox-criancas.dev`, crie
   ou reutilize o certificado Apple Distribution do time e crie o profile App
   Store `Digitavox Criancas Dev App Store` para esse App ID.
2. No App Store Connect, crie o app com esse bundle ID, se ainda não existir.
3. Crie uma chave da API do App Store Connect com permissão App Manager.
4. Execute o fluxo local acima para gerar e enviar o primeiro IPA. O TestFlight
   aceita o primeiro build pela API. A configuração do Environment e a ativação
   de `IOS_DISTRIBUTION_ENABLED=true` devem seguir a seção GitHub Actions, após
   validar o caminho local.
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
4. Confirme em Integridade do app que a assinatura é feita pelo Play App
   Signing, ativado por padrão em apps novos sem etapa de aceite. As
   declarações exigidas para app infantil ficam em Política > Conteúdo do app,
   fora do fluxo da versão: público-alvo, política de Famílias, segurança de
   dados e política de privacidade.
5. Cadastre os testers na lista do track interno.
6. Conceda acesso à conta de serviço do workflow pela conta de desenvolvedor,
   em Usuários e permissões: convide o e-mail `client_email` do JSON da conta
   de serviço e conceda permissões somente ao app dev, incluindo lançar em
   tracks de teste. A conta de serviço é criada no Google Cloud, com a Google
   Play Android Developer API ativada no projeto. A conta atual,
   `github-dev-distribution`, está no projeto Painel Gestor USP.

## GitHub Actions

O workflow [dev-distribution.yml](../.github/workflows/dev-distribution.yml) é
executado após push em `develop` ou manualmente. A execução manual só aparece
no GitHub depois que o workflow existir no branch padrão. Primeiro ele chama
o [CI](../.github/workflows/ci.yml) como quality gate reutilizável, sem acesso
aos secrets de distribuição: formatação, análise, unitários/widgets, APK debug,
testes da ferramenta iOS e integração no simulador. Se qualquer job obrigatório
falhar, nenhum build de distribuição ou upload começa.

Depois do gate aprovado, os jobs Android/iOS usam o Environment
`distribution-dev`, restrito a `develop` e sem revisores obrigatórios. Cada job
gera seu artefato release, valida-o, registra SHA-256 e o preserva por 14 dias
antes de publicar no canal interno correspondente. Os jobs de plataforma são
independentes depois do gate: falha de build/upload em uma plataforma não
desfaz uma publicação concluída na outra. Use a reexecução apenas dos jobs com
falha, conforme a regra de numeração.

O job de iOS só executa quando a variable de repositório
`IOS_DISTRIBUTION_ENABLED` vale `true`. Ela precisa ser de repositório, porque
a condição do job é avaliada antes de o Environment ser carregado. Ela controla
a distribuição iOS; o gate de testes iOS continua obrigatório. Habilite-a depois
de validar o primeiro build local no TestFlight e cadastrar os valores abaixo.

Configure os seguintes valores nesse Environment:

| Tipo | Nome | Uso |
| --- | --- | --- |
| Secret | `ANDROID_KEYSTORE_BASE64` | Upload key dev em Base64 |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | Senha do keystore |
| Secret | `ANDROID_KEY_ALIAS` | Alias da chave de upload |
| Secret | `ANDROID_KEY_PASSWORD` | Senha da chave de upload |
| Secret | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON da conta de serviço com acesso ao app dev no Play Console |
| Secret | `MATCH_PASSWORD` | Senha do armazenamento criptografado Match |
| Secret | `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 de usuário:token com leitura do repo de assinatura |
| Secret | `APP_STORE_CONNECT_KEY` | Chave privada `.p8` da API, em Base64 |
| Variable | `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID da API do App Store Connect |
| Variable | `APP_STORE_CONNECT_KEY_ID` | Key ID da API do App Store Connect |

O certificado Apple Distribution pertence ao time e é compartilhado entre os
apps; cada bundle ID tem o seu profile. O workflow obtém os materiais pelo Match
no repo privado da equipe; URL e branch são configuração não secreta. O keychain
temporário é removido ao terminar, inclusive em falha. A chave da API deve permitir
as operações do App Manager. O Environment `distribution-prod` usará os mesmos
nomes, com os valores apropriados e revisores obrigatórios.

Não registre esses valores, arquivos, perfis, certificados ou keystores no
repositório, em issues ou em logs de CI.

## Piloto acessível

Esta validação pertence às issues do core de cursos e não bloqueia o teste ou
a execução de CI/CD. Cada versão dev deve ser validada em ao menos um Android com TalkBack e um iOS
com VoiceOver. O teste manual precisa cobrir instalação/atualização, nome
anunciado do app, aviso DEMO, fluxo de exercício, persistência ao reabrir,
teclado físico/Bluetooth, ordem de foco, anúncios de estado, áudio com e sem
leitor de tela e escala de texto.

Os testes de widget automatizam o contrato de semântica, texto, teclado e
contraste. Eles não comprovam a fala emitida pelos leitores de tela nem a
interação deles com o áudio do curso.
