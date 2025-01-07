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

;; =============================================================================
;; Get User Input, Print To Screen & Choose Menu Option Or Run Command
;; =============================================================================

get_input:
    mov si, prompt          ; Print The Prompt Text
    call print_string
    xor cx, cx              ; Reset Byte Counter Of Input
    mov si, commandString   ; SI Now Pointing To commandString

    mov ax, 0x2000          ; Reset ES & DS Segments To Kernel Area
    mov es, ax
    mov ds, ax

keyloop:
    xor ax, ax              ; AH = 0x0, AL = 0x0
    int 0x16                ; BIOS Int Get Keystroke AH = 0, Character Goes Into AL

    mov ah, 0x0e
    cmp al, 0xD             ; Did User Press 'Enter' Key?
    je run_command

    int 0x10                ; Else Print Input Character To Screen
    mov [si], al            ; Store Input Character To String
    inc cx                  ; Increment Byte Counter of Input
    inc si                  ; Go To Next Byte At DI / commandString
    jmp keyloop             ; Loop For Next Character From User

run_command:
    cmp cx, 0
    je get_input            ; Handle Empty Input

    mov byte [si], 0        ; Else Null Terminate commandString From DI
    mov si, commandString   ; Reset SI To Point To Start Of User Input

check_commands:
    push cx
    mov di, cmdDir
    repe cmpsb
    je file_browser

    pop cx
    push cx
    mov di, cmdReboot
    mov si, commandString
    repe cmpsb
    je reboot

    pop cx
    push cx
    mov di, cmdReg
    mov si, commandString
    repe cmpsb
    je print_registers_command

    pop cx
    push cx
    mov di, cmdGfx
    mov si, commandString
    repe cmpsb
    je graphics_test

    pop cx
    push cx
    mov di, cmdHlt
    mov si, commandString
    repe cmpsb
    je end_program

    pop cx
    push cx
    mov di, cmdCls
    mov si, commandString
    repe cmpsb
    je clear_screen

    pop cx                  ; Reset Command Length

check_files:
    mov ax, 1000h           ; Reset ES:BX To Start Of File Table (0x1000:0x0000)
    mov es, ax
    xor bx, bx

    mov si, commandString   ; Reset SI To Start Of User Input String

check_next_char:
    mov al, [ES:BX]         ; Get File Table Char
    cmp al, 0               ; At End Of File Table?
    je input_not_found      ; If So, No File / Program Found For User Input

    cmp al, [si]            ; Does User Input Match File Table Character
    je start_compare

start_compare:
    push bx                 ; Save File Table Location

compare_loop:
    mov al, [ES:BX]         ; Get File Table Char
    inc bx                  ; Next Byte In Input / File Table
    cmp al, [si]            ; Does Input Match File Table Char?
    jne restart_search      ; If Not Search Again From This Point In Filetable

    dec cl                  ; If It Does Match, Decrement Length Counter
    jz found_program        ; Counter = 0, Input Found In File Table
    inc si                  ; Else Go Next Byte Of Input
    jmp compare_loop

restart_search:
    mov si, commandString   ; Else, Reset To Start Of User Input
    pop bx                  ; Get The Saved File Table Position
    inc bx                  ; Go To Next Char In File Table
    jmp check_next_char     ; Start Checking Again

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
    jmp get_input           ; Go Back To Prompt For Input

program_loaded:
    mov ax, 0x8000          ; Program Loaded, Set Segment Registers To Location
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x8000:0x0000       ; Far Jump To Program

input_not_found:
    mov si, commandFailure  ; Command Not Found!
    call print_string
    jmp get_input

;;
;; dir: File / Program Browser & Loader 
;;
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

file_size:
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


;; =====================================================
;; reboot: Reboot, Far Jump To Reset Vector
;; =====================================================
reboot:
    jmp 0xFFFF:0x0000

;; =====================================================
;; reg: Print Register Values
;; =====================================================
print_registers_command:
    ;; Print Register Values To Screen
    mov si, printRegisterHeading
    call print_string

    call print_registers
    jmp get_input           ; Return To Prompt

;; =====================================================
;; gfx: Graphics Mode Tests
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
;; cls: Clear Screen
;; =====================================================
clear_screen:
    call resetTextScreen
    jmp get_input

;; =====================================================
;; hlt: End Program
;; =====================================================
end_program:
    mov si, endProgramText
    call print_string
    cli                     ; Clear Interrupts
    hlt                     ; Halt The CPU

;; =====================================================
;; Included Files
;; =====================================================
include 'utilities/print_string.asm'
include 'utilities/print_hex.asm'
include 'utilities/print_registers.asm'
include 'utilities/print_blanks.asm'
include 'screen/resetTextScreen.asm'
include 'screen/resetGraphicsScreen.asm'
;include 'utilities/clearScreen.asm'

;; =====================================================
;; Variables
;; =====================================================
versionText:            db 0xA, 0xD, 0xA, 0xD, '  Microbit [Version 0.1.1-rc3]', 0xA, 0xD, 0
welcomeText:            db '  Kernel Booted, Welcome To Microbit OS!', 0xA, 0xD, 0
commandFailure:         db 0xA, 0xD, '  Command not found!', 0xA, 0xD, 0
prompt:                 db 0xA, 0xD, '  > ', 0
endProgramText:         db 0xA, 0xD, '  Ending Program...', 0
fileTableHeading:       db 0xA, 0xD, 0xA, 0xD, '  File Name   Extension   Entry #   Start Sector   Size (sectors)', \
                        0xA, 0xD, 0xA, 0xD, '  ', 0
printRegisterHeading:   db 0xA, 0xD, 0xA, 0xD, '  Register Memory Location', 0xA, 0xD, 0
goBackMessage:          db 0xA, 0xD, 0xA, 0xD, '  Press any key to go back...', 0
programFailure:         db 0xA, 0xD, 0xA, 0xD, '  Program / File Not Found! Try again? (Y)', 0xA, 0xD, '  > ', 0
pgmNotLoaded:           db 0xA, 0xD, 0xA, 0xD, '  Error! Program Not Loaded, Press Any Key To Try Again...', 0

cmdDir:                 db 'dir', 0
cmdReboot:              db 'reboot', 0
cmdReg:                 db 'reg', 0
cmdGfx:                 db 'gfx', 0
cmdHlt:                 db 'hlt', 0
cmdCls:                 db 'cls', 0

sectorNotFound:         db 0xA, 0xD, 0xA, 0xD, '  Error! Secor Number Not Found! Try Again? (Y)', 0xA, 0xD, '  > ', 0
getProgramName:         db 0xA, 0xD, 0xA, 0xD, '  Enter Program Name: ', 0
commandString:          db '', 0
commandLength:          db 0

;; =====================================================
;; Sector Padding Magic
;; =====================================================
times 1536-($-$$) db 0       ; Pad File With 0s Until The End Of 3 Sectors
