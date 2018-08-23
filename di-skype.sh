#!/bin/zsh -f
# Purpose: Download and install the latest version of Skype
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-22

NAME="$0:t:r"

INSTALL_TO="/Applications/Skype.app"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function use_v7 {

	ASTERISK='(Note that version 8 is also available.)'
	USE_VERSION='7'
	URL='https://www.dropbox.com/s/8yakzhul3bmefnb/Skype-7.59.0.37.dmg?dl=0'
	LATEST_VERSION="7.59.0.37"
}

function use_v8 {

	USE_VERSION='8'

	URL=$(curl -sfLS --head 'https://get.skype.com/go/getskype-skypeformac' \
		| awk -F'\r| ' '/^.ocation/{print $2}')

	LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

}

if [[ -e "$INSTALL_TO" ]]
then
		# if v7 is installed, check that. Otherwise, use v8
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion | cut -d. -f1)

	if [[ "$1" == "--force7" ]]
	then

		if [[ "$MAJOR_VERSION" -gt "7" ]]
		then
			echo "$NAME: Version $MAJOR_VERSION is installed. Removing it and installing to version 7."

			rm -rf "$INSTALL_TO" || sudo rm -rf "$INSTALL_TO"
		fi

		use_v7

	elif [[ "$MAJOR_VERSION" == "7" ]]
	then
		use_v7
	else
		use_v8
	fi
else
	if [ "$1" = "--use7" -o "$1" = "-7" -o "$1" = "--force7" ]
	then
		use_v7

	else
		use_v8
	fi
fi

	# If any of these are blank, we should not continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

if (( $+commands[di-skypecallrecorder-private.sh] ))
then
		# if 'di-skypecallrecorder-private.sh' exists, run it.
		# n.b. that script can't be shared because the download link contains the user's registration code.
	di-skypecallrecorder-private.sh
fi

exit 0
#EOF