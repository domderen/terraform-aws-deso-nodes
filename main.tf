terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

locals {
  deso_dns                        = "${var.name}.${var.deso_public_hosted_zone}"
  startup_lifecycle_hook_name     = "startup"
  termination_lifecycle_hook_name = "termination"

  deso_frontend_healthcheck_port = 8081

  user_data = <<-EOT
  #!/bin/bash
  
  echo "Creating directory for deso."
  mkdir /deso-node

  echo "Starting DeSo node initalization."
  INSTANCE_ID="`wget -q -O - http://instance-data/latest/meta-data/instance-id`"
  REGION="`wget -q -O - http://instance-data/latest/meta-data/placement/region`"
  LIFECYCLE_HOOK_NAME = "${local.startup_lifecycle_hook_name}"
  ASG_NAME = "${var.name}"

  echo "Updating system & installing required software."
  sudo yum update -y
  sudo yum install -y \
    docker git \
    python37 \
    python3-devel.$(uname -m) libpython3.7-dev \
    libffi-devel openssl-devel
  sudo yum groupinstall -y "Development Tools"
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

  echo "Informing ASG lifesyscle action heartbeat."
  aws autoscaling record-lifecycle-action-heartbeat --instance-id $INSTANCE_ID --lifecycle-hook-name $LIFECYCLE_HOOK_NAME --auto-scaling-group-name $ASG_NAME --region $REGION

  echo "Starting docker service."
  sudo systemctl enable docker.service
  sudo systemctl start docker.service

  echo "Creating Deso Frontend Caddy File."
  cat > /deso-node/Caddyfile.dev <<EOL
  {
      admin off
      auto_https off
  }

  :8080 {
      file_server
      try_files {path} index.html

      header Access-Control-Allow-Methods "GET, PUT, POST, DELETE, OPTIONS"
      header Access-Control-Allow-Origin "*"
      header Content-Security-Policy "
        default-src 'self';
        connect-src 'self'
          api.bitclout.com bitclout.com:*
          bithunt.bitclout.com pulse.bitclout.com
          api.bitpop.dev
          ${local.deso_dns}:* api.${local.deso_dns}:*
          localhost:*
          explorer.bitclout.com:*
          https://api.blockchain.com/ticker
          https://api.blockchain.com/mempool/fees
          https://ka-f.fontawesome.com/
          bitcoinfees.earn.com
          api.blockcypher.com 
          amp.bitclout.com
          api.bitclout.green api.bitclout.blue
          api.bitclout.navy
          api.testwyre.com
          api.sendwyre.com
          https://videodelivery.net
          https://upload.videodelivery.net;
        script-src 'self' https://cdn.jsdelivr.net/npm/sweetalert2@10
          https://kit.fontawesome.com/070ca4195b.js https://ka-f.fontawesome.com/ https://bitclout.com/tags.js;
        style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
        img-src 'self' data: i.imgur.com images.bitclout.com quickchart.io arweave.net *.arweave.net cloudflare-ipfs.com;
        font-src 'self' https://fonts.googleapis.com
          https://fonts.gstatic.com https://ka-f.fontawesome.com;
        frame-src 'self' localhost:*
          identity.bitclout.com identity.bitclout.blue identity.bitclout.green
          identity.deso.org identity.deso.blue identity.deso.green
          https://www.youtube.com
          https://player.vimeo.com
          https://www.tiktok.com
          https://giphy.com
          https://open.spotify.com
          https://w.soundcloud.com
          https://player.twitch.com
          https://clips.twitch.com
          pay.testwyre.com
          pay.sendwyre.com
          https://iframe.videodelivery.net;"
  }

  :${local.deso_frontend_healthcheck_port} {
    respond /health-check 200
  }
  EOL

  echo "Creating Deso Backend environment variables file."
  cat > /deso-node/dev.env <<EOL
  # A miner is started if and only if this field is set. Indicates where to send
  # block rewards from mining blocks. Public keys must be
  # comma-separated compressed ECDSA public keys formatted as base58 strings.
  MINER_PUBLIC_KEYS=${var.miner_public_keys}

  # How many threads to run for mining. Only has an effect when --miner_public_keys
  # is set. If set to zero, which is the default, then the number of
  # threads available to the system will be used.
  NUM_MINING_THREADS=2

  # admin_public_keys is list of public keys delimited by a space
  # which gives users access to the admin panel. If '*' is specified 
  # anyone can access the admin panel. 
  ADMIN_PUBLIC_KEYS=${var.admin_public_keys}

  # super_admin_public_keys is a list of public keys delimited by a space
  # which gives users access to the super tab of the admin panel and select endpoints
  # for these privileged users.  At this time, super admins can adjust the reserve price
  # at which this node will sell $DESO, set the slippage fee applied to $DESO buys,
  # and manage verification of users on this node. 
  SUPER_ADMIN_PUBLIC_KEYS=${var.super_admin_public_keys}

  # Optional. Twilio account SID (string id). Twilio is used for sending 
  # verification texts. See twilio documentation for more info.
  TWILIO_ACCOUNT_SID=

  # Optional. Twilio authentication token. See twilio documentation for more info.
  TWILIO_AUTH_TOKEN=

  # Optional. ID for a verify service configured within Twilio (used for
  # verification texts)
  TWILIO_VERIFY_SERVICE_ID=

  # Optional. Show a support email to users of this node.
  SUPPORT_EMAIL=${var.support_email}

  ### Environment vars for the backend image

  # The log level. 0 = INFO, 1 = DEBUG, 2 = TRACE. Defaults to zero
  GLOG_V=0

  # The syntax of the argument is a comma-separated list of pattern=N
  # where pattern is a literal file name (minus the ".go" suffix) or "glob"
  # pattern and N is a V level. For instance, -vmodule=gopher*=3 sets the V
  # level to 3 in all Go files whose names begin "gopher".
  GLOG_VMODULE=

  # Whether or not to use the DeSo testnet. Mainnet is used by default.
  TESTNET=false

  # A comma-separated list of ip:port addresses that we should listen on.
  # These will take priority over addresses discovered by network
  # interfaces.
  EXTERNAL_IPS=

  # A comma-separated list of ip:port addresses that we should connect to on startup.
  # If this argument is specified, we don't connect to any other peers.
  CONNECT_IPS=

  # A comma-separated list of ip:port addresses that we should connect to on startup.
  # If this argument is specified, we will still fetch addresses from DNS seeds and
  # potentially connect to them.
  ADD_IPS=

  # A comma-separated list of DNS seeds to be used in addition to the
  # pre-configured seeds.
  ADD_SEEDS=

  # When set, determines the port on which this node will listen for protocol-related
  # messages. If unset, the port will default to what is present in the DeSoParams set.
  # Note also that even though the node will listen on this port, its outbound
  # connections will not be determined by this flag (17000).
  PROTOCOL_PORT=17000

  # When set, determines the port on which this node will listen for json
  # requests. If unset, the port will default to what is present in the
  # DeSoParams set (17001).
  API_PORT=17001

  # Transactions below this feerate will be rate-limited rather than flat-out
  # rejected. This is in contrast to min_feerate, which will flat-out reject
  # transactions with feerates below what is specified. As such, this value will have no
  # effect if it is set below min_feerate. This, along with min_feerate, should
  # be the first line of defense against attacks that involve flooding the
  # network with low-fee transactions in an attempt to overflow the mempool
  RATE_LIMIT_FEERATE=0

  # The minimum feerate this node will accept when processing transactions
  # relayed by peers. Increasing this number, along with increasing
  # rate_limit_feerate, should be the first line of
  # defense against attacks that involve flooding the network with low-fee
  # transactions in an attempt to overflow the mempool
  MIN_FEERATE=1000

  # The target number of outbound peers. The node will continue attempting to connect to
  # random addresses until it has this many outbound connections. During testing it's
  # useful to turn this number down and test a small number of nodes in a controlled
  # environment.
  TARGET_OUTBOUND_PEERS=8

  # The maximum number of inbound peers a node can have.
  MAX_PEERS=125

  # The location where all of the protocol-related data like blocks is stored.
  # Useful for testing situations where multiple clients need to run on the
  # same machine without trampling over each other.
  # When unset, defaults to the system's configuration directory.
  DATA_DIR=/db


  # When set, the node will not allow more than one connection to/from a particular
  # IP. This prevents forms of attack whereby one node tries to monopolize all of
  # our connections and potentially make onerous requests as well. Useful to
  # disable this flag when testing locally to allow multiple inbound connections
  # from test servers
  ONE_INBOUND_PER_IP=true

  # How long the node will wait for a peer to reply to certain types of requests.
  # We make this gratuitous just in case the node we're connecting to is backed up.
  STALL_TIMEOUT_SECONDS=900

  # When set to true, the node does not look up addresses from DNS seeds.
  PRIVATE_MODE=false

  # When set to true, the node will generate an index mapping transaction
  # ids to transaction information. This enables the use of certain API calls
  # like ones that allow the lookup of particular transactions by their ID.
  # Defaults to false because the index can be large.
  TXINDEX=true

  # The amount of DeSo given to new accounts to get them started. Only
  # active if --starter_deso_seed is set and funded.
  # 1 milli (~$0.10 at $100 coin price).
  STARTER_DESO_NANOS=1000000

  # A comma-separated list of 'prefix=nanos' mappings, where prefix is a phone
  # number prefix such as \"+1\". These mappings allow the
  # node operator to specify custom amounts of DeSo to users verifying their phone
  # numbers based on the country they're in. This is useful as it is more expensive
  # for attackers to get phone numbers from certain countries. An example string would
  # be '+1=2000000,+2=2000000', which would double the default nanos for users with
  # with those prefixes.
  STARTER_PREFIX_NANOS_MAP=

  # When proviced, this seed is used to send a 'starter' amount of DeSo to
  # newly-created accounts.
  STARTER_DESO_SEED=


  # The IP:PORT or DOMAIN:PORT corresponding to a node that can be used to
  # set/get global state. When this is not provided, global state is set/fetched
  # from a local DB. Global state is used to manage things like user data, e.g.
  # emails, that should not be duplicated across multiple nodes.
  GLOBAL_STATE_REMOTE_NODE=

  # When a remote node is being used to set/fetch global state, a shared_secret
  # is also required to restrict access.
  GLOBAL_STATE_REMOTE_SECRET=

  # Accepts a space-separated lists of origin domains that will be allowed as the
  # Access-Control-Allow-Origin HTTP header. Defaults to * if not set.
  #
  # TODO: We should show some kind of warning or something if this option is set to *
  ACCESS_CONTROL_ALLOW_ORIGINS=*

  # If set, runs our secure header middleware in development mode, which disables some
  # of the options. The default is true to make it easy to run a node locally.
  # See https://github.com/unrolled/secure for more info. Note that
  #
  # TODO: We should show some kind of warning if we're in development mode, which
  # is the default right now.
  SECURE_HEADER_DEVELOPMENT=true

  # These are the domains that our secure middleware will accept requests from. 
  # Accepts a space-separated lists of origin domains.
  # We also set the HTTP Access-Control-Allow-Origin
  SECURE_HEADER_ALLOW_HOSTS=

  # Optional. Client-side amplitude key for instrumenting user behavior.
  AMPLITUDE_KEY=

  # Optional. Client-side amplitude API Endpoint.
  AMPLITUDE_DOMAIN=api.amplitude.com

  # Users won't be able to create a profile unless they buy this
  # amount of satoshis or provide a phone number.
  # TODO: This field is deprecated by ParamUpdater transaction
  MIN_SATOSHIS_FOR_PROFILE=50000

  ## Arguments for the block producer
  #
  # When set to a non-zero value, the node will generate block
  # templates, and cache the number of templates specified by this flag. When set
  # to zero, the node will not produce block templates.
  MAX_BLOCK_TEMPLATES_CACHE=10

  # When set to a non-zero value, the node will wait at least this many seconds
  # before producing another block template
  MIN_BLOCK_UPDATE_INTERVAL=10

  # When specified, this key is used to power the BitcoinExchange flow
  # and to check for double-spends in the mempool
  #
  # Note: It is currently a bit dangerous to serve user traffic without a
  # BLOCK_CYPHER_API_KEY because the validation of transactions using
  # alternative mechanisms is not 100%.
  BLOCK_CYPHER_API_KEY=

  # When set, the mempool is initialized using a db in the directory specified, and
  # subsequent dumps are also written to this dir
  MEMPOOL_DUMP_DIR=

  ## Emergency flags that can help in reducing noise from peers when trying to debug.

  # When set to true, the node will not make any outgoing connections or accept
  # any incoming connections.
  DISABLE_NETWORKING=false

  # When set to true, the node will ignore all INV messages unless they come
  # from an outbound peer. This is useful when setting up a node that you want to
  # have a direct and 1:1 relationship with another node, as is common when
  # setting up read sharding.
  IGNORE_INBOUND_INVS=false

  # When set to true, the node will ignore all transactions created on this node.
  READ_ONLY_MODE=true

  # When set to an IP:PORT, the BitcoinManager will use this peer to source Bitcoin
  # headers and won't talk to anyone else. When unset, a random Bitcoin peer is chosen.
  BITCOIN_CONNECT_PEER=

  # When set to true, the node will log a snapshot of all DB keys every 30s.
  LOG_DB_SUMMARY_SNAPSHOTS=false

  # When set to true, the UI will show processing spinners for unmined posts / DeSo
  # / creator coins.
  SHOW_PROCESSING_SPINNERS=true

  # When set to true, unmined BitcoinExchange transactions from peers are 
  # disregarded. This is OK because we will eventually reprocess this transaction once
  # it gets mined into a block, although anything that is built on top of it may not
  # be considered. It's set to false by default because most nodes connect to trusted
  # peers right now via --connectips and --ignore_inbound_peer_inv_messages.
  #
  # TODO: It is currently insecure to serve user write traffic without setting this
  # flag to true because soneone could theoretically submit garbage entries to the
  # mempool.
  IGNORE_UNMINED_BITCOIN=false

  # Google credentials to upload images to bucket. This is needed in order for image
  # uploads to work.
  GCP_CREDENTIALS_PATH=

  # Name of bucket to store images
  GCP_BUCKET_NAME=images.bitclout.com

  ### Environment vars for the frontend image

  # Override the Caddyfile with the one in this directory
  CADDY_FILE=/app/Caddyfile.dev
  EOL


  echo "Creating Docker-Compose file for running DeSo services."
  cat > /deso-node/docker-compose.dev.yml <<EOL
  version: "3.7"
  services:
    backend:
      logging:
        driver: awslogs
        options:
          awslogs-region: us-east-1
          awslogs-group: ${var.name}/backend
      container_name: backend
      image: ${var.deso_backend_docker_image}
      command: run
      volumes:
      - db:/db
      ports:
      - ${var.deso_backend_port}:${var.deso_backend_port}
      - 17000:17000
      env_file:
      - dev.env
      expose:
      - "${var.deso_backend_port}"
      - "17000"
    frontend:
      logging:
        driver: awslogs
        options:
          awslogs-region: us-east-1
          awslogs-group: ${var.name}/frontend
      container_name: frontend 
      image: ${var.deso_frontend_docker_image}
      ports:
      - ${var.deso_frontend_port}:${var.deso_frontend_port}
      - ${local.deso_frontend_healthcheck_port}:${local.deso_frontend_healthcheck_port}
      volumes:
      - ./:/app
      env_file:
      - dev.env
      expose:
      - "${var.deso_frontend_port}"
      - "${local.deso_frontend_healthcheck_port}"
  volumes:
    db:
  EOL

  echo "Running DeSo Docker Compose services."
  sudo docker-compose -f /deso-node/docker-compose.dev.yml pull
  sudo docker-compose -f /deso-node/docker-compose.dev.yml up -d

  echo "All done, notifying autoscaling that node setup is complete."
  
  aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id $INSTANCE_ID --lifecycle-hook-name $LIFECYCLE_HOOK_NAME --auto-scaling-group-name $ASG_NAME --region $REGION
  EOT
}