;;;
;;; dir.asm: File / Program Browser
;;;

file_browser:
    mov si, fileTableHeading
    call print_string

    ;; Load File Table String From Its Memory Location (0x1000:0000), Print File
    ;; And Program Names & Sector Numbers To Screen, For User To Choose

    xor cx, cx              ; Reset Counter For # Bytes At Current File Table Entry
    mov ax, 0x1000          ; File Table Location
    mov es, ax              ; ES = 0x1000
    xor bx, bx              ; ES:BX = 0x1000:0
    mov ah, 0x0e            ; Get Ready To Print To Screen

file_name_loop:
    mov al, [ES:BX]
    cmp al, 0               ; Is File Name Null? At End Of File Table?
    je get_input            ; If End Of File Table, Done Printing, Get Next User Input

    int 0x10                ; Otherwise Print Char In AL To Screen
    cmp cx, 9               ; If At End Of Name, Go On
    je file_extension
    inc cx                  ; Increment File Entry Byte Counter
    inc bx                  ; Get Next Byte At File Table
    jmp file_name_loop

file_extension:
    ;; 2 Blanks Before File Extension
    mov cx, 2
    call print_blanks

    inc bx
    mov al, [ES:BX]
    int 0x10
    inc bx
    mov al, [ES:BX]
    int 0x10
    inc bx
    mov al, [ES:BX]
    int 0x10

directory_entry_number:
    ;; 9 Blanks Before Entry #
    mov cx, 9
    call print_blanks

    inc bx
    mov al, [ES:BX]
    call print_hex_as_ascii

start_sector_number:
    ;; 9 Blanks Before Starting Sector
    mov cx, 9
    call print_blanks

    inc bx
    mov al, [ES:BX]
    call print_hex_as_ascii

get_file_size:
    ;; 13 Blanks Before File Size
    mov cx, 14
    call print_blanks

    inc bx
    mov al, [ES:BX]
    call print_hex_as_ascii
    mov al, 0xA
    int 0x10
    mov al, 0xD
    int 0x10
    mov al, 0x20
    int 0x10
    mov al, 0x20
    int 0x10

    inc bx                  ; Get First Byte Of Next File Name
    xor cx, cx              ; Reset Counter For Next File Name
    jmp file_name_loop