;;; ==============================================================
;;; Small Routine To Print Out CX # Of Spaces To Screen
;;; ==============================================================

print_blanks:
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    loop print_blanks
    ret