# Ganger changelog

## 0.3.0

Significant redesign:

* A single thread is responsible for container allocation and launch, which makes
  features like pooling and limiting possible.
* The network code has been significantly hardened against various kinds of failures.
* The container allocation code has been separated off into 'engines'.
* Some basic barely-tested support for Consul discovery of Docker daemons has been added.
* The configuration file is now pure Ruby (like Vagrant etc).
* Numerous other fixes and improvements.

## 0.0.4

Protection against faulty container launches (see [Docker bug 7563](https://github.com/docker/docker/issues/7563)) that can occur under high concurrency.

## 0.0.2, 0.0.3

Various debugging changes.

## 0.0.1

First public release.
