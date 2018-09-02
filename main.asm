;
; Elevator.asm
;
; Created: 8/26/2018 12:22:47 PM
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																SETTING INTERRUPTIONS ADDRESSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rjmp RESET
.org INT0addr 					
rjmp INT0_CALLBACK				; Call interruptions of elevator or outside #TODO
.org INT1addr
rjmp INT1_CALLBACK				; Call interruptions of elevator or outside #TODO
.org OC1Aaddr
rjmp TIMER_CALLBACK 			; Call interruption of timer (1s)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;															END SETTING INTERRUPTIONS ADDRESSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																	SETTING DEFINES AND SETS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; DEFINES
.def temp = r16					; Temporary variable
.def CLOCK 16.0e6				; Clock speed
.def TIMER 1					; Timer to interruption
.def BAUDRATE 115200			; Define qt of bits to s to baud rate

; INPUTS
.equ BUTTON_ELE_CD = 4			; bit position on PINB to elevator close door
.equ BUTTON_ELE_OD = 5			; bit position on PINB to elevator open door
.equ BUTTON_ELE_T = 0			; T bit position on PINB to elevator
.equ BUTTON_ELE_1 = 1			; 1 bit position on PINB to elevator
.equ BUTTON_ELE_2 = 2			; 2 bit position on PINB to elevator
.equ BUTTON_ELE_3 = 3			; 3 bit position on PINB to elevator

.equ BUTTON_OUTSIDE_T = 4		; T bit position on PIND to outside
.equ BUTTON_OUTSIDE_1 = 5		; 1 bit position on PIND to outside
.equ BUTTON_OUTSIDE_2 = 6		; 2 bit position on PIND to outside
.equ BUTTON_OUTSIDE_3 = 7		; 3 bit position on PIND to outsides

; OUTPUTS
.equ BUZZER_POSITION = 0		; Buzzy bit position
.equ LED_POSITION = 1			; Led bit position

; POSITION OF BITS IN REGRISTERS
.equ stateM = 0					; M bit position
.equ stateS = 1					; S bit position
.equ stateT = 2					; T bit position
.equ stateC = 3					; C bit position

.equ call_T = 0					; T bit position on outside and elevator call registers
.equ call_1 = 1					; 1 bit position on outside and elevator call registers
.equ call_2 = 2					; 2 bit position on outside and elevator call registers
.equ call_3 = 3					; 3 bit position on outside and elevator call registers

; POSITION OF OFFSETS
.equ offset_ET = 5				; Position on variable log
.equ offset_E1 = 4				; Position on variable log
.equ offset_E2 = 3				; Position on variable log
.equ offset_E3 = 2				; Position on variable log
.equ offset_OST = 13			; Position on variable log
.equ offset_OS1 = 12			; Position on variable log
.equ offset_OS2 = 11			; Position on variable log
.equ offset_OS3 = 10			; Position on variable log
.equ offset_L = 17				; Position on variable log
.equ offset_O = 21				; Position on variable log
.equ offset_S_C = 25			; Position on variable log
.equ offset_S_T = 26			; Position on variable log
.equ offset_S_S = 27			; Position on variable log
.equ offset_S_M = 28			; Position on variable log
.equ offset_DOOR_CNT = 33		; Position on variable log
.equ offset_FLOOR_CNT = 38		; Position on variable log
.equ offset_WAIT_TIME_FLAG = 42 ; Position on variable log

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																END SETTING DEFINES AND SETS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																	CREATING VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg

logs: .byte 45					; String for put log

; Defining variables related to floors and calls
change_floor_cnt: .byte 1   	; variable used to count change floor
door_cnt: .byte 1   			; variable used to count the open door
door_flag: .byte 1    			; variable used to register if the door is open(1) or closed(0)
level: .byte 1    				; variables used to tell on wich floor the elevator is
outside_calls: .byte 1    		; variable used to store the outside calls
ele_calls: .byte 1    			; variable used to store the elevator calls
display_out: .byte 1    		; variable used to store the display value
led_buzzer_out: .byte 1   		; variable used to store the led and buzzer state

; Defining variables related to FSM
state: .byte 1    				; variable used to store the actual state
old_state: .byte 1    			; variable used to store the last state
state_rise_out: .byte 1   		; variable used to map rise out state
state_des_out: .byte 1    		; variable used to map des out state
state_rise_ele: .byte 1   		; variable used to map rise ele state
state_des_ele: .byte 1    		; variable used to map des ele state
state_des_ele_out: .byte 1    	; variable used to map des ele out state
state_stop_ele: .byte 1   		; variable used to map stop ele state 
state_stop: .byte 1   			; variable used to map stop state

; Defining help variables
wait_cnt: .byte 1				; variable used to counter of wait
wait_time_flag: .byte 1			; variable used to flag of wait


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																	END CREATING VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																		CONFIGURATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.cseg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						RESET
; This label will initializing the variables and con-
; figurations necessary in order to the program work
; properly.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RESET:
	; Initializing the stack pointer
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	; Calling init functions
	rcall INIT_ELE_BUTTONS
	rcall INIT_OUTSIDE_BUTTONS
	rcall INIT_OUT_ELEMENTS
	rcall INIT_EXT_ISR
	rcall INIT_TIMERS
	rcall INIT_USART
	rcall INIT_VARIABLES
	rcall INIT_LOG_STRING

	; Enabling the interruptions
	sei

	; Go to MAIN function
	rjmp MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					INIT_ELE_BUTTONS
