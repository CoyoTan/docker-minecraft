#!/bin/sh

printf "Downloading Paperclip..."
wget -qP /paper/ "https://ci.destroystokyo.com/job/PaperSpigot/lastSuccessfulBuild/artifact/paperclip.jar"
