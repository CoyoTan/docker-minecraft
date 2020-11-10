#!/bin/sh

(
  cd /tmp
  #If a modpack is specified then...
  if [ "$MODPACK" ]; then
    printf "Using specified modpack...\n"
    if printf "$MODPACK" | grep -q '://'; then
      wget -qO modpack.zip "$MODPACK"
    else
      cp "/data/$MODPACK" modpack.zip
    fi
    printf "Extracting modpack...\n"
    unzip -q modpack
    MC_VERSION=$(jq -r '.minecraft.version' < manifest.json)
    FORGE_VERSION=$(jq -r '(.minecraft.modLoaders[] | select(.primary)).id' < manifest.json | cut -d- -f2)

#However, if a modpack is not specified...
  else
    if printf "$VERSION" | grep -q [A-z]; then
      printf "Downloading promotions manifest...\n"
      wget -q "https://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions.json"
      MC_VERSION=$(jq -r --arg ver "$VERSION" '.promos[$ver].mcversion' < promotions.json)
      FORGE_VERSION=$(jq -r --arg ver "$VERSION" '.promos[$ver].version' < promotions.json)
    else
      MC_VERSION=$(printf "$VERSION" | cut -d- -f1)
      FORGE_VERSION=$(printf "$VERSION" | cut -d- -f2)
    fi
  fi
  
  #Either way, we need to do this.
  printf "Downloading Forge server ($MC_VERSION-$FORGE_VERSION)...\n"
  wget -q "https://files.minecraftforge.net/maven/net/minecraftforge/forge/$MC_VERSION-$FORGE_VERSION/forge-$MC_VERSION-$FORGE_VERSION-installer.jar"
)

#We're now back in /data.
printf "Installing Forge server...\n"
(
  cd /forge
  mkdir mods # For < 12.18.3.2202
  java $@ -Djava.net.preferIPv4Stack=true -jar /tmp/forge-*-installer.jar --installServer > /dev/null
)

#We're now back in /data.
mkdir -p mods
mv -n /forge/mods/* mods

#If the environment variable $MODPACK is defined, then
if [ "$MODPACK" ]; then
  rm -f mods/*.jar mods/*.zip
  printf "Downloading mods...\n"
  for i in $(jq -cr '.files[]' < /tmp/manifest.json); do
    wget -qP mods $(curl -Lso /dev/null -w %{url_effective} $(curl -s https://addons-ecs.forgesvc.net/api/v2/addon/$(printf "$i" | jq -r '.projectID')/file/$(printf "$i" | jq -r '.fileID')/download-url))
  done
  printf "Using modpack overrides...\n"
  cp -r /tmp/$(jq -r '.overrides' < /tmp/manifest.json)/* .
fi

printf "Clean up...\n"
rm -rf /tmp/*
touch /forge/.init_done
