# 📡 Raspberry Pi 5 – Point d’accès Wi-Fi avec NordVPN (via Ansible)

Ce projet transforme un Raspberry Pi 5 sous **Debian** en point d’accès Wi-Fi sécurisé, routé via **NordVPN**, le tout automatisé avec **Ansible**.

---

## 🔧 Prérequis

### Matériel
- Raspberry Pi 5 (avec Wi-Fi intégré)
- Carte SD (min. 8 Go)
- Alimentation
- Connexion Ethernet pour l'installation

### Logiciel requis sur ton poste
- Ansible ≥ 2.10  
  ```bash
  sudo apt install ansible
  ```
- Git, SSH
- Optionnel : `sshpass` si tu utilises un mot de passe au lieu d’une clé SSH

---

## 🚀 Étape 1 : Installer Debian sur le Raspberry Pi 5

### ✅ Option recommandée : Raspberry Pi Imager

1. Télécharge [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Choisis **Debian Bookworm ARM64 Lite**
3. Avant de flasher :
   - Clique sur ⚙️ :
     - **Nom d’hôte** : `rpi5`
     - **Activer SSH**
     - **Utilisateur** : `pi` / mot de passe `raspberry` *(ou autre)*
4. Flashe l’image sur la carte SD
5. Insère la carte SD dans le Pi et branche-le en **Ethernet**

---

## 🌐 Étape 2 : Connexion initiale au Raspberry Pi

Depuis ton PC :

```bash
ping rpi5.local
ssh pi@rpi5.local
# ou remplace par l'IP si mDNS ne fonctionne pas
```

---

## 📁 Étape 3 : Cloner ce dépôt

```bash
git clone https://github.com/ton-user/raspberrypi-wifi-vpn.git
cd raspberrypi-wifi-vpn
```

Arborescence :

```bash
inventory/
  hosts
roles/
  base/
  wifi_ap/
  vpn/
  firewall/
playbook.yml
```

---

## 🗂️ Étape 4 : Configurer l’inventaire Ansible

Dans `inventory/hosts` :

```bash
[rpi]
rpi5 ansible_host=192.168.1.42 ansible_user=pi ansible_ssh_pass=raspberry
```

---

## ⚙️ Étape 5 : Personnaliser les variables

Tu peux éditer `group_vars/all.yml` :

- `wifi_ssid`: Nom du réseau Wi-Fi à créer
- `wifi_password`: Mot de passe
- `nordvpn_user` / `nordvpn_pass` : Identifiants NordVPN

---

## ▶️ Étape 6 : Lancer le déploiement

```bash
ansible-playbook -i inventory/hosts playbook.yml 
```

---

## 📡 Résultat attendu

- Un réseau Wi-Fi nommé `VPN-AccessPoint`
- Tous les clients connectés passent par **NordVPN**
- Le Pi reste accessible en SSH via Ethernet (`rpi5.local`)
- **Cluster Kubernetes K3s** configuré et sécurisé :
  - API Server : `https://10.0.0.1:6443`
  - Accessible uniquement depuis le réseau VPN (`10.0.0.0/24`)
  - Bloqué depuis le réseau domestique (`192.168.1.0/24`)
  - Prêt pour les déploiements **Pulumi**

---

## 🧼 Nettoyage / Reset

```bash
ansible-playbook -i inventory/hosts reset.yml
```

Ce playbook optionnel remet à zéro le système réseau du Pi.

---

## 🧠 Notes

- Le rôle VPN installe **OpenVPN** et se connecte à NordVPN via `auth-user-pass`.
- Le Wi-Fi est géré par `hostapd` et `dnsmasq`.
- Un firewall `iptables` redirige tout le trafic vers l’interface VPN uniquement.

---

## ✅ Vérifications post-installation

Sur un client connecté au Wi-Fi :

```bash
curl ifconfig.io
# ➜ tu dois voir une IP NordVPN
```

Sur le Pi lui-même :

```bash
systemctl status openvpn-client@nordvpn
```

### 🚢 K3s Kubernetes Cluster

Le cluster K3s est maintenant configuré et sécurisé :

```bash
# Vérifier le statut du cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Utiliser le script de gestion
k3s-manage status
k3s-manage logs
```

#### 🔗 Connexion depuis Pulumi

Pour connecter Pulumi à ton cluster K3s :

1. **Récupérer le kubeconfig** :
   ```bash
   scp pi@10.0.0.1:k3s-external.yaml ~/.kube/config-rpi
   export KUBECONFIG=~/.kube/config-rpi
   ```

2. **Tester la connexion** :
   ```bash
   kubectl get nodes
   # ➜ doit afficher ton Raspberry Pi
   ```

3. **Utiliser avec Pulumi** :
   ```python
   import pulumi_kubernetes as k8s
   
   k8s_provider = k8s.Provider(
       "rpi-k3s",
       kubeconfig="~/.kube/config-rpi"
   )
   ```

#### 🔒 Sécurité K3s

- ✅ **API Server accessible uniquement depuis le VPN** (`10.0.0.0/24`)
- ❌ **Bloqué depuis le réseau domestique** (`192.168.1.0/24`)  
- 🔧 **Ports sécurisés** : 6443 (API), 10250 (Kubelet), 30000-32767 (NodePort)

#### 📁 Namespaces disponibles

- `pulumi-system` - Pour les ressources Pulumi
- `development` - Environnement de développement
- `production` - Environnement de production  
- `monitoring` - Outils de supervision

---

## 📄 Licence

MIT – libre d’utilisation, modification et partage.

