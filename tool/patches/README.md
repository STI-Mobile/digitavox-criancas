# Backport temporário do Flutter no CI

O Flutter 3.47.2 pode iniciar o app antes de o leitor de logs do simulador estar
pronto. O URI do Dart VM service se perde e `flutter test` fica esperando após
`Xcode build done`, sem iniciar os testes. Isso ocorreu na execução real do CI.

`flutter-3.47.2-ios-log-stream.patch` adapta somente o contexto do backport oficial
[flutter/flutter#193142](https://github.com/flutter/flutter/pull/193142), commit
`c3ed85ef987759ee54a6bce275490cde2a238dc1`, relacionado ao
[defeito #181771](https://github.com/flutter/flutter/issues/181771).
A alteração espera o primeiro evento do log antes de lançar o app. A licença BSD
do Flutter está em `flutter-LICENSE`.

`tool/patch_flutter_ios_ci.sh` aplica o patch somente ao SDK do CI, exige a versão
3.47.2, falha se o contexto divergir e invalida o snapshot do flutter_tools para
recompilação. O script aceita um cache já corrigido. O SDK local não é alterado.
Os testes continuam obrigatórios, sem repetição automática ou falhas ignoradas.

Ao atualizar o Flutter para uma versão que contenha esse commit, remover o passo
do workflow, o script e estes arquivos. Validar novamente a integração iOS no
GitHub antes de liberar distribuição.
