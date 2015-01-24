 

	list  P=PIC18F452, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON

    #include "P18F452.INC"  ; Include header file

		__CONFIG  _CONFIG1H, _HS_OSC_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOR_ON_2L & _BORV_42_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_ON_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L  ;RB5 enabled for I/O

        CBLOCK 0x20             ; Declare variable addresses starting at 0x20
          dataL
        ENDC

        org   0x0000            ; Program starts at 0x000
       
        goto mainline
; ------------------------------------
; SET BAUD RATE TO COMMUNICATE WITH PC
; ------------------------------------
; Boot Baud Rate = 9600, No Parity, 1 Stop Bit
;

mainline

		rcall Initial
        rcall message          
loop 
       	rcall send               ; send the char
       	goto loop


       ;;;;;;HARKKA;;;
Initial


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


; -------------------------------------------------------------
; SEND CHARACTER IN W VIA RS232 AND WAIT UNTIL FINISHED SENDING
; -------------------------------------------------------------
;


;
; -------
; MESSAGE
; -------
;
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



        END 