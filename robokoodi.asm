;;;;;;; Demo3 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use 10 MHz crystal frequency.
; Use Timer0 for ten millisecond looptime.
; Blink "Alive" LED for 10 ms every second.
; Button (SW3 on RD<3>) controls other LEDs
;
;;;;;;; Program hierarchy ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mainline
;   Initial
;   BlinkAlive
;   Button
;   LoopTime
;
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F452, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include P18F452.inc
        __CONFIG  _CONFIG1H, _HS_OSC_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOR_ON_2L & _BORV_42_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_ON_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L  ;RB5 enabled for I/O

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000           ;Beginning of Access RAM
        TMR0LCOPY               ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY              ;Copy of INTCON for LoopTime subroutine
        ALIVECNT                ;Counter for blinking "Alive" LED
    OLDBUTTON       ;Value of button at previous loop
        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm

;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000             ;Reset vector
        nop
        goto  Mainline

        org  0x0008             ;High priority interrupt vector
        goto  $                 ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto  $                 ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial          ;Initialize everything
Loop
        rcall  BlinkAlive       ;Blink "Alive" LED
        rcall  Button       ;Detect button pressed or not, and respond
        rcall  LoopTime         ;Make looptime be ten milliseconds
        bra  Loop

;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
        MOVLF  B'10000111',ADCON1  ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'01100000',ADCON0  ;A/D converter OFF (bit 0)
        MOVLF  B'11100001',TRISA   ;Set I/O for PORTA
        MOVLF  B'11011100',TRISB   ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC   ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD   ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE   ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON   ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA   ;Turn off all four LEDs driven from PORTA
    CLRF   OLDBUTTON       ;OLDBUTTON <= 0
    CLRF   ALIVECNT        ;ALIVECNT <= 0


        BANKSEL SPBRG
        movlw D'25'
        movwf SPBRG
        BANKSEL TXSTA
        bsf TXSTA, BRGH

        BANKSEL TXSTA
        movlw B'00100100'
        movwf TXSTA
        BANKSEL RCSTA
        movlw B'10010000'
        movwf RCSTA

        return

;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine waits for Timer0 to complete its ten millisecond count
; sequence. As shown in lecture 4.

Bignum  equ     65536-25000+12+2

LoopTime
        btfss   INTCON,TMR0IF       ;Wait until ten milliseconds are up
        bra     LoopTime
        movff   INTCON,INTCONCOPY   ;Disable all interrupts to CPU
        bcf     INTCON,GIEH     
        movff   TMR0L,TMR0LCOPY     ;Read 16-bit counter at this moment
        movff   TMR0H,TMR0HCOPY
        movlw   low  Bignum
        addwf   TMR0LCOPY,F
        movlw   high  Bignum
        addwfc  TMR0HCOPY,F
        movff   TMR0HCOPY,TMR0H
        movff   TMR0LCOPY,TMR0L     ;Write 16-bit counter at this moment
        movf    INTCONCOPY,W        ;Restore GIEH interrupt enable bit
        andlw   B'10000000'
        iorwf   INTCON,F
        bcf     INTCON,TMR0IF       ;Clear Timer0 flag
        return

;;;;;;; BlinkAlive subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine briefly blinks the LED next to the PIC every second.

BlinkAlive
        bsf     PORTA,RA4         ;Turn off LED ('1' => OFF for LED D2)
        decf    ALIVECNT,F        ;Decrement loop counter and return if not zero
        bnz     BAend
        MOVLF   100,ALIVECNT      ;Reinitialize BLNKCNT
        bcf     PORTA,RA4         ;Turn on LED for ten milliseconds 
BAend
        return

;;;;;;; Button subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine detects if button has been pressed, and toggles leds 
; accordingly.
;

Button
    movf    PORTD, w
    andlw   b'00001000'       ;Leaves only the button bit, others <= 0
    cpfseq  OLDBUTTON
    bra Do_Button     ;If changed, go to Do_Button
    return
Do_Button
    movwf   OLDBUTTON
    btfsc   OLDBUTTON, 3      ;Find only falling edges, return on rising

   rcall message
   rcall send

    return



                  ;This is the code executed when button has
                  ;been pressed (once)
    btg PORTA, RA1    ;LED D6 is controlled by PORTA,RA1
                  ;LED D5 is controlled by PORTA,RA2
                  ;LED D4 is controlled by PORTA,RA3
                  ;In all of these '1' => ON

                  ;The button code ends on this return
    return
    


message movlw  '#'
        call send
        movlw  '8'
        call send
        movlw  'P'
        call send
        movlw  '7'
        call send
        movlw  '5'
        call send        
        movlw  '0'
        call send
        movlw  '0'
        call send
        movlw  0x0D ;CR
        call send
        return


send 
      movwf TXREG
      BANKSEL PIR1
WaitTX
       btfss PIR1, TXIF
       goto WaitTX  
       return  


        end           ;End the program






















