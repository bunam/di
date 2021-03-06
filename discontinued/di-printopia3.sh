#!/bin/zsh -f
# Purpose: Download and install the latest version of Printopia 3
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Printopia.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

HOMEPAGE="https://www.decisivetactics.com/products/printopia/"

	## 2018-07-17 we should get something like this:
	## https://www.decisivetactics.com/products/printopia/dl/Printopia_3.0.11.zip

if (( $+commands[lynx] ))
then

	URL=$(lynx -nonumbers -listonly -dump -nomargins "$HOMEPAGE" | egrep '^http.*\.zip$' | head -1)

else

	URL=$(curl -sfL "$HOMEPAGE" \
		| tr '"' '\012' \
		| egrep "^http.*\.zip$" \
		| head -1)
fi

if [[ "$URL" == "" ]]
then
	echo "$NAME: Scraping of $HOMEPAGE apparently failed. \$URL is empty."
	exit 1
fi

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: Could not determine LATEST_VERSION from $URL"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date ($LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="https://www.decisivetactics.com/products/printopia/release-notes"

	echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n"

	curl -sfL "${RELEASE_NOTES_URL}" \
	| sed '1,/<div class="date">/d; /<div class="releasenotes">/,$d' \
	| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin

	echo "\nSource: <$RELEASE_NOTES_URL>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#
#EOF

