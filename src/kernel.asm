;;; ==========================================================================================================
;;; kernel.asm: Basic Kernel Loadad From Out Bootsector
;;; ==========================================================================================================


;; =====================================================
;; Main Menu
;; =====================================================
main_menu:
    ;; Reset Screen State
    call resetTextScreen

    ;; =====================================================
    ;; Print Version, Welcome Text and Menu
    ;; =====================================================
    mov si, versionText         ; Print The Version Text
    call print_string

    mov si, welcomeText         ; Print The Welcome Text
    call print_string

    mov si, menuText            ; Print The Menu Text
    call print_string

;; =============================================================================
;; Get User Input, Print To Screen & Choose Menu Option Or Run Command
;; =============================================================================

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
    je file_table
    cmp al, 'f'
    je file_table
    cmp al, 'R'             ; Warm Reboot Option
    je reboot
    cmp al, 'r'
    je reboot
    cmp al, 'P'             ; Print Register Values
    je print_registers_command
    cmp al, 'p'
    je print_registers_command
    cmp al, 'G'             ; Graphics Mode Test
    je graphics_test
    cmp al, 'g'
    je graphics_test
    cmp al, 'N'             ; E(n)d Our Current Program
    je end_program
    cmp al, 'n'
    je end_program
    mov si, commandFailure  ; Command Not Found
    call print_string
    jmp get_input

;; =====================================================
;; F) File Table
;; =====================================================
file_table:
    ;; Reset Screen State
    call resetTextScreen

    mov si, fileTableHeading
    call print_string

    ;; Load File Table String From Its Memory Location (0x1000), Print File
    ;; And Program Names & Sector Numbers To Screen, For User To Choose
    xor cx, cx                  ; Reset Counter For # Chars In File/Pgm Name
    mov ax, 0x1000              ; File Table Location
    mov es, ax                  ; ES = 0x1000
    xor bx, bx                  ; ES:BX = 0x1000:0
    mov ah, 0x0e                ; Get Ready To Print To Screen

file_table_loop:
    inc bx
    mov al, [ES:BX]
    cmp al, '}'
    je stop
    cmp al, '-'
    je sector_number_loop
    cmp al, ','
    je next_element
    inc cx
    int 0x10
    jmp file_table_loop

sector_number_loop:
    cmp cx, 21
    je file_table_loop
    mov al, ' '
    int 0x10
    inc cx
    jmp sector_number_loop

next_element:
    xor cx, cx              ; Reset Counter
    mov al, 0xA
    int 0x10
    mov al, 0xD
    int 0x10
    mov al, 0x20
    int 0x10
    mov al, 0x20
    int 0x10
    jmp file_table_loop

stop:
    mov si, goBackMessage
    call print_string

    mov ah, 0x00            ; Get Keystroke
    int 0x16
    jmp main_menu           ; Go Back To Main Menu


;; =====================================================
;; R) Warm Reboot
;; =====================================================
reboot:
    jmp 0xFFFF:0x0000

;; =====================================================
;; P) Print Registers
;; =====================================================
print_registers_command:
    ;; Reset Screen State
    call resetTextScreen

    ;; Print Register Values To Screen
    mov si, printRegisterHeading
    call print_string

    call print_registers

    ;; Go Back To Main Menu
    mov si, goBackMessage
    call print_string
    mov ah, 0x00
    int 0x16                ; Get Keystroke
    jmp main_menu           ; Go Back To Main Menu

;; =====================================================
;; N) End Program
;; =====================================================
end_program:
    mov si, endProgramText
    call print_string
    cli                     ; Clear Interrupts
    hlt                     ; Halt The CPU

;; =====================================================
;; G) Graphics Mode Test
;; =====================================================
graphics_test:
    call resetGraphicsScreen

    ;; Test Square
    mov ah, 0x0C            ; INT 0x10 AH 0x0C - Write GFX Pixel
    mov al, 0x02            ; Green
    mov bh, 0x00            ; Page #

    ;; Starting Pixel Of Square (GFX)
    mov cx, 100             ; Column #
    mov dx, 100             ; Row #
    int 0x10

squareLoop:
    ;; Pixels For Columns
    inc cx
    int 0x10
    cmp cx, 150
    jne squareLoop

    ;; Go Down One Row
    inc dx
    int 0x10
    mov cx, 99
    cmp dx, 150
    jne squareLoop          ; Pixels For Next Row

    mov ah, 0x00
    int 0x16                ; Get Keystroke
    jmp main_menu

;; =====================================================
;; Included Files
;; =====================================================
include 'utilities/print_string.asm'
include 'utilities/print_hex.asm'
include 'utilities/print_registers.asm'
include 'screen/resetTextScreen.asm'
include 'screen/resetGraphicsScreen.asm'

;; =====================================================
;; Variables
;; =====================================================
versionText:            db 0xA, 0xD, 0xA, 0xD, '  Microbit [Version 0.1.0]', 0xA, 0xD, 0
welcomeText:            db '  Kernel Booted, Welcome To Microbit OS!', 0xA, 0xD, 0xA, 0xD, 0xA, 0xD, 0
menuText:               db '  Commands:', 0xA, 0xD, '  F) File & Program Browser / Loader', \
                        0xA, 0xD, '  N) End Program', 0xA, 0xD, '  R) Reboot', 0xA, 0xD, \
                        '  P) Print Register Values', 0xA, 0xD, '  G) Graphics Mode Test', \
                        0xA, 0xD, 0xA, 0xD, '  > ', 0
commandSuccess:         db 0xA, 0xD, '  Command ran successfully!', 0xA, 0xD, 0xA, 0xD, '  > ', 0
commandFailure:         db 0xA, 0xD, '  Oops! Something went wrong :(', 0xA, 0xD, 0xA, 0xD, '  > ', 0
endProgramText:         db 0xA, 0xD, '  Ending Program...', 0
fileTableHeading:       db 0xA, 0xD, 0xA, 0xD, '  File/Program         Sector #', 0xA, 0xD, 0xA, 0xD, '  ', 0
printRegisterHeading:   db 0xA, 0xD, 0xA, 0xD, '  Register Memory Location', 0xA, 0xD, 0
goBackMessage:          db 0xA, 0xD, 0xA, 0xD, '  Press any key to go back...', 0
commandString:          db '', 0

;; =====================================================
;; Sector Padding Magic
;; =====================================================
times 1024-($-$$) db 0       ; Pad File With 0s Until 1024th Byte