; This function will init the input elevator buttons on
; port B. It has the need for 6 bits.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_ELE_BUTTONS :
	ldi temp, 0
	out DDRB, temp
	out PORTB, temp
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					INIT_OUTSIDE_BUTTONS
; This function will init the outside buttons that call
; the elevator. This buttons will be initialized on
; port D as inputs and with 2 pins to interruption.
; It has the need for 6(4+2) bits.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_OUTSIDE_BUTTONS :
	ldi temp, 0
	out DDRD, temp
	out PORTD, temp
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					INIT_OUT_ELEMENTS
; This function will init elements as buzzer, led and
; display.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_OUT_ELEMENTS :
	ldi temp, 0xFF
	out DDRC, temp
	ldi temp, 0
	out PORTC, temp
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					INIT_EXT_ISR
; This function will init external interrupts in INT0
; and INT1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_EXT_ISR :
	ldi temp, (0b11 << ISC10) | (0b11 << ISC00)		; configuring INT0 and INT1 to active in positive edges
	sts EICRA, temp
	ldi temp, (1 << INT0) | (1 << INT1)				; enabling interruptions in INT0 and INT1
	out EIMSK, temp

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						INIT_TIMERS
; This function will init the timers that are used to
; turn on buzzer, close the elevator door and counting
; change of floor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_TIMERS :
	; Setting constants to configuration
	.equ PRESCALE = 0b100									;/256 prescale
	.equ PRESCALE_DIV = 256
	.equ WGM = 0b0100										; Waveform generation mode: CTC
	.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*TIMER))		; defining TOP value

	; Checking the viability of TOP
	.if TOP > 65535 
	.error "TOP is out of range"
	.endif

	; On MEGA series, write high byte of 16-bit timer registers first
	; Setting TOP
	ldi temp, high(TOP)
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp

	; Setting CTC mode and prescale /256
	ldi temp, ((WGM&0b11) << WGM10)
	sts TCCR1A, temp										; Setting WGM11 and WGM10 position on TCCR1A to 0
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, temp 										; Setting WGM12 to 1 and setting CS12, CS11 and CS10 to 0b100 on TCCR1b

	; Enabling timer interrupt
	lds temp, TIMSK1
	sbr temp, (1 << OCIE1A)
	sts TIMSK1, temp

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						INIT_USART
; This function will init the usart configurations.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_USART :
	; Setting constants to configuration
	.equ UBRR_VALUE = int(CLOCK / ((16 * BAUDRATE) - 1))

	; Initializing UBRR value to the USART
	ldi temp, high(UBRR_VALUE)
	sts UBRR0H, temp
	ldi temp, low(UBRR_VALUE)
	sts UBRR0L, temp

	; Initializing USART configuration
	; UMSEL0		00 (Async)
	; UPM00			00 (Parity disabled)
	; USBS0			0 (1 stop bit)
	; UCSZ00			011 (8-bit)
	ldi temp, (0b00 << UMSEL00) | (0b00 << UPM00) | (0b0 << USBS0) | (0b11 << UCSZ00)
	sts UCSR0C, temp

	; Enabling transmit 8 bits in USART
	ldi temp, (1 << TXEN0)
	sts UCSR0B, temp

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						INIT_LOG_STRING
; This function will init the variables to program work
; properly.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_LOG_STRING:
	; Config log call elevator 7 bytes
	ldi temp, 'E'
	sts logs, temp
	ldi temp, ' '
	sts logs+1, temp
	ldi temp, 'X'
	sts logs+2, temp
	sts logs+3, temp
	sts logs+4, temp
	sts logs+5, temp
	ldi temp, '\n'
	sts logs+6, temp

	; Config log call outside 8 bytes
	ldi temp, 'O'
	sts logs+7, temp
	ldi temp, 'S'
	sts logs+8, temp
	ldi temp, ' '
	sts logs+9, temp
	ldi temp, 'X'
	sts logs+10, temp
	sts logs+11, temp
	sts logs+12, temp
	sts logs+13, temp
	ldi temp, '\n'
	sts logs+14, temp

	; Config log call level 4 bytes
	ldi temp, 'L'
	sts logs+15, temp
	ldi temp, ' '
	sts logs+16, temp
	ldi temp, 'X'
	sts logs+17, temp
	ldi temp, '\n'
	sts logs+18, temp

	; Config log call output 4 bytes (led and buzzy) 
	ldi temp, 'O'
	sts logs+19, temp
	ldi temp, ' '
	sts logs+20, temp
	ldi temp, 'X'
	sts logs+21, temp
	ldi temp, '\n'
	sts logs+22, temp

	; Config log call state 7 bytes
	ldi temp, 'S'
	sts logs+23, temp
	ldi temp, ' '
	sts logs+24, temp
	ldi temp, 'X'
	sts logs+25, temp
	sts logs+26, temp
	sts logs+27, temp
	sts logs+28, temp
	ldi temp, '\n'
	sts logs+29, temp

	; Config log door count 5 bytes
	ldi temp, 'D'
	sts logs+30, temp
	ldi temp, 'C'
	sts logs+31, temp
	ldi temp, ' '
	sts logs+32, temp
	ldi temp, 'X'
	sts logs+33, temp
	ldi temp, '\n'
	sts logs+34, temp

	; Config log change floor count 5 bytes
	ldi temp, 'F'
	sts logs+35, temp
	ldi temp, 'C'
	sts logs+36, temp
	ldi temp, ' '
	sts logs+37, temp
	ldi temp, 'X'
	sts logs+38, temp
	ldi temp, '\n'
	sts logs+39, temp

	; Config log wait time count 5 bytes
	ldi temp, 'W'
	sts logs+40, temp
	ldi temp, ' '
	sts logs+41, temp
	ldi temp, 'X'
	sts logs+42, temp
	ldi temp, '\n'
	sts logs+43, temp
	sts logs+44, temp

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						INIT_VARIABLES
; This function will init the variables to program work
; properly.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_VARIABLES :
ldi temp, 0

	; Setting state as 0b0000
	sts state, temp

	; Setting wait_time_cnt to 0
	sts wait_cnt, temp

	; Setting change floor count to 0
	sts change_floor_cnt, temp

	; Setting change floor count to 0
	sts door_cnt, temp

	; Setting ele_calls to 0x00
	sts ele_calls, temp

	; Setting outside_calls to 0x00
	sts outside_calls, temp

	; Setting initial level to 0
	sts level, temp

	; Setting led_buzzer_out to 0
	sts led_buzzer_out, temp

	; Setting door flag to 1
	ldi temp, 1
	sts door_flag, temp

	; Setting wait_time_flag to 1
	sts wait_time_flag, temp

	; Initializing states mapping
	ldi temp, 0b00000000
	sts state_stop, temp

	ldi temp, 0b00000011
	sts state_rise_out, temp

	ldi temp, 0b00000001
	sts state_des_out, temp

	ldi temp, 0b00000111
	sts state_rise_ele, temp

	ldi temp, 0b00000101
	sts state_des_ele, temp

	ldi temp, 0b00001101
	sts state_des_ele_out, temp

	ldi temp, 0b00001000
	sts state_stop_ele, temp

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																				END CONFIGURATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																					PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					TIMER_CALLBACK
; This function will handle the timer interrupt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def cnt = r17
.def cur_state = r18

