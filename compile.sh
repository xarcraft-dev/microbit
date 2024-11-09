# Color Variables
default='\033[0m'
bold_blue='\033[1;34m'
bold_green='\033[1;32m'

# Compile
echo -e "${bold_blue}[INFO] Compiling...${default}"
mkdir -p bin
rm bin/*
cd src
fasm bootSect.asm ../bin/bootSect.bin
fasm kernel.asm ../bin/kernel.bin
fasm fileTable.asm ../bin/fileTable.bin
cat ../bin/bootSect.bin ../bin/fileTable.bin ../bin/kernel.bin > ../bin/system.bin
echo -e "${bold_green}[INFO] Successfully compiled!${default}"
exit 0