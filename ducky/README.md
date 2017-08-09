# SYNOPSIS

Runs Bailador t/ tests under [Ducky](https://github.com/melezhik/ducky)

# INSTALL

    $ git clone https://github.com/melezhik/ducky.git
    $ PATH=$PWD/ducky:$PATH # add ducky.bash to the system PATH

# Run tests

    $ cd ducky/
    $ docker pull melezhik/alpine-perl6
    $ docker run --name bailador -itd  -v $PWD:/var/ducky melezhik/alpine-perl6
    $ ducky.bash bailador

# Author

Alexey Melezhik