TIMER_CALLBACK :
	; Saving registers and SREG
	push temp
	push cnt
	push cur_state
	in temp, SREG
	push temp

	; Verify if wait time is active
	lds temp, wait_time_flag
	cpi temp, 1
	breq end_if_timer_callback				; jump to end if

	; Function implementation
	lds cur_state, state					; get current state
	ldi temp, (1 << stateM)					; setting 0bxxx1

	begin_if_timer_callback :
		and cur_state, temp					; checking moving bit
		brne is_moving						; if M bit is set
		rjmp is_not_moving					; if M bit is not set

	is_moving :
		lds cnt, change_floor_cnt			; load change floor count
		inc cnt								; increment count
		sts change_floor_cnt, cnt			; store the new value of change floor count
		rjmp end_if_timer_callback			; jump to end if

	is_not_moving :
		lds temp, door_flag
		cpi temp, 0
		breq end_if_timer_callback
		lds cnt, door_cnt					; load door count
		inc cnt								; increment count
		sts door_cnt, cnt					; store the new value of door count
	
	end_if_timer_callback :

	rcall SEND_LOG							; Call log

	lds temp, wait_cnt
	inc temp
	sts wait_cnt, temp

	; Restore registers and SREG
	pop temp
	out SREG, temp
	pop cur_state
	pop cnt
	pop temp

	; Return to the normal routine
	reti

.undef cnt
.undef cur_state

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					INT0_CALLBACK
; This function will handle the int0 callback that
; takes care of elevator buttons.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def update_ele = r21
.def pinb_bits = r11
.def temp_pinb = r20
.def cur_state = r22

