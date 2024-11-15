;;; ===============================================================================================================================================================
;;; file_table.asm: Basic File Table Made With DB, String Consists Of '{fileName-sector#, fileName2-sector#, ...fileNameN-sector#}'
;;; ===============================================================================================================================================================
;;; 16 Byte Entires For File Table
;;; Byte                Purpose
;;; =====               ==========
;;; 0-9                 File Name
;;; 10-12               File Extension (txt, exe...)
;;; 13                  "Directory Entry" - 0h Based # Of File Table Entries
;;; 14                  Starting Sector i.e. 6h Would Be Start In Sector 6
;;; 15                  File Size (In Hex Digit Sectors) - Range 00h-FFh / 0-255 of 512th Byte
;;;                     sectors. Max File Size For 1 File Table Entry = 130560 Bytes Or
;;;                     127.5 KB; Max File Size Overall = 255*512*255 or ~32MB
;;; =============================================================================================

;;; Files
db 'bootSect  ', 'bin', 00h, 01h, 01h, \             ; Boot Sector
'kernel    ', 'bin', 00h, 02h, 03h, \                ; Kernel
'fileTable ', 'txt', 00h, 05h, 01h, \                ; File Table
'calculator', 'bin', 00h, 06h, 01h                   ; Calculator

;; Sector Padding Magic
times 512-($-$$) db 0                                ; Pad Rest Of File To 0s Until 512th Byte / End Of Sector