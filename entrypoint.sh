#!/bin/bash
# Use Bash as default command shell

#Config file processing procedures
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
  echo "Reading global paramets and setting defaults"

  if cfg_haskey registry_json; then
        registry_json=$(cfg_read registry_json)
	echo "Using Registry JSON file $registry_json"
  else
        registry_json="/home/registry-json"
	echo "Default to Registry JSON file /home/registry-json"
  fi
 
}

###
# Main body of entrypoint script starts here
###

# If we were given arguments, override the default configuration and run /bin/bash
if [ $# -gt 0 ]; then
   exec /bin/bash fi
   exit $?  # Make sure we really exit
fi

# Define path to configuration file globally
config_file="/home/container-config"

# Get global parameters and set defaults
do_params

# You should use either Avahi or Apple mDNS - DO NOT use both
#
# mDNSResponder 878.30.4
#   /etc/init.d/mdns start
# Avahi
/etc/init.d/dbus start
/etc/init.d/avahi-daemon start

# Adjust registry-json to update/add "label" with relevant "$(hostname)" data

if cfg_haskey update_label && [ "$(cfg_read update_label)" = "TRUE" ]; then
    if grep "label" /home/registry-json; then
        echo "Replacing label: with $(hostname) hostname in registry-json file"
        sed -i.bak "s/\(\"label\":\)[^,]*,/\"label\": \"$(hostname)\",/g" registry-json
    else
        echo "Inserting label: with $(hostname) hostname in registry-json file"
        sed -i.bak "$(( $( wc -l < registry-json) -2 ))s/$/\n\"label\": \"$(hostname)\",/" registry-json
    fi
fi

# Start Sony Registry Application inside correct directory with logging on or off
sleep 1

if cfg_haskey log_registry && [ "$(cfg_read log_registry)" = "TRUE" ]; then  
   /home/nmos-cpp-registry $registry_json >>/home/logreg-err.txt 2>/home/logreg-out.txt
else
   /home/nmos-cpp-registry $registry_json > /dev/null
fi

exit $?  # Make sure we really exit



cfg_read run
output=$(cfg_read run)
echo $output

if cfg_haskey another; then
	echo $(cfg_read testparam)
else
        echo "NOTHING"
fi

cfg_delete another

if cfg_haskey another; then
	echo $(cfg_read testparam)
else
        echo "NOTHING"
fi
cfg_delete another

echo "End of script..."
