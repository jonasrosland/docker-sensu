#!/bin/sh
DASHBOARD_USER=${DASHBOARD_USER:-admin}
DASHBOARD_PASS=${DASHBOARD_PASS:-sensu}
SENSU_HOST=${SENSU_HOST:-localhost}
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
REDIS_HOST=${REDIS_HOST:-redis}
SKIP_CONFIG=${SKIP_CONFIG:-}
SENSU_CONFIG_URL=${SENSU_CONFIG_URL:-}
SENSU_CLIENT_CONFIG_URL=${SENSU_CLIENT_CONFIG_URL:-}
SENSU_CHECKS_CONFIG_URL=${SENSU_CHECKS_CONFIG_URL:-}

if [ ! -z "$SENSU_CONFIG_URL" ] ; then
    wget --no-check-certificate -O /etc/sensu/config.json $SENSU_CONFIG_URL
else
    if [ ! -e "/etc/sensu/config.json" ] ; then
        cat << EOF > /etc/sensu/config.json
{
  "rabbitmq": {
    "port": 5672,
    "host": "$RABBITMQ_HOST",
    "user": "sensu",
    "password": "sensu",
    "vhost": "/"
  },
  "redis": {
    "host": "$REDIS_HOST",
    "port": 6379
  },
  "api": {
    "host": "$SENSU_HOST",
    "port": 4567
  },
  "handlers": {
    "default": {
      "type": "pipe",
      "command": "true"
    }
  }
}

EOF
    fi
fi

if [ ! -z "$SENSU_CLIENT_CONFIG_URL" ] ; then
    wget --no-check-certificate -O /etc/sensu/conf.d/client.json $SENSU_CLIENT_CONFIG_URL
else
    if [ ! -e "/etc/sensu/conf.d/client.json" ] ; then
    cat << EOF > /etc/sensu/conf.d/client.json
{
    "client": {
      "name": "sensu-server",
      "address": "127.0.0.1",
      "subscriptions": [ "default", "sensu" ]
    }
}
EOF
    fi
fi

if [ ! -z "$SENSU_CHECKS_CONFIG_URL" ] ; then
    wget --no-check-certificate -O /etc/sensu/conf.d/checks.json $SENSU_CHECKS_CONFIG_URL
else
    if [ ! -e "/etc/sensu/conf.d/checks.json" ] ; then
    	cat << EOF > /etc/sensu/conf.d/checks.json
{
  "checks": {
    "sensu-rabbitmq-beam": {
      "handlers": [
        "default"
      ],
      "command": "/etc/sensu/plugins/processes/check-procs.rb -p beam -C 1 -w 4 -c 5",
      "interval": 60,
      "occurrences": 2,
      "refresh": 300,
      "subscribers": [ "sensu" ]
    },
    "sensu-rabbitmq-epmd": {
      "handlers": [
        "default"
      ],
      "command": "/etc/sensu/plugins/processes/check-procs.rb -p epmd -C 1 -w 1 -c 1",
      "interval": 60,
      "occurrences": 2,
      "refresh": 300,
      "subscribers": [ "sensu" ]
    },
    "sensu-redis": {
      "handlers": [
        "default"
      ],
      "command": "/etc/sensu/plugins/processes/check-procs.rb -p redis-server -C 1 -w 4 -c 5",
      "interval": 60,
      "occurrences": 2,
      "refresh": 300,
      "subscribers": [ "sensu" ]
    },
    "sensu-api": {
      "handlers": [
        "default"
      ],
      "command": "/etc/sensu/plugins/processes/check-procs.rb -p sensu-api -C 1 -w 4 -c 5",
      "interval": 60,
      "occurrences": 2,
      "refresh": 300,
      "subscribers": [ "sensu" ]
    },
    "sensu-dashboard": {
      "handlers": [
        "default"
      ],
      "command": "/etc/sensu/plugins/processes/check-procs.rb -p sensu-dashboard -C 1 -w 1 -c 1",
      "interval": 60,
      "occurrences": 2,
      "refresh": 300,
      "subscribers": [ "sensu" ]
    }
  }
}
EOF
  fi
fi

/usr/bin/supervisord
