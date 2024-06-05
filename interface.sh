#!/bin/bash

# Function to create a sub-interface on a specific VLAN and configure it for DHCP
create_subinterface() {
    read -p "Enter the parent interface (e.g., eth0): " parent_interface
    read -p "Enter the VLAN ID: " vlan_id
    sub_interface="${parent_interface}.${vlan_id}"

    # Check if the sub-interface already exists
    if ip link show dev "$sub_interface" &> /dev/null; then
        echo "Sub-interface $sub_interface already exists."
        return
    fi

    # Create the sub-interface
    ip link add link "$parent_interface" name "$sub_interface" type vlan id "$vlan_id"
    ip link set dev "$sub_interface" up

    # Configure the sub-interface for DHCP
    dhclient "$sub_interface"

    echo "Sub-interface $sub_interface created and configured for DHCP."
}

# Function to remove a sub-interface configuration
remove_subinterface() {
    read -p "Enter the sub-interface to remove (e.g., eth0.100): " sub_interface

    # Check if the sub-interface exists
    if ! ip link show dev "$sub_interface" &> /dev/null; then
        echo "Sub-interface $sub_interface does not exist."
        return
    fi

    # Remove the sub-interface
    ip link delete dev "$sub_interface"

    echo "Sub-interface $sub_interface removed."
}

# Main menu
while true; do
    echo "Select an option:"
    echo "1. Create a sub-interface on a specific VLAN and configure it for DHCP"
    echo "2. Remove a sub-interface configuration"
    echo "3. Exit"
    read -p "Enter your choice (1-3): " choice

    case "$choice" in
        1)
            create_subinterface
            ;;
        2)
            remove_subinterface
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
