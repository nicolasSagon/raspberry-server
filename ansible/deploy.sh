#!/bin/bash
# Script de déploiement avec mot de passe vault automatique
# Usage: ./deploy.sh

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Déploiement Raspberry Pi VPN + K3s${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier que le mot de passe vault est défini
if [ -z "$ANSIBLE_VAULT_PASSWORD" ]; then
    echo -e "${RED}❌ Erreur: Variable ANSIBLE_VAULT_PASSWORD non définie${NC}"
    echo ""
    echo "Pour définir le mot de passe vault :"
    echo "  export ANSIBLE_VAULT_PASSWORD='votre_mot_de_passe'"
    echo "  ./deploy.sh"
    echo ""
    echo "Ou créer un fichier .env :"
    echo '  export $(cat .env | xargs)'
    echo "  ./deploy.sh"
    exit 1
fi

# Vérifier l'inventaire
if [ ! -f "inventory/hosts" ]; then
    echo -e "${YELLOW}⚠️  Fichier d'inventaire manquant${NC}"
    echo "Copie de l'exemple..."
    cp inventory/hosts.example inventory/hosts
    echo -e "${YELLOW}📝 Veuillez éditer inventory/hosts avec l'IP de votre Pi${NC}"
    exit 1
fi

# Vérifier les secrets
if [ ! -f "vars/secrets.yml" ]; then
    echo -e "${YELLOW}⚠️  Fichier secrets.yml manquant${NC}"
    echo "Copie de l'exemple..."
    cp vars/secrets.yml.example vars/secrets.yml
    echo -e "${YELLOW}📝 Veuillez éditer et chiffrer vars/secrets.yml${NC}"
    echo "  ansible-vault encrypt vars/secrets.yml"
    exit 1
fi

echo -e "${GREEN}✅ Prérequis vérifiés${NC}"
echo ""

# Test de connexion
echo -e "${BLUE}🔍 Test de connexion...${NC}"
if ansible -i inventory/hosts rpi -m ping --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD"); then
    echo -e "${GREEN}✅ Connexion réussie${NC}"
else
    echo -e "${RED}❌ Impossible de se connecter au Pi${NC}"
    echo "Vérifiez :"
    echo "- L'IP dans inventory/hosts"
    echo "- La connectivité réseau"
    echo "- Les clés SSH"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Lancement du déploiement...${NC}"
echo ""

# Exécuter le playbook
ansible-playbook \
    -i inventory/hosts \
    playbook.yml \
    --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD") \
    -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Déploiement terminé avec succès !${NC}"
    echo ""
    echo -e "${BLUE}📋 Informations de connexion :${NC}"
    echo "  • Wi-Fi AP: VPN-AccessPoint"
    echo "  • K3s API: https://10.0.0.1:6443"
    echo "  • SSH Pi: ssh $(grep ansible_user inventory/hosts | cut -d'=' -f3)@$(grep ansible_host inventory/hosts | cut -d'=' -f2)"
    echo ""
    echo -e "${BLUE}🛠 Commandes utiles :${NC}"
    echo "  • Statut K3s: ssh pi@IP 'k3s-manage status'"
    echo "  • Reset: ansible-playbook -i inventory/hosts reset.yml --vault-password-file <(echo \"\$ANSIBLE_VAULT_PASSWORD\")"
else
    echo -e "${RED}❌ Erreur lors du déploiement${NC}"
    exit 1
fi
