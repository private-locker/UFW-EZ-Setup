# !/bin/bash
# REDD's Firewall "Made Easy" Script
# Gift from REDD to the IT friends.
#
# This will set Open Ports for UFW Firewall.
# Open standard SSH and DNS ports.
# ./firewall.sh
#
# Open custom ports and SSH/DNS ports.
# ./firewall.sh 7000 7001 7002


# Allow LAN Variable - to allow set "YES"
ALLOWLAN="YES"
# Allow IPv6 Variable - to allow set "YES"
IP6="NO"

# Script Colors
DEF="\e[39m"
RED="\e[91m"
CYN="\e[36m"
LBL="\e[94m"

defterm(){
        echo -e "${LBL} -> ${CYN}$1${DEF}";
}
# Check for root priviliges
if [[ $EUID -ne 0 ]]; then
   printf "${RED}Please run as root:\nsudo %s\n${DEF}" "${0}"
   exit 1
fi
if [ -z "$1" ];then
        # Double check/set Variables to make sure they're set to NOTASSIGNED if no input
        NOPORTS=1
else
        NUMCHK='^[0-9]+$'
        # Check for user defined Ports
        for ((i = 1; i <= $#; i++ )); do
                if ! [[ ${!i} =~ $NUMCHK ]] ; then
                        echo "${RED}ERROR: Argument $i is not a numberic value.${DEF}" >&2; exit 1
                fi
                PORT[$i]=${!i};
        done
        NOPORTS=0
fi
defterm "Resetting UFW Configuration."
# Reset the ufw config
ufw --force reset
defterm "Setting Default Rules. (Deny Incoming/Allow Outgoing)"
# Allow all outgoing traffic pass
ufw default deny incoming
ufw default allow outgoing
defterm "Allowing DNS and SSH Connections to Local Machine."
# Allow DNS queries
ufw allow proto tcp to 0.0.0.0/0 port 53
# Allow SSH Port
ufw allow proto tcp to 0.0.0.0/0 port 22

# Allow incoming port determined from user input
if [[ "$NOPORTS" == "0" ]]; then
        defterm "Enabling custom ports."
        for ((i = 1; i <= $#; i++ )); do
                ufw allow in ${!i};
        done
else
        defterm "No Custom Ports enabled."
fi

if [[ "$ALLOWLAN" == "YES" ]]; then
        defterm "Allowing Local connections and multicasts from LAN."
        # Allow local IPv4 connections
        ufw allow in from 10.0.0.0/8
        ufw allow in from 192.168.0.0/16
        # Allow IPv4 local multicasts
        ufw allow in from 224.0.0.0/24
        ufw allow in from 239.0.0.0/8
        if [[ "$IP6" == "YES" ]]; then
                # Allow local IPv6 connections
                ufw allow in from fe80::/64
                # Allow IPv6 link-local multicasts
                ufw allow in from ff01::/16
                # Allow IPv6 site-local multicasts
                ufw allow in from ff02::/16
                ufw allow in from ff05::/16
        fi
else
        defterm "Not Allowing Local connections and multicasts from LAN."
fi

# Enable the firewall
defterm "Enabling UFW on Local Machine."
ufw enable

# Show "UFW Status" Command to Display what has been enabled.
ufw status numbered

defterm "Type \"ufw delete #\" to delete specific rule."
echo -e ""
exit 0
