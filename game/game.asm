; --------- Pinout: ----------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr
; PA0/PCINT0: 9th button
; PA1: Buttons A0
; PA2: Buttons A1
; PA3: Buttons A2
; PCINT7: interupt for the first 8 buttons

	.include "tn84def.inc"       ; pretty sure this is the right thing

	.cseg                         ; Not sure what this does
	.org 	0x00

    rjmp setup ; External pin, power-on reset, brown-out reset, watchdog reset
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
    .def copy1 = r4

    .def turn = r5

    .def zero = r6; seems redundant, but is needed at some point

    .def working = r16

    .def i = r17
    .def n = r18

    .def x0     = r19         ; x's 8-0
    .def x1      = r20         ; x's 15-9
    .def o0     = r21         ; o's 8-0
    .def o1      = r22         ; o's 15-9
    .def lastPush  = r23         ; last button that was pushed

delay: ldi i,255 ; delay for long enough to avoid button bounce
    ldi n,200
iloop: subi i,1
    brne iloop
    ldi i,255
    subi n,1
    brne iloop
    ret

delayMed: rcall delay
    rcall delay
    ret

tick: or output,clkHigh; tick the shift register clock
    out PORTB,output
    eor output,clkHigh
    out PORTB,output
    ret

enInterupts: ; enable interupts PCINT0 and PCINT7
    ; These are used to signal that a button has been pushed
    ldi working,(1<<PINA0)|(1<<PINA7); enable PCINT0 and PCINT7
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

lShift: ldi i,PINB1; shifts the working register by PINB1. Used in 'write'
    lsl working
    subi i,1
    brne lShift
    ret

write: rcall clear; --- writes the current board ---
    mov copy,o0; write o's
    ldi n,8; 8 times
    rcall rwrite;
    mov copy,o1;
    ldi n,1; 1 time
    rcall rwrite;
    mov copy,x0; write x's
    ldi n,8
    rcall rwrite;
    mov copy,x1;
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

setup:; RESET interupt points here
    ldi	working,(1<<DDB1)|(1<<DDB0)|(1<<DDB2); Set port B0 B1 B2 to output
    out DDRB,working
    nop; noop for synchronization

    ldi working,(1<<PINB0); used to turn clock on
    mov clkHigh,working
    ldi working,(1<<PINB1)
    mov dataHigh,working; used to toggle the data
    ldi working,(1<<PINB2)
    mov clrHigh,working; used to toggle the clr

    ldi o0,0; clear state
    ldi o1,0
    ldi x0,0
    ldi x1,0

    rcall clear; clear lights

    ; set green ready light ------------
    or output,dataHigh ; set data high
    out PORTB,output
    rcall tick
    eor output,dataHigh ; set data low
    out PORTB,output

    rcall enInterupts
    rcall main
    reti

main:
    rcall checkForWin
    rcall checkForTie
    rjmp main
    ret; unreachable return

btnpush: cli; handler for the button interrupt; disable interrupts
    in copy,PINA; read the input
    
    mov working,copy
    andi working,(1<<PINA0)|(1<<PINA7); isolate the interrupt pins
    cpi working,(0<<PINA0)|(1<<PINA7)
    breq btnFinally; immediately return if no button is pushed. Prevents btnpush from firing when we release a button
    ; mov o0,working

    mov lastPush,copy
    andi lastPush,(1<<PINA1)|(1<<PINA2)|(1<<PINA3); mask for the inputs we want
    lsr lastPush
    inc lastPush
    eor lastPush,working

    ; special case for when button 0 is pressed
    sbrc copy,PINA0
    ldi lastPush,0

    rcall updateState

    rcall delay
    
    btnFinally: sei; re-enable interrupts
        reti

