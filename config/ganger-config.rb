Ganger.configure do |c|

  # These are all the Docker daemons we can start containers on
  # It must be an array of hashes, with each hash having a url key
  # and a max_containers key. If you want to allow an infinite number of
  # concurrent containers, specify -1. (This is not a good idea!)
  c.docker.daemons = [
    {
      url: 'boot2docker',
      max_containers: 2
    }
  ]
  
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
  # Only 'static' is available right now, but the plan is to support
  # 'consul' (consul.io) as well
  c.ganger.docker_discovery = 'static'
  
end