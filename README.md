# SPF

SPF (as in "Sieve, Process, and Forward") is a Software-Defined Networking
(SDN) and Value-of-Information (VoI) based solution for dynamic IoT
applications in urban computing environments.

SPF aims to address the explosion of IoT data by processing it at the edge of
the network, in close proximity to the source of its generation. In order to
filter information objects, SPF uses a minimum content difference threshold for
new IoT data to be considered for processing and dissemination. In addition,
SPF prioritizes dissemination of critical information by ranking objects
according to their corresponding VoI metric.


## Stakeholders

We envision 3 roles for the stakeholders in the SPF architecture:
administrators, service providers, and users. Administrators manage the SPF
platform by deploying, running, and operating SPF controllers and Programmable
IoT Gateways (PIGs), and making them available to service providers. Service
providers develop IoT applications, deploy them, and take care of their
management. Finally, users are people who use SPF applications through a client
app on their smart devices. In our example, users of the SPF are participants,
the EMS, and the police force. We can imagine that the management and service
provider roles in this scenario would be played by two corresponding commercial
companies.


## Android Client

SPF users can access the services offered by the platform through an Android
client App, which is available [here](https://github.com/gentiliniluca/AndroidApp).


## Information processing pipelines

At the moment, SPF supports an image processing pipeline, which leverages the
well known OpenCV and Tesseract software components. The source code is
available [here](https://github.com/gentiliniluca/Pipeline_SPF).


## Requirements

We have test successfully this project with Ubuntu 16.04 and Fedora 25.

This simple guide is for Ubuntu operating system.

For starting you need to have:
- Java Runtime Environment (Oracle Java 8)
- Tesseract
- OpenCV (version 3.10)
- libchromaprint
- JRuby 9.1.2.0
installed in your machine.

### Tesseract
If you don't have it, you can install it with the following step:
```
$ sudo apt install tesseract-ocr
$ sudo apt install libchromaprint-dev
```

### libchromaprint
If you don't have it, you can install it with the following step:
```
$ sudo apt install tesseract-ocr
```

### Java Runtime Environment
You can follow this [guide](http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html)
for install Java Runtime Environment.

### OpenCV
Now you need to compile OpenCV.
You can download it from [here](https://github.com/Itseez/opencv/archive/3.1.0.zip)
and follow this [guide](https://opencv-java-tutorials.readthedocs.io/en/latest/01-installing-opencv-for-java.html#install-opencv-3-x-under-linux)
for compile OpenCV.

After this procedure you need to copy `opencv-310.jar` in a specific path with:
```
$ sudo copy /your/path/opencv-3.1.0/build/bin/opencv-310.jar /usr/share/java/opencv-310.jar
$ sudo ln -s /usr/share/java/opencv-310.jar /usr/share/java/opencv.jar
```

and `libopencv_java310.so` in another path:
```
$ sudo copy /your/path/opencv-3.1.0/build/lib/libopencv_java310.so /usr/local/lib/libopencv_java310.so
```

Now you can use execstack to mark binary or shared library as not requiring
executable stack.
If you don't have it, you can install it with:
```
$ sudo apt install execstack
```
and this for execute execstack:
```
$ sudo execstack -c /usr/local/lib/libopencv_java310.so
```

### JRuby
For install JRuby you can choose different way:
- install the JRuby [binaries](https://github.com/jruby/jruby/wiki/GettingStarted#linux-and-mac-os-x)
- use Ruby version manager [RVM](https://rvm.io/) or Ruby environment [rbenv](https://github.com/rbenv/rbenv)


Oh yeah, now you have all for proceed over.


## Installation

For starting you need to clone this project:
```
$ git clone https://github.com/DSG-UniFE/spf.git
```

First step is to install all required gem with:
```
$ bundle install
```
This command is to execute inside `spf` folder.

We recommend to use:
```
$ bundle install --path vendor/bundle
```
for don't share gems with the default location.

If you don't have [Bundler](http://bundler.io/) installed, you can install it with:
```
gem install bundler
```

You need to download all request jar library with:
```
rake all_jars
```
or
```
bundle exec rake all_jars
```
if you installed gems with a *path* option.


Now you are ready for to start!!!


## Getting started

Ready to get started with SPF?

For first you need starting [DisService](http://www.ing.unife.it/en/research/research-1/information-technology/computer-science/distributed-systems-group/research-projects/disservice),
after this you can execute *controller*:
```
jruby src/ruby/bin/controller
```

and *PIG*:
```
jruby src/ruby/bin/pig
```


Now, if you haven't error, you have a *controller* and a *PIG* in the same machine.
You can simulate a request with a simple client:
```ruby
require 'socket'

socket = TCPSocket.new("localhost", 52161)
socket.puts "REQUEST participants/find_text"
socket.puts "User 3;44.838124,11.619786;find 'water'"
socket.close

puts "Sent request"
```
