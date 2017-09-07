_MYDATA SEGMENT
	STR0	DB	0AH, 0DH, '--------------------------------$'
	STR1	DB	0AH, 0DH, '|                              |$'
	STR2	DB	0AH, 0DH, '|     Simple ASM Calculator    |$'
	STR3	DB	0AH, 0DH, '|  By 1551713 - ZHANG Zhenyan  |$'
	STR4	DB	0AH, 0DH, 'S=$'
	STR5	DB	0AH, 0DH, 'Thank you and goodbye~$'
	STR6	DB	0AH, 0DH, 'ILLEGAL CHARACTER! Execution terminated.$'
	STR7	DB	0AH, 0DH, 'TOO MORE DIGITS! Execution terminated.$'
	STR8	DB	0AH, 0DH, 'TOO MORE OPERATORS! Execution terminated.$'
	MAINANS	DW	9 DUP(0)
	REMAIN	DW	2 DUP(0)
	DIVFLG	DB	0		; Flag of continuous dividing.
	FLAG	DB	0
	PLSCNT	DB	0
	MNSCNT	DB	0
	MPYCNT	DB	0
	DIVCNT	DB	0
_MYDATA	ENDS

; NAME: SHOW
; INSTRUCTION: Print a string using function 9.
; REG OCCUPATION: AX, DX.
; INPUT: Already initialized string.
; OUTPUT: None.

SHOW MACRO STR
	PUSH	AX
	PUSH	DX
	LEA		DX, STR
	MOV		AH, 9
	INT		21H
	POP		DX
	POP		AX
ENDM

; NAME: CRLF
; INSTRUCTION: Start a new line.
; REG OCCUPATION: AX, DX.
; INPUT: None.
; OUTPUT: None.

CRLF MACRO
	PUSH	AX
	PUSH	DX
	MOV		AH, 2
	MOV		DL, 0DH
	INT		21H
	MOV		AH, 2
	MOV		DL, 0AH
	INT		21H
	POP		DX
	POP		AX
ENDM

_CODE SEGMENT
	ASSUME	CS: _CODE, DS: _MYDATA
_MAIN PROC	FAR
	PUSH	DS
	MOV		AX, 0
	PUSH	AX
	MOV		AX, _MYDATA
	MOV		DS, AX
; Main program starts here.

; Initialization starts here.
	SHOW	STR0
	SHOW	STR1
	SHOW	STR2
	SHOW	STR3
	SHOW	STR1
	SHOW	STR0
	MOV		AX, 0
	MOV		BX, 0
	MOV		CX, 0
	MOV		DX, 0
	CRLF
	SHOW	STR4
	LEA		SI, MAINANS		; Initialize SI as index for MAINANS.
	LEA		DI, REMAIN		; Initialize DI as index for REMAIN.
; Initialization ends here.

_INPUT:
	MOV		AX, 0100H
	INT		21H
_COMPARE:
	CMP		AL, 0DH
	JE		_FINAL0		; Input CR.
	CMP		AL, 2BH
	JE		_PLUS		; Input '+'.
	CMP		AL, 2DH
	JE		_MINUS0		; Input '-'.
	CMP		AL, 2AH
	JE		_MTPLY0		; Input '*'.
	CMP		AL, 2FH
	JE		_DVIDE0		; Input '/'.
	CMP		AL, 30H
	JB		_ERROR1		; Illegal inputs < 30H.
	CMP		AL, 39H
	JBE		_DIGITS		; Input 30H ~ 39H.
_ERROR1:
	SHOW	STR6
	CRLF
	JMP		_END
_ERROR2:
	SHOW	STR7
	CRLF
	JMP		_END
_DIGITS:
	MOV		DIVFLG, 0
	CMP		FLAG, 0
	JNE		_ERROR2
	AND		AX, 000FH		; Change ascii to number.
	MOV		[SI], AX
	MOV		FLAG, 1
	JMP		_INPUT
_DVIDE0:
	JMP		_DVIDE
_FINAL0:
	JMP		_FINAL
_MINUS0:
	JMP		_MINUS
