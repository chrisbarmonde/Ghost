#!/bin/bash

DEPLOY=0
DEPLOY_ADMIN=0
DEPLOY_THEME=0
BUILD_ADMIN=0

while [ ${#} -gt 0 ]; do
    OPTERR=0
    OPTIND=1
    getopts ":abdtx" opt
    case $opt in
        a)
            DEPLOY_ADMIN=1
            ;;
        b)
            BUILD_ADMIN=1
            ;;
        d)
            DEPLOY=1
            ;;
        t)
            DEPLOY_THEME=1
            ;;
        x)
            DEPLOY_ADMIN=1
            DEPLOY_THEME=1
            BUILD_ADMIN=1
            ;;
        \?) SET+=("$1")
    esac
    shift
    [ "" != "$OPTARG" ] && shift
done
[ ${#SET[@]} -gt 0 ] && set "" "${SET[@]}" && shift

LOCAL_ROOT=`pwd`

REMOTE_ROOT="/var/www/ghost/versions/3.3.0"
REMOTE_ADMIN_ASSETS="$REMOTE_ROOT/core/built/assets"
REMOTE_VIEWS="$REMOTE_ROOT/core/server/web/admin/views"
REMOTE_THEME="$REMOTE_ROOT/content/themes/casper"
# REMOTE_THEME_ASSETS="$REMOTE_THEME/assets/built"


if [[ $DEPLOY_ADMIN -eq 1 ]]; then
    # Update admin JS
    echo "grunt build prod"
    if [[ $DEPLOY -eq 1 && $BUILD_ADMIN -eq 1 ]]; then
        grunt build prod
    fi

    cd $LOCAL_ROOT/core/built/assets/

    GHOST_JS=`ls ghost.min-*.js`
    VENDOR_JS=`ls vendor.min-*.js`

    # Copy the built files over
    echo "scp $GHOST_JS $VENDOR_JS blog@supersweet:$REMOTE_ADMIN_ASSETS"
    if [[ $DEPLOY -eq 1 ]]; then
        scp $GHOST_JS $VENDOR_JS blog@supersweet:$REMOTE_ADMIN_ASSETS
    fi

    # Replace the file names in the default templates
    echo "ssh blog@supersweet \"sed -i -e 's/ghost.min-\\\w\+.js/$GHOST_JS/g' $REMOTE_VIEWS/default.html $REMOTE_VIEWS/default-prod.html\""
    if [[ $DEPLOY -eq 1 ]]; then
        ssh blog@supersweet "sed -i -e 's/ghost.min-\\w\+.js/$GHOST_JS/g' $REMOTE_VIEWS/default.html $REMOTE_VIEWS/default-prod.html"
    fi

    echo "ssh blog@supersweet \"sed -i -e 's/vendor.min-\\\w\+.js/$VENDOR_JS/g' $REMOTE_VIEWS/default.html $REMOTE_VIEWS/default-prod.html\""
    if [[ $DEPLOY -eq 1 ]]; then
        ssh blog@supersweet "sed -i -e 's/vendor.min-\\w\+.js/$VENDOR_JS/g' $REMOTE_VIEWS/default.html $REMOTE_VIEWS/default-prod.html"
    fi
fi

if [[ $DEPLOY_THEME -eq 1 ]]; then
    echo "ssh blog@supersweet \"cd $REMOTE_THEME && git pull\""
    if [[ $DEPLOY -eq 1 ]]; then
        ssh blog@supersweet "cd $REMOTE_THEME && git pull"
    fi
fi

# Update theme CSS
#cd $LOCAL_ROOT/content/themes/casper
#
#./node_modules/.bin/gulp build
#
#cd assets/built
#
#scp global.css screen.css blog@supersweet:$REMOTE_THEME_ASSETS

echo "ssh blog@supersweet \"cd $REMOTE_ROOT && git add -A && git status && git commit -m 'Release'\""
if [[ $DEPLOY -eq 1 ]]; then
    ssh blog@supersweet "cd $REMOTE_ROOT && git add -A && git status && git commit -m 'Release'"
fi

echo "ssh blog@supersweet cd /var/www/ghost && ghost restart"
if [[ $DEPLOY -eq 1 ]]; then
    ssh -t blog@supersweet "cd /var/www/ghost && ghost restart"
fi

# sed -i -e "s/CODEVERSION/$GIT_SHA/g" templates/_rollbar.html config.py
# ssh blog@supersweet ls -l /var/www/ghost/versions/3.3.0/core/built/assets/
