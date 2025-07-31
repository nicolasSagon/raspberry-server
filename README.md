# 🍓 Raspberry Pi 5 – Point d'accès VPN avec Kubernetes K3s

Ce projet transforme un **Raspberry Pi 5** en infrastructure complète comprenant :

- 📡 **Point d'accès Wi-Fi sécurisé** via NordVPN
- ⚙️ **Cluster Kubernetes K3s** isolé et sécurisé  
- 🚀 **Ready pour Pulumi** et déploiements cloud-native
- 🔒 **Sécurité réseau avancée** avec isolation des réseaux

Tout est automatisé avec **Ansible** pour un déploiement reproductible et sans erreur.

---

## 🏗️ Architecture du projet

```
┌─────────────────────────────────────────────────────────────────┐
│                     Raspberry Pi 5                             │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   Ethernet      │    │   Wi-Fi AP      │                   │
│  │  192.168.1.1    │    │   10.0.0.1      │                   │  
│  │  (WAN/SSH)      │    │  (VPN clients)   │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                            │
│           │              ┌─────────────────┐                   │
│           │              │   NordVPN       │                   │
│           │              │   (tun0)        │                   │
│           │              └─────────────────┘                   │
│           │                       │                            │
│  ┌─────────────────────────────────────────────────────────────┤
│  │              Kubernetes K3s Cluster                        │
│  │                                                             │
│  │  API Server: https://10.0.0.1:6443                        │
│  │  ✅ Accessible depuis VPN (10.0.0.0/24)                   │
│  │  ❌ Bloqué depuis WAN (192.168.1.0/24)                    │
│  │                                                             │
│  │  Namespaces: pulumi-system, development, production        │
│  └─────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Installation rapide

### 1. Prérequis

- Raspberry Pi 5 avec Debian Bookworm
- Ansible ≥ 2.10 sur votre machine
- Identifiants NordVPN

### 2. Configuration automatique

```bash
git clone https://github.com/nicolasSagon/raspberry-server.git
cd raspberry-server/ansible

# Configuration initiale interactive
./setup.sh
```

### 3. Déploiement simple

```bash
# Charger l'environnement
source .env

# Déployer
./deploy.sh
```

**Fini les `--ask-vault-pass` ! 🎉**

### 4. Vérifier

```bash
# Sur un client connecté au Wi-Fi "VPN-AccessPoint"
curl ifconfig.io  # Doit afficher une IP NordVPN

# Sur le Pi
kubectl get nodes
k3s-manage status
```

---

## 📖 Documentation détaillée

Pour une documentation complète, voir [ansible/README.md](ansible/README.md).

---

## 🔐 Sécurité et isolation

### Réseau VPN (10.0.0.0/24)
- ✅ Accès au cluster K3s
- ✅ API Kubernetes : `https://10.0.0.1:6443`
- ✅ Services NodePort : `10.0.0.1:30000-32767`
- ✅ Tout le trafic passe par NordVPN

### Réseau domestique (192.168.1.0/24)  
- ✅ Accès SSH au Pi : `192.168.1.1:22`
- ❌ **Pas d'accès** au cluster K3s
- ❌ **Bloqué** par firewall iptables

---

## 🚢 Utilisation avec Pulumi

### Récupérer le kubeconfig

```bash
scp pi@10.0.0.1:k3s-external.yaml ~/.kube/config-rpi
export KUBECONFIG=~/.kube/config-rpi
kubectl get nodes
```

### Exemple Pulumi Python

```python
import pulumi_kubernetes as k8s

# Provider K3s
k8s_provider = k8s.Provider(
    "rpi-k3s",
    kubeconfig="~/.kube/config-rpi"
)

# Déployer une app
app = k8s.apps.v1.Deployment(
    "my-app",
    spec=k8s.apps.v1.DeploymentSpecArgs(
        replicas=2,
        selector=k8s.meta.v1.LabelSelectorArgs(
            match_labels={"app": "my-app"}
        ),
        template=k8s.core.v1.PodTemplateSpecArgs(
            metadata=k8s.meta.v1.ObjectMetaArgs(
                labels={"app": "my-app"}
            ),
            spec=k8s.core.v1.PodSpecArgs(
                containers=[
                    k8s.core.v1.ContainerArgs(
                        name="app",
                        image="nginx:alpine",
                        ports=[k8s.core.v1.ContainerPortArgs(
                            container_port=80
                        )]
                    )
                ]
            )
        )
    ),
    opts=pulumi.ResourceOptions(provider=k8s_provider)
)
```

Un exemple complet est disponible dans `/home/pi/pulumi-examples/` sur le Pi.

---

## 🛠️ Gestion du cluster

### Script de gestion K3s

```bash
# Statut du cluster
k3s-manage status

# Logs du service
k3s-manage logs  

# Redémarrer K3s
k3s-manage restart

# Reset complet (⚠️ destructif)
k3s-manage reset
```

### Commandes kubectl utiles

```bash
# Infos cluster
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Namespaces disponibles
kubectl get namespaces

# Ressources système
kubectl top nodes
kubectl top pods --all-namespaces
```

---

## 🧼 Reset complet

Pour remettre le Pi dans son état initial :

```bash
ansible-playbook -i inventory/hosts reset.yml --ask-vault-pass
```

---

## 🤝 Contributions

Les contributions sont bienvenues ! N'hésitez pas à :

- 🐛 Signaler des bugs
- 💡 Proposer des améliorations  
- 📖 Améliorer la documentation
- ⭐ Mettre une étoile si le projet vous plaît

---

## 📄 Licence

Ce projet est sous licence Apache 2.0. Voir [LICENSE](LICENSE) pour plus de détails.

---

## 🙏 Remerciements

- [K3s](https://k3s.io/) pour Kubernetes léger
- [NordVPN](https://nordvpn.com/) pour les services VPN
- [Pulumi](https://pulumi.com/) pour l'infrastructure as code
- [Ansible](https://ansible.com/) pour l'automatisation
