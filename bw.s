; Brain Waves
;
; 256 bytes intro for ZX Spectrum by Tomasz Slanina ( dox/joker )
; 1st place in 256b compo @ Speccy.pl Party 2019.1
; 

; Sin table generated (expanded from 1/4 data @ .table) @ $b000
; Data table generated (8 different MODEs) @ $4000
; Pixel masks @ $e000
; 
; Idea is damn simple:
; 1 generate sin table
; 2 generate data table (offsets in the sin table) based on formula 
; 3 loop for n frames
;   4 loop for each data i the table:
;    *5 draw (xor) pixel @ old position (erase old gfx)
;     6 increase data (offset in sin table)
;     7 draw (xor) pixel @ new position (draw new gfx)
; 8 change formula (directly write new opcodes), jump to 2
;  
;* 1st frame in a loop has no "delete" draw (code mod)
;
;There is more than 192 lines of pixels rendered, so the pixels modifies the attribute ram, gives extra
;effect. Also, data table is generated in linear form, so the extra ULA screen draw line logic is a plus -
;another extra effect ;)



MODE equ $e200
    
    org $e000

    ; pixel masks

    db %11000000
    db %01100000
    db %00110000
    db %00011000
    db %00001100
    db %00000110
    db %00000011

.table:
    db %00000001 ; first entry of sin table and last of pixel mask
    db 4,8,12,15,17,19,21,22,23,24,25,25,26,26,27,27,28,28,28,29,29,29,30,30,30,30,31,31,31,31,31  ; It's a SIN!  (almost, hand typed')

start:
    ld de,$b000 ; sin table
    ld b,e
.bld:
    ld a,b
    and %11111  ; 0-31
    bit 5,b
    jr z,.isup
    cpl
    and %11111
.isup:

    ld hl,.table

    add a,l
    ld l,a
    ld a,[hl]  ; pixel x from table
    
    bit 6,b
    jr z,.isplus
    cpl 
.isplus:
    ld [de],a
    inc de
    inc b
    jr nz,.bld

    ld a,7
    ld [MODE],a

    ; calc position table
    
.restart:

    ld hl,MODE
    inc [hl]
    ld a,[hl]
    and 7
    add a,a
    add a,a
    ld hl,.types
    add a,l
    ld l,a
    ld de,.ko
    ld bc,3
    ldir
    ld a,[hl]
    ld [23693],a
    call  $daf   ; clear & fill

    ;de=0000
    ;hl=4000

    ld d, $c0
    ld h,$b0
    ld l,e
    ld b,e
.ko:
    ld a,e   ; waves   ;7b e6  3f
    and $3f

    ld [de],a
    inc de
    inc l
    djnz .ko


    ld hl,.modme    
    ld [hl],$18
    inc l
    ld [hl],$03

    ld c,h 
.main:
    ld de,$4000
    ld l,e
    ld b,192+24
    
.inner:
    ld h,192
    ld l,b
    ld a,[hl] ;index

    push hl
    push de
    call .innerdraw ; erase old (old in 1st pass ever - draw it)
    pop de
    pop hl

.modme:
    jr .skip ; overwritten after first pass 

    call .innerdraw

.skip:
    ld a,e
    and %11100000
    ld e,a
    ld hl,32    ; next screen line
    add hl,de
    push hl
    pop de

    djnz .inner

    ld hl,.modme  
    ld [hl],$34
    inc l
    ld [hl],$7e

    dec c
    jr nz,.main
    jp .restart

.innerdraw
    ld l,a
    ld h,$b0  ; angles table @ $b000
    and h
    ld a,[hl]

    push af
    and h
    out [254],a
    pop af

    add a,a

    add a,$c0; 128+64 add center
    push af
    push de
    call .inpixel ; draw right
    pop de
    pop af
    cpl

.inpixel:  ; draw left
    
    ld h,a
    rra
    rra
    rra  ;0-31

    and 31

    or e
    ld e,a

    ; de contains addres

    ld a,d
    cp $58 ; attributes area ?
    ld a,h
    ld hl,$e007
    jr nc, .n2
.nino:
    and l
    ld l,a
.n2:
    ld a,[de]   ; load  from mem
    xor [hl]    ; xor with new pixel data
    ld [de],a   ; store
    ret

; 2 - red- magenta
; 3 magenta -red
; 4 green -cyan
; 5 cyan green
; 6 yellow - white
; 7 white - yellow

;2d dec l
;2f  rra
;1f cpl
;aa xor a
;ad xor l
;85 add a,l    
;87 add a,a
;b5 or l
;a5 and l

.types:

    ; 3bytes for opcodes + color

    db $7b,$e6,$3f,2 ;  ld a,e + and $3f
    db $7e,$2c,$00,4 ;  la a,[hl] + inc l + inc l
    db $7e,$ab,$00,6 ;  ld a,[hl] + xor e + inc l
    db $7e,$85,$23,5 ;  la a,[hl] + add a,l + inc hl
    db $7e,$00,$00,3 ;  ld a,[hl] + nop + inc l
    db $7b,$87,$87,7 ;  ld a,e + and a,a + add a,a
    db $7b,$2f,$1f,4 ;  ld a,e + rra + cpl
    db $7e,$85,$00,6 ;  la a,[hl] + add a,l + inc l

end start



