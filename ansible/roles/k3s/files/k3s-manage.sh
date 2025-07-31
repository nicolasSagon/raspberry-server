#!/bin/bash
# K3s Cluster Management Script
# Usage: k3s-manage.sh [status|logs|restart|reset]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_status() {
    echo -e "${BLUE}📊 K3s Cluster Status${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo -e "\n${GREEN}🔧 Service Status:${NC}"
    systemctl status k3s --no-pager | head -10
    
    echo -e "\n${GREEN}🖥 Node Status:${NC}"
    kubectl get nodes -o wide
    
    echo -e "\n${GREEN}📦 Running Pods:${NC}"
    kubectl get pods --all-namespaces
    
    echo -e "\n${GREEN}🔌 Services:${NC}"
    kubectl get services --all-namespaces
    
    echo -e "\n${GREEN}🌐 Network Info:${NC}"
    echo "API Server: https://10.0.0.1:6443"
    echo "Cluster CIDR: 10.42.0.0/16"
    echo "Service CIDR: 10.43.0.0/16"
    
    echo -e "\n${GREEN}💾 Resource Usage:${NC}"
    if command -v kubectl top &> /dev/null; then
        kubectl top nodes 2>/dev/null || echo "Metrics server not ready yet"
    fi
}

function show_logs() {
    echo -e "${BLUE}📋 K3s Service Logs${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    journalctl -u k3s --no-pager -n 50
}

function restart_k3s() {
    echo -e "${YELLOW}🔄 Restarting K3s...${NC}"
    systemctl restart k3s
    echo -e "${GREEN}✅ K3s restarted${NC}"
    
    echo "Waiting for API server to be ready..."
    sleep 10
    kubectl get nodes
}

function reset_k3s() {
    echo -e "${RED}⚠️  WARNING: This will completely reset the K3s cluster!${NC}"
    echo "All deployments, services, and persistent data will be lost."
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    
    if [[ $confirm == "yes" ]]; then
        echo -e "${YELLOW}🔄 Resetting K3s cluster...${NC}"
        
        # Stop the service
        systemctl stop k3s
        
        # Run the uninstall script if it exists
        if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
            /usr/local/bin/k3s-uninstall.sh
        fi
        
        # Clean up any remaining files
        rm -rf /etc/rancher/k3s/
        rm -rf /var/lib/rancher/k3s/
        rm -rf /var/lib/kubelet/
        rm -rf /home/*/k3s-external.yaml
        rm -rf /home/*/.kube/
        rm -rf /root/.kube/
        
        echo -e "${GREEN}✅ K3s cluster reset complete${NC}"
        echo "You can reinstall by running the Ansible playbook again."
    else
        echo -e "${BLUE}🛑 Reset cancelled${NC}"
    fi
}

function show_help() {
    echo -e "${BLUE}🛠 K3s Cluster Management${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status    - Show cluster status and information"
    echo "  logs      - Show K3s service logs"  
    echo "  restart   - Restart K3s service"
    echo "  reset     - Reset cluster (WARNING: destructive)"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs"
    echo "  $0 restart"
}

# Main logic
case "${1:-status}" in
    "status")
        print_status
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        restart_k3s
        ;;
    "reset")
        reset_k3s
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
