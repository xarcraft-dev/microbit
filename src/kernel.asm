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
    cmp al, '}'                 ; At End Of File Table?
    je get_program_name
    cmp al, '-'                 ; At Secor Number Of Element?
    je sector_number_loop
    cmp al, ','                 ; Between Table Element
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

;; ============================================================================
;; After File Table Printed To Screen, User Can Input Program To Load
;; ============================================================================

get_program_name:
    mov ah, 0x0e
    mov si, getProgramName
    call print_string
    mov di, commandString   ; DI Now Pointing To 'commandString'
    ;; Reset Counter & Length of User Input
    mov byte [commandLength], 0

program_loop:
    mov ax, 0x00            ; AH = 0x00, AL = 0x00
    int 0x16                ; BIOS Int Get Keystroke AH = 0, Character Goes Into AL

    mov ah, 0x0e
    cmp al, 0xD             ; Did User Press 'Enter' Key?
    je start_search

    inc byte [commandLength] ; If Not Add to Counter
    mov [di], al            ; Store Input Character To Command String
    inc di
    int 0x10                ; Print Input Character To Screen
    jmp program_loop

start_search:
    mov di, commandString   ; Reset DI, Point To Start Of Command String
    xor bx, bx              ; Reset ES:BX To Point To Beginning Of File Table

check_next_char:
    mov al, [ES:BX]         ; Get File Table Char
    cmp al, '}'             ; At End Of File Table?
    je program_not_found    ; If Yes, Program Was Not Found

    cmp al, [di]            ; Does User Input Match File Table Character
    je start_compare

    inc bx                  ; If Not, Get Next Char In File Table And Recheck
    jmp check_next_char

start_compare:
    push bx                 ; Save File Table Position
    mov byte cl, [commandLength]

compare_loop:
    mov al, [ES:BX]         ; Get File Table Character
    inc bx                  ; Next Byte In Input / File Table
    cmp al, [di]            ; Does Inpput Match File Table Character?
    jne restart_search      ; If Not Search Again From This Point In File Table

    dec cl                  ; If It Does Match, Decrement Length Counter
    jz found_program        ; Counter = 0, Input Found In File Table
    inc di                  ; Else Go To Next Byte Of Input
    jmp compare_loop

restart_search:
    mov di, commandString   ; Else, Reset To Start Of User Input
    pop bx                  ; Get The Saved File Table Location
    inc bx                  ; Go To Next Character In File Table
    jmp check_next_char     ; Start Checking Again

program_not_found:
    mov si, programFailure
    call print_string       ; Print Program Not Found Text
    mov ah, 0x00            ; Get Keystroke, Print To Screen
    int 0x16
    mov ah, 0x0e
    int 0x10
    cmp al, 'Y'
    je file_table           ; Reload File Table Screen To Search Again
    cmp al, 'y'
    je file_table
    jmp file_table_end      ; Else Go Back To Main Menu

found_program:
    inc bx
    mov cl, 10              ; Use To Get Sector Number
    xor al, al              ; Reset AL To 0

next_sector_number:
    mov dl, [ES:BX]         ; Checking Next Byte Of File Table
    inc bx
    cmp dl, ','             ; At End Of Sector Number?
    je load_program         ; If So, Load Program From That Sector
    cmp dl, 48              ; Else, Check If AL is '0' - '9' In ASCII
    jl sector_not_found     ; Before '0', Not A Number
    cmp dl, 57
    jg sector_not_found     ; After '9', Not A Number
    sub dl, 48              ; Covert ASCII Character Into Integer
    mul cl                  ; AL * CL (AL * 10), Result In AH / AL (AX)
    add al, dl              ; AL = AL + DL
    jmp next_sector_number

sector_not_found:
    mov si, sectorNotFound  ; Did Not Find Program Name In File Table
    call print_string
    mov ah, 0x00            ; Get Keystroke, Print To Screen
    int 0x16
    mov ah, 0x0e
    int 0x10
    cmp al, 'Y'
    je file_table           ; Reload File Browser Screen To Search Again
    cmp al, 'y'
    je file_table
    jmp file_table_end      ; Else Go Back To Main Menu

load_program:
    mov cl, al              ; CL = Sector # To Start Loading / Reading At

    mov ah, 0x00            ; INT 13H AH 0 = Reset Disk System
    mov dl, 0x00
    int 0x13

    mov ax, 0x8000          ; Memory Location To Load Program To
    mov es, ax
    xor bx, bx              ; ES:BX -> 0x8000:0x0000

    mov ah, 0x02            ; INT 13 AH 02 = Read Disk Sectors To Memory
    mov al, 0x01            ; # Of Sectors To Read
    mov ch, 0x00            ; Track #
    mov dh, 0x00            ; Head #
    mov dl, 0x00            ; Drive #

    int 0x13
    jnc program_loaded      ; Carry Flag Not Set, Success

    mov si, pgmNotLoaded    ; Else Error, Program Did Not Load Correctly
    call print_string
    mov ah, 0x00
    int 0x16
    jmp file_table          ; Reload File Table

program_loaded:
    mov ax, 0x8000          ; Program Loaded, Set Segment Registers To Location
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x8000:0x0000       ; Far Jump To Program

file_table_end:
    mov si, goBackMessage   ; Show Go Back Message
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
;; N) End Program
;; =====================================================
end_program:
    mov si, endProgramText
    call print_string
    cli                     ; Clear Interrupts
    hlt                     ; Halt The CPU

;; =====================================================
;; End Main Logic
;; =====================================================

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
versionText:            db 0xA, 0xD, 0xA, 0xD, '  Microbit [Version 0.1.1-rc1]', 0xA, 0xD, 0
welcomeText:            db '  Kernel Booted, Welcome To Microbit OS!', 0xA, 0xD, 0xA, 0xD, 0xA, 0xD, 0
menuText:               db '  Commands:', 0xA, 0xD, '  F) File & Program Browser / Loader', \
                        0xA, 0xD, '  N) End Program', 0xA, 0xD, '  R) Reboot', 0xA, 0xD, \
                        '  P) Print Register Values', 0xA, 0xD, '  G) Graphics Mode Test', \
                        0xA, 0xD, 0xA, 0xD, '  > ', 0
commandFailure:         db 0xA, 0xD, '  Oops! Something went wrong :(', 0xA, 0xD, 0xA, 0xD, '  > ', 0
endProgramText:         db 0xA, 0xD, '  Ending Program...', 0
fileTableHeading:       db 0xA, 0xD, 0xA, 0xD, '  File/Program         Sector #', 0xA, 0xD, 0xA, 0xD, '  ', 0
printRegisterHeading:   db 0xA, 0xD, 0xA, 0xD, '  Register Memory Location', 0xA, 0xD, 0
goBackMessage:          db 0xA, 0xD, 0xA, 0xD, '  Press any key to go back...', 0
programFailure:         db 0xA, 0xD, 0xA, 0xD, '  Program Not Found! Try again? (Y)', 0xA, 0xD, '  > ', 0
pgmNotLoaded:           db 0xA, 0xD, 0xA, 0xD, '  Error! Program Not Loaded, Try Again.', 0xA, 0xD, 0
sectorNotFound:         db 0xA, 0xD, 0xA, 0xD, '  Error! Secor Number Not Found! Try Again? (Y)', 0xA, 0xD, '  > ', 0
getProgramName:         db 0xA, 0xD, 0xA, 0xD, '  Enter Program Name: ', 0
commandString:          db ' ', 0
commandLength:          db 0

;; =====================================================
;; Sector Padding Magic
;; =====================================================
times 1536-($-$$) db 0       ; Pad File With 0s Until 1024th Byte
