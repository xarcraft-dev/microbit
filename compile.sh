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
fasm calculator.asm ../bin/calculator.bin
cat ../bin/bootSect.bin ../bin/fileTable.bin ../bin/kernel.bin ../bin/calculator.bin > ../bin/temp.bin
dd if=/dev/zero of=../bin/system.bin bs=512 count=2880
dd if=../bin/temp.bin of=../bin/system.bin conv=notrunc
rm ../bin/temp.bin
echo -e "${bold_green}[INFO] Successfully compiled!${default}"
exit 0