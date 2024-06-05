#!/bin/bash

# Function to reload network interfaces
reload_interfaces() {
    # Reload systemd-networkd
    if systemctl restart systemd-networkd; then
        echo "Network interfaces reloaded successfully."
    else
        echo "Failed to reload network interfaces."
    fi
}

# Function to create a sub-interface on a specific VLAN and configure it
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

    # Prompt for IP configuration method
    read -p "Configure IP address manually (y/n)? " manual_ip
    if [[ "$manual_ip" =~ ^[Yy]$ ]]; then
        read -p "Enter the IP address: " ip_address
        read -p "Enter the subnet mask (CIDR eg. 24 for 255.255.255.0): " subnet_mask
        read -p "Enter the default gateway: " gateway
    fi

    # Write the sub-interface configuration to the systemd-networkd files
    config_file="/etc/systemd/network/${sub_interface}.netdev"
    {
        echo "[NetDev]"
        echo "Name=$sub_interface"
        echo "Kind=vlan"
        echo "  [VLAN]"
        echo "  Id=$vlan_id"
    } > "$config_file"

    config_file="/etc/systemd/network/${sub_interface}.network"
    {
        echo "[Match]"
        echo "Name=$sub_interface"
        if [[ "$manual_ip" =~ ^[Yy]$ ]]; then
            echo "[Network]"
            echo "Address=$ip_address/$subnet_mask"
            echo "Gateway=$gateway"
        else
            echo "[Network]"
            echo "DHCP=yes"
        fi
    } >> "$config_file"

    echo "Sub-interface $sub_interface created and configured."
    echo "Configuration written to $config_file"

    # Reload network interfaces
    reload_interfaces
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

    # Remove the sub-interface configuration files
    netdev_config_file="/etc/systemd/network/${sub_interface}.netdev"
    network_config_file="/etc/systemd/network/${sub_interface}.network"

    if [ -f "$netdev_config_file" ]; then
        rm "$netdev_config_file"
    fi

    if [ -f "$network_config_file" ]; then
        rm "$network_config_file"
    fi

    echo "Sub-interface $sub_interface removed, configuration files deleted."

    # Reload network interfaces
    reload_interfaces
}

# Main menu
while true; do
    echo "Select an option:"
    echo "1. Create a sub-interface on a specific VLAN and configure it"
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