INT0_CALLBACK :

	; Saving registers and SREG
	push temp
	push update_ele
	push pinb_bits
	push temp_pinb
	in temp, SREG
	push temp

	; Function implementation
	in pinb_bits, PINB						; getting pind pins
	mov temp_pinb, pinb_bits				; copy pind bins to backup

	if_T_pressed_ele :
		andi temp_pinb, (1 << BUTTON_ELE_T)
		brbs SREG_Z, end_if_T_pressed_ele
		lds update_ele, ele_calls
		ori update_ele, (1 << call_T)
		sts ele_calls, update_ele
	end_if_T_pressed_ele :

	mov temp_pinb, pinb_bits

	if_1_pressed_ele :
		andi temp_pinb, (1 << BUTTON_ELE_1)
		brbs SREG_Z, end_if_1_pressed_ele
		lds update_ele, ele_calls
		ori update_ele, (1 << call_1)
		sts ele_calls, update_ele
	end_if_1_pressed_ele :

	mov temp_pinb, pinb_bits

	if_2_pressed_ele :
		andi temp_pinb, (1 << BUTTON_ELE_2)
		brbs SREG_Z, end_if_2_pressed_ele
		lds update_ele, ele_calls
		ori update_ele, (1 << call_2)
		sts ele_calls, update_ele
	end_if_2_pressed_ele :

	mov temp_pinb, pinb_bits

	if_3_pressed_ele :
		andi temp_pinb, (1 << BUTTON_ELE_3)
		brbs SREG_Z, end_if_3_pressed_ele
		lds update_ele, ele_calls
		ori update_ele, (1 << call_3)
		sts ele_calls, update_ele
	end_if_3_pressed_ele :

	mov temp_pinb, pinb_bits

	if_close_pressed_ele :
		andi temp_pinb, (1 << BUTTON_ELE_CD)
		brbs SREG_Z, end_if_close_pressed_ele
		ldi temp, 0
		sts door_flag, temp
		sts door_cnt, temp
	end_if_close_pressed_ele :

	mov temp_pinb, pinb_bits

	if_open_pressed_ele :
		andi temp_pinb, (1 << BUTTON_ELE_OD)
		brbs SREG_Z, end_if_open_pressed_ele
		lds cur_state, state
		andi cur_state, (1 << stateM)
		brne end_if_open_pressed_ele
		ldi temp, 1
		sts door_flag, temp
		ldi temp, 0
		sts door_cnt, temp
	end_if_open_pressed_ele :

	; Restore registers and SREG
	pop temp
	out SREG, temp
	pop temp_pinb
	pop pinb_bits
	pop update_ele
	pop temp

	; Return to the normal routine
	reti

.undef cur_state
.undef pinb_bits
.undef temp_pinb
.undef update_ele

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					INT1_CALLBACK
; This function will handle the int1 callback that
; takes care of outside buttons.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def update_outside = r21
.def pind_bits = r11
.def temp_pind = r20

INT1_CALLBACK :

	; Saving registers and SREG
	push temp
	push update_outside
	push pind_bits
	push temp_pind
	in temp, SREG
	push temp

	; Function implementation
	in pind_bits, PIND						; getting pinb pins
	mov temp_pind, pind_bits				; copy pinb bins to backup

	if_T_pressed_outside :
		andi temp_pind, (1 << BUTTON_OUTSIDE_T) 
		brbs SREG_Z, end_if_T_pressed_outside
		lds update_outside, outside_calls
		ori update_outside, (1 << call_T)
		sts outside_calls, update_outside
	end_if_T_pressed_outside :

	mov temp_pind, pind_bits

	if_1_pressed_outside :
		andi temp_pind, (1 << BUTTON_OUTSIDE_1)
		brbs SREG_Z, end_if_1_pressed_outside
		lds update_outside, outside_calls
		ori update_outside, (1 << call_1)
		sts outside_calls, update_outside
	end_if_1_pressed_outside :

	mov temp_pind, pind_bits

	if_2_pressed_outside :
		andi temp_pind, (1 << BUTTON_OUTSIDE_2)
		brbs SREG_Z, end_if_2_pressed_outside
		lds update_outside, outside_calls
		ori update_outside, (1 << call_2)
		sts outside_calls, update_outside
	end_if_2_pressed_outside :

	mov temp_pind, pind_bits

	if_3_pressed_outside :
		andi temp_pind, (1 << BUTTON_OUTSIDE_3)
		brbs SREG_Z, end_if_3_pressed_outside
		lds update_outside, outside_calls
		ori update_outside, (1 << call_3)
		sts outside_calls, update_outside
	end_if_3_pressed_outside :

	; Restore registers and SREG
	pop temp
	out SREG, temp
	pop temp_pind
	pop pind_bits
	pop update_outside
	pop temp

	; Return to the normal routine
	reti

.undef pind_bits
.undef temp_pind
.undef update_outside


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					TRANSMIT
; This label will handle the state_stop state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.def empty = r17
.def byte_tx = r24

TRANSMIT:
	lds empty, UCSR0A
	sbrs empty, UDRE0				;wait for Tx buffer to be empty
	rjmp TRANSMIT 					;not ready yet
	sts UDR0, byte_tx				;transmit character

	ret

.undef byte_tx
.undef empty

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					SEND_LOG
; This label will handle the state_stop state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def output = r17
.def cnt = r18
.def flag = r19
.def calls = r20
.def zero = r21
.def one = r22
.def cur_state = r23
.def send_byte = r24

