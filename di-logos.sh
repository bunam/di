#!/bin/zsh -f
# Purpose: Download Logos v6 or 7 depending on what's asked for or installed
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-20

	# Default to this unless we're told otherwise
USE_VERSION='7'
XML_FEED='https://clientservices.logos.com/update/v1/feed/logos7-mac/stable.xml'

function use_v6 {
	XML_FEED='https://clientservices.logos.com/update/v1/feed/logos6-mac/stable.xml'
	ASTERISK='(Note that version 7 is now available.)'
	}

NAME="$0:t:r"

INSTALL_TO='/Applications/Logos.app'

HOMEPAGE="https://www.logos.com"

DOWNLOAD_PAGE=$(curl -sfLS "$XML_FEED" \
| sed 's#\.dmg.*#.dmg# ; s#.*https://downloads.logoscdn.com#https://downloads.logoscdn.com#g')

SUMMARY="Logos helps you discover, understand, and share more of the biblical insights you crave."

# No RELEASE_NOTES_URL available in XML_FEED or elsewhere, as far as I can find

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

if [[ -e "$INSTALL_TO" ]]
then
		# if v5 is installed, check that. Otherwise, use v6
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "6" ]]
	then
		use_v6
	fi
else
	if [ "$1" = "--use6" -o "$1" = "-6" ]
	then
		use_v6
	fi
fi

INFO=($(curl -sfL "$XML_FEED" \
| tidy \
	--char-encoding utf8 \
	--force-output yes \
	--input-xml yes \
	--markup yes \
	--output-xhtml no \
	--output-xml yes \
	--quiet yes \
	--show-errors 0 \
	--show-warnings no \
	--wrap 0 \
| egrep 'link href|logos:version' \
| head -2 \
| sed 's#<logos:version>##g ; s#</logos:version>##g ; s#<link href="##g; s#" .*##g'))

URL="$INFO[1]"

#LATEST_VERSION=`echo "$INFO[2]" | sed 's#\.000#.#g ; s#\.00#.#g' `

LATEST_VERSION="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

		# the “official” version has an extra 0 before the last 3 numbers. Why? Who knows. But it does.
	[[ "$INSTALLED_VERSION" == "6.14.0.134" ]] && INSTALLED_VERSION="6.14.0.0134"

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
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

fi

FILENAME="$HOME/Downloads/Logos-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Logos" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Logos" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Logos.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $MNTPNT/Logos.app to $INSTALL_TO"

ditto --noqtn -v "$MNTPNT/Logos.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installed $LATEST_VERSION to $INSTALL_TO"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi

diskutil eject "$MNTPNT"

[[ "$LAUNCH" == "yes" ]] && open "$INSTALL_TO"

exit 0
#EOF