updateState:; updates the state to include whatever lastPush was
    ldi working,1
    mov copy,working
    ldi working,0
    mov copy1,working
    mov working,lastPush

    shftLoop: cpi working,0
        breq checkIfOccupied
        rol copy
        rol copy1
        subi working,1
        rjmp shftLoop

    checkIfOccupied:; do nothing if the space is already occupied
        mov working,x0
        and working,copy
        brne endUpdate
        mov working,x1
        and working,copy1
        brne endUpdate
        mov working,o0
        and working,copy
        brne endUpdate
        mov working,o1
        and working,copy1
        brne endUpdate

    ; test the turn
    branchForTurn:
        ldi working,1
        eor working,turn
        breq setX
        rjmp setO

    setX:
        eor x0,copy
        eor x1,copy1
        rcall write
        rjmp flipTurn
    setO:
        eor o0,copy
        eor o1,copy1
        rcall write
        rjmp flipTurn

    flipTurn:
        ldi working,1
        eor turn,working
    endUpdate: ret
        
checkForWin:; brute forcing this
    cli; disable interrupts

    cpi x1,1
    breq checkForX1
    rjmp checkForX0

    ; TODO: make this simpler

    checkForX1:
        ldi working,0b00010001
        and working,x0
        cpi working,0b00010001
        breq xWon
        ldi working,0b11000000
        and working,x0
        cpi working,0b11000000
        breq xWon
        ldi working,0b00100100
        and working,x0
        cpi working,0b00100100
        breq xWon

        rjmp checkO

    checkForX0:
        ldi working,0b10010010
        and working,x0
        cpi working,0b10010010
        breq xWon
        ldi working,0b01001001
        and working,x0
        cpi working,0b01001001
        breq xWon
        ldi working,0b01010100
        and working,x0
        cpi working,0b01010100
        breq xWon
        ldi working,0b00111000
        and working,x0
        cpi working,0b00111000
        breq xWon
        ldi working,0b00000111
        and working,x0
        cpi working,0b00000111
        breq xWon

    rjmp checkO

    xWon:; infinite win loop
    ldi o0,0
    ldi o1,0
    xLoop: ldi x0,255
        ldi x1,1
        rcall write
        rcall delayMed
        ldi x0,0
        ldi x1,0
        rcall write
        rcall delayMed
        rjmp xLoop

    checkO:
    cpi o1,1
    breq checkForO1
    rjmp checkForO0

    checkForO1:
        ldi working,0b00010001
        and working,o0
        cpi working,0b00010001
        breq oWon
        ldi working,0b11000000
        and working,o0
        cpi working,0b11000000
        breq oWon
        ldi working,0b00100100
        and working,o0
        cpi working,0b00100100
        breq oWon

        rjmp endCheck

    checkForO0:
        ldi working,0b10010010
        and working,o0
        cpi working,0b10010010
        breq oWon
        ldi working,0b01001001
        and working,o0
        cpi working,0b01001001
        breq oWon
        ldi working,0b01010100
        and working,o0
        cpi working,0b01010100
        breq oWon
        ldi working,0b00111000
        and working,o0
        cpi working,0b00111000
        breq oWon
        ldi working,0b00000111
        and working,o0
        cpi working,0b00000111
        breq oWon
    
    rjmp endCheck

    oWon:; infinite win loop
        ldi x0,0
        ldi x1,0
        oLoop: ldi o0,255
            ldi o1,1
            rcall write
            rcall delayMed
            ldi o0,0
            ldi o1,0
            rcall write
            rcall delayMed
            rjmp oLoop

    endCheck:
        sei; re-enable interrupts
        ret

checkForTie:
    cli; disable interrupts

    ldi working,0
    mov zero,working

    ; count how many moves have happened
    mov copy,x0
    rcall count
    mov copy,x1
    rcall count
    mov copy,o0
    rcall count
    mov copy,o1
    rcall count

    cpi working,9; if nine moves have happened
    breq tie

    sei; re-enable interrupts
    ret
    count:; count the 1's in copy
        clc; cleary the carry flag
        ror copy
        adc working,zero
        cp copy,zero
        brne count
        ret

tie:; infinite tie loop
    ldi o0,0
    ldi o1,0
    ldi x0,0
    ldi x1,0
    rcall write
    rcall delayMed
    ldi x0,255
    ldi x1,1
    ldi o0,255
    ldi o1,1
    rcall write
    rcall delayMed
    rjmp tie