#!/bin/bash
DOCKER_LOG=/var/log/docker.log
DEBUG_LOG=/dev/null

echo ">> [$(date)] Build for TARGET_DEVICE $*"

if [ "$DEBUG" = true ]; then
    DEBUG_LOG=$DOCKER_LOG
fi

if [ "$USE_CCACHE" = 1 ]; then
    ccache -M $CCACHE_SIZE 2>&1 >&$DEBUG_LOG
fi

git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_MAIL

cd $SRC_DIR

if ! [ -f "$SRC_DIR/.repo/manifest.xml" ]; then
    echo ">> [$(date)] Initializing repository" >> $DOCKER_LOG
    yes | repo init -u git://github.com/lineageos/android.git -b $BRANCH_NAME 2>&1 >&$DEBUG_LOG
fi

echo ">> [$(date)] Syncing repository" >> $DOCKER_LOG
repo sync -j16 -f 2>&1 >&$DEBUG_LOG

echo ">> [$(date)] Preparing build environment" >> $DOCKER_LOG
source build/envsetup.sh 2>&1 >&$DEBUG_LOG
source <( curl https://gist.githubusercontent.com/yasu-hide/f3f160b7a4569ee3940420bd5613523d/raw/repopick.sh )

for codename in $*; do

    echo ">> [$(date)] Starting build for $codename" >> $DOCKER_LOG
    if brunch $codename 2>&1 >&$DEBUG_LOG; then
        echo ">> [$(date)] Moving build artifacts for $codename to '$OUT_DIR'" >> $DOCKER_LOG
        cd $SRC_DIR
        find out/target/product/$codename -name '*UNOFFICIAL*.zip*' -exec mv {} $OUT_DIR \; >&$DEBUG_LOG
    else
        echo ">> [$(date)] Failed build for $codename" >> $DOCKER_LOG
    fi
    
    echo ">> [$(date)] Cleaning build for $codename" >> $DOCKER_LOG
    mka clean 2>&1 >&$DEBUG_LOG
    
    echo ">> [$(date)] Finishing build for $codename" >> $DOCKER_LOG
done
