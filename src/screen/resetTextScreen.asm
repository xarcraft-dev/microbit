;;; ===============================================================================
;;; resetTextScreen.asm: Reset A Text Mode Screen
;;; ===============================================================================

resetTextScreen:
    ;; Set Video Mode
    mov ah, 0x00                ; int 0x10 / ah 0x00 = Set Video Mode
    mov al, 0x03                ; 80x25, 16 Color TXT Mode
    int 0x10

    ;; Change Color / Palette
    mov ah, 0x0B
    mov bh, 0x00                ; Change BG Color
    mov bl, 0x01                ; Blue
    int 0x10

    ret