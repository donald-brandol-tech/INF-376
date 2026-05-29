#!/bin/bash

#===========================================
# SNORT IDS - SCRIPT DE DÉMARRAGE
#===========================================

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Pas de couleur

clear

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║      🛡️  SNORT IDS - DÉMARRAGE              ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

#-------------------------------------------------
# 1. ARRÊT DES ANCIENS PROCESSUS
#-------------------------------------------------
echo -e "${YELLOW}[1/5] Arrêt des anciens processus...${NC}"
sudo pkill snort 2>/dev/null
pkill -f visualize.py 2>/dev/null
sleep 2

if pgrep snort > /dev/null; then
    echo -e "${RED}⚠️  Snort encore actif, force kill...${NC}"
    sudo pkill -9 snort
    sleep 1
fi

if pgrep -f visualize.py > /dev/null; then
    echo -e "${RED}⚠️  Dashboard encore actif, force kill...${NC}"
    pkill -9 -f visualize.py
    sleep 1
fi

echo -e "${GREEN}✅ Anciens processus arrêtés${NC}"

#-------------------------------------------------
# 2. PRÉPARATION DES LOGS
#-------------------------------------------------
echo -e "${YELLOW}[2/5] Préparation des fichiers de logs...${NC}"

sudo mkdir -p /var/log/snort
sudo chmod 777 /var/log/snort

# Vérifier que le dossier est accessible
if [ ! -w /var/log/snort ]; then
    echo -e "${RED}❌ Impossible d'écrire dans /var/log/snort${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dossier logs prêt${NC}"

#-------------------------------------------------
# 3. LANCEMENT DE SNORT
#-------------------------------------------------
echo -e "${YELLOW}[3/5] Démarrage de Snort...${NC}"

# Lancer Snort en arrière-plan
sudo snort -c /etc/snort/snort.lua -i wlp2s0 -A fast -l /var/log/snort/ > /tmp/snort.log 2>&1 &
SNORT_PID=$!

# Attendre le démarrage
sleep 4

# Vérifier que Snort tourne
if pgrep snort > /dev/null; then
    echo -e "${GREEN}✅ Snort démarré (PID: $SNORT_PID)${NC}"
else
    echo -e "${RED}❌ Échec du démarrage de Snort${NC}"
    echo -e "${YELLOW}Logs Snort :${NC}"
    tail -20 /tmp/snort.log
    exit 1
fi

#-------------------------------------------------
# 4. LANCEMENT DU DASHBOARD
#-------------------------------------------------
echo -e "${YELLOW}[4/5] Démarrage du dashboard...${NC}"

# Vérifier que visualize.py existe
if [ ! -f ~/visualize.py ]; then
    echo -e "${RED}❌ Fichier ~/visualize.py introuvable !${NC}"
    exit 1
fi

# Lancer le dashboard en arrière-plan
nohup python3 ~/visualize.py > /tmp/dashboard.log 2>&1 &
DASH_PID=$!

sleep 3

# Vérifier que le dashboard tourne
if pgrep -f visualize.py > /dev/null; then
    echo -e "${GREEN}✅ Dashboard démarré (PID: $DASH_PID)${NC}"
else
    echo -e "${RED}❌ Échec du démarrage du dashboard${NC}"
    echo -e "${YELLOW}Logs dashboard :${NC}"
    tail -20 /tmp/dashboard.log
    exit 1
fi

#-------------------------------------------------
# 5. RÉSUMÉ
#-------------------------------------------------
echo -e "${YELLOW}[5/5] Vérification finale...${NC}"

# Récupérer l'adresse IP
IP=$(ip addr show wlp2s0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║         ✅  TOUT EST LANCÉ !                 ║"
echo "║                                              ║"
echo "╠══════════════════════════════════════════════╣"
echo "║                                              ║"
echo "║  📊 Dashboard local : http://localhost:8082  ║"

if [ ! -z "$IP" ]; then
    echo "║  🌐 Dashboard réseau : http://$IP:8082       ║"
fi

echo "║  📁 Logs Snort : /var/log/snort/             ║"
echo "║  🛑 Arrêt : ~/snort_stop.sh                  ║"
echo "║  📋 Status : ~/snort_status.sh               ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Sauvegarder les PIDs
echo $SNORT_PID > /tmp/snort.pid
echo $DASH_PID > /tmp/dashboard.pid

# Vérification que le fichier d'alertes se remplit
sleep 2
ALERT_COUNT=$(wc -l < /var/log/snort/snort.alert.fast 2>/dev/null || echo 0)
echo -e "${CYAN}📝 Alertes dans le fichier : $ALERT_COUNT${NC}"
echo ""
echo -e "${GREEN}👉 Ouvrez http://localhost:8082 dans votre navigateur${NC}"
echo ""
