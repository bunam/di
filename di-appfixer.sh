#!/bin/zsh -f
# Purpose: Download and install the latest version of App Fixer
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-24

NAME="$0:t:r"

echo "$NAME: https://sqwarq.com/appfixer/ says 'App Fixer has been discontinued.'"

exit 0




### The code below is left as reference, but no longer works.












if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

LATEST_VERSION=`curl -sfL https://s3.amazonaws.com/sqwarq.com/AppFixerDownload/updateappfixer.html`

INSTALL_TO='/Applications/App Fixer.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0`

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

# URL='https://s3.amazonaws.com/sqwarq.com/AppFixerDownload/App+Fixer.app.zip'

URL='https://s3.amazonaws.com/sqwarq.com/PublicZips/AppFixer.app.zip'

FILENAME="$HOME/Downloads/AppFixer-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "App Fixer" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "App Fixer" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/App Fixer.$INSTALLED_VERSION.app"
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
#EOF
