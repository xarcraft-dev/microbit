;;;
;;; Prints Character Strings in BX Register
;;;

print_string:
    pusha                   ; Store All Register Values Onto The Stack
    mov ah, 0x0e            ; int 10 / ah 0x0e BIOS Teletype Output

print_char:
    mov al, [bx]            ; Move Character Value at Addres in BX Into AL
    cmp al, 0
    je end_print            ; Jump If Equal (AL = 0) To Halt Label
    int 0x10                ; Print Character in AL
    add bx, 1               ; Move 1 Byte Forward / Get Next Character
    jmp print_char          ; Loop

end_print:
    popa                    ; Restore Registers From The Stack Before Returning
    ret