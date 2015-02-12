echo ""
echo "Ready to start ? Brutalize a key with your favorite finger"
read -n1 -s

echo -n "Please give me your User ID: "
read USER_ID
export SPACE_CP_USER_ID=$USER_ID

echo -n "And your API key please: "
read API_KEY
export SPACE_CP_API_KEY=$API_KEY

echo "
--> Opening some ports"
ufw enable
echo "### Opening port 22"
ufw allow 22
echo "### Opening port 25565"
ufw allow 25565
echo "### Opening port 35565"
ufw allow 35565
echo "### Opening port 35566"
ufw allow 35566

echo "
--> Adding the Java 8 apt repository"
rf /etc/apt/sources.list.d/webupd8team-java-trusty.list 2>/dev/null
apt-add-repository -y ppa:webupd8team/java
echo "
--> Adding the Node apt repository"
rf /etc/apt/sources.list.d/nodesource.list 2>/dev/null
curl -sL https://deb.nodesource.com/setup | bash -

echo "
--> Adding a 2GB Swapfile"
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon -s

echo "
--> Installing dependencies"
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer nodejs build-essential unzip makepasswd

if [ -z "$(getent passwd SpaceCP)" ]; then
    echo "
--> Creating a new sudo user"
    useradd -m SpaceCP
    export SPACE_CP_PASSWORD=$(makepasswd)
    echo $SPACE_CP_PASSWORD | passwd SpaceCP &> /dev/null
    echo "The Password for your SpaceCP user is '$SPACE_CP_PASSWORD'"
else
        echo "
--> SpaceCP user already exists"
fi

su SpaceCP <<'EOF'
echo "
--> Installing daemon with User ID: $SPACE_CP_USER_ID and API Key: $SPACE_CP_API_KEY"
if [ -e ~/spacecp ]; then
  cd ~/spacecp
else
  mkdir ~/spacecp
  cd ~/spacecp
fi
wget http://dl.spacecp.net/houston/houston.zip
unzip houston.zip
rm houston.zip
npm install
echo "
--> Bootsrapping Houston"
node houston bootstrap -i $SPACE_CP_USER_ID -k $SPACE_CP_API_KEY -f
EOF

echo "
--> Creating a upstart script"
wget -O /etc/init/space_cp.conf https://raw.githubusercontent.com/ValkyrieUK/SpaceCP-fast-install/master/space_cp.conf

echo "
--> Starting SpaceCP daemon"
start space_cp

echo "
--> Space CP daemon is up and running ! Use the command below to look at the logs !

tail -f /var/log/space_cp.log
"


