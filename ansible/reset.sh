#!/bin/bash
# Script de reset avec mot de passe vault automatique
# Usage: ./reset.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🧼 Reset Raspberry Pi VPN + K3s${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier que le mot de passe vault est défini
if [ -z "$ANSIBLE_VAULT_PASSWORD" ]; then
    echo -e "${RED}❌ Erreur: Variable ANSIBLE_VAULT_PASSWORD non définie${NC}"
    echo ""
    echo "Chargez le fichier .env ou définissez la variable :"
    echo "  source .env"
    echo "  ./reset.sh"
    exit 1
fi

echo -e "${YELLOW}⚠️  ATTENTION: Cette opération va :${NC}"
echo "  • Arrêter tous les services (K3s, VPN, Wi-Fi AP)"
echo "  • Supprimer le cluster K3s et toutes les données"
echo "  • Remettre la configuration réseau par défaut"
echo "  • Redémarrer le Raspberry Pi"
echo ""
echo -e "${RED}Toutes les données du cluster seront perdues !${NC}"
echo ""

read -p "Êtes-vous sûr de vouloir continuer ? (tapez 'yes' pour confirmer): " CONFIRM

if [[ $CONFIRM != "yes" ]]; then
    echo -e "${BLUE}🛑 Reset annulé${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🔄 Lancement du reset...${NC}"

# Exécuter le playbook de reset
ansible-playbook \
    -i inventory/hosts \
    reset.yml \
    --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD") \
    -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Reset terminé avec succès !${NC}"
    echo ""
    echo "Le Raspberry Pi a été remis à son état initial."
    echo "Vous pouvez relancer le déploiement avec : ./deploy.sh"
else
    echo -e "${RED}❌ Erreur lors du reset${NC}"
    exit 1
fi
