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
    xor cx, cx                  ; Reset Counter For # Of Bytes At Current 'fileTable' Entry
    mov ax, 0x1000              ; File Table Location
    mov es, ax                  ; ES = 0x1000
    xor bx, bx                  ; ES:BX = 0x1000:0
    mov ah, 0x0e                ; Get Ready To Print To Screen

file_name_loop:
    mov al, [ES:BX]
    cmp al, 0                   ; Is The File Name Null? At End Of File Table?
    je get_program_name         ; If So, Stop Reading The File Table

    int 0x10                    ; Otherwise Print Character In AL To Screen
    cmp cx, 9                   ; If At End Of Name, Go On
    je get_file_extension
    inc cx                      ; Increment File Entry Byte Counter
    inc bx                      ; Get Next Byte At File Table
    jmp file_name_loop

get_file_extension:
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

get_dir_entry_number:
    ;; 9 Blanks Before Entry #
    mov cx, 9
    call print_blanks

    inc bx
    mov al, [ES:BX]
    call print_hex_as_ascii

get_start_sector:
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

    inc bx                  ; Get First Byte Of Next File Name
    xor cx, cx              ; Reset Counter For Next File Name
    jmp file_name_loop

;; ============================================================================
;; After File Table Printed To Screen, User Can Input Program To Load
;; ============================================================================

;; TODO: Change To Accomadate New File Table Layout

get_program_name:
    mov ah, 0x0e
    mov si, getProgramName
    call print_string
    mov di, commandString   ; DI Now Pointing To 'commandString'
    ;; Reset Counter & Length of User Input
    mov byte [commandLength], 0

program_loop:
    xor ax, ax              ; AH = 0x00, AL = 0x00
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
    cmp al, 0               ; At End Of File Table?
    je program_not_found    ; If Yes, Program Was Not Found

    cmp al, [di]            ; Does User Input Match File Table Character
    je start_compare

    add bx, 16              ; If Not, Go To Next File Entry In The File Table
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

;; =============================================================================
;; Read Disk Sector Of Program To Memory And Execute It By Far Jumping
;; =============================================================================

found_program:
    add bx, 4               ; Go To Starting Sector # In File Table Entry
    mov cl, [ES:BX]         ; Sector Number To Start Reading At
    inc bx
    mov bl, [ES:BX]         ; File Size In Sectors / # Of Sectors To Read

    xor ax, ax
    mov dl, 0x00            ; Disk #
    int 0x13                ; INT 13h / AH = 0 Reset Disk System

    mov ax, 0x8000          ; Memory Location To Load Program To
    mov es, ax
    mov al, bl              ; # Of Sectors To Read
    xor bx, bx              ; ES:BX -> 0x8000:0x0000

    mov ah, 0x02            ; INT 13 / AH 02 = Read Disk Sectors To Memory
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
include 'utilities/print_blanks.asm'
include 'screen/resetTextScreen.asm'
include 'screen/resetGraphicsScreen.asm'

;; =====================================================
;; Variables
;; =====================================================
versionText:            db 0xA, 0xD, 0xA, 0xD, '  Microbit [Version 0.1.1 Test Build 1]', 0xA, 0xD, 0
welcomeText:            db '  Kernel Booted, Welcome To Microbit OS!', 0xA, 0xD, 0xA, 0xD, 0xA, 0xD, 0
menuText:               db '  Commands:', 0xA, 0xD, '  F) File & Program Browser / Loader', \
                        0xA, 0xD, '  N) End Program', 0xA, 0xD, '  R) Reboot', 0xA, 0xD, \
                        '  P) Print Register Values', 0xA, 0xD, '  G) Graphics Mode Test', \
                        0xA, 0xD, 0xA, 0xD, '  > ', 0
commandFailure:         db 0xA, 0xD, '  Oops! Something went wrong :(', 0xA, 0xD, 0xA, 0xD, '  > ', 0
endProgramText:         db 0xA, 0xD, '  Ending Program...', 0
fileTableHeading:       db 0xA, 0xD, 0xA, 0xD, '  File Name   Extension   Entry #   Start Sector   Size (sectors)', \
                        0xA, 0xD, 0xA, 0xD, '  ', 0
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
times 1536-($-$$) db 0       ; Pad File With 0s Until The End Of Sector
