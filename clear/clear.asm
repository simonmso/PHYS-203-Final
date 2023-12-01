; -------------------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr

	.include "tn84def.inc"       ; pretty sure this is the right thing

	.cseg                         ; Not sure what this does
	.org 	0x00

    .def state       = r16
    .def counter1    = r17
    .def counter2    = r18

    .def clkHigh     = r19
    .def dataHigh    = r20
    .def clrHigh     = r21

    ldi state,(1<<DDB0)|(1<<DDB1)|(1<<DDB2) ; set B0 B1 B2 to output
    out DDRB,state
    nop

    ldi state,0                     ; clr state
    out PORTB,state
    nop

    ldi clkHigh,(1<<PINB0)
    ldi dataHigh,(1<<PINB1)
    ldi clrHigh,(1<<PINB2)

    mov state,clrHigh               ; set clr high
    or state,dataHigh               ; set data high
    out PORTB,state
    nop

tick: eor state,clkHigh              ; tick clock
    out PORTB,state
    nop

    eor state,clkHigh 
    out PORTB,state
    nop

delay: ldi counter1,255             ; set counters for delay.
    ldi counter2,255                ; Delaying 255*255 clock cycles
iloop: subi counter1,1
    brne iloop                      ; only continue once counter1 is zero
    ldi counter1,255                ; reset counter 1
    subi counter2,1                 ; decrement counter2
    brne iloop                      ; only continue once counter2 is zero

clear: eor state,clrHigh
    out PORTB,state
    nop

    eor state,clrHigh
    out PORTB,state
    nop


delay2: ldi counter1,255             ; set counters for delay.
    ldi counter2,255                ; Delaying 255*255 clock cycles
iloop2: subi counter1,1
    brne iloop2                      ; only continue once counter1 is zero
    ldi counter1,255                ; reset counter 1
    subi counter2,1                 ; decrement counter2
    brne iloop2                      ; only continue once counter2 is zero

    rjmp tick