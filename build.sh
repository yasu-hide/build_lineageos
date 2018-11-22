#!/bin/bash

git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_MAIL
    
repo_init () {
    cd $SRC_DIR
    if ! [ -f "$SRC_DIR/.repo/manifest.xml" ]; then
        echo ">> [$(date)] Initializing repository"
        yes | repo init -u git://github.com/lineageos/android.git -b $BRANCH_NAME 2>&1
    fi
}

repo_sync () {
    echo ">> [$(date)] Syncing repository"
    repo sync -j16 -f 2>&1
    source build/envsetup.sh 2>&1
    source <( curl https://gist.githubusercontent.com/yasu-hide/f3f160b7a4569ee3940420bd5613523d/raw/repopick.sh )
}

build () {
    source build/envsetup.sh 2>&1
    processornum=$(grep -c ^processor /proc/cpuinfo)
    parahosts=("localhost")
    if [ $USE_CCACHE -a -n "$DISTCC_HOSTS" ]; then
        echo ">> [$(date)] Entering distcc+ccache mode"
        unset USE_GOMA DISTCC_POTENTIAL_HOSTS
        parahosts=($parahosts $DISTCC_HOSTS)
        export USE_CCACHE=1 CCACHE_COMPRESS=1 CCACHE_PREFIX=distcc
        echo ">> [$(date)] Setup ccache"
        ccache -M $CCACHE_SIZE 2>&1
    elif [ -n "$DISTCC_POTENTIAL_HOSTS" ]; then
        echo ">> [$(date)] Entering distcc-pump mode"
        unset USE_CCACHE DISTCC_HOSTS USE_GOMA
        parahosts=($parahosts $DISTCC_POTENTIAL_HOSTS)
        export CC_WRAPPER=distcc CXX_WRAPPER=distcc
        echo ">> [$(date)] Startup distcc-pump"
        eval $(distcc-pump --startup)
    elif [ $USE_GOMA ]; then
        echo ">> [$(date)] Entering GOMA mode"
        unset USE_CCACHE DISTCC_HOSTS DISTCC_POTENTIAL_HOSTS
        processornum=100
    fi
    parallelnum=$(($processornum * ${#parahosts[@]}))

    for codename in $*; do
        echo ">> [$(date)] Starting build (par=${parallelnum}=${processornum}*${#parahosts[@]}) for $codename"
        if (breakfast $codename && make -j$parallelnum bacon) 2>&1; then
            echo ">> [$(date)] Moving build artifacts for $codename to '$ARTIFACT_OUT_DIR'"
            cd $SRC_DIR
            find out/target/product/$codename -name '*UNOFFICIAL*.zip*' -exec mv {} $ARTIFACT_OUT_DIR \;
        else
            echo ">> [$(date)] Failed build for $codename"
        fi
        
        echo ">> [$(date)] Cleaning build for $codename"
        mka clean 2>&1
        
        echo ">> [$(date)] Finishing build for $codename"
    done

    if [ -n "$DISTCC_POTENTIAL_HOSTS" ]; then
        echo ">> [$(date)] Shutdown distcc-pump"
        distcc-pump --shutdown
    fi
}

do_init=0; do_sync=0; do_build=0
while getopts ISPB OPT; do
    case "$OPT" in
    I) do_init=1;;
    S) do_sync=1;;
    B) do_build=1;;
    esac
done
shift $((OPTIND - 1))
[ $do_init -eq 1 ] && repo_init
[ $do_sync -eq 1 ] && repo_sync
[ $do_build -eq 1 ] && build $*
exit 0
