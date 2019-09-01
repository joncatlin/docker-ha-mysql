# High Availability MySQL cluster
This repo is based on the article at: https://mysqlrelease.com/2018/03/docker-compose-setup-for-innodb-cluster/ and the repo at: https://github.com/neumayer/mysql-docker-compose-examples/tree/master/innodb-cluster.

Some modifications were necessary to get the containers to run in the swarm. The modifications are listed below:

1.  The image for neumayer/mysql-shell-batch used a volume to access the scripts directory which could potentially not be available if the container ran on another node in the swarm. In order to overcome this the scripts directory was built into the docker image. The image is now part of this repo and is `csc-mysql-shell`.

## How To Build
In order to build the image for the container that runs the scripts use the following command.
```
$ docker-compose build
```

## How to Use Adminer
Connect using a browser to the swarm on port 8080.
The server to connect to should be the router: `mysql-router:6446`

## Hardening the Server Installation
Implement some of the suggestions in the following articles:
1.  https://www.upguard.com/articles/top-11-ways-to-improve-mysql-security
2.  https://www.tecmint.com/mysql-mariadb-security-best-practices-for-linux/
3.  https://sucuri.net/guides/wordpress-security/

## TODO
1.  Convert the solution to use docker secrets, rather than the hardcoded passwords
2.  Add a container to the solution that enables GUI access to the MySQL cluster for debug purposes.
3.  Change the name of the initial database created so it makes sense for us
4.  Determine how to secure the MySQL DB. Look for best practices and implement them.
5.  Change the restart command in the docker-compose.yml file so it is stack ready
6.  Change the port on the adminer container so it does not die if the port is in use
7.  Get the router to wait for all the cluster members before starting, otherwise it fails a few times before succeeding

## Debug Stuff

 mysqlsh "root@mysql-server-1:3306" --dbpassword="mysql" -f "setupCluster.js"
