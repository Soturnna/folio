#!/bin/sh
# Name: Passador Desligar
# Author: Marcos

PORTA=8080
PIDFILE=/tmp/passador.pid

if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
fi

iptables -D INPUT -p tcp --dport $PORTA -j ACCEPT 2>/dev/null

echo "$(date +%T) servidor desligado" >> /mnt/us/passador/servidor.log
echo "Passador DESLIGADO"
