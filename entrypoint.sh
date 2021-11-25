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
        registry_json="/home/registry.json"
        echo -e "Default to Registry JSON file /home/registry.json"
  fi

  if cfg_haskey node_json; then
        node_json=$(cfg_read node_json)
        echo -e "Using Node JSON file $node_json"
  else
        node_json="/home/node.json"
        echo -e "Default to Registry JSON file /home/node.json"
  fi
}

###
# Main body of entrypoint script starts here
###

echo -e "\nStart of container entrypoint.sh BASH script..."

# If we were given arguments, override the default command and interpret in /bin/bash
if [ $# -gt 0 ]; then
   exec $@
   exit $?  # Make sure we really exit
fi

# Define path to configuration file globally
config_file="/home/container-config"

# Get global parameters and set defaults
do_params

# Adjust registry.json and node.json to update/add "label" with relevant "$(hostname)" data

echo -e "\nChecking for update_label parameter"
if cfg_haskey update_label && [ "$(cfg_read update_label)" = "TRUE" ]; then

    # Update label field in registry.json

    echo -e "Insert/Replace label: with $(hostname) hostname in $registry_json file"
    jq --arg key "$(hostname)-registry" '. + {label: $key}' "$registry_json" > /home/registry.json.tmp

    mv /home/registry.json.tmp $registry_json

    # Update label field in node.json

    echo -e "Insert/Replace label: with $(hostname) hostname in $node_json file"
    jq --arg key "$(hostname)-node" '. + {label: $key}' "$node_json" > /home/node.json.tmp
    mv /home/node.json.tmp $node_json
fi

# Adjust registry.json to update/add "ptp_domain_number" with relevant PTP Domain data if on a Mellanox switch

echo -e "\nChecking for update_ptp_domain parameter"
if cfg_haskey update_ptp_domain && [ "$(cfg_read update_ptp_domain)" = "TRUE" ]; then

    # Retrieve switch username and password from config file
    username=$(cfg_read switch_username)
    password=$(cfg_read switch_password)

    # Test for being on a Mellanox switch
    json_data="{\"username\": \""$username"\", \"password\": \""$password"\", \"cmd\": \"show ptp\", \"execution_type\": \"sync\"}"
    echo "Sending JSON: "$json_data
    curl -k -L -X POST -d "$json_data" -c /dev/null --connect-timeout 5 \
    "https://localhost/admin/launch?script=rh&template=json-request&action=json-login" > /home/ptp_data

    # If Error Code is 0 - Then we must be running on a Mellanox switch
    if [ $? -eq 0 ]; then

        # Test for OK response from switch in returned JSON output
        if [[ $(jq -r '.status' /home/ptp_data) == "OK" ]]; then

            # Recover PTP domain number from JSON output

            ptp_domain=$(jq -r '.data[0].Domain' /home/ptp_data)
            echo -e "BC PTP Domain on Mellanox Switch is set to: $ptp_domain"

            echo -e "Insert/Replace ptp_domain_number: with $ptp_domain in $registry_json file"
            jq --argjson key "$ptp_domain" '. + {ptp_domain_number: $key}' "$registry_json" > /home/registry.json.tmp
            mv /home/registry.json.tmp $registry_json

        else
            # We got an ERROR from the Switch report why we had error
            echo -e "Switch did not return valid PTP data. Error response from Mellanox switch is:"
            cat /home/ptp_data
        fi
    else
        # Not running on a Mellanox switch so report error
        echo -e "updata_ptp_domain set but not running on a Mellanox switch - not updating ptp_domain_number in $registry_json"
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

# Start Sony Registry, Sony Node and/or MQTT Broker inside correct directory with logging on or off
sleep 1

if [ -v RUN_NODE ] && [ "$RUN_NODE" = "TRUE" ]; then

    # Start Sony Node Application 

    echo -e "\nStarting Sony Node Application with following config"
    cat $node_json
    if cfg_haskey log_output && [ "$(cfg_read log_output)" = "TRUE" ]; then
        echo -e "\nStarting with file logging"
        /home/nmos-cpp-node $node_json >>/home/lognode-err.txt 2>/home/lognode-out.txt
    else
        echo -e "\nStarting with output to console"
        /home/nmos-cpp-node $node_json
    fi
    ret=$?

else

    # Start Mosquitto MQTT Broker service
    if cfg_haskey mqtt_port; then
        mqtt_port=$(cfg_read mqtt_port)
        echo -e "\nSetting MQTT Broker port to $mqtt_port"
        echo -e "\n#Automatically added by entrypoint.sh script on execution\nlistener $mqtt_port 0.0.0.0\nallow_anonymous true\n" >> /etc/mosquitto/mosquitto.conf
    else
        echo -e "\nUsing default MQTT Broker port of 1883"
    fi

    if cfg_haskey run_mqtt && [ "$(cfg_read run_mqtt)" = "TRUE" ]; then
        echo -e "\nStarting MQTT Broker Service"
        /etc/init.d/mosquitto start
        if cfg_haskey advertise_mqtt && [ "$(cfg_read advertise_mqtt)" = "TRUE" ]; then
            mqtt_instance="nmos-cpp_mqtt_$(hostname -I | cut -d ' ' -f1):$mqtt_port"
            echo -e "\nAdvertising MQTT Broker using mDNS instance: $mqtt_instance"
            dns-sd -R $mqtt_instance _nmos-mqtt._tcp local $mqtt_port api_proto=mqtt api_auth=false &
        else
            echo -e "\nNot advertising MQTT Broker"
        fi
    else
        echo -e "\nNot starting MQTT Broker Service"
    fi

    # Start Sony Registry Application

    echo -e "\nStarting Sony Registry Application with following config"
    cat $registry_json
    if cfg_haskey log_output && [ "$(cfg_read log_output)" = "TRUE" ]; then
        echo -e "\nStarting with file logging"
        /home/nmos-cpp-registry $registry_json >>/home/logreg-err.txt 2>/home/logreg-out.txt
    else
        echo -e "\nStarting with output to console"
        /home/nmos-cpp-registry $registry_json
    fi
    ret=$?
fi
echo -e "\nEnd of script..."

exit $ret  # Make sure we really exit
