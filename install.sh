# Color Variables
default='\033[0m'
bold_blue='\033[1;34m'
bold_red='\033[1;31m'

if [ ! -z $(grep "system_installed=true" "system.ini") ];
then
    echo -e "${bold_red}[ERROR] It seems that Microbit has already been installed! If not, delete system.ini file.${default}"
    exit 1
fi

clear
echo -e "${bold_blue}[INFO] Installing fasm, qemu and ovmf...${default}"
sudo apt-get install fasm qemu-system ovmf
echo -e "${bold_blue}[INFO] Giving access for the other shell scripts...${default}"
chmod +x compile.sh boot.sh run.sh clear.sh
echo -e "${bold_blue}[INFO] Prepearing to boot for the first time...${default}"
echo "system_installed=true" > system.ini
./run.sh