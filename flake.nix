{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { functions , pkgs , visitor , user , working-directory } : stash :
                        let
                            data =
                                {
                                    dependencies =
                                        let
                                            mapper =
                                                name : value :
                                                    let
                                                        mapper =
                                                            name_ : value_ :
                                                                if builtins.typeOf value_ != "string" then builtins.throw "The dependency ${ name_ } of stash hash ${ name } name ${ builtins.toJSON value.path } is not string but ${ builtins.typeOf value_ }."
                                                                else if ! builtins.elem ( builtins.attrNames data.set ) value_ then builtins.throw "The dependency ${ name_ } ${ value_ } of stash hash ${ name } name ${ builtins.toJSON value.path } is not enabled."
                                                                else if name == _value then builtins.throw "The dependency ${ name_ } ${ value_ } of stash hash ${ name } name ${ builtins.toJSON value.path } is circular."
                                                                else _value ;
                                                        in builtins.attrValues ( builtins.mapAttrs mapper ( value.dependencies tree ) ) ;
                                            in builtins.mapAttrs mapper set ;
                                    dependencies-with-transitive-closure =
                                        let
                                            mapper =
                                                name : value :
                                                    let
                                                        mapper =
                                                            dependency :
                                                                if builtins.typeOf dependency != "string" then builtins.throw "The dependency of stash hash ${ name } is not string but ${ builtins.typeOf dependency }."
                                                                else if ! builtins.elem ( builtins.attrNames data.set ) dependency then builtins.throw "The dependency ${ dependency } of stash hash ${ name } name is not enabled."
                                                                else if name == dependency then builtins.throw "The dependency ${ dependency } of stash hash ${ name } is circular."
                                                                else dependency ;
                                                        in builtins.map mapper ( builtins.concatLists [ [ dependency ] ( builtins.map ( dependency ) ( builtins.getAttr dependency data.dependencies-with-transitive-closure ) ) ] ) ;
                                            in builtins.map mapper ( builtins.getAttr value data.dependencies ) ;
                                    outputs =
                                        let
                                            mapper =
                                                name : value :
                                                    let
                                                        mapper = output : { name = output ; value = builtins.concatStringsSep "/" [ work-directory ( builtins.substring 0 16 name ) "mount" output ] ;
                                                        in builtins.listToAttrs ( builtins.map mapper value.outputs ) ;
                                            in builtins.mapAttrs mapper set ;
                                    script =
                                        let
                                            mapper =
                                                name : { dependencies , enable , init-packages , init-script , path , release-packages , release-script } : direction :
                                                    let
                                                        arguments =
                                                            {
                                                                dependencies =
                                                                    let
                                                                        mapper = name : value : builtins.getAttr value data.outputs ;
                                                                        in builtins.mapAttrs mapper dependencies ;
                                                                outputs = builtins.getAttr name data.outputs ;
                                                            } ;
                                                        init =
                                                            pkgs.writeShellApplication
                                                                {
                                                                    name = "init" ;
                                                                    runtimeInputs = init-packages ;
                                                                    text = init-script arguments ;
                                                                } ;
                                                        script-name = if direction then "init" else "release" ;
                                                        release =
                                                            pkgs.writeShellApplication
                                                                {
                                                                    name =  "release" ;
                                                                    runtimeInputs = release-packages ;
                                                                    text = release-script arguments ;
                                                                } ;
                                                        yaml =
                                                            code :
                                                                pkgs.writeShellApplication
                                                                    {
                                                                        name = "yaml" ;
                                                                        runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
                                                                        text =
                                                                            ''
                                                                            '' ;
                                                                    } ;
                                                        in
                                                            pkgs.writeShellApplication
                                                                {
                                                                    name = if direction then "setup" else "teardown" ;
                                                                    runtimeInputs = [ pkgs.coreutils pkgs.yq ] ;
                                                                    text =
                                                                        ''
                                                                            if [ -f success.yaml ]
                                                                            then
                                                                                yq --yaml-output success.yaml
                                                                                exit 0
                                                                            elif [ -f failure.yaml ]
                                                                            then
                                                                                yq --yaml-output failure.yaml
                                                                                exit 64
                                                                            else
                                                                                mkdir --parents ${ builtins.substring 0 16 name }/mount
                                                                                if ${ if direction then "${ init }/bin/init" else "${ release }/bin/release" } > ${ builtins.substring 0 16 name }/${ script-name }.standard-output 2> ${ builtins.substring 0 16 name }/${ script-name }.standard-error
                                                                                then
                                                                                    if [ -s ${ builtins.substring 0 16 name }/${ script-name }.standard-error
                                                                                    then
                                                                                        ${ yaml 9354 }/bin/yaml
                                                                                        exit 64
                                                                                    elif
                                                                                    then
                                                                                        ${ yaml 9581 }/bin/yaml
                                                                                        exit 64
                                                                                    else
                                                                                        ${ yaml 4059 }/bin/yaml
                                                                                        exit 0
                                                                                    fi
                                                                                else
                                                                                    ${ yaml 2192 }/bin/yaml
                                                                                    exit 64
                                                                                fi
                                                                        '' ;
                                                                } ;
                                            in builtins.map mapper set ;
                                    set = builtins.listToAttrs ( visitor visitors.list stash ) ;
                                    setup =
                                        {
                                            wantedBy = [ "multi-user.target" ] ;
                                            serviceConfig =
                                                {
                                                    ExecStart =
                                                        let
                                                            application =
                                                                pkgs.writeShellApplication
                                                                    {
                                                                        name = "application" ;
                                                                        runtimeInputs = [ pkgs.flock ] ;
                                                                        text =
                                                                            ''
                                                                                exec 201> lock
                                                                                flock -x 201
                                                                                cleanup ( )
                                                                                    {
                                                                                        if [ $? == 0 ]
                                                                                        then
                                                                                            mv work.yaml success.yaml
                                                                                        else
                                                                                            mv work.yaml failure.yaml
                                                                                        fi
                                                                                        rm lock
                                                                                        flock -u 201
                                                                                    }
                                                                                trap cleanup EXIT
                                                                            '' ;
                                                                    } ;
                                                            in "${ application }/bin/application" ;
                                                    User = user ;
                                                    WorkingDirectory = working-directory ;
                                                } ;
                                            wants = [ "network.target" ] ;
                                        }
                                    teardown = null ;
                                    tree = visitor visitors.tree data.yaml ;
                                    yaml = visitor visitors.yaml stash ;
                                } ;
                            visitors =
                                {
                                    list =
                                        {
                                            lambda =
                                                path : value :
                                                    let
                                                        point =
                                                            let
                                                                identity =
                                                                    {
                                                                        dependencies ? tree : { } ,
                                                                        enable ? true ,
                                                                        init-packages ? [ ] ,
                                                                        init-script ? { dependencies , outputs } : "" ,
                                                                        outputs ? [ ] ,
                                                                        release-packages ? [ ] ,
                                                                        release-script ? { dependencies , outputs } : ""
                                                                    } :
                                                                        {
                                                                            dependencies = visitor visitors.types.lambda dependencies ;
                                                                            enable = visitor visitors.bool enable ;
                                                                            init-packages = builtins.sort ( a : b : a < b ) ( visitor visitors.type.list-of-string init-packages ) ;
                                                                            init-script = visitor visitors.types lambda init-script ;
                                                                            outputs = builtins.sort ( a : b : a < b ) ( visitor visitors.type.list-of-string outputs ) ;
                                                                            path = path ;
                                                                            release-packages = builtins.sort ( a : b : a < b ) ( visitor visitors.type.list-of-string release-packages );
                                                                            release-script = visitor visitors.types lambda release-script ;
                                                                        } ;
                                                                in identity ( point null ) ;
                                                        in if point.enable then [ { name = builtins.hashString "sha512" ( builtins.toJSON path ) ; value = point ; } ] else [ ] ;
                                            list = path : list : builtins.concatLists list ;
                                            set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                        } ;
                                    tree = { string = path : value : builtins.substring ( 0 16 ( builtins.hashString "sha512" path ) ;
                                    types =
                                        let
                                            unsupported = path : value : builtins.throw "we do not support type ${ builtins.typeOf value } at ${ builtins.toJSON path }" ;
                                            in
                                                {
                                                    bool = { bool = path : value : value ; list = unsupported ; set = unsupported ; } ;
                                                    lambda = { lambda = path : value : value ; list = unsupported ; set = unsupported ; } ;
                                                    list-of-strings = { list = path : list : builtins.map ( l : visitor visitors.type.string l ) list ; set = unsupported ; string = path : value : value ; } ;
                                                    string = { list = unsupported ; set = unsupported ; string = path : value : value ; } ;
                                                } ;
                                    yaml = { lambda = path : value : builtins.toJSON value ; } ;
                                } ;
                            in
                                {
                                    implementation = implementation
                                } ;
            } ;
}