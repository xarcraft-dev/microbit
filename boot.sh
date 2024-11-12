# Color Variables
default='\033[0m'
bold_blue='\033[1;34m'

# Boot
echo -e "${bold_blue}[INFO] Booting...${default}"
cd bin
qemu-system-i386 -drive format=raw,file=./system.bin,if=floppy,index=0,media=disk
echo -e "${bold_blue}[INFO] Shutting down...${default}"