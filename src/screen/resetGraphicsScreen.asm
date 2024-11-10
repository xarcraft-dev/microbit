;;; ===============================================================================
;;; resetGraphicsScreen.asm: Reset A Graphics Mode Screen
;;; ===============================================================================

resetGraphicsScreen:
    ;; Set Video Mode
    mov ah, 0x00                ; int 0x10 / ah 0x00 = Set Video Mode
    mov al, 0x13                ; 320x200, 256 Color GFX Mode
    int 0x10

    ret