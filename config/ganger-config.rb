Ganger.configure do |c|
  
  # The image - will be pulled on startup
  c.docker.image = "andytinycat/ncat"
  
  # The Docker command to run in the container; can be left blank, in which
  # case the image's command will be used
  c.docker.cmd = [ 'ncat', '-l', '12345', '-k', '-c', 'xargs -n1 echo']
  
  # The port to expose
  c.docker.expose = '12345/tcp'
  
  # The port we'll listen on for frontend connections
  c.ganger.listen_port = 5454
  
  # Try to connect immediately after starting the container, then
  # 6 more times, with a timeout of 5 seconds
  c.ganger.service_connection_timeout = 5
  c.ganger.service_connection_retries = 6
  
  # Wait 300 seconds for Docker to respond (image pulls can be slow!)
  c.ganger.docker_timeout = 300
  
  # Engine to use to locate Docker servers
  # Two engines are available: 'static' and 'consul'.
  # Static uses a list of pre-configured Docker daemons.
  # Consul uses the Consul service discovery tool (http://consul.io)
  # to locate Docker servers to use.
  c.ganger.docker_discovery = 'static'
  
  #
  # STATIC ENGINE SETTINGS
  #
  
  # These are all the Docker daemons we can start containers on
  # It must be an array of hashes, with each hash having a url key
  # and a max_containers key. If you want to allow an infinite number of
  # concurrent containers, specify -1. (This is not a good idea!)
  c.static_engine.daemons = [
    {
      url: 'boot2docker',
      max_containers: 2
    }
  ]
  
  #
  # CONSUL ENGINE SETTINGS
  #
  
  # These are the hosts running Consul that you want to use for
  # service discovery. You should have at least 3 of these Consul agents
  # running in server mode for availability.
  c.consul_engine.hosts = [ 'host1:8500', 'host2:8500', 'host3:8500' ]
  
  # The name of the service registered with Consul
  c.consul_engine.service_name = 'docker'
  
  # The maximum number of containers each discovered server will support,
  # if not specified in a tag (see the README)
  c.consul_engine.default_max_containers = 10
  
  # Consul has three consistency modes when making API request; see the Consul documentation
  # for more information (http://www.consul.io/docs/agent/http.html)
  # We default to 'stale', since this is fast and we can cope with service data being
  # slightly out of date.
  c.consul_engine.consistency_mode = 'stale'
  
  # List of datacenters to try for services, in order of preference.
  # e.g. Here we'd try to find a service in DC 'eu', then 'us', then 'faraway'
  c.consul_engine.datacenters = ['eu', 'us', 'faraway']
  
end