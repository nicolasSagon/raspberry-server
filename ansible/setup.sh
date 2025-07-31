#!/bin/bash
# Script de configuration initiale du projet
# Usage: ./setup.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Configuration initiale du projet Raspberry Pi VPN + K3s${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Configuration de l'inventaire
echo -e "\n${YELLOW}📝 Configuration de l'inventaire Ansible${NC}"
if [ ! -f "inventory/hosts" ]; then
    cp inventory/hosts.example inventory/hosts
    echo -e "${GREEN}✅ Fichier inventory/hosts créé${NC}"
else
    echo -e "${BLUE}ℹ️  Fichier inventory/hosts existe déjà${NC}"
fi

# Demander l'IP du Raspberry Pi
read -p "🌐 Entrez l'IP de votre Raspberry Pi (ex: 192.168.1.42): " PI_IP
read -p "👤 Entrez le nom d'utilisateur SSH (ex: pi): " PI_USER

# Mettre à jour l'inventaire
cat > inventory/hosts << EOF
[rpi]
raspberrypi ansible_host=${PI_IP} ansible_user=${PI_USER}
EOF

echo -e "${GREEN}✅ Inventaire configuré avec ${PI_USER}@${PI_IP}${NC}"

# 2. Configuration des secrets
echo -e "\n${YELLOW}🔐 Configuration des secrets VPN${NC}"
if [ ! -f "vars/secrets.yml" ]; then
    cp vars/secrets.yml.example vars/secrets.yml
    echo -e "${GREEN}✅ Fichier secrets.yml créé${NC}"
    
    echo "📝 Veuillez éditer vars/secrets.yml avec vos identifiants NordVPN"
    read -p "Voulez-vous l'éditer maintenant ? (y/N): " EDIT_SECRETS
    
    if [[ $EDIT_SECRETS =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} vars/secrets.yml
    fi
else
    echo -e "${BLUE}ℹ️  Fichier secrets.yml existe déjà${NC}"
fi

# 3. Configuration du mot de passe vault
echo -e "\n${YELLOW}🔑 Configuration du mot de passe vault${NC}"
if [ ! -f ".env" ]; then
    read -s -p "🔒 Entrez un mot de passe pour chiffrer le vault: " VAULT_PASSWORD
    echo
    
    echo "ANSIBLE_VAULT_PASSWORD='${VAULT_PASSWORD}'" > .env
    echo -e "${GREEN}✅ Fichier .env créé${NC}"
    
    # Chiffrer le fichier secrets si ce n'est pas déjà fait
    if ! grep -q "ANSIBLE_VAULT" vars/secrets.yml; then
        echo -e "${YELLOW}🔐 Chiffrement du fichier secrets.yml...${NC}"
        ansible-vault encrypt vars/secrets.yml --vault-password-file <(echo "$VAULT_PASSWORD")
        echo -e "${GREEN}✅ Fichier secrets.yml chiffré${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  Fichier .env existe déjà${NC}"
    source .env
fi

# 4. Test de connexion
echo -e "\n${YELLOW}🔍 Test de connexion au Raspberry Pi${NC}"
if ansible -i inventory/hosts rpi -m ping --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD") 2>/dev/null; then
    echo -e "${GREEN}✅ Connexion au Pi réussie${NC}"
else
    echo -e "${RED}❌ Impossible de se connecter au Pi${NC}"
    echo "Vérifiez :"
    echo "  • L'IP et l'utilisateur dans inventory/hosts"
    echo "  • La connectivité réseau"
    echo "  • Les clés SSH (ssh-copy-id ${PI_USER}@${PI_IP})"
fi

# 5. Résumé
echo -e "\n${BLUE}🎉 Configuration terminée !${NC}"
echo ""
echo -e "${GREEN}Fichiers créés/configurés :${NC}"
echo "  ✅ inventory/hosts"
echo "  ✅ vars/secrets.yml (chiffré)"
echo "  ✅ .env (mot de passe vault)"
echo ""
echo -e "${BLUE}Prochaines étapes :${NC}"
echo "  1. Vérifiez la connexion SSH : ssh ${PI_USER}@${PI_IP}"
echo "  2. Lancez le déploiement : ./deploy.sh"
echo ""
echo -e "${YELLOW}Variables d'environnement pour les prochaines sessions :${NC}"
echo "  source .env"
