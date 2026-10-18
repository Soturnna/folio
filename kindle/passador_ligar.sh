#!/bin/sh
# Name: Passador Ligar
# Author: Marcos

DIR=/mnt/us/passador
PORTA=8080
HANDLER=/tmp/passador_handler.sh
PIDFILE=/tmp/passador.pid

IP=$(ifconfig wlan0 | sed -n 's/.*inet addr:\([0-9.]*\).*/\1/p')

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Passador JA ESTA LIGADO"
    echo "http://$IP:$PORTA"
    exit 0
fi

cp "$DIR/handler.sh" "$HANDLER"
chmod 755 "$HANDLER"

iptables -D INPUT -p tcp --dport $PORTA -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $PORTA -j ACCEPT

nc -lk -p $PORTA -e "$HANDLER" > /dev/null 2>&1 &
echo $! > "$PIDFILE"

echo "$(date +%T) servidor ligado em $IP:$PORTA" >> "$DIR/servidor.log"
echo "Passador LIGADO"
echo "No iPhone, abra:"
echo "http://$IP:$PORTA"