SEND_LOG:
	; Saving registers
	push output
	push cnt
	push flag
	push calls
	push zero
	push one
	push cur_state
	push send_byte

	; Getting 
	ldi zero, '0'
	ldi one, '1'
	ldi output, 0

	; Setting
	lds calls, ele_calls
	lds flag, door_flag
	lds cnt, door_cnt

	; Setting value default 0 on registrers
	sts logs + offset_ET, zero
	sts logs + offset_E1, zero
	sts logs + offset_E2, zero
	sts logs + offset_E3, zero

	sts logs + offset_OST, zero
	sts logs + offset_OS1, zero
	sts logs + offset_OS2, zero
	sts logs + offset_OS3, zero

	sts logs + offset_S_C, zero
	sts logs + offset_S_T, zero
	sts logs + offset_S_S, zero
	sts logs + offset_S_M, zero


	mov temp, calls
	andi temp, (1 << call_T)
	breq skip_E_T
	sts logs + offset_ET, one

	skip_E_T :
		mov temp, calls
		andi temp, (1 << call_1)
		breq skip_E_1
		sts logs + offset_E1, one

	skip_E_1 :
		mov temp, calls
		andi temp, (1 << call_2)
		breq skip_E_2
		sts logs + offset_E2, one

	skip_E_2 :
		mov temp, calls
		andi temp, (1 << call_3)
		breq skip_E_3
		sts logs + offset_E3, one

	skip_E_3 :
	; ---------------------------------------------------

	lds calls, outside_calls
	mov temp, calls
	andi temp, (1 << call_T)
	breq skip_OS_T
	sts logs + offset_OST, one

	skip_OS_T :
		mov temp, calls
		andi temp, (1 << call_1)
		breq skip_OS_1
		sts logs + offset_OS1, one

	skip_OS_1 :
		mov temp, calls
		andi temp, (1 << call_2)
		breq skip_OS_2
		sts logs + offset_OS2, one

	skip_OS_2 :
		mov temp, calls
		andi temp, (1 << call_3)
		breq skip_OS_3
		sts logs + offset_OS3, one

	skip_OS_3 :

	; ---------------------------------------------------
	lds cur_state, state

	mov temp, cur_state
	andi temp, (1 << stateM)
	breq skip_S_M
	sts logs + offset_S_M, one

	skip_S_M :
		mov temp, cur_state
		andi temp, (1 << stateS)
		breq skip_S_S
		sts logs + offset_S_S, one

	skip_S_S :
		mov temp, cur_state
		andi temp, (1 << stateT)
		breq skip_S_T
		sts logs + offset_S_T, one

	skip_S_T :
		mov temp, cur_state
		andi temp, (1 << stateC)
		breq skip_S_C
		sts logs + offset_S_C, one

	skip_S_C :

	; ---------------------------------------------------

	lds temp, level
	add temp, zero
	sts logs + offset_L, temp

	; ---------------------------------------------------

	lds temp, door_cnt
	add temp, zero
	sts logs + offset_DOOR_CNT, temp

	; ---------------------------------------------------
	lds temp, wait_time_flag
	add temp, zero
	sts logs + offset_WAIT_TIME_FLAG, temp

	; ---------------------------------------------------


	lds temp, change_floor_cnt
	add temp, zero
	sts logs+offset_FLOOR_CNT, temp


	cpi flag, 0		; lembrar de colocar a flag para 1 quando mudar para um state_stop ou state_stop_ele
	breq write_output
	ldi temp, ( 1 << (LED_POSITION) )
	or output, temp
	cpi cnt, 5
	brlo write_output
	ldi temp, ( 1 << (BUZZER_POSITION) )
	or output, temp

	write_output :
		add output, zero
		sts logs + offset_O, output

	ldi temp, 0
	ldi ZH, high(logs)
	ldi ZL, low(logs)

	while_test_log :		;#TODO: mudar
		cpi temp, 45
		brsh while_end_log

	while_loop_log :
		ld send_byte, Z+
		rcall TRANSMIT
		inc temp
		rjmp while_test_log
	while_end_log :

	pop send_byte
	pop cur_state
	pop one
	pop zero
	pop calls
	pop flag
	pop cnt
	pop output

	ret

.undef send_byte
.undef one
.undef zero
.undef flag
.undef cnt
.undef calls
.undef cur_state
.undef output

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					STATE_STOP_HANDLE
; This label will handle the state_stop state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.def cnt = r19
.def flag = r20
.def cur_ele_calls = r21
.def cur_outside_calls = r22
.def cur_level = r23
.def A = r24

STATE_STOP_HANDLE :

	lds temp, wait_time_flag
	cpi temp, 1
	brne go_not_to_wait_time_stop

	go_to_wait_time_stop :
		ldi temp, 0
		sts wait_cnt, temp
		rcall WAIT_TIME

	go_not_to_wait_time_stop :
		lds cnt, door_cnt
		lds flag, door_flag
		lds cur_level, level
		lds cur_ele_calls, ele_calls
		lds cur_outside_calls, outside_calls
		ldi A, 1

		push A
		push cur_level
		rcall SHIFT_B_TIMES_LEFT
		pop cur_level
		pop A
		com A

		and cur_ele_calls, A
		and cur_outside_calls, A
		sts ele_calls, cur_ele_calls
		sts outside_calls, cur_outside_calls

		cpi flag, 0		; lembrar de colocar a flag para 1 quando mudar para um state_stop ou state_stop_ele
		breq check_calls_elevator

		cpi cnt, 10
		brne check_calls_elevator
		ldi temp, 0
		sts door_flag, temp
		sts door_cnt, temp


	check_calls_elevator :
		lds cur_ele_calls, ele_calls
		cpi cur_ele_calls, 0
		breq check_calls_outside

		push cur_ele_calls
		push cur_level
		rcall SHIFT_B_TIMES_RIGHT
		pop cur_level
		pop cur_ele_calls		; A shifted cur_level times

		cpi cur_ele_calls, 0
		brne go_state_rise_ele

		lds temp, state_des_ele
		sts state, temp
		rjmp end_state_stop_handle

	go_state_rise_ele:
		lds temp, state_rise_ele
		sts state, temp
		ldi temp, 0
		sts door_flag, temp
		rjmp end_state_stop_handle

	check_calls_outside:
		lds cur_outside_calls, outside_calls
		cpi cur_outside_calls, 0
		breq end_state_stop_handle

		push cur_outside_calls
		push cur_level
		rcall SHIFT_B_TIMES_RIGHT
		pop cur_level
		pop cur_outside_calls

		cpi cur_outside_calls, 0
		brne go_state_rise_out

		lds temp, state_des_out
		sts state, temp
		ldi temp, 0
		sts door_flag, temp
		rjmp end_state_stop_handle

	go_state_rise_out :
		lds temp, state_rise_out
		sts state, temp
		ldi temp, 0
		sts door_flag, temp

	end_state_stop_handle:

	ret

