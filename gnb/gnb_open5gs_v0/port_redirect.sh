#!/bin/bash

# Script to manage port redirection 2152 -> 2153
# Usage: ./port_redirect.sh [add|remove]
# This is useful for switching between local and remote Open5GS configurations

RULE="OUTPUT -p udp --dport 2152 -j REDIRECT --to-ports 2153"

show_usage() {
    echo "Usage: $0 [add|remove]"
    echo ""
    echo "Commands:"
    echo "  add     - Add port redirection 2152 -> 2153 (for local Open5GS)"
    echo "  remove  - Remove port redirection (for remote Open5GS)"
    echo ""
    echo "This script manages iptables NAT rules for gNB N3 interface port redirection."
    echo "Local Open5GS uses custom port 2153, while remote uses standard port 2152."
}

check_rule_exists() {
    iptables -t nat -C $RULE 2>/dev/null
    return $?
}

add_redirect() {
    if check_rule_exists; then
        echo "✓ Port redirection 2152 -> 2153 already exists"
        return 0
    fi
    
    echo "Adding port redirection 2152 -> 2153..."
    if sudo iptables -t nat -A $RULE; then
        echo "✓ Port redirection added successfully"
        echo "  gNB traffic to port 2152 will be redirected to port 2153"
        echo "  Use this configuration with gnb_local.yml"
    else
        echo "✗ Failed to add port redirection"
        return 1
    fi
}

remove_redirect() {
    if ! check_rule_exists; then
        echo "✓ Port redirection 2152 -> 2153 does not exist"
        return 0
    fi
    
    echo "Removing port redirection 2152 -> 2153..."
    if sudo iptables -t nat -D $RULE; then
        echo "✓ Port redirection removed successfully"
        echo "  gNB will use standard port 2152"
        echo "  Use this configuration with gnb.yml (remote Open5GS)"
    else
        echo "✗ Failed to remove port redirection"
        return 1
    fi
}

show_status() {
    echo "Current iptables NAT rules for port 2152:"
    echo "=========================================="
    sudo iptables -t nat -L OUTPUT -n --line-numbers | grep -E "(Chain|2152)" || echo "No port 2152 rules found"
    echo ""
    
    if check_rule_exists; then
        echo "Status: Port redirection 2152 -> 2153 is ACTIVE"
        echo "Recommended config: gnb_local.yml (local Open5GS)"
    else
        echo "Status: No port redirection (standard port 2152)"
        echo "Recommended config: gnb.yml (remote Open5GS)"
    fi
}

# Main script logic
case "$1" in
    add)
        add_redirect
        echo ""
        show_status
        ;;
    remove)
        remove_redirect
        echo ""
        show_status
        ;;
    status)
        show_status
        ;;
    "")
        show_usage
        echo ""
        show_status
        ;;
    *)
        echo "Error: Invalid argument '$1'"
        show_usage
        exit 1
        ;;
esac
