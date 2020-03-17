#!/bin/bash
# Use Bash as default command shell

# Config file processing procedures
sed_escape() {
  sed -e 's/[]\/$*.^[]/\\&/g'
}

cfg_write() { # path, key, value
  cfg_delete "$1"
  echo "$1=$2" >> "$config_file"
}

cfg_read() { # path, key -> value
  test -f "$config_file" && grep "^$(echo "$1" | sed_escape)=" "$config_file" | sed "s/^$(echo "$1" | sed_escape)=//" | tail -1
}

cfg_delete() { # path, key
  test -f "$config_file" && sed -i "/^$(echo "$1" | sed_escape).*$/d" "$config_file"
}

cfg_haskey() { # path, key
  test -f "$config_file" && grep "^$(echo "$1" | sed_escape)=" "$config_file" > /dev/null
}

do_params() { # get global parameters from config file and set alternative defaults
  echo -e "\nReading global parameters and setting defaults"

  if cfg_haskey registry_json; then
        registry_json=$(cfg_read registry_json)
        echo -e "Using Registry JSON file $registry_json"
  else
        registry_json="/home/registry-json"
        echo -e "Default to Registry JSON file /home/registry-json"
  fi

}

###
# Main body of entrypoint script starts here
###

echo -e "\nStart of container entrypoint.sh BASH script..."

# If we were given arguments, override the default configuration and run /bin/bash
if [ $# -gt 0 ]; then
   exec /bin/bash
   exit $?  # Make sure we really exit
fi

# Define path to configuration file globally
config_file="/home/container-config"

# Get global parameters and set defaults
do_params

# Adjust registry-json to update/add "label" with relevant "$(hostname)" data

echo -e "\nChecking for update_label parameter"
if cfg_haskey update_label && [ "$(cfg_read update_label)" = "TRUE" ]; then
    echo -e "Insert/Replace label: with $(hostname) hostname in $registry_json file"
    jq --arg key "$(hostname)" '. + {label: $key}' "$registry_json" > /home/registry-json.tmp
    mv /home/registry-json.tmp $registry_json
fi

# Adjust registry-json to update/add "ptp_domain_number" with relevant PTP Domain data if on a Mellanox switch

echo -e "\nChecking for update_ptp_domain parameter"
if cfg_haskey update_ptp_domain && [ "$(cfg_read update_ptp_domain)" = "TRUE" ]; then

    # Retrieve switch username and password from config file
    username=$(cfg_read switch_username)
    password=$(cfg_read switch_password)

    # Test for being on a Mellanox switch
    json_data="{\"username\": \""$username"\", \"password\": \""$password"\", \"cmd\": \"show ptp\", \"execution_type\": \"sync\"}"
    echo "Sending JSON: "$json_data
    curl -k -L -X POST -d "$json_data" -c /dev/null \
    "https://localhost/admin/launch?script=rh&template=json-request&action=json-login" > /home/ptp_data

    # If Error Code is 0 - Then we must be running on a Mellanox switch
    if [ $? -eq 0 ]; then

        # Test for OK response from switch in returned JSON output
        if [[ $(jq -r '.status' /home/ptp_data) == "OK" ]]; then

            # Recover PTP domain number from JSON output

            ptp_domain=$(jq -r '.data[0].Domain' /home/ptp_data)
            echo -e "BC PTP Domain on Mellanox Switch is set to: $ptp_domain"

            echo -e "Insert/Replace ptp_domain_number: with $ptp_domain in $registry_json file"
            jq --argjson key "$ptp_domain" '. + {ptp_domain_number: $key}' "$registry_json" > /home/registry-json.tmp
            mv /home/registry-json.tmp $registry_json

        else
            # We got an ERROR from the Switch report why we had error
            echo -e "Switch did not return valid PTP data. Error response from Mellanox switch is:"
            cat /home/ptp_data
        fi
    else
        # Not running on a Mellanox switch so report error
        echo -e "updata_ptp_domain set but not running on a Mellanox switch - not updating ptp_domain_number in registry-json"
    fi
    # Clean up /home/ptp_data file
    rm /home/ptp_data
fi

# You should use either Avahi or Apple mDNS - DO NOT use both
#
# mDNSResponder 878.30.4
echo -e "\nStarting mDNSResponder service"
/etc/init.d/mdns start
# Avahi
#echo -e "\nStarting dbus and avahi services"
#/etc/init.d/dbus start
#/etc/init.d/avahi-daemon start

# Start Sony Registry Application inside correct directory with logging on or off
sleep 1

echo -e "\nStarting Sony Registry Application with following congfig"
cat $registry_json
if cfg_haskey log_registry && [ "$(cfg_read log_registry)" = "TRUE" ]; then
    echo -e "\nStarting with Logging enabled"
    /home/nmos-cpp-registry $registry_json >>/home/logreg-err.txt 2>/home/logreg-out.txt
else
    echo -e "\nStarting with Logging disabled"
    /home/nmos-cpp-registry $registry_json > /dev/null
fi
ret=$?

echo -e "\nEnd of script..."

exit $ret  # Make sure we really exit
