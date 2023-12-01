; -------------------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr

	.include "tn84def.inc"       ; pretty sure this is the right thing

	.cseg                         ; Not sure what this does
	.org 	0x00

    .def state       = r16
    .def clkHigh     = r17
    .def dataHigh    = r20
    .def clrHigh     = r19

    .def counter1    = r21
    .def counter2    = r22

	ldi	state,(1<<DDB1)|(1<<DDB0)|(1<<DDB2)  ; Set port B0 and B1 to output
    out DDRB,state
    nop                            ; noop for synchronization

    ldi clkHigh,(1<<PINB0)         ; used to turn clock on
    ldi dataHigh,(1<<dataPin)      ; used to toggle the data
    ldi clrHigh,(1<<PINB2)         ; used to toggle the clr

    ldi state,0                    ; start everything at zero
    out PORTB,state
    nop

    mov state,clrHigh              ; then keep clr = 1
    out PORTB,state
    nop

tick: eor state,dataHigh           ; toggle the data bit
    out PORTB,state                ; write
    nop

    eor state,clkHigh              ; set clock to one
    out PORTB,state
    nop

    eor state,clkHigh              ; set clock to 0
    out PORTB,state
    nop

    rcall delay

    rjmp tick

delay: ldi counter1,255             ; set counters for delay.
    ldi counter2,255                ; Delaying 255*255 clock cycles
iloop: subi counter1,1
    brne iloop                      ; only continue once counter1 is zero
    ldi counter1,255                ; reset counter 1
    subi counter2,1                 ; decrement counter2
    brne iloop                      ; only continue once counter2 is zero
    ret                      ; jump back to tick
                                    ; once we've counted down from 255 255 times

