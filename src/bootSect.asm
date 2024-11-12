;;; ==========================================================================================================
;;; bootSect.asm: Simple Boot Loader That Uses INT13 AH2 To Read From Disk Into Memory
;;; ==========================================================================================================

org 0x7c00                  ; 'Origin' of Boot Code; Helps Make Sure Addresses Don't Change

;; ======================================================================================
;; Read File Table Into Memory First
;; Set Up ES:BX Memory Address / Segment; Offset To Load Sector(s) Into
;; ======================================================================================
mov bx, 0x1000              ; Load Sector To Memory Address 0x1000
mov es, bx
mov bx, 0x0                 ; ES:BX = 0x1000:0x0

;; =====================================================
;; Set Up Disk Read
;; =====================================================
mov dh, 0x0                 ; Head 0
mov dl, 0x0                 ; Drive 0
mov ch, 0x0                 ; Cylinder 0
mov cl, 0x02                ; Starting Sector To Read From Disk

read_disk_1000:
    mov ah, 0x02            ; BIOS INT 13 / AH = 2 Read Disk Sectors
    mov al, 0x01            ; # Of Sectors To Read
    int 0x13                ; BIOS Interrupts For Disk Functions

    jc read_disk_1000       ; Retry If Disk Read Error (Carry Flag Set/ = 1)

    ;; ====================================================================================
    ;; Read Kernel Into Memory Second
    ;; Set Up ES:BX Memory Address / Segment; Offset To Load Sector(s) Into
    ;; ====================================================================================
    mov bx, 0x2000          ; Load Sector To Memory Address 0x2000
    mov es, bx
    mov bx, 0x0             ; ES:BX = 0x2000:0x0

    ;; =====================================================
    ;; Set Up Disk Read
    ;; =====================================================
    mov dh, 0x0             ; Head 0
    mov dl, 0x0             ; Drive 0
    mov ch, 0x0             ; Cylinder 0
    mov cl, 0x03            ; Starting Sector To Read From Disk

read_disk_2000:
    mov ah, 0x02             ; BIOS INT 13 / AH = 2 Read Disk Sectors
    mov al, 0x04             ; # Of Sectors To Read
    int 0x13                 ; BIOS Interrupts For Disk Functions

    jc read_disk_2000        ; Retry If Disk Read Error

    ;; =====================================================
    ;; Reset Segment Registers For RAM
    ;; =====================================================
    mov ax, 0x2000
    mov ds, ax              ; Data Segment
    mov es, ax              ; Extra Segment
    mov fs, ax              ; ""
    mov gs, ax              ; ""
    mov ss, ax              ; Stack Segment

    jmp 0x2000:0x0          ; Never Return From This!

;; =====================================================
;; Boot Sector Magic
;; =====================================================
times 510-($-$$) db 0       ; Pad File With 0s Until 510th Byte

dw 0xaa55                   ; BIOS Magic Number in 511th and 512th Byte