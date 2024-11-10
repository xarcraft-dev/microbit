;;; ==========================================================================================================
;;; print_string.asm Prints Strings in SI Register
;;; ==========================================================================================================

print_string:
    pusha                   ; Store All Registers Onto Stack
    mov ah, 0x0e            ; INT 10 / AH 0x0e BIOS Teletype Output
    mov bh, 0x0             ; Page Number
    mov bl, 0x07            ; Foreground Text Color If In GFX Modes

print_char:
    lodsb                   ; Move Byte At SI Into AL
    cmp al, 0               ; At The End Of String?
    je end_print            ; End If So
    int 0x10                ; Or Print Character In AL
    jmp print_char          ; Loop

end_print:
    popa                    ; Restore All Registers From The Stack
    ret