#!/bin/sh

set -e

CUR_DIR=$PWD

case $1 in

	upload-release )

	APP_VERSION=$(cat VERSION)
	git remote remove origin  && git remote add origin https://${REPO_TOKEN}@github.com/mageddo/dns-proxy-server.git
	git push origin $TRAVIS_BRANCH
	PAYLOAD=`echo '{
			"tag_name": "VERSION",
			"target_commitish": "TARGET",
			"name": "VERSION",
			"body": "",
			"draft": false,
			"prerelease": false
		}' | sed -e "s/VERSION/$APP_VERSION/" | sed -e "s/TARGET/$TRAVIS_BRANCH/"` && \
	TAG_ID=`curl -v -s -X POST "https://api.github.com/repos/mageddo/dns-proxy-server/releases?access_token=$REPO_TOKEN" \
--data "$PAYLOAD" | grep -o -E 'id": [0-9]+'| awk '{print $2}' | head -n 1`

	curl -d "@build/dns-proxy-server-$APP_VERSION.tgz" -i -w '\n' -s -X POST -H 'Content-Type: application/octet-stream' \
"https://uploads.github.com/repos/mageddo/dns-proxy-server/releases/$TAG_ID/assets?name=dns-proxy-server-$APP_VERSION.tgz&access_token=$REPO_TOKEN"

		done;
	;;

case $1 in

	pull-all )
		git pull
		for i in `git submodule | awk '{print $2}'`; do
			MATCH=`echo $i | grep -o "mageddo"`
			MATCH2=`echo $i | grep -o "ElvisDeFreitas"`

				echo "pulling $i"
				cd $i
				git pull
				cd $CUR_DIR

		done;
	;;

	build )

		echo "starting build"
		VERSION=`cat VERSION`

		rm -rf build/ && \
		mkdir -p build/ && \
		git submodule init && \
		git submodule update && \
		cd src && \
		go test -cover=false \
			-ldflags "-X github.com/mageddo/dns-proxy-server/flags.version=test" \
			./github.com/mageddo/dns-proxy-server/.../ && \
		go build -v -o ../build/dns-proxy-server \
			-ldflags "-X github.com/mageddo/dns-proxy-server/flags.version=$VERSION" && \
		cp -r ../static ../build/ && \
		cd ../build/ && \
		tar -czvf dns-proxy-server-$VERSION.tgz * && \
		cd ../

		echo "build success"

	;;

esac