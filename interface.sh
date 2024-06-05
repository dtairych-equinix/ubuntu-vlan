#!/bin/bash

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
        read -p "Enter the subnet mask: " subnet_mask
        read -p "Enter the default gateway: " gateway
    fi

    # Write the sub-interface configuration to the interfaces file
    config_file="/etc/network/interfaces.d/${sub_interface}.cfg"
    echo "auto $sub_interface" > "$config_file"
    if [[ "$manual_ip" =~ ^[Yy]$ ]]; then
        echo "iface $sub_interface inet static" >> "$config_file"
        echo "address $ip_address" >> "$config_file"
        echo "netmask $subnet_mask" >> "$config_file"
        echo "gateway $gateway" >> "$config_file"
    else
        echo "iface $sub_interface inet dhcp" >> "$config_file"
    fi
    echo "vlan-raw-device $parent_interface" >> "$config_file"

    echo "Sub-interface $sub_interface created and configured."
    echo "Configuration written to $config_file"
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

    # Remove the sub-interface configuration file
    config_file="/etc/network/interfaces.d/${sub_interface}.cfg"
    if [ -f "$config_file" ]; then
        rm "$config_file"
        echo "Sub-interface $sub_interface removed, configuration file $config_file deleted."
    else
        echo "Sub-interface $sub_interface removed."
    fi
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
