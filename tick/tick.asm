; -------------------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr

	.include "tn84def.inc"       ; pretty sure this is the right thing

	.cseg                         ; Not sure what this does
	.org 	0x00

    .def state       = r16
    .def clrHighMask = r18

    .def counter1    = r20
    .def counter2    = r21

	ldi	state,(1<<DDB2)            ; set B2 to output
    out DDRB,state
    nop                            ; noop for synchronization

    ldi clrHighMask,(1<<PINB2)     ; used to turn clock on

    ldi state,0

tick: eor state,clrHighMask            ; clock high
    out PORTB,state                ; write
    nop

    rjmp delay

delay: ldi counter1,255             ; set counters for delay.
    ldi counter2,255                ; Delaying 255*255 clock cycles
iloop: subi counter1,1
    brne iloop                      ; only continue once counter1 is zero
    ldi counter1,255                ; reset counter 1
    subi counter2,1                 ; decrement counter2
    brne iloop                      ; only continue once counter2 is zero
    rjmp tick                       ; jump back to tick
                                    ; once we've counted down from 255 255 times

