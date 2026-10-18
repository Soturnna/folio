# Scripts do Kindle

- `passador_ligar.sh` / `passador_desligar.sh`: Scriptlets (pasta `documents` do Kindle).
- `handler.sh`: fica em `/mnt/us/passador/`; atende cada requisição HTTP e injeta a tecla.
- `avancar.bin` / `voltar.bin`: eventos `KEY_PAGEDOWN` / `KEY_PAGEUP` (64 bytes), gerados pelo Scriptlet "Teste Injetor".
