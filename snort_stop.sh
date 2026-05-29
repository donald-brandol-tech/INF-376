#!/bin/bash

#===========================================
# SNORT IDS - SCRIPT D'ARRÊT
#===========================================

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear

echo -e "${RED}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║        🛑  SNORT IDS - ARRÊT                ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

#-------------------------------------------------
# 1. ARRÊT DE SNORT
#-------------------------------------------------
echo -e "${YELLOW}[1/3] Arrêt de Snort...${NC}"

if [ -f /tmp/snort.pid ]; then
    SNORT_PID=$(cat /tmp/snort.pid)
    sudo kill $SNORT_PID 2>/dev/null
    echo -e "${GREEN}✅ Signal d'arrêt envoyé à Snort (PID: $SNORT_PID)${NC}"
else
    sudo pkill snort 2>/dev/null
fi

sleep 2

# Vérifier si Snort est toujours actif
if pgrep snort > /dev/null; then
    echo -e "${YELLOW}⚠️  Snort encore actif, force kill...${NC}"
    sudo pkill -9 snort
    sleep 1
fi

if pgrep snort > /dev/null; then
    echo -e "${RED}❌ Impossible d'arrêter Snort${NC}"
else
    echo -e "${GREEN}✅ Snort arrêté${NC}"
fi

#-------------------------------------------------
# 2. ARRÊT DU DASHBOARD
#-------------------------------------------------
echo -e "${YELLOW}[2/3] Arrêt du dashboard...${NC}"

if [ -f /tmp/dashboard.pid ]; then
    DASH_PID=$(cat /tmp/dashboard.pid)
    kill $DASH_PID 2>/dev/null
    echo -e "${GREEN}✅ Signal d'arrêt envoyé au dashboard (PID: $DASH_PID)${NC}"
else
    pkill -f visualize.py 2>/dev/null
fi

sleep 2

# Vérifier si le dashboard est toujours actif
if pgrep -f visualize.py > /dev/null; then
    echo -e "${YELLOW}⚠️  Dashboard encore actif, force kill...${NC}"
    pkill -9 -f visualize.py
    sleep 1
fi

if pgrep -f visualize.py > /dev/null; then
    echo -e "${RED}❌ Impossible d'arrêter le dashboard${NC}"
else
    echo -e "${GREEN}✅ Dashboard arrêté${NC}"
fi

#-------------------------------------------------
# 3. NETTOYAGE
#-------------------------------------------------
echo -e "${YELLOW}[3/3] Nettoyage...${NC}"

# Supprimer les fichiers PID
rm -f /tmp/snort.pid /tmp/dashboard.pid

# Supprimer les logs temporaires
rm -f /tmp/snort.log /tmp/dashboard.log

echo -e "${GREEN}✅ Fichiers temporaires nettoyés${NC}"

#-------------------------------------------------
# RÉSUMÉ
#-------------------------------------------------
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║         ✅  TOUT EST ARRÊTÉ                 ║"
echo "║                                              ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  🚀 Redémarrer : ~/snort_start.sh           ║"
echo "║  📋 Status     : ~/snort_status.sh          ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
