# SYNOPSIS

Runs Bailador `t/` tests under [Ducky](https://github.com/melezhik/ducky).

# INSTALL

    # install ducky first
    $ git clone https://github.com/melezhik/ducky.git
    $ PATH=$PWD/ducky:$PATH # add ducky.bash to the system PATH

# Run tests

    # then run Bailador tests against running docker container
    # tests are described at ducky/ducky.json file
    $ cd ducky/
    $ docker pull melezhik/alpine-perl6
    $ docker run --name bailador -itd  -v $PWD:/var/ducky melezhik/alpine-perl6
    $ ducky.bash bailador

# Author

Alexey Melezhik

