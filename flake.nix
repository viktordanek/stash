{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { arguments ? { } , current-time ? 0 , nixpkgs , system , user ? "me" , visitor , working-directory ? "$TMPDIR" } :
                        let
                            implementation =
                                stash :
                                    {
                                        outputs =
                                            visitor.lib.implementation
                                                {
                                                    lambda =
                                                        path : value :
                                                            let
                                                                point = value arguments ;
                                                                list = builtins.map mapper point.outputs ;
                                                                mapper =
                                                                    output :
                                                                        {
                                                                            name = output ;
                                                                            value =
                                                                                builtins.concatStringsSep
                                                                                    "/"
                                                                                    [
                                                                                        working-directory
                                                                                        ( builtins.substring 0 16 ( builtins.hashString "sha512" ( builtins.toString current-time ) ) )
                                                                                        ( builtins.substring 0 16 ( builtins.hashString "sha512" ( builtins.toJSON path ) ) )
                                                                                        "mount"
                                                                                        output
                                                                                    ] ;
                                                                        } ;
                                                                in builtins.listToAttrs list ;
                                                }
                                                stash ;
                                    } ;
                            in
                                {
                                    implementation = implementation ;
                                    test =
                                        { outputs , stash , success ? true } :
                                            let
                                                pkgs = builtins.getAttr system nixpkgs.legacyPackages ;
                                                in
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                ''
                                                                    mkdir $out
                                                                    ( cat <<EOF
                                                                    ${ builtins.toJSON { success = success ; value = { outputs = outputs ; } ; } }
                                                                    EOF
                                                                    ) | yq --yaml-output > $out/expected.yaml
                                                                    ( cat <<EOF
                                                                    ${ builtins.toJSON ( builtins.tryEval ( implementation stash ) ) }
                                                                    EOF
                                                                    ) | yq --yaml-output > $out/observed.yaml
                                                                    diff $out/expected.yaml $out/observed.yaml
                                                                '' ;
                                                            name = "test-stash" ;
                                                            nativeBuildInputs = [ pkgs.coreutils pkgs.diffutils pkgs.jq pkgs.yq ] ;
                                                            src = ./. ;
                                                        } ;
                                } ;
            } ;
}