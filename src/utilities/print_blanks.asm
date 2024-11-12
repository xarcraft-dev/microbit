;;; ==============================================================
;;; Small Routine To Print Out CX # Of Spaces To Screen
;;; ==============================================================

print_blanks:
    cmp cx, 0
    je end_print_blanks
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    dec cx
    jmp print_blanks

end_print_blanks:
    ret