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

## That sounds mad! Why would you want to use Ganger?

The rationale for creating Ganger was driven by a real-world problem. At Forward3D, we use
Hive to probe the data we import into Hadoop. Some of our processes are automatic, and run over
small amounts of data every day - there are thousands of these processes. 
[Hive local mode](http://hadoop-pig-hive-thejas.blogspot.co.uk/2013/04/running-hive-in-local-mode.html) is a
good way to run small jobs quickly without the overhead of launching MapReduce JVMs.

However, local mode seems to leak memory in some situations, and drops tons of junk into /tmp
on the machine that eventually causes problems. Ganger was created to allow me to isolate
a single query to a single container, then throw it away when the query is complete. It
should be useful in similar situations where you want to run code in a totally pure environment
on every request.

Docker is the perfect tool for this, since the time and overhead required to start a Docker
container (when considering the time required to run a query) is minimal.

## An example

Put an ncat example here.

## Future features

Ganger is deliberately very simple. However, the following features are planned:

 - Container reuse; keep a "container pool" and reuse containers a configurable
   number of times
 - A simple status webpage, similar to HAproxy
 - Control of various TCP timeout parameters
 - Graceful switchovers to a new container (for upgrades, etc)