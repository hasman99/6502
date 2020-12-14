PORTB = $6000
PORTA = $6001   
DDRB = $6002
DDRA = $6003
IFR  = $600d
IER = $600e
PCR = $600c


value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
counter = $020a ; 2 bytes


E = %10000000
RW = %01000000
RS = %00100000


    .org $8000

reset:
    ldx #$ff ;Initialise stack pointer
    txs
    cli

    lda #$82 ; Enable CA1 for interupts
    sta IER
    lda #$00 ; Ensure CA1 active on falling edge
    sta PCR 

    lda #%11111111 ; Set all pins on port B to output
    sta DDRB

    lda #%11100000 ; Set top 3 pins on port A to output
    sta DDRA

    lda #%00111000 ; Set 8-bit mode, 2-line display, 5 x 8 font
    jsr lcd_instruction
    lda #%00001110 ; Display on; cursor on; blink off
    jsr lcd_instruction
    lda #%00000110 ; Increment cursor, don't shift display
    jsr lcd_instruction
    lda #%00000001 ; Clear Display
    jsr lcd_instruction

    lda #0
    sta counter
    sta counter + 1

loop:
    lda #%00000010 ; Put cursor home
    jsr lcd_instruction

    lda #0
    sta message

    ;Initialise value to be number to convert
    sei
    lda counter
    sta value
    lda counter + 1
    sta value + 1
    cli

divide:
    ;Initialise the remainder to zero
    lda #0
    sta mod10
    sta mod10 + 1
    clc

    ldx #16 
divloop:
    ;rotate quotient and remainder
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

    sec ;set carry bit
    lda mod10
    sbc #10
    tay ;save low byte in y reg
    lda mod10 + 1
    sbc #0
    bcc ignore_result
    sty mod10
    sta mod10 + 1

ignore_result:
    dex 
    bne divloop
    rol value  ;Shift the last bit of the quotient
    rol value + 1

    lda mod10
    clc
    adc #"0"
    jsr push_char

    lda value
    ora value + 1
    bne divide

    ldx #0

print_number:
    lda message, x
    beq loop
    jsr print_char
    inx
    jmp print_number
    jmp loop


number: .word 1729

; Add character in A reg to beginning of null-termitated string 'message'
push_char:
    pha ; Push new character on stack
    ldy #0

char_loop:
    lda message, y
    tax
    pla
    sta message, y
    iny
    txa
    pha
    bne char_loop

    pla
    sta message, y
    rts


lcd_wait:
    pha
    lda #%00000000 ; Set port B to input
    sta DDRB
lcdbusy:
    lda #RW
    sta PORTA
    lda #(RW | E)
    sta PORTA
    lda PORTB
    and #%10000000
    bne lcdbusy

    lda #RW
    sta PORTA
    lda #%11111111 ; Set port B output
    sta DDRB
    pla
    rts


lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0 ; Clear RS/RW/E bits on LCD
    sta PORTA
    lda #E ; Set E to send intruction to LCD
    sta PORTA
    lda #0 ; Clear RS/RW/E bits on LCD 
    sta PORTA
    rts

print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS ; Set RS to data register, clear RW/E
    sta PORTA
    lda #(RS | E) ; Set E to send instruction
    sta PORTA
    lda #RS ; Clear E again
    sta PORTA
    rts 

nmi:
irq:
    inc counter
    bne exit_irq
    inc counter + 1
exit_irq:
    bit PORTA ; This is ok as processor automatically saves flags when going to irq
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
   
