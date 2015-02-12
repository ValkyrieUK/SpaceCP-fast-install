echo ""
check_upstart_service(){
    status $1 | grep -q "^$1 start" > /dev/null
    return $?
}

if [ "$(id -u)" != "0" ]
then
  echo "This script must be run as root!" 1>&2
  exit 1
fi

if [ ! -x /usr/bin/wget ]; then
  command -v wget >/dev/null 2>&1 || { echo >&2 "--> Installing wget"; apt-get install wget; }
fi

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
echo 'y' | ufw enable &> /dev/null
echo '-------------------'
echo "### Opening port 22"
ufw allow 22 &> /dev/null
echo "### Opening port 25565"
ufw allow 25565 &> /dev/null
echo "### Opening port 35565"
ufw allow 35565 &> /dev/null
echo "### Opening port 35566"
ufw allow 35566 &> /dev/null
echo '-------------------'

echo "
--> Adding the Java 8 apt repository"
rf /etc/apt/sources.list.d/webupd8team-java-trusty.list &> /dev/null
apt-add-repository -y ppa:webupd8team/java &> /dev/null
echo "
--> Adding the Node apt repository"
rf /etc/apt/sources.list.d/nodesource.list &> /dev/null
curl -sL https://deb.nodesource.com/setup | bash - &> /dev/null

echo "
--> Adding a 2GB Swapfile"
fallocate -l 2G /swapfile &> /dev/null
chmod 600 /swapfile &> /dev/null
mkswap /swapfile &> /dev/null
swapon /swapfile &> /dev/null
swapon -s &> /dev/null

echo "
--> Installing Java 8. This may take a while..."
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer &> /dev/null

echo "
--> Installing Node JS"
apt-get install -y nodejs &> /dev/null
echo "
--> Installing build-essential"
apt-get install -y build-essential &> /dev/null
echo "
--> Installing Unzip"
apt-get install -y unzip &> /dev/null
echo "
--> Installing makepasswd"
apt-get install -y makepasswd &> /dev/null

if [ -z "$(getent passwd SpaceCP)" ]; then
    echo "
    --> Creating a new user"
    useradd -m SpaceCP &> /dev/null
    export SPACE_CP_PASSWORD=$(makepasswd)
    echo $SPACE_CP_PASSWORD | passwd SpaceCP &> /dev/null
    echo "
    --> The Password for your SpaceCP user is '$SPACE_CP_PASSWORD'"
else
        echo "
--> SpaceCP user already exists"
fi

su SpaceCP <<'EOF'
echo "
--> Installing daemon with User ID: $SPACE_CP_USER_ID and API Key: $SPACE_CP_API_KEY. This might take some time ..."
if [ -e ~/spacecp ]; then
  cd ~/spacecp
else
  mkdir ~/spacecp
  cd ~/spacecp
fi
wget http://dl.spacecp.net/houston/houston.zip &> /dev/null
unzip houston.zip &> /dev/null
rm houston.zip 
npm install &> /dev/null
echo "
--> Bootsrapping Houston"
node houston bootstrap -i $SPACE_CP_USER_ID -k $SPACE_CP_API_KEY -f
EOF

echo "
--> Downloading the upstart script"
wget -O /etc/init/space_cp.conf https://raw.githubusercontent.com/ValkyrieUK/SpaceCP-fast-install/master/space_cp.conf &> /dev/null

if [ check_upstart_service space_cp ]; then
  echo "
--> SpaceCP daemon already running, 'tail -f /var/log/space_cp.log' to check the logs."
else
  echo "
--> Starting SpaceCP daemon"
  start space_cp

  echo "
--> Space CP daemon is up and running ! Use the command below to look at the logs !

  tail -f /var/log/space_cp.log
  "
fi

if grep -q "alias houston='node /home/SpaceCP/spacecp/houston'" "~/.profile"; then
 echo '--> Toolbelt already installed !' 
else
  echo "
--> Installing command line toolbet !"
  echo "alias houston='node /home/SpaceCP/spacecp/houston'" >> ~/.profile
  echo "alias houston='node /home/SpaceCP/spacecp/houston'" >> /home/SpaceCP/.profile
  source ~/.profile
fi

echo "--> Thats it ! We're done ! "
echo ""
echo "--> To use the use the 'houston' command for more information"

