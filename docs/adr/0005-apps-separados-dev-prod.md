# ADR 0005: apps separados para desenvolvimento e produção

- Status: aceita
- Data: 2026-10-29

## Contexto

A distribuição beta atual publica um build release com `APP_ENV=beta` no mesmo app das lojas que receberá a versão de produção. Beta e produção compartilham application ID, bundle ID, contador de `versionCode`/`CFBundleVersion`, dados locais do aparelho e credenciais. A regra de que um build beta não pode ser promovido para produção depende apenas de disciplina: nos dois consoles, a promoção é tecnicamente possível.

O projeto também serve de referência para apps maiores da equipe, nos quais backend, analytics, notificações e deep links costumam exigir separação entre homologação e produção. Os identificadores `br.usp.digitavox_criancas.dev` (Google Play) e `br.usp.digitavox-criancas.dev` (App Store Connect) já foram registrados, sem nenhum upload realizado.

## Alternativas consideradas

- Um app com tracks de teste: é o modelo atual. Exige menos cadastro, mas mantém contador e dados compartilhados e não impede a promoção de um build de teste.
- Firebase App Distribution: já foi descartado na distribuição beta por aumentar o atrito de instalação e atualização para os testers.
- Dois apps nas lojas, gerados por flavors do mesmo código: dobra o cadastro e as credenciais, mas torna a separação estrutural e reproduz o padrão desejado para apps maiores.

## Decisão

Gerar dois apps a partir do mesmo código, com flavors `dev` e `prod` no Android e no iOS.

| Flavor | Android (`applicationId`) | iOS (bundle ID) | Nome exibido | Catálogo técnico |
| --- | --- | --- | --- | --- |
| `dev` | `br.usp.digitavox_criancas.dev` | `br.usp.digitavox-criancas.dev` | Digitavox Crianças Dev | Habilitado como DEMO |
| `prod` | `br.usp.digitavox_criancas` | `br.usp.digitavox-criancas` | Digitavox Crianças | Desabilitado em release |

O flavor é a única fonte do ambiente. `AppEnvironment` passa a ser derivado da constante `appFlavor` do Flutter, e `APP_ENV` deixa de existir. Builds em modo debug continuam expondo o catálogo técnico em qualquer flavor. Os builds nativos recusam flavors inexistentes, e um build release com flavor ausente ou desconhecido falha na inicialização em vez de assumir um ambiente. O `pubspec.yaml` declara `dev` como `default-flavor`; produção exige `--flavor prod` explícito.

O nome exibido do app `dev` contém o termo "Dev" em texto, porque testers cegos distinguem os apps pelo nome anunciado por VoiceOver e TalkBack. O ícone do app `dev` recebe uma faixa com o texto "DEV" para facilitar a distinção visual, sem substituir o nome. O ícone `dev` é derivado do ícone de produção e deve ser regenerado quando este mudar. O aviso DEMO e a sua semântica continuam presentes no catálogo técnico.

### Distribuição

- `dev`: push em `develop` publica no Google Play Internal Testing e no TestFlight do app `dev`. Esse app nunca sai dos canais de teste: não recebe track de produção no Play nem é submetido à revisão da App Store, que rejeita versões beta ou demo.
- `prod`: um release candidate do flavor `prod` é publicado no track interno e no TestFlight do próprio app de produção e, após aprovação, o mesmo binário é promovido para produção. O workflow de produção só será implementado quando houver conteúdo pedagógico aprovado; até lá, um release `prod` não teria curso disponível.

### Credenciais e numeração

- Cada app Android tem a sua upload key, lida de `android/key-<flavor>.properties` ou das propriedades Gradle `digitavox.signing.<flavor>.<nome>`. A chave de assinatura final fica no Play App Signing de cada app.
- No iOS, o certificado Apple Distribution pertence ao time e é compartilhado; cada bundle ID tem o seu provisioning profile App Store. O Release de cada flavor usa assinatura manual com o profile correspondente.
- Cada app tem um GitHub Environment próprio, `distribution-dev` e `distribution-prod`, com os mesmos nomes de secrets e valores diferentes. `distribution-prod` exige revisores obrigatórios.
- Cada app tem o seu contador de build. No app `dev`, o workflow usa `100 + github.run_number`, e os números de 1 a 99 ficam reservados para uploads manuais, como o primeiro upload exigido pelo Play. A numeração de `prod` será definida com o workflow de produção.

## Consequências

- Um build de desenvolvimento não pode ser promovido para produção, porque pertence a outro app.
- Os dois apps podem ser instalados no mesmo aparelho, com progresso e preferências isolados.
- A promoção do mesmo binário dentro do app de produção passa a ser o fluxo esperado de release.
- O cadastro dobra: dois apps em cada console, duas upload keys, dois profiles, dois acessos da conta de serviço do Play e as declarações de app infantil (público-alvo, política de Famílias, privacidade) preenchidas em ambos.
- Todo comando de build e execução passa a considerar o flavor; o iOS precisa de build configurations e schemes por flavor no projeto Xcode, mantendo SwiftPM.
- Os identificadores de `prod` estão reservados por este ADR, mas ainda precisam ser registrados nas lojas antes do workflow de produção. Identificadores não podem mudar após o registro.
- A distribuição é documentada em [docs/distribution.md](../distribution.md).
