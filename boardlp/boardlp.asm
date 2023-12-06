; -------------------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr

    .include "tn84def.inc"       ; pretty sure this is the right thing

    .cseg                        ; Not sure what this does
    .org 	0x00

    .def output    = r16         ; output to PORTB

    .def xzero     = r17         ; x's 8-0
    .def xone      = r18         ; x's 15-9
    .def ozero     = r19         ; o's 8-0
    .def oone      = r20         ; o's 15-9

    .def copy        = r0         ; register for copying states into
    .def working     = r21
    .def i           = r22         ; used for counting
    .def n           = r23         ; used for counting
    .def j           = r24

    .def clkHigh     = r1       ; masks for setting things
    .def dataHigh    = r2
    .def clrHigh     = r3
    ldi working,(1<<PINB0)
    mov clkHigh,working
    ldi working,(1<<PINB1)
    mov dataHigh,working
    ldi working,(1<<PINB2)
    mov clrHigh,working

    ldi	output,(1<<DDB1)|(1<<DDB0)|(1<<DDB2); Set port B0 and B1 to output
    out DDRB,output
    nop; noop for synchronization

    rjmp main

clear: ldi output,0; clear the board, does NOT clear the state
    out PORTB,output
    eor output,clrHigh
    out PORTB,output
    ret

tick: or output,clkHigh; ticks the shift register clock
    out PORTB,output
    eor output,clkHigh
    out PORTB,output
    ret

lShift: ldi i,PINB1; shifts the working register by PINB1
    lsl working
    subi i,1
    brne lShift
    ret

write: rcall clear; --- writes the current board ---
    mov copy,ozero; write o's
    ldi n,8; 8 times
    rcall rwrite;
    mov copy,oone;
    ldi n,1; 1 time
    rcall rwrite;
    mov copy,xzero; write x's
    ldi n,8
    rcall rwrite;
    mov copy,xone;
    ldi n,1
    rcall rwrite;
    ret
    ; Recursively write n times
    rwrite: ldi working,1; isolate the last bit
        and working,copy
        
        rcall lShift; then shift it to the data position
        andi output,~(1<<PINB1); clear the data bit
        eor output,working;

        out PORTB,output; send it
        rcall tick

        lsr copy; shift copy so the next bit is in the first position

        subi n,1
        brne rwrite; then do the whole thing over again
        ret

delay: ldi i,255 ; delay for long enough to avoid button bounce
    ldi j,100
iloop: subi i,1
    brne iloop
    ldi i,255
    subi j,1
    brne iloop
    ret

circle: ldi xzero,0b00100000; -----------------------------------------------------------------
ldi xone,0b00000001
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00100100
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000110
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000011
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00001001
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01001000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b11000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b10000000
ldi xone,0b00000001
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

explosion: ldi xzero,0b00000000; -----------------------------------------------------------------
ldi xone,0b00000000
ldi ozero,0b00010000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b10111010
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11101111
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01000101
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ret

xo: ldi xzero,0b01010101; -----------------------------------------------------------------
ldi xone,0b00000001
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11101111
ldi oone,0b00000001
rcall write
rcall delay
ret

right: ldi xzero,0b10000000; -----------------------------------------------------------------
ldi xone,0b00000000
ldi ozero,0b10000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01010000
ldi xone,0b00000001
ldi ozero,0b01010000
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00101010
ldi xone,0b00000000
ldi ozero,0b00101010
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000101
ldi xone,0b00000000
ldi ozero,0b00000101
ldi oone,0b00000000
rcall write
rcall delay

ret

xfall: ldi xzero,0b00000000; -----------------------------------------------------------------
ldi xone,0b00000001
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b10000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01000100
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01000010
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01000001
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01100001
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01010001
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01010001
ldi xone,0b00000001
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b01010101
ldi xone,0b00000001
ldi ozero,0b00000000
ldi oone,0b00000000
rcall write
rcall delay

ret

ocircle: ldi xzero,0b00000000; -----------------------------------------------------------------
ldi xone,0b00000000
ldi ozero,0b01000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b10000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000000
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00100000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000100
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000010
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00000001
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b00001000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11000000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01000000
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01100000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01000100
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01000010
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01000001
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11001000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001000
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01101000
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001100
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001010
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001001
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11001001
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001001
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01101001
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001101
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001011
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11001011
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001011
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01101011
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001111
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11001111
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01001111
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01101111
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11101111
ldi oone,0b00000000
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b01101111
ldi oone,0b00000001
rcall write
rcall delay

ldi xzero,0b00000000
ldi xone,0b00000000
ldi ozero,0b11101111
ldi oone,0b00000001
rcall write
rcall delay

ret

delayLong: rcall delay
rcall delay
rcall delay
rcall delay
rcall delay
rcall delay
ret

main:
    ; rcall circle
    ; rcall explosion
    ; rcall xo
    ; rcall right
    rcall delayLong
    rcall xfall
    rcall delayLong
    rcall ocircle
    rcall delayLong
    ; rcall ocircle
    rjmp main
