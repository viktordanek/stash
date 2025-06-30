{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib = { functions , pkgs , visitor , user , working-directory } : stash : null ;
            } ;
}