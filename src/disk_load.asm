;;; ==========================================================================================================
;;; disk_load.asm: Read DH Sectors Into ES:BX Memory Location From Drive DL
;;; ==========================================================================================================

disk_load:
    push dx                     ; Store DX On Stack So We Can Check Number Of Sectors Actually Read Later

retry:
    mov ah, 0x02                ; INT 13 / AH = 2, Read Disk Sectors Into Memory
    mov al, dh                  ; Number Of Sectors We Want To Read Ex. 1
    mov ch, 0x00                ; Cylinder 0
    mov dh, 0x00                ; Head 0
    mov cl, 0x02                ; Start Reading At CL Sector (Sector 2 In This Case, Right After Our Bootsector)

    int 0x13                    ; BIOS Interrupts For Disk Functions

    jc retry                    ; Jump If Disk Read Error (Carry Flag Set/ = 1)

    pop dx                      ; Restore DX From The Stack