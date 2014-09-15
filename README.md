# Ganger

## What is Ganger?

_ganger |ˈgaŋə| noun; Brit; the foreman of a gang of labourers._

Ganger is a tool for running short-lived network services inside Docker containers, and then
proxying client connections to them. Think of Ganger as a sort of 
multi-machine [(x)inetd](http://en.wikipedia.org/wiki/Xinetd). 

## How does Ganger work?

Ganger is very simple. It receives TCP connections from clients, creates a Docker container
with a network service (listening on TCP), then proxies the client connection to the Docker
container. When the connection is over, the Docker container is terminated.

Ganger can use one or more Docker daemons - so you can spread the containers over as many
machines as you wish. Ganger will use the least-utilised daemon (the one running the fewest 
containers) to launch a new machine.

It's not important what the network service is - only that you supply a Docker image which
was built with a port exposed via the `EXPOSE` command. You tell Ganger what that port is,
what the port you want to be available to clients on is, and Ganger will do the rest.

## That sounds mad! Why would you want to use Ganger?

The rationale for creating Ganger was driven by a real-world problem. I use
Hive to query the data I import into Hadoop. They run over small amounts of data.
[Hive local mode](http://hadoop-pig-hive-thejas.blogspot.co.uk/2013/04/running-hive-in-local-mode.html) is a
good way to run small jobs quickly without the overhead of launching MapReduce JVMs on a cluster.

However, local mode seems to leak memory in some situations, and drops tons of junk into /tmp
on the machine that eventually causes problems. Ganger was created to allow me to isolate
a single query to a single container, then throw it away when the query is complete. It
should be useful in similar situations where you want to run code in a totally pure environment
on every request.

Docker is the perfect tool for this, since the time and overhead required to start a Docker
container (when considering the time required to run a query) is minimal.

## Features

- Spreads the load over multiple Docker daemons, launching new containers on the least-utilised one.
- Tries to connect to the service port a configurable number of times (with configurable timeout);
  useful if you have a service that takes a while to start.
- Tells all configured Docker daemons to pull the image on startup.
- Control of various timeout and retry parameters.
- Discovery of Docker services with [Consul](http://consul.io). Now you can autoscale your
  docker hosts!
- Configurable max containers; will hold connections in a queue until they can be serviced.

## An example

You must have Docker installed (somewhere). The example config file assumes you're running
[Boot2Docker](https://github.com/boot2docker/boot2docker) on Mac OS X. If you're not, then you will 
need to modify the configuration file to add the URL to your Docker daemon. This can be local,
on some servers somewhere, in the cloud, etc.

Clone this repository, and `cd` into it, then run:

    bundle install
    bundle exec bin/ganger.rb

This will use the default config file, which will pull an example dummy 'service' that uses
ncat to echo back whatever you send it. This default image is hosted in
[my DockerHub repository](https://registry.hub.docker.com/u/andytinycat/ncat/), and just contains
ncat and will start it on 12345/tcp when run.

To test it, telnet to it (it defaults to listening on 5454):

    telnet localhost 5454

In another shell, run `docker ps`

    CONTAINER ID        IMAGE                     COMMAND                CREATED             STATUS              PORTS                      NAMES
    c8c438e47f96        andytinycat/ncat:latest   ncat -l 12345 -k -c    14 hours ago        Up 2 seconds        0.0.0.0:49176->12345/tcp   nostalgic_bohr

A Docker container was started to service the request.

When you're done, exit your telnet session (CTRL-], then type `quit` on Mac OS X), and run
`docker ps` again. The container will have shut down and been destroyed.

## Future features

Ganger is a simple proof-of-concept. However, the following features are planned:

 - Container reuse; keep a "container pool" and reuse containers a configurable number of times
 - A simple status webpage, similar to HAproxy
 - Graceful switchovers to a new container (for upgrades, etc)
 - Graceful cleanup of threads and containers when terminating
 - Detecting containers that exit before a request can be sent (indicates broken container)
 
## Contributing
 
Pull requests are welcomed! The current state of code works for the simple things I need it for,
but there's so much more that could be added (see features above, tests, etc).
