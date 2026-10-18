# Folio

Controle remoto para o Kindle (Kindle Basic 11ª geração, jailbreak Véra), feito em SwiftUI.

O app envia `GET /avancar` e `GET /voltar` para o servidor `nc` que roda no Kindle
(pasta `kindle/`), que injeta as teclas `KEY_PAGEDOWN` e `KEY_PAGEUP` em `/dev/input/event2`.

## Estrutura

- `project.yml`: definição do projeto para o XcodeGen
- `Folio/`: código do app (Model, Views, Intents, Resources)
- `kindle/`: scripts que rodam no Kindle
- `.github/workflows/build-ipa.yml`: compila o `.ipa` sem assinatura em um Mac do GitHub

## Compilar

Cada push na `main` gera o artefato `Folio-ipa` na aba Actions.
Instale com o Sideloadly usando seu Apple ID.
