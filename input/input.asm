
; -------------------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr

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

; WORKING ON: reset pin
    
    .def output      = r16
    .def clkHigh     = r17
    .def dataHigh    = r20
    .def clrHigh     = r19

    .def working = r20

    .def i = r21
    .def j = r22

delay: ldi i,255
    ldi j,200
iloop: subi i,1
    brne iloop
    ldi i,255
    subi j,1
    brne iloop
    ret

btnpush: cli ; prevent interrupts
    rcall tick
    rcall delay
    sei ; re-enable interrupts

    reti

tick: 
    or output,clkHigh
    out PORTB,output
    nop

    eor output,clkHigh
    out PORTB,output
    nop

    ret

main:
    ldi	working,(1<<DDB1)|(1<<DDB0)|(1<<DDB2)  ; Set port B0 B1 B2 to output
    out DDRB,working
    nop                            ; noop for synchronization

    ldi clkHigh,(1<<PINB0)         ; used to turn clock on
    ldi dataHigh,(1<<PINB1)      ; used to toggle the data
    ldi clrHigh,(1<<PINB2)         ; used to toggle the clr

    ldi output,0                   ; start everything at zero
    out PORTB,output
    nop

    mov output,clrHigh ; set clr high
    out PORTB,output
    nop

    or output,dataHigh ; set data high
    out PORTB,output
    nop

    rcall tick

    eor output,dataHigh ; set data low
    out PORTB,output
    nop

    ldi working,(1<<PCINT0)
    out PCMSK0,working ; enable interrupt 0
    nop

    ldi working,(1<<PCIE0)
    out GIMSK,working
    nop

    sei ; enable interupts

snooze: sleep
    rjmp snooze

