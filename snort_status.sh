#!/bin/bash

#===========================================
# SNORT IDS - SCRIPT DE STATUS
#===========================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║        📊  SNORT IDS - STATUT               ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Snort
if pgrep snort > /dev/null; then
    echo -e "${GREEN}✅ Snort : EN COURS${NC}"
    echo -e "   PID : $(pgrep snort | head -1)"
else
    echo -e "${RED}❌ Snort : ARRÊTÉ${NC}"
fi

# Dashboard
if pgrep -f visualize.py > /dev/null; then
    echo -e "${GREEN}✅ Dashboard : EN COURS${NC}"
    echo -e "   PID : $(pgrep -f visualize.py | head -1)"
else
    echo -e "${RED}❌ Dashboard : ARRÊTÉ${NC}"
fi

# Fichier d'alertes
ALERT_FILE="/var/log/snort/snort.alert.fast"
if [ -f "$ALERT_FILE" ]; then
    SIZE=$(stat -c%s "$ALERT_FILE" 2>/dev/null || echo 0)
    LINES=$(wc -l < "$ALERT_FILE" 2>/dev/null || echo 0)
    echo -e "${GREEN}✅ Fichier alertes : $LINES lignes ($SIZE octets)${NC}"
    
    # Date de dernière modification
    LAST_MOD=$(stat -c %y "$ALERT_FILE" 2>/dev/null | cut -d. -f1)
    echo -e "   Dernière modification : $LAST_MOD"
    
    # Dernière alerte
    LAST_ALERT=$(tail -1 "$ALERT_FILE" 2>/dev/null)
    if [ ! -z "$LAST_ALERT" ]; then
        echo -e "   Dernière alerte : ${LAST_ALERT:0:80}..."
    fi
else
    echo -e "${RED}❌ Fichier alertes introuvable${NC}"
fi

# Dashboard URLs
IP=$(ip addr show wlp2s0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo ""
echo -e "${CYAN}Accès Dashboard :${NC}"
echo -e "   Local  : http://localhost:8082"
if [ ! -z "$IP" ]; then
    echo -e "   Réseau : http://$IP:8082"
fi

echo ""
echo -e "${YELLOW}Commandes :${NC}"
echo -e "   Démarrer : ~/snort_start.sh"
echo -e "   Arrêter  : ~/snort_stop.sh"
echo -e "   Status   : ~/snort_status.sh"
