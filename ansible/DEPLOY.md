# 🚀 Guide de déploiement rapide

Ce guide te permet de déployer ton Raspberry Pi VPN + K3s sans te soucier des mots de passe vault !

## 📦 Configuration initiale (une seule fois)

```bash
cd ansible
./setup.sh
```

Ce script va :
1. ✅ Configurer l'inventaire avec l'IP de ton Pi
2. ✅ Créer et chiffrer le fichier secrets.yml
3. ✅ Configurer le mot de passe vault dans `.env`
4. ✅ Tester la connexion au Pi

## 🚀 Déploiement automatique

```bash
# Charger les variables d'environnement
source .env

# Déployer
./deploy.sh
```

## 🧼 Reset si nécessaire

```bash
source .env
./reset.sh
```

## 🔑 Variables d'environnement

Le fichier `.env` contient :
```bash
# ⚠️ Important: Utilisez des guillemets simples pour les caractères spéciaux
ANSIBLE_VAULT_PASSWORD='your_vault_password'
```

**Caractères spéciaux à protéger :** `&`, `$`, `!`, `*`, `?`, `(`, `)`, `[`, `]`, `{`, `}`, `;`, `<`, `>`, `|`

### Alternative : Export manuel

Si tu préfères ne pas utiliser le fichier `.env` :

```bash
# Avec guillemets pour protéger les caractères spéciaux
export ANSIBLE_VAULT_PASSWORD='ton_mot_de_passe_vault'
./deploy.sh
```

### Pour ton bashrc/zshrc (permanent)

Ajoute dans `~/.bashrc` ou `~/.zshrc` :
```bash
export ANSIBLE_VAULT_PASSWORD="ton_mot_de_passe_vault"
```

## 🛠️ Commandes manuelles si besoin

Si tu veux toujours utiliser ansible directement :

```bash
# Déploiement
ansible-playbook -i inventory/hosts playbook.yml --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD")

# Reset  
ansible-playbook -i inventory/hosts reset.yml --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD")

# Test de connexion
ansible -i inventory/hosts rpi -m ping --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD")
```

## 🔒 Sécurité

- ✅ Le fichier `.env` est dans `.gitignore` (pas de commit accidentel)
- ✅ Le vault reste chiffré avec ansible-vault
- ✅ Seul le mot de passe est en variable d'environnement

## 🎯 Workflow complet

```bash
# 1. Setup initial (une fois)
cd ansible
./setup.sh

# 2. Pour chaque déploiement
source .env
./deploy.sh

# 3. Si besoin de reset
source .env  
./reset.sh
```

**Plus jamais besoin de taper `--ask-vault-pass` ! 🎉**
