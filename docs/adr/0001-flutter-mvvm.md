# ADR 0001: Flutter e MVVM pragmático

- Status: aceita
- Data: 2026-09-22

## Contexto

Digitavox Crianças precisa atender iOS e Android, operar sem backend próprio no fluxo básico, tratar acessibilidade como requisito estrutural e permitir conteúdo de cursos orientado a dados. O início do projeto também precisa ser simples de compreender, testar e modificar por pessoas e agentes de IA.

## Alternativas consideradas

- Aplicações nativas separadas para iOS e Android: oferecem integração direta, mas duplicariam implementação, testes e evolução nesta fase.
- Flutter com widgets e estado sem separação definida: reduz arquivos inicialmente, mas acopla regras, conteúdo e persistência à UI conforme o produto cresce.
- Flutter com Clean Architecture completa ou framework arquitetural: amplia fronteiras e abstrações antes de existirem casos que as justifiquem.
- Flutter com MVVM pragmático: compartilha código entre plataformas e separa UI, estado e domínio com poucas estruturas.

## Decisão

Usar Flutter para iOS e Android e MVVM pragmático como base. Widgets ficam em apresentação, ViewModels coordenam estado da interface e modelos/regras permanecem no domínio. Dados e infraestrutura implementam apenas contratos necessários nas fronteiras de persistência e conteúdo.

Usar primeiro recursos do Flutter/Dart, incluindo `ChangeNotifier`, e avaliar dependências externas apenas diante de necessidade concreta.

## Consequências

- Há uma base única para as duas plataformas e testes compartilhados.
- Regras de curso e progresso podem ser testadas sem widgets.
- Persistência e origem do catálogo podem ser substituídas na composição.
- A equipe precisa manter a direção das dependências e evitar lógica nos widgets.
- Alguns detalhes específicos de plataforma continuarão exigindo implementação e teste em iOS e Android.
- O padrão poderá ser revisto por ADR se a complexidade real superar o suporte adequado de `ChangeNotifier` e da composição manual.
