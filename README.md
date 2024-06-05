# Easily manage subinterfaces on Ubuntu 22.04LTS

Built specifically for Ubuntu 22.04LTS, this repo hosts an interactive script that allows users to create and delete subinterfaces without having to worry about command line syntax or ensuring persistence of configuration after reboot.
Currently this shell script supports manually configured interfaces, as well as those expected to received addresses via DHCP.

## How to use

Clone this repo to your server, such as one deployed in Equinix Metal

```
git clone https://github.com/dtairych-equinix/ubuntu-vlan
```

Enter the directory and make the shell script executable

```
cd ubuntu-vlan
```
```
chmod +x interface.sh
```

You can then execute the script and follow the prompts
```
./interfaces.sh
```
