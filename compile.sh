# Color Variables
default='\033[0m'
bold_blue='\033[1;34m'
bold_green='\033[1;32m'
bold_red='\033[1;31m'

# Compile
echo -e "${bold_blue}[INFO] Compiling...${default}"
cd src
fasm bootSect.asm
echo -e "${bold_green}[INFO] Successfully compiled!${default}"
exit 0