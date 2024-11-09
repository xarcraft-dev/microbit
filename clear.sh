# Color Variables
default='\033[0m'
bold_blue='\033[1;34m'

# Remove The Binaries
echo -e "${bold_blue}[INFO] Removing the binaries...${default}"
mkdir -p bin
rm bin/*
echo -e "${bold_green}[INFO] Successfully removed the binaries!${default}"
exit 0