.undef cnt
.undef flag
.undef cur_ele_calls
.undef cur_outside_calls
.undef cur_level
.undef A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				STATE_STOP_ELE_HANDLE
; This label will handle the state_stop_ele state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def cnt = r20
.def flag = r21
.def cur_level = r22
.def new_state = r23
.def A = r24
.def cur_ele_calls = r14
.def cur_outside_calls = r13

STATE_STOP_ELE_HANDLE :

	lds temp, wait_time_flag
	cpi temp, 1
	brne go_not_to_wait_time_stop_ele

	go_to_wait_time_stop_ele :
		ldi temp, 0
		sts wait_cnt, temp
		rcall WAIT_TIME

	go_not_to_wait_time_stop_ele :
		lds cnt, door_cnt
		lds flag, door_flag
		lds cur_level, level
		lds cur_ele_calls, ele_calls
		lds cur_outside_calls, outside_calls
		ldi A, 1

		push A
		push cur_level
		rcall SHIFT_B_TIMES_LEFT
		pop cur_level
		pop A
		com A

		and cur_ele_calls, A
		and cur_outside_calls, A
		sts ele_calls, cur_ele_calls
		sts outside_calls, cur_outside_calls

		cpi flag, 0		; lembrar de colocar a flag para 1 quando mudar para um state_stop ou state_stop_ele
		breq go_to_old_state

		cpi cnt, 10
		brne end_state_stop_ele
		ldi temp, 0
		sts door_flag, temp

	go_to_old_state : 
		lds new_state, old_state
		sts state, new_state

	end_state_stop_ele :

	ret

.undef cnt
.undef flag
.undef cur_level
.undef new_state
.undef A
.undef cur_ele_calls
.undef cur_outside_calls

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				STATE_RISE_OUT_HANDLE
; This label will handle the state_rise_out state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def cur_level = r20
.def cnt = r21
.def A = r22
.def calls = r23
.def new_state = r24

STATE_RISE_OUT_HANDLE :
	lds cur_level, level		; getting current level
	lds cnt, change_floor_cnt		; getting current change floor count
	lds calls, ele_calls

	push calls
	push cur_level
	rcall SHIFT_B_TIMES_RIGHT
	pop cur_level
	pop calls

	brlo init_state_rise_out
	lds new_state, state_rise_ele
	sts state, new_state
	rjmp end_state_rise_out

	init_state_rise_out :
		lds calls, outside_calls		; getting current calls in elevator

	begin_if_rise_out :		; checking if the floor changed
		cpi cnt, 3
		brlo end_state_rise_out		; if not, it is moving and nothing happen
		ldi cnt, 0		; else, it is in a new floor
		sts change_floor_cnt, cnt		; clear count
		ldi A, 0b00000001		; creating a variable to shift cur_level times
		inc cur_level		; update cur_level so that the floor changed
		sts level, cur_level		; store new level

		push calls
		push cur_level
		rcall SHIFT_B_TIMES_RIGHT
		pop cur_level
		pop calls		; A shifted cur_level times

		cpi calls, 1
		brne end_state_rise_out		; if not, skip

	; Example
	;	 x1xx (calls)
	;	-0100 (A)
	;  ------------
	;	 x0xx
	;   -0100
	;  ------------
	;   if answer is positive is because the LSM is 1. Therefore, exist new calls in biggest floors.

		ldi temp, 1
		sts wait_time_flag, temp
		ldi temp, 0
		sts door_cnt, temp
		lds new_state, state_stop
		sts state, new_state

	end_state_rise_out :

	ret

.undef cur_level
.undef cnt
.undef A
.undef calls
.undef new_state

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				STATE_DES_OUT_HANDLE
; This label will handle the state_des_out state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def cur_level = r20
.def cnt = r21
.def A = r22
.def calls = r23
.def new_state = r24

