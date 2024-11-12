;;; ===============================================================================================================================================================
;;; file_table.asm: Basic File Table Made With DB, String Consists Of '{fileName-sector#, fileName2-sector#, ...fileNameN-sector#}'
;;; ===============================================================================================================================================================

db '{calculator-06,program2-12}'

;; Sector Padding Magic
times 512-($-$$) db 0   ; Pad Rest Of File To 0s Until 512th Byte / End Of Sector