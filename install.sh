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
--> Adding some apt repositories"
rf /etc/apt/sources.list.d/webupd8team-java-trusty.list 2>/dev/null
rf /etc/apt/sources.list.d/nodesource.list 2>/dev/null
apt-add-repository -y ppa:webupd8team/java
curl -sL https://deb.nodesource.com/setup | bash -

echo "
--> Installing dependencies"
apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer nodejs build-essential unzip makepasswd

echo "
--> Opening daemon port"
ufw enable
ufw allow 22
ufw allow 25565
ufw allow 35565
ufw allow 35566

echo "
--> Creating a new sudo user"
useradd -m SpaceCP
export SPACE_CP_PASSWORD=$(makepasswd)
echo $SPACE_CP_PASSWORD | passwd SpaceCP &> /dev/null
echo "The Password for your SpaceCP user is '$SPACE_CP_PASSWORD'"

su SpaceCP <<'EOF'
echo "
--> Installing daemon with User ID: $SPACE_CP_USER_ID and API Key: $SPACE_CP_API_KEY"
mkdir ~/spacecp
cd ~/spacecp
wget http://dl.spacecp.net/houston/houston.zip
unzip houston.zip
rm houston.zip
npm install
node houston bootstrap -i $SPACE_CP_USER_ID -k $SPACE_CP_API_KEY -f

echo "
--> Starting daemon"
echo "
--> Check the web panel for a connection"
node houston start
EOF
