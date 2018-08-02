#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19

NAME="$0:t:r"
APPNAME="Screens"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO="/Applications/$APPNAME.app"

# https://app-updates.agilebits.com/check/1/15.2.0/OPM4/en/600008
# https://app-updates.agilebits.com/check/1/15.2.0/OPM4/en/601003
# where '600008' = CFBundleVersion

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`
BUILD_NUMBER=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo 600000`

# echo $INSTALLED_VERSION
# echo $BUILD_NUMBER

FEED_URL="https://updates.edovia.com/com.edovia.screens.mac/appcast.xml"

INFO=($(curl -sfL $FEED_URL \
| tr ' ' '\012' \
| egrep '^(url|sparkle:shortVersionString)=' \
| head -2 \
| awk -F'"' '//{print $2}'))

URL="$INFO[1] $INFO[2].zip"
# URL="$( echo "$URL" | sed 's/ /%20/g' )"
# echo $URL

LATEST_VERSION="$INFO[2]"
# echo $LATEST_VERSION

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
 then
 	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
 	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
 then
 	echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
 	exit 0
 fi
 
 echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


FILENAME="$HOME/Downloads/${APPNAME//[[:space:]]/}-${LATEST_VERSION}.zip"


echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [ -e "$INSTALL_TO" ]
then
	pgrep -qx "$APPNAME" && LAUNCH='yes' && killall "$APPNAME"
	mv -f "$INSTALL_TO" "$HOME/.Trash/$APPNAME.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"
	
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi




exit 0
EOF