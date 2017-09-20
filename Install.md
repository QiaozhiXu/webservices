# Installing the CISPaces web services

## Prerequisites
The CISPaces web services are Java based and have tested with OpenJDK 8 and Oracle JDK 8
http://www.oracle.com/technetwork/java/javase/downloads/index.html

The build process employs Apache Ant, and has been tested with version 1.9 and 1.10
http://ant.apache.org/bindownload.cgi

The services run under a Java web application server, and have been test with Apache Tomcat 8.0.45
http://tomcat.apache.org/download-80.cgi

## Installation

### Clone CISpaces repository

- Currently, the up to date version of code is in the Integration branch, so clone the Integration branch

```$ git clone -b Integration https://gitlab.it-innovation.soton.ac.uk/IntelAnalysisDSTL/cispaces-web-services.git```

- Run the installation script from the cispaces directory

```$ cd cispaces-web-services
$ ./install.sh```

- Update the environment

```$ source ~/.profile```

- Build and deploy the project using ant

```$ ant deploy```

- Start GAIANDB in a GNU Screen session (allows it to continue running in the background)
```$ screen
$ cd $GAIAN
$ ./launchGaianServer.sh
$ <CTRL+A>,<D>```

- To re-attach:

```$ screen -r```

- Start Tomcat web server:

```$ $CATALINA_HOME/bin/startup.sh```

- To use CISpaces we interface, point your web browser to https://<your-ip>:8080/VC

- To stop Tomcat:

```$ $CATALINA_HOME/bin/shutdown.sh```