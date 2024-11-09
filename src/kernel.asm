;;;
;;; kernel.asm: Basic Kernel Loadad From Out Bootsector
;;;

;; Set Video Mode
mov ah, 0x00                ; int 0x10 / ah 0x00 = Set Video Mode
mov al, 0x03
int 0x10

;; Change Color / Palette
mov ah, 0x0B
mov bh, 0x00
mov bl, 0x01
int 0x10

;; Print Functions
mov si, versionText
call print_string

mov si, welcomeText
call print_string

mov si, menuText
call print_string

;; Get User Input, Print To Screen & Choose Menu Option Or Run Command
get_input:
    mov di, commandString   ; DI Now Pointing To 'commandString' 
keyloop:
    mov ax, 0x00            ; AH = 0x00, AL = 0x00
    int 0x16                ; BIOS Int Get Keystroke AH = 0, Character Goes Into AL

    mov ah, 0x0e
    cmp al, 0xD             ; Did User Press 'Enter' Key?
    je run_command
    int 0x10                ; If Not, Print Input Character To Screen
    mov [di], al            ; Store Input Character To String
    inc di                  ; Go To Next Byte At DI / 'commandString'
    jmp keyloop             ; Loop For Next Character From User

run_command:
    mov byte [di], 0        ; Null Terminate 'commandString' From Dı
    mov al, [commandString]
    cmp al, 'F'             ; File Table Command / Menu Option
    jne command_not_found
    cmp al, 'N'             ; E(n)d Our Current Program
    je end_program
    mov si, commandSuccess
    call print_string
    jmp get_input

command_not_found:
    mov si, commandFailure
    call print_string
    jmp get_input

print_string:
    mov ah, 0x0e            ; INT 10 / AH 0x0e BIOS Teletype Output
    mov bh, 0x0             ; Page Number
    mov bl, 0x07            ; Color

print_char:
    mov al, [si]            ; Move Character Value At Address In BX Into AL
    cmp al, 0
    je end_print            ; Jump If Equal (AL = 0) To Halt Label
    int 0x10                ; Print Character In AL
    add si, 1               ; Move 1 Byte Forward / Get Next Character
    jmp print_char          ; Loop

end_print:
    ret

end_program:
    cli                     ; Clear Interrupts
    hlt                     ; Halt The CPU

;; Variables
versionText:    db 0xA, 0xD, '  ===========================================', \
                0xA, 0xD, '  Microbit [Version 0.1.0-pre4]', 0xA, 0xD, 0
welcomeText:    db '  Kernel Booted, Welcome To Microbit OS!', 0xA, 0xD, \
                '  ===========================================', 0xA, 0xD, 0xA, 0xD, 0
menuText:       db '  F) File & Program Browser / Loader', 0xA, 0xD, 0xA, 0xD, '  > ', 0
commandSuccess: db 0xA, 0xD, '  Command ran successfully!', 0xA, 0xD, 0xA, 0xD, '  > ', 0
commandFailure: db 0xA, 0xD, '  Oops! Something went wrong :(', 0xA, 0xD, 0xA, 0xD, '  > ', 0
commandString:  db ''

;; Sector Padding Magic
times 512-($-$$) db 0       ; Pad File With 0s Until 510th Byte
