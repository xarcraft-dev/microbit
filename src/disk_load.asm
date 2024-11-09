;;;
;;; disk_load.asm: Read DH Sectors Into ES:BX Memory Location From Drive DL
;;;

disk_load:
    push dx                     ; Store DX On Stack So We Can Check Number Of Sectors Actually Read Later

    mov ah, 0x02                ; int 13 / ah = 02h, BIOS Read Disk Sectors Into Memory
    mov al, dh                  ; Number Of Sectors We Want To Read Ex. 1
    mov ch, 0x00                ; Cylinder 0
    mov dh, 0x00                ; Head 0
    mov cl, 0x02                ; Start Reading At CL Sector (Sector 2 In This Case, Right After Our Bootsector)

    int 0x13                    ; BIOS Interrupts For Disk Functions

    jc disk_error               ; Jump If Disk Read Error (Carry Flag Set/ = 1)

    pop dx                      ; Restore DX From The Stack
    cmp dh, al                  ; If AL (# Sectors Actually Read) != DH (# Sectors We Wanted To Read)
    jne disk_error              ; Error, Sectors Read Not Equal To Number We Wanted To Read
    ret                         ; Return To Caller

disk_error:
    mov bx, DISK_ERROR_MSG
    call print_string
    hlt
    

;; Variables
DISK_ERROR_MSG: db 'Disk read error!', 0