# SYNOPSIS

Runs Bailador `t/` tests inside Docker containers using [Ducky](https://github.com/melezhik/ducky) tool.


# INSTALL

    # install ducky first
    $ git clone https://github.com/melezhik/ducky.git
    $ PATH=$PWD/ducky:$PATH # add ducky.bash to the system PATH

# Run tests

    # then run Bailador tests against running docker container
    # tests are described at ducky.json file

    $ docker pull melezhik/alpine-perl6
    $ docker run --name bailador-alpine -itd  -v $PWD:/var/ducky melezhik/alpine-perl6
    $ ducky.bash bailador-alpine

# Run tests for other OS

OS list is limited by those ones where Rakudo binary package is available, see https://github.com/nxadm/rakudo-pkg/releases/

Nothing have to be changed from the ducky point of view, except choosing another docker container. 

For example, for CentOS7:

    $ docker pull centos
    $ docker run --name bailador-centos -itd  -v $PWD:/var/ducky centos:7
    $ ducky.bash bailador-centos

# Author

Alexey Melezhik

