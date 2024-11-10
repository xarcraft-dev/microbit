;;; ==========================================================================================================
;;; print_registers.asm: Prints Registers & Memory Addresses To Screen
;;; ==========================================================================================================

print_registers:
    mov si, regString
    call print_string
    call print_hex              ; Print DX

    mov byte [regString + 4], 'a'
    call print_string
    mov dx, ax
    call print_hex              ; Print AX

    mov byte [regString + 4], 'b'
    call print_string
    mov dx, bx
    call print_hex              ; Print BX

    mov byte [regString + 4], 'c'
    call print_string
    mov dx, cx
    call print_hex              ; Print CX

    mov word [regString + 4], 'si'
    call print_string
    mov dx, si
    call print_hex              ; Print SI

    mov byte [regString + 4], 'd'
    call print_string
    mov dx, di
    call print_hex              ; Print DI

    mov word [regString + 4], 'cs'
    call print_string
    mov dx, cs
    call print_hex              ; Print CS

    mov byte [regString + 4], 'd'
    call print_string
    mov dx, ds
    call print_hex              ; Print DS

    mov byte [regString + 4], 'e'
    call print_string
    mov dx, es
    call print_hex              ; Print ES

    ret

;; =====================================================
;; Variables
;; =====================================================
regString:      db 0xA, 0xD, '  dx        ', 0 ; Hold String Of Current Register