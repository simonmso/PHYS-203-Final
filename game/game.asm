; --------- Pinout: ----------------
; PINB0: shift reg. clock
; PINB1: shift reg. data
; PINB2: shift reg. clr
; PA0/PCINT0: 9th button
; PA1: Buttons A0
; PA2: Buttons A1
; PA3: Buttons A2
; PCINT7: interupt for the first 8 buttons

	.include "tn84def.inc"

	.cseg
	.org 	0x00

    rjmp setup; External pin, power-on reset, brown-out reset, watchdog reset
    reti; INT0 ; External interrupt request 0
    rjmp btnpush; PCINT0 ; Pin change interrupt request 0
    rjmp btnpush; PCINT1 ; Pin change interrupt request 1
    reti; WDT ; Watchdog time-out
    reti; TIMER1 ; CAPT Timer/Counter1 capture event
    reti; TIMER1 ; COMPA Timer/Counter1 compare match A
    reti; TIMER1 ; COMPB Timer/Counter1 compare match B
    reti; TIMER1 ; OVF Timer/Counter0 overflow
    reti; TIMER0 ; COMPA Timer/Counter0 compare match A
    reti; TIMER0 ; COMPB Timer/Counter0 compare match B
    reti; TIMER0 ; OVF Timer/Counter0 overflow
    reti; ANA_COMP ; Analog comparator
    reti; ADC ; ADC conversion complete
    reti; EE_RDY ; EEPROM ready
    reti; USI_START ; USI START
    reti; USI_OVF ; USI overflow

    ; low registers
    .def clkHigh = r0
    .def dataHigh = r1
    .def clrHigh = r2

    .def copy = r3
    .def copy1 = r4

    .def zero = r6; seems redundant, but is needed at some point

    ; game state -----------
    .def turn = r5

    .def x0 = r7; x's 8-0
    .def x1 = r8; x's 15-9
    .def o0 = r9; o's 8-0
    .def o1 = r10; o's 15-9
    ; ---------------------

    ; high registers
    .def working = r16

    .def i = r17; used for delays
    .def n = r18

    .def red0 = r19; used for animations
    .def red1 = r20
    .def green0 = r21
    .def green1 = r22

    .def output = r23
    .def lastPush = r24; last button that was pushed

; This could all be nicer, BUT it works right now and I have other finals to do
delayBounce: ldi i,255; delay for long enough to avoid button bounce
    ldi n,200
iloop: subi i,1
    brne iloop
    ldi i,255
    subi n,1
    brne iloop
    ret

delay75: ldi i,255
    ldi n,75
    rjmp iloop

delay125:ldi i,255
    ldi n,125
    rjmp iloop

delay500:
    rcall delay125; *ellegant*
    rcall delay125
    rcall delay125
    rcall delay125
    ret

delay1000:
    rcall delay500
    rcall delay500
    ret

tick: or output,clkHigh; tick the shift register clock
    out PORTB,output
    eor output,clkHigh
    out PORTB,output
    ret

enInterupts:; enable interupts PCINT0 and PCINT7
    ; These are used to signal that a button has been pushed
    ldi working,(1<<PINA0)|(1<<PINA7); enable PCINT0 and PCINT7
    out PCMSK0,working
    ldi working,(1<<PCIE0)
    out GIMSK,working

    sei ; set the global interupt enable pin
    ret

clearLights:; clear lights but not the state
    ldi output,0                   ; start everything at zero
    out PORTB,output
    mov output,clrHigh; set clr high
    out PORTB,output
    ret

clearState:; clear state
    ldi working,0
    mov o0,working
    mov o1,working
    mov x0,working
    mov x1,working
    ret

lShift: ldi i,PINB1; shifts the working register by PINB1. Used in 'write'
    lsl working
    subi i,1
    brne lShift
    ret

write: rcall clearLights; writes the current board
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

writeRG: rcall clearLights; writes the red and green registers
    mov copy,green0; write o's
    ldi n,8; 8 times
    rcall rwrite;
    mov copy,green1;
    ldi n,1; 1 time
    rcall rwrite;
    mov copy,red0; write x's
    ldi n,8
    rcall rwrite;
    mov copy,red1;
    ldi n,1
    rcall rwrite;
    ret
    

setup:; setup for the everything; RESET interupt points here
    ldi	working,(1<<DDB1)|(1<<DDB0)|(1<<DDB2); Set port B0 B1 B2 to output
    out DDRB,working
    nop; noop for synchronization

    ldi working,(1<<PINB0)
    mov clkHigh,working; used to turn clock on
    ldi working,(1<<PINB1)
    mov dataHigh,working; used to toggle the data
    ldi working,(1<<PINB2)
    mov clrHigh,working; used to toggle the clr

    rcall clearLights
    rcall clearState

    rcall enInterupts; enable interrupts

    rcall animate; animate before the game starts
    reti; unreachable reti

