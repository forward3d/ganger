FROM ubuntu:12.04
MAINTAINER github@tinycat.co.uk

# Install Ruby + Bundler
RUN apt-get update
RUN apt-get -y install python-software-properties
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get -y install ruby2.1
RUN gem install bundler --no-ri --no-rdoc

# Add the Gemfile + Gemfile.lock, bundle
# This is a neat trick to cache bundling:
# http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# Now add the app
ADD . /opt/ganger
WORKDIR /opt/ganger

# Start up Ganger
EXPOSE 5454
CMD [ "/usr/bin/ruby", "/opt/ganger/bin/ganger.rb" ]