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
    rcall send
    eor output,clrHigh
    rcall send
    ret

send: out PORTB,output; send whatever output is to PORTB
    nop
    ret

tick: or output,clkHigh; ticks the shift register clock
    rcall send
    eor output,clkHigh
    rcall send
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

        rcall send; send it
        rcall tick

        lsr copy; shift copy so the next bit is in the first position

        subi n,1
        brne rwrite; then do the whole thing over again
        ret

main: ldi xzero,0b00010010
    ldi xone,0b00000001
    ldi ozero,0b10000101
    ldi oone,0b00000000
    ; msb x _ o
    ;     o x x
    ;     _ _ o lsb
    rcall write