btnpush:; handler for the button interrupt
    cli; disable interrupts
    in copy,PINA; read the input
    
    mov working,copy
    andi working,(1<<PINA0)|(1<<PINA7); isolate the interrupt pins
    cpi working,(0<<PINA0)|(1<<PINA7); test for case where no button is pressed
    breq btnFinally; immediately return if no button is pushed. Prevents btnpush from firing when we release a button

    ; save inputs to lastPush
    mov lastPush,copy
    andi lastPush,(1<<PINA1)|(1<<PINA2)|(1<<PINA3); mask for the inputs we want
    lsr lastPush
    inc lastPush
    eor lastPush,working

    ; special case for when button 0 is pressed
    sbrc copy,PINA0
    ldi lastPush,0

    rcall updateState

    rcall delayBounce; delay to avoid button bounce
    
    btnFinally: sei; re-enable interrupts
        rcall checkForWin
        rcall checkForTie
    
    gameLoop: rjmp gameLoop; then wait in an infinite loop for the next button to be pressed
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

    mov copy,x0
    ldi working,1
    cp x1,working
    brne checkX0
    rcall checkFor1
    checkX0: rcall checkFor0

    mov copy,o0
    ldi working,1
    cp o1,working
    brne checkO0
    rcall checkFor1
    checkO0: rcall checkFor0

    rjmp endCheck


    checkFor1:
        ldi working,0b00010001
        and working,copy
        cpi working,0b00010001
        breq winner
        ldi working,0b11000000
        and working,copy
        cpi working,0b11000000
        breq winner
        ldi working,0b00100100
        and working,copy
        cpi working,0b00100100
        breq winner
        ret

    checkFor0:
        ldi working,0b10010010
        and working,copy
        cpi working,0b10010010
        breq winner
        ldi working,0b01001001
        and working,copy
        cpi working,0b01001001
        breq winner
        ldi working,0b01010100
        and working,copy
        cpi working,0b01010100
        breq winner
        ldi working,0b00111000
        and working,copy
        cpi working,0b00111000
        breq winner
        ldi working,0b00000111
        and working,copy
        cpi working,0b00000111
        breq winner
        ret

    winner:
        sbrc turn,0
        rcall oWon
        rcall xWon

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
        clc; clear the carry flag
        ror copy
        adc working,zero
        cp copy,zero
        brne count
        ret

tie:; infinite tie loop
    ldi working,255
    mov x0,working
    mov o0,working
    ldi working,1
    mov x1,working
    mov o1,working
    rcall write
    tLoop: rjmp tLoop

xWon:; infinite win loop
    ldi working,0
    mov o0,working
    mov o1,working
    xLoop:
        ldi working,255
        mov x0,working
        ldi working,1
        mov x1,working
        rcall write
        rcall delay500
        ldi working,0
        mov x0,working
        mov x1,working
        rcall write
        rcall delay500
        rjmp xLoop

oWon:; infinite win loop
    ldi working,0
    mov x0,working
    mov x1,working
    oLoop:
        ldi working,255
        mov o0,working
        ldi working,1
        mov o1,working
        rcall write
        rcall delay500
        ldi working,0
        mov o0,working
        mov o1,working
        rcall write
        rcall delay500
        rjmp oLoop

animate: 
    rcall ocircle
    rcall delay1000
    rcall xfall
    rcall delay1000

    rcall ocircle
    rcall delay1000
    rcall xfall
    rcall delay1000

 
    rjmp animate

; --------------------- All that lies below are frames of animation ---------------------------

ocircle: ldi red0,0b00000000; -----------------------------------------------------------------
ldi red1,0b00000000
ldi green0,0b01000000
rcall writeRG
rcall delay75

ldi green0,0b10000000
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b00000000
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b00100000
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b00000100
rcall writeRG
rcall delay75

ldi green0,0b00000010
rcall writeRG
rcall delay75

ldi green0,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b00001000
rcall writeRG
rcall delay75

ldi green0,0b01000000
rcall writeRG
rcall delay75

ldi green0,0b11000000
rcall writeRG
rcall delay75

ldi green0,0b01000000
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b01100000
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b01000100
rcall writeRG
rcall delay75

ldi green0,0b01000010
rcall writeRG
rcall delay75

ldi green0,0b01000001
rcall writeRG
rcall delay75

ldi green0,0b01001000
rcall writeRG
rcall delay75

ldi green0,0b11001000
rcall writeRG
rcall delay75

ldi green0,0b01001000
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b01101000
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b01001100
rcall writeRG
rcall delay75

ldi green0,0b01001010
rcall writeRG
rcall delay75

ldi green0,0b01001001
rcall writeRG
rcall delay75

ldi green0,0b11001001
rcall writeRG
rcall delay75

ldi green0,0b01001001
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b01101001
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b01001101
rcall writeRG
rcall delay75

ldi green0,0b01001011
rcall writeRG
rcall delay75

ldi green0,0b11001011
rcall writeRG
rcall delay75

ldi green0,0b01001011
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b01101011
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b01001111
rcall writeRG
rcall delay75

ldi green0,0b11001111
rcall writeRG
rcall delay75

ldi green0,0b01001111
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b01101111
ldi green1,0b00000000
rcall writeRG
rcall delay75

ldi green0,0b11101111
rcall writeRG
rcall delay75

ldi green0,0b01101111
ldi green1,0b00000001
rcall writeRG
rcall delay75

ldi green0,0b11101111
ldi green1,0b00000001
rcall writeRG
rcall delay75

ret

xfall: ldi red0,0b00000000; -----------------------------------------------------------------
ldi red1,0b00000001
ldi green0,0b00000000
ldi green1,0b00000000
rcall writeRG
rcall delay125

ldi red0,0b10000000
ldi red1,0b00000000
rcall writeRG
rcall delay125

ldi red0,0b01000000
rcall writeRG
rcall delay125

ldi red0,0b01000100
rcall writeRG
rcall delay125

ldi red0,0b01000010
rcall writeRG
rcall delay125

ldi red0,0b01000001
rcall writeRG
rcall delay125

ldi red0,0b01100001
rcall writeRG
rcall delay125

ldi red0,0b01010001
rcall writeRG
rcall delay125

ldi red0,0b01010001
ldi red1,0b00000001
ldi green0,0b00000000
rcall writeRG
rcall delay125

ldi red0,0b01010101
ldi red1,0b00000001
ldi green0,0b00000000
rcall writeRG
rcall delay125

ret