perl -MCPAN -e'shell'

cpan[1]> o conf mbuildpl_arg "--install_base /home/charlie"
    mbuildpl_arg       [--install_base /home/charlie]
Please use 'o conf commit' to make the config permanent!


cpan[2]> o conf makepl_arg "PREFIX=/home/charlie" 
    makepl_arg         [PREFIX=/home/charlie]
Please use 'o conf commit' to make the config permanent!


cpan[3]> install Expect