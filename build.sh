#!/bin/bash
repo_init () {
    git config --global user.name $GIT_USER_NAME
    git config --global user.email $GIT_USER_MAIL
    
    cd $SRC_DIR
    
    if ! [ -f "$SRC_DIR/.repo/manifest.xml" ]; then
        echo ">> [$(date)] Initializing repository"
        yes | repo init -u git://github.com/lineageos/android.git -b $BRANCH_NAME 2>&1
    fi
}

repo_sync () {
    echo ">> [$(date)] Syncing repository"
    repo sync -j16 -f 2>&1
}

repo_pick () {
    echo ">> [$(date)] Preparing build environment"
    source build/envsetup.sh 2>&1
    source <( curl https://gist.githubusercontent.com/yasu-hide/f3f160b7a4569ee3940420bd5613523d/raw/repopick.sh )
}

build () {
    for codename in $*; do
    
        echo ">> [$(date)] Starting build for $codename"
        if brunch $codename 2>&1; then
            echo ">> [$(date)] Moving build artifacts for $codename to '$OUT_DIR'"
            cd $SRC_DIR
            find out/target/product/$codename -name '*UNOFFICIAL*.zip*' -exec mv {} $OUT_DIR \;
        else
            echo ">> [$(date)] Failed build for $codename"
        fi
        
        echo ">> [$(date)] Cleaning build for $codename"
        mka clean 2>&1
        
        echo ">> [$(date)] Finishing build for $codename"
    done
}

if [ "$USE_CCACHE" = 1 ]; then
    ccache -M $CCACHE_SIZE 2>&1
fi

do_init=0; do_sync=0; do_pick=0; do_build=0
while getopts ISPB OPT; do
    case "$OPT" in
    I) do_init=1;;
    S) do_sync=1;;
    P) do_pick=1;;
    B) do_build=1;;
    esac
done
shift $((OPTIND - 1))
[ $do_init -eq 1 ] && echo repo_init
[ $do_sync -eq 1 ] && echo repo_sync
[ $do_pick -eq 1 ] && echo repo_pick
[ $do_build -eq 1 ] && echo build $*
exit 0
