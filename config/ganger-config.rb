Ganger.configure do |c|

  # These are all the Docker daemons we can start containers on
  # Either specify a string, or an array of strings of Docker URLs
  c.docker.daemons = "boot2docker"
  
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
  
end