STATE_DES_OUT_HANDLE :
	lds cur_level, level		; getting current level
	lds cnt, change_floor_cnt		; getting current change floor count
	lds calls, outside_calls		; getting current calls in outside

	begin_if_des_out :		; checking if the floor changed
		cpi cnt, 3
		brlo end_if_des_out		; if not, it is moving and nothing happen

		ldi cnt, 0		; else, it is in a new floor
		sts change_floor_cnt, cnt		; clear count
		ldi A, 0b00000001		; creating a variable to shift cur_level times
		dec cur_level		; update cur_level so that the floor changed
		sts level, cur_level		; store new level

		push A
		push cur_level
		rcall SHIFT_B_TIMES_LEFT
		pop cur_level
		pop A		; A shifted cur_level times

		and A, calls		; checking if there is a call in the current floor
		breq end_if_des_out		; if not, skip
		ldi temp, 1
		sts wait_time_flag, temp
		ldi temp, 0
		sts door_cnt, temp

		lds new_state, state_stop
		sts state, new_state

	end_if_des_out :

	ret

.undef cur_level
.undef cnt
.undef A
.undef calls
.undef new_state

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				STATE_RISE_ELE_HANDLE
; This label will handle the state_rise_ele state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.def old_state_update = r19
.def cur_level = r20
.def cnt = r21
.def A = r22
.def calls = r23
.def new_state = r24

STATE_RISE_ELE_HANDLE :
	lds cur_level, level		; getting current level
	lds cnt, change_floor_cnt		; getting current change floor count
	lds calls, ele_calls		; getting current calls in elevator


	begin_if_rise_ele :		; checking if the floor changed
		cpi cnt, 3
		brlo end_if_rise_ele		; if not, it is moving and nothing happen
		ldi cnt, 0		; else, it is in a new floor
		sts change_floor_cnt, cnt		; clear count
		ldi A, 0b00000001		; creating a variable to shift cur_level times
		inc cur_level		; update cur_level so that the floor changed
		sts level, cur_level		; store new level

		push A
		push cur_level
		rcall SHIFT_B_TIMES_LEFT
		pop cur_level
		pop A		; A shifted cur_level times

		and A, calls		; checking if there is a call in the current floor
		breq end_if_rise_ele		; if not, skip
		ldi temp, 1
		sts wait_time_flag, temp
		ldi temp, 0
		sts door_cnt, temp

	; Example
	;	 x1xx (calls)
	;	-0100 (A)
	;  ------------
	;	 x0xx
	;   -0100
	;  ------------
	;   if answer is positive is because the LSM is 1. Therefore, exist new calls in biggest floors.

		sub calls, A		
		cp calls, A
		brlo go_state_stop

		lds old_state_update, state
		sts old_state, old_state_update
		lds new_state, state_stop_ele
		sts state, new_state
		rjmp end_if_rise_ele

	go_state_stop :
		lds new_state, state_stop
		sts state, new_state

	end_if_rise_ele :

	ret

.undef old_state_update
.undef cur_level
.undef cnt
.undef A
.undef calls
.undef new_state

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				STATE_DES_ELE_HANDLE
; This label will handle the state_des_ele state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def old_state_update = r19
.def cur_level = r20
.def cnt = r21
.def A = r22
.def calls = r23
.def new_state = r24
.def cur_outside_calls = r25

STATE_DES_ELE_HANDLE :
	lds cur_level, level		; getting current level
	lds cnt, change_floor_cnt		; getting current change floor count
	lds calls, ele_calls		; getting current calls in elevator
	lds cur_outside_calls, outside_calls

	begin_if_des_ele :		; checking if the floor changed
		cpi cnt, 3
		brlo end_if_des_ele		; if not, it is moving and nothing happen
		ldi cnt, 0		; else, it is in a new floor
		sts change_floor_cnt, cnt		; clear count
		ldi A, 0b00000001		; creating a variable to shift cur_level times
		dec cur_level		; update cur_level so that the floor changed
		sts level, cur_level		; store new level

		push A
		push cur_level
		rcall SHIFT_B_TIMES_LEFT
		pop cur_level
		pop A		; A shifted cur_level times
		or calls, cur_outside_calls

		and A, calls		; checking if there is a call in the current floor
		breq end_if_des_ele		; if not, skip
		ldi temp, 1
		sts wait_time_flag, temp
		ldi temp, 0
		sts door_cnt, temp

	; Example
	;	 x1xx (calls)
	;	-0100 (A)
	;  ------------
	;	 x0xx
	;   &0011
	;  ------------
	;    00xx
	; How A is pow2 -> 0...010...0
	; A-1 is -> 0...001...1
		sub calls, A		
		dec A
		and calls, A
		breq go_state_stop_2

		lds old_state_update, state
		sts old_state, old_state_update
		lds new_state, state_stop_ele
		sts state, new_state
		rjmp end_if_rise_ele

	go_state_stop_2 :
		lds new_state, state_stop
		sts state, new_state

	end_if_des_ele :

	ret

.undef old_state_update
.undef cur_level
.undef cnt
.undef A
.undef calls
.undef new_state
.undef cur_outside_calls

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				STATE_DES_ELE_OUT_HANDLE
; This label will handle the state_des_ele_out state.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STATE_DES_ELE_OUT_HANDLE :
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				SHIFT_B_TIMES_LEFT 
; This function will receive a register A and B, and
; A will be shift left B times.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.set offset = 7
.def A = r22
.def B = r23

