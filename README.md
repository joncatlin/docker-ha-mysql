# High Availability MySQL Cluster in Swarm
This repo is based on the article at: https://mysqlrelease.com/2018/03/docker-compose-setup-for-innodb-cluster/ and the repo at: https://github.com/neumayer/mysql-docker-compose-examples/tree/master/innodb-cluster.

Some modifications were necessary to get the containers to run in the swarm. The modifications are listed below:

1.  The image for neumayer/mysql-shell-batch used a volume to access the scripts directory which could potentially not be available if the container ran on another node in the swarm. In order to overcome this the scripts directory was built into the docker image. The image is now part of this repo and is `csc-mysql-shell`.

2.  Added `hostname` to the docker-compose file for each of the mysql-server nodes. This was needed to enable the cluster software to initialize correctly. Without it the shell container failed to create the cluster.

3.  Prevented the shell container from restarting which is the default action in swarm mode. Added a restart policy of `none`. Without this when the container finished and stoppped swarm restarted it and then it reported errors retrying the same commands as the first time.

## How To Build
In order to build the image for the container that runs the scripts use the following command.
```
docker-compose build
```
## Use of Docker Secrets
To keep the user and passwords secure in a docker swarm this repo uses secrets for the following mysql env variables.

- MYSQL_USER
- MYSQL_ROOT_PASSWORD
- MYSQL_PASSWORD

To create the secrets run the following code from a management node in the swarm.
```
openssl rand -base64 12 | docker secret create db_root_password -
openssl rand -base64 12 | docker secret create db_user_password -
openssl rand -base64 12 | docker secret create db_user -
```

Or if you want to specify the values for the secrets
```
echo '<put your MYSQL_ROOT_PASSWORD here>' | docker secret create db_root_password -
echo '<put your MYSQL_PASSWORD here>' | docker secret create db_user_password -
echo '<put your MYSQL_USER here>' | docker secret create db_user -
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
3.  Change the name of the initial database created so it makes sense for us
4.  Determine how to secure the MySQL DB. Look for best practices and implement them.
7.  Get the router to wait for all the cluster members before starting, otherwise it fails a few times before succeeding

## Debug Stuff

 mysqlsh "root@mysql-server-1:3306" --dbpassword="mysql" -f "setupCluster.js"
