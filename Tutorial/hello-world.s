PORTB = $6000
PORTA = $6001   
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000


    .org $8000

reset:
    ldx #$ff ;Initialise stack pointer
    txs

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

    ldx #0
    
print_message:
    lda message, x
    beq loop
    jsr print_char
    inx
    jmp print_message

    
loop:
    jmp loop

message: .asciiz "Hello World!"

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


    .org $fffc
    .word reset
    .word $0000