_MTPLY0:
	JMP		_MTPLY
_PLUS:
	CMP		FLAG, 0
	JE		_ERROR3
	INC		PLSCNT
	CMP		PLSCNT, 3
	JNB		_ERROR3
	CALL	__PLUS
	JMP		_INPUT
_INPUT0:
	JMP		_INPUT
_MINUS:
	CMP		FLAG, 0
	JE		_ERROR3
	INC		MNSCNT
	CMP		MNSCNT, 3
	JNB		_ERROR3
	CALL	__MINUS
	JMP		_INPUT
_ERROR3:
	SHOW	STR8
	CRLF
	JMP		_END
_MTPLY:
	CMP		FLAG, 0
	JE		_ERROR3
	INC		MPYCNT
	CMP		MPYCNT, 3
	JNB		_ERROR3
	CALL	__MTPLY
	JMP		_INPUT
_DVIDE:
	CMP		FLAG, 0
	JE 		_ERROR3
	INC		DIVCNT
	CMP		DIVCNT, 3
	JNB		_ERROR3
	CALL	__DVIDE
	JMP		_INPUT0
_FINAL:
	CMP		FLAG, 0
	JE		_INPUT0
	CALL	__FINAL
	SHOW	STR5
	CRLF
; Main program ends here.

_END:
	RET
_MAIN ENDP

; NAME: __PLUS
; INSTRUCTION: Processes responsing '+' input.
; REG OCCUPATION: None.
; INPUT: SI.
; OUTPUT: None.

__PLUS PROC
	MOV		DIVFLG, 0
	ADD		SI, 2
	MOV		FLAG, 0
	RET
__PLUS ENDP

; NAME: __MINUS
; INSTRUCTION: Processes responsing '-' input.
; REG OCCUPATION: AX.
; INPUT: SI.
; OUTPUT: None.

__MINUS PROC
	MOV		DIVFLG, 0
	PUSH	AX
	ADD		SI, 2
_MINUSINPUT:
	MOV		AX, 0100H
	INT		21H
	CMP		AL, 30H
	JB		_MINUSINPUT		; Illegal inputs < 30H.
	CMP		AL, 39H
	JA		_MINUSINPUT		; Illegal inputs > 39H.
	AND		AX, 000FH		; Change ascii to number.
	NEG		AX
	MOV		[SI], AX
	POP		AX
	RET
__MINUS ENDP

; NAME: __MTPLY
; INSTRUCTION: Processes responsing '*' input.
; REG OCCUPATION: AX, BX, DX.
; INPUT: SI.
; OUTPUT: None.

__MTPLY PROC
	PUSH	AX
	PUSH	BX
	PUSH	DX
	CMP		DIVFLG, 1
	JE		_MPYDIV
	MOV		DIVFLG, 0
	MOV		BX, [SI]
_MTPLYINPUT:
	MOV		AX, 0100H
	INT		21H
	CMP		AL, 30H
	JB		_MTPLYINPUT		; Illegal inputs < 30H.
	CMP		AL, 39H
	JA		_MTPLYINPUT		; Illegal inputs > 39H.
	AND		AX, 000FH		; Change ascii to number.
	IMUL	BL
	MOV		[SI], AX
	JMP		_MTPLYEND
_MPYDIV:
	MOV		AX, [SI]
	MOV		BX, 10
	IMUL	BX
	MOV		BX, [DI]
	ADD		BX, AX
_MTPLYINPUT2:
	MOV		AX, 0100H
	INT		21H
	CMP		AL, 30H
	JB		_MTPLYINPUT2		; Illegal inputs < 30H.
	CMP		AL, 39H
	JA		_MTPLYINPUT2		; Illegal inputs > 39H.
	AND		AX, 000FH		; Change ascii to number.
	IMUL	BX
	MOV		BX, 10
	CWD
	IDIV	BX
	MOV		[SI], AX
	MOV		[DI], DX
_MTPLYEND:
	POP		DX
	POP		BX
	POP		AX
	RET
__MTPLY ENDP

