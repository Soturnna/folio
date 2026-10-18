#!/bin/sh
# HANDLER: atende UMA requisicao HTTP (executado pelo nc a cada conexao).

DEV=/dev/input/event2
DIR=/mnt/us/passador

read -r METODO CAMINHO VERSAO

CR=$(printf '\r')
while read -r LINHA; do
    [ "$LINHA" = "$CR" ] || [ -z "$LINHA" ] && break
done

CAMINHO="${CAMINHO%%\?*}"

STATUS="200 OK"
case "$CAMINHO" in
    /avancar) cat "$DIR/avancar.bin" > "$DEV" ;;
    /voltar)  cat "$DIR/voltar.bin"  > "$DEV" ;;
    /)        ;;
    *)        STATUS="404 Not Found" ;;
esac

echo "$(date +%T) $METODO $CAMINHO -> $STATUS" >> "$DIR/servidor.log"

printf 'HTTP/1.1 %s\r\n' "$STATUS"
printf 'Content-Type: text/html; charset=utf-8\r\n'
printf 'Cache-Control: no-store\r\n'
printf 'Connection: close\r\n\r\n'

cat <<'HTML'
<!doctype html>
<html lang="pt-BR"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Passador Kindle</title>
<style>
body{margin:0;height:100vh;display:flex;flex-direction:column;
font-family:-apple-system,sans-serif;background:#111;color:#eee}
.b{flex:1;border:0;font-size:64px;color:#eee}
#v{background:#333}#a{background:#2a6;flex:2}
#s{text-align:center;padding:10px;font-size:14px}
</style></head><body>
<button class="b" id="v" onclick="ir('voltar')">&#9664; Voltar</button>
<button class="b" id="a" onclick="ir('avancar')">Avan&ccedil;ar &#9654;</button>
<div id="s">Pronto</div>
<script>
function ir(c){
  var s=document.getElementById('s');
  fetch('/'+c,{cache:'no-store'})
    .then(function(){s.textContent=c+' ok '+new Date().toLocaleTimeString();})
    .catch(function(){s.textContent='Sem conexao com o Kindle';});
}
</script>
</body></html>
HTML
