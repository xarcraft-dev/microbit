;;;
;;; clearScreen.asm: Clears Screen By Scrolling (BIOS int 10h AH 06h)
;;;
clear_screen:
    pusha
    mov ah, 06h
    mov al, 00h

    xor cx, cx      ; CH / CL = Row / Col Of Upper Left Corner
    mov dh, 24      ; DH = Row Of Lower Right Corner
    mov dl, 79      ; DL = Col Of Lower Right Corner

    int 10h         ; Call BIOS Video Services Interrupt

    popa
    ret