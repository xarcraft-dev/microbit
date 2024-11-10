;;;
;;; Prints Strings in SI Register
;;;

print_string:
    pusha                   ; Store All Registers Onto Stack
    mov ah, 0x0e            ; INT 10 / AH 0x0e BIOS Teletype Output
    mov bh, 0x0             ; Page Number
    mov bl, 0x07            ; Color

print_char:
    lodsb                  ; Move Character Value At Address In BX Into AL
    cmp al, 0
    je end_print            ; Jump If Equal (AL = 0) To Halt Label
    int 0x10                ; Print Character In AL
    jmp print_char          ; Loop

end_print:
    popa                    ; Restore All Registers From The Stack
    ret