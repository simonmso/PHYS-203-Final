; --------- Pinout: ----------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr
; PCINT0: interupt for the first 8 buttons
; PCINT1: interupt for the last button

	.include "tn84def.inc"       ; pretty sure this is the right thing

	.cseg                         ; Not sure what this does
	.org 	0x00

    rjmp main ; External pin, power-on reset, brown-out reset, watchdog reset
    reti ; INT0 ; External interrupt request 0
    rjmp btnpush ; PCINT0 ; Pin change interrupt request 0
    rjmp btnpush ; PCINT1 ; Pin change interrupt request 1
    reti ; WDT ; Watchdog time-out
    reti ; TIMER1 ; CAPT Timer/Counter1 capture event
    reti ; TIMER1 ; COMPA Timer/Counter1 compare match A
    reti ; TIMER1 ; COMPB Timer/Counter1 compare match B
    reti ; TIMER1 ; OVF Timer/Counter0 overflow
    reti ; TIMER0 ; COMPA Timer/Counter0 compare match A
    reti ; TIMER0 ; COMPB Timer/Counter0 compare match B
    reti ; TIMER0 ; OVF Timer/Counter0 overflow
    reti ; ANA_COMP ; Analog comparator
    reti ; ADC ; ADC conversion complete
    reti ; EE_RDY ; EEPROM ready
    reti ; USI_START ; USI START
    reti ; USI_OVF ; USI overflow

    
    .def output      = r16
    .def clkHigh     = r17
    .def dataHigh    = r20
    .def clrHigh     = r19

    .def working = r20

    .def i = r21
    .def j = r22

delay: ldi i,255 ; delay for long enough to avoid button bounce
    ldi j,200
iloop: subi i,1
    brne iloop
    ldi i,255
    subi j,1
    brne iloop
    ret

btnpush: cli ; handler for the button interrupt
    rcall tick
    rcall delay
    sei ; re-enable interrupts
    reti

tick: ; tick the shift register clock
    or output,clkHigh
    out PORTB,output

    eor output,clkHigh
    out PORTB,output

    ret

enInterupts: ; enable interupts PCINT0 and PCINT1
    ; These are used to signal that a button has been pushed
    ldi working,0b00000011
    out PCMSK0,working
    ldi working,(1<<PCIE0)
    out GIMSK,working

    sei ; set the global interupt enable pin
    ret

clear: ; clear the board and the state
    ldi output,0                   ; start everything at zero
    out PORTB,output

    mov output,clrHigh ; set clr high
    out PORTB,output

    ret

main:
    ldi	working,(1<<DDB1)|(1<<DDB0)|(1<<DDB2)  ; Set port B0 B1 B2 to output
    out DDRB,working
    nop                            ; noop for synchronization

    ldi clkHigh,(1<<PINB0)         ; used to turn clock on
    ldi dataHigh,(1<<PINB1)      ; used to toggle the data
    ldi clrHigh,(1<<PINB2)         ; used to toggle the clr

    rcall clear

    or output,dataHigh ; set data high
    out PORTB,output

    rcall tick

    eor output,dataHigh ; set data low
    out PORTB,output

    rcall enInterupts

snooze: sleep
    rjmp snooze

