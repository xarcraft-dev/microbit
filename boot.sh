# Color Variables
default='\033[0m'
bold_blue='\033[1;34m'

# Boot
echo -e "${bold_blue}[INFO] Booting...${default}"
cd src
qemu-system-i386 bootSect.bin
echo -e "${bold_blue}[INFO] Shutting down...${default}"