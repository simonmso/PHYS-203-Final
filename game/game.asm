; --------- Pinout: ----------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr
; PCINT0: interupt for the first 8 buttons
; PCINT1: interupt for the last button
; PA2: Buttons A0
; PA3: Buttons A1
; PA7: Buttons A2

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

    
    .def output      = r23
    .def clkHigh     = r0
    .def dataHigh    = r1
    .def clrHigh     = r2

    .def copy = r3

    .def working = r16

    .def i = r17
    .def n = r18

    .def xzero     = r19         ; x's 8-0
    .def xone      = r20         ; x's 15-9
    .def ozero     = r21         ; o's 8-0
    .def oone      = r22         ; o's 15-9

delay: ldi i,255 ; delay for long enough to avoid button bounce
    ldi n,200
iloop: subi i,1
    brne iloop
    ldi i,255
    subi n,1
    brne iloop
    ret

tick: or output,clkHigh; tick the shift register clock
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

clear: ; clear lights but not the state
    ldi output,0                   ; start everything at zero
    out PORTB,output
    mov output,clrHigh ; set clr high
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

setup:; setup code before main runs
    ldi	working,(1<<DDB1)|(1<<DDB0)|(1<<DDB2); Set port B0 B1 B2 to output
    out DDRB,working
    nop; noop for synchronization

    ldi working,(1<<PINB0); used to turn clock on
    mov clkHigh,working
    ldi working,(1<<PINB1)
    mov dataHigh,working; used to toggle the data
    ldi working,(1<<PINB2)
    mov clrHigh,working; used to toggle the clr

    rcall clear
    ret

main:; the main program
    rcall setup

    or output,dataHigh ; set data high
    out PORTB,output

    rcall tick

    eor output,dataHigh ; set data low
    out PORTB,output

    rcall enInterupts

snooze: sleep
    rjmp snooze

btnpush: cli; handler for the button interrupt
    ldi xzero,0b00010010
    ldi xone,0b00000001
    ldi ozero,0b10000101
    ldi oone,0b00000000
    rcall write
    rcall delay
    sei; re-enable interrupts
    reti