; NAME: __DVIDE
; INSTRUCTION: Processes responsing '/' input.
; REG OCCUPATION: AX, BX, DX.
; INPUT: SI, DI.
; OUTPUT: AX, DX, REMAIN.

__DVIDE PROC
	PUSH	AX
	PUSH	BX
	PUSH	DX
	MOV		AX, [SI]
	MOV		BX, 10
	IMUL	BX
	CMP		DIVFLG, 1
	JE		_DVIDEDOWN
	CMP		WORD PTR [DI], 0
	JE		_DVIDEDOWN
	ADD		DI, 2
_DVIDEDOWN:
	MOV		DX, [DI]
	ADD		AX, DX
	MOV		BX, AX
_DVIDEINPUT:
	MOV		AX, 0100H
	INT		21H
	CMP		AL, 30H
	JB		_DVIDEINPUT		; Illegal inputs < 30H.
	CMP		AL, 39H
	JA		_DVIDEINPUT		; Illegal inputs > 39H.
	AND		AX, 000FH		; Change ascii to number.
	XCHG	AX, BX
	CWD
	IDIV	BX

; Rounding begins.
	ADD		DX, DX
	CMP		DX, 0
	JL		_DVIDENEGNEXT
	CMP		DX, BX
	JL		_DVIDENEXT
	INC		AX
	JMP		_DVIDENEXT
_DVIDENEGNEXT:				; Rounding for negative numbers.
	NEG		DX
	CMP		DX, BX
	JL		_DVIDENEXT
	DEC		AX
; Rounding ends.

_DVIDENEXT:
	MOV		BX, 10
	CWD
	IDIV	BX
	MOV		[SI], AX
	MOV		[DI], DX
	MOV		DIVFLG, 1
	POP		DX
	POP		BX
	POP		AX
	RET
__DVIDE ENDP

; NAME: __FINAL
; INSTRUCTION: Final processing.
; REG OCCUPATION: AX, BX, CX, DX.
; INPUT: None.
; OUTPUT: None.

__FINAL PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	SHOW	STR4
	MOV		AX, 0
	LEA		SI, MAINANS		; Initialize SI as index for MAINANS.
	LEA		DI, REMAIN		; Initialize DI as index for REMAIN.

; Add all numbers in MAINANS.
	MOV		CX, 9
_FINALMAIN:
	ADD		AX, [SI]
	ADD		SI, 2
	LOOP	_FINALMAIN
	MOV		BX, 10
	IMUL	BX
	ADD		AX, [DI]
	ADD		AX, [DI + 2]
	CALL	__PRINTDEC
	POP		DX
	POP		CX
	POP		BX
	POP		AX
	RET
__FINAL ENDP

; NAME: __PRINTDEC
; INSTRUCTION: Exchange hexadecimal number in AX to decimal and print.
; REG OCCUPATION: BX, CX, DX.
; INPUT: AX.
; OUTPUT: None.

__PRINTDEC PROC
	PUSH	BX
	PUSH	CX
	PUSH	DX
	MOV		CX, 0
	MOV		BX, 10
	CMP		AX, 0
	JNL		_CHGLOOP0
	NEG		AX
	PUSH	AX
	MOV		DL, 2DH
	MOV		AX, 0200H
	INT		21H
	POP		AX
_CHGLOOP0:
	CMP		AX, 10
	JNB		_CHGLOOP
	PUSH	AX
	MOV		DL, 30H
	MOV		AX, 0200H
	INT		21H
	POP		AX
_CHGLOOP:
	MOV		DX, 0
	IDIV	BX
	PUSH	DX
	INC		CX
	CMP		AX, 0
	JNE		_CHGLOOP
_PRINTLOOP:
	CMP		CX, 1
	JNE		_NOPOINT
	MOV		DL, 2EH
	MOV		AX, 0200H
	INT		21H
_NOPOINT:
	POP		DX
	ADD		DL, 30H
	MOV		AX, 0200H
	INT		21H
	LOOP	_PRINTLOOP
	POP		DX
	POP		CX
	POP		BX
	RET
__PRINTDEC ENDP

_CODE ENDS
	END	_MAIN