SHIFT_B_TIMES_LEFT :
	push A
	push B
	push YH
	push YL

	in YL, SPL
	in YH, SPH

	ldd A, Y + offset + 1
	ldd B, Y + offset
	ldi temp, 0

	while_test_SBTL :
		cpi B, 0
		breq while_end_SBTL
	
	while_loop_SBTL :
		lsl A
		dec B
		rjmp while_test_SBTL
	
	while_end_SBTL :
		std Y + offset + 1, A

	pop YL
	pop YH
	pop B
	pop A

	ret

.undef A
.undef B

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;				SHIFT_B_TIMES_RIGHT 
; This function will receive a register A and B, and
; A will be shift right B times.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.set offset = 7
.def A = r22
.def B = r23

SHIFT_B_TIMES_RIGHT :
	push A
	push B
	push YH
	push YL

	in YL, SPL
	in YH, SPH

	ldd A, Y + offset + 1
	ldd B, Y + offset
	ldi temp, 0

	while_test_SBTR :
		cpi B, 0
		breq while_end_SBTR
		
	while_loop_SBTR :
		lsr A
		dec B
		rjmp while_test_SBTR
		
	while_end_SBTR :
		std Y + offset + 1, A

	pop YL
	pop YH
	pop B
	pop A

	ret

.undef A
.undef B


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						OUTPUTS
; Set values of buzzer, leds and display for PORTC.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def cur_led_buzzer = r20
.def cur_level = r21
.def flag = r22
.def cnt = r23
.def output = r19

OUTPUTS:
	lds cur_level, level
	lds flag, door_flag
	lds cnt, door_cnt
	ldi output, 0

	cpi flag, 0		; lembrar de colocar a flag para 1 quando mudar para um state_stop ou state_stop_ele
	breq print
	ldi temp, ( 1 << (LED_POSITION+4) )
	or output, temp
	cpi cnt, 5
	brlo print
	ldi temp, ( 1 << (BUZZER_POSITION+4) )
	or output, temp

	print :
		or output, cur_level
		
	out PORTC, output 
	
	ret

.undef cnt
.undef flag
.undef cur_led_buzzer
.undef cur_level
.undef output

.def cur_time = r20

WAIT_TIME :

	push cur_time

	begin :
		lds cur_time, wait_cnt
		cpi cur_time, 3
		breq end
		rjmp begin

	end :
		ldi temp, 0
		sts wait_time_flag, temp
		ldi temp, 1
		sts door_flag, temp
	
	pop cur_time

	ret

.undef cur_time

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						MAIN
; This label will have the main loop of the program.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.def cur_state = r18

MAIN:
	; getting current state
	lds cur_state, state

	begin_if_main :
	; checking state_stop
		lds temp, state_stop
		cp cur_state, temp		; comparing current state with state_top
		brbc SREG_Z, is_not_in_state_stop		; branch if isnt in this state
		rcall STATE_STOP_HANDLE		; else, execute this state handle
		rjmp end_if_main

	is_not_in_state_stop :
		; checking state_rise_out
		lds temp, state_rise_out
		cp cur_state, temp		; comparing current state with state_rise_out
		brbc SREG_Z, is_not_in_state_rise_out		; branch if isnt in this state
		rcall STATE_RISE_OUT_HANDLE		; else, execute this state handle
		rjmp end_if_main
	
	is_not_in_state_rise_out :
		; checking state_des_out
		lds temp, state_des_out
		cp cur_state, temp		; comparing current state with state_des_out
		brbc SREG_Z, is_not_in_state_des_out		; branch if isnt in this state
		rcall STATE_DES_OUT_HANDLE		; else, execute this state handle
		rjmp end_if_main

	is_not_in_state_des_out :
		; checking state_rise_ele
		lds temp, state_rise_ele
		cp cur_state, temp		; comparing current state with state_rise_ele
		brbc SREG_Z, is_not_in_state_rise_ele		; branch if isnt in this state
		rcall STATE_RISE_ELE_HANDLE		; else, execute this state handle
		rjmp end_if_main

	is_not_in_state_rise_ele :
		; checking state_des_ele
		lds temp, state_des_ele
		cp cur_state, temp		; comparing current state with state_des_ele
		brbc SREG_Z, is_not_in_state_des_ele		; branch if isnt in this state
		rcall STATE_DES_ELE_HANDLE		; else, execute this state handle
		rjmp end_if_main

	is_not_in_state_des_ele :
		; checking state_des_ele_out
		lds temp, state_des_ele_out
		cp cur_state, temp		; comparing current state with state_des_ele_out
		brbc SREG_Z, is_not_in_state_des_ele_out		; branch if isnt in this state
		rcall STATE_DES_ELE_OUT_HANDLE		; else, execute this state handle
		rjmp end_if_main

	is_not_in_state_des_ele_out :
		; checking state_stop_ele
		lds temp, state_stop_ele
		cp cur_state, temp		; comparing current state with state_stop_ele
		brbc SREG_Z, is_not_in_state_stop_ele		; branch if isnt in this state
		rcall STATE_STOP_ELE_HANDLE		; else, execute this state handle
		rjmp end_if_main
		
	is_not_in_state_stop_ele :

	end_if_main :

	rcall OUTPUTS

	RJMP MAIN

.undef cur_state

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			END PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
