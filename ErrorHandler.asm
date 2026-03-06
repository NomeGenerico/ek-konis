jmp main


;--------- ErrorSystem     Version 0.1
;
;	Minimalist Suit To Allow For Easier Error Catching: 
; 	Is required in all my libraries to allow you to know imediatly 
;	if the error is related to my shitty code or your code
;
;	Error Mesages and ErrorMessageTables can be moved at will, but they must exist somewhere
;	
;	The Usage Is prety simple, Define Error Mesages and Assing them to IDs. Call "CallError" with the IDs to get a 
;	Yellow Screen Of Death (YSOD)
;
; 	Some Other Functions may also provided, They are mainly used for my other libraries but are general error cheking tha you can use. 
;
;	Please Respect the Private And Public Declarations. You are king, but Private Functions May Use Undeclared Conventions
;	That might make Debuging Hell
;
;	All my functions have input and output documented like this     <Inputs>, <Outputs>
;	If there are no resgister indication you can just assume the first is r0, the second r1, etc
;

	;Private
		PrintYellowScreen:  ; < > , < >

			push r0
			push r1
			push r2

			loadn r0, #0
			loadn r1, #1200
			loadn r2, #893 ; YellowSquare

			PrintYellowScreen_loop:

				
				cmp r0, r1
				jeq PrintYellowScreen_Exit

				outchar r2, r0
				inc r0
				jmp PrintYellowScreen_loop
			PrintYellowScreen_Exit:
			pop r2
			pop r1
			pop r0
			rts


		PrintErrorMessage:  ; <ErrorID> , <LastPrintedPosition>

			;r0  printing position
			push r1	 ; String Address ; its now a pointer
			push r2	 ; color
			push r3
			push r4
			push r5


			loadn r1, #ErrorMessageTable
			add r1, r1, r0   ; Use Id to find string
			loadi r1, r1 ; now its the string addres

			loadn r0, #0   ; load the position to write to
			loadn r2, #0

			
			loadn r3, #'\0'

			PrintErrorMessage_Loop:
				loadi r4, r1          ; Carrega no r4 o caractere apontado por r1
				cmp r4, r3            ; Compara o caractere atual com '\0'
				jeq PrintErrorMessage_Sai    ; Se for igual a '\0', salta para ImprimeStr_Sai, encerrando a impressão.
				
				add r4, r2, r4        ; Soma r2 ao valor do caractere. 
				
				outchar r4, r0         ; Imprime o caractere (r4) na posição de tela (r0).
				inc r0                 ; Incrementa a posição na tela para o próximo caractere.
				mov r5, r0			   ; Salve o Indice printado
				inc r1                 ; Incrementa o ponteiro da string para o próximo caractere.
				jmp PrintErrorMessage_Loop    ; Volta ao início do loop para continuar imprimindo.

			PrintErrorMessage_Sai:
			mov r0, r5 ; coloca o indicie printado em r0
			pop r5	
			pop r4	; Resgata os valores dos registradores utilizados na Subrotina da Pilha
			pop r3
			pop r2
			pop r1 
			rts


		DigitHexFinder: ; <r3 = Num> , <r3 = Char> Takes a number from 0 to 15 and gives back the coresponding hex char
			push r4
			
			loadn r4, #10
			cmp r3, r4	   ; Checks if shift is nedded for char
			jle DigitHexFinder_SkipShift
			loadn r4, #7
			add r3, r3, r4  ; goes from 9 to A

			DigitHexFinder_SkipShift:
			loadn r4, #"0"
			add r3, r3, r4  ; add num to the char for 0, with the proper handling of 7,8,9 -> A,B,C 
			pop r4
			rts


	; Public:
		
		CallError:  ; <ERRORID>, < >   ; Clobers r0 and r1. IF you neeed their data, get it before this runs


			call PrintYellowScreen
			call PrintErrorMessage ; clobers r0

			; retrieve PC from stack
			
			pop r1

			call PrintHexNumberOnScreen
			; Print PC after the message

			halt



		PrintHexNumberOnScreen: ; <Index, Number>, < >   ; Prints On Screen

			; r0 is the Index to print the number
			loadn r3, "x"
			outchar r3, r0
			inc r0

			loadn r2, #61440  ; Highest Four Bits
			and r3, r1, r2 
			shiftR0 r3, #12
			call DigitHexFinder
			outchar r3, r0
			inc r0

			loadn r2, #3840  ; High middle Four Bits
			and r3, r1, r2 
			shiftR0 r3, #8
			call DigitHexFinder
			outchar r3, r0
			inc r0

			loadn r2, #240  ; Low middle Four Bits
			and r3, r1, r2 
			shiftR0 r3, #4
			call DigitHexFinder
			outchar r3, r0
			inc r0

			loadn r2, #15  ; Low Four Bits
			and r3, r1, r2 
			call DigitHexFinder
			outchar r3, r0
			inc r0

			rts


		CheckOverFlow: ; <ERRORID, Size, Buffer*, BufferSize, BufferPointer >, < >  Used By the Memory Handler

			push r1
			push r2
			push r3
			push r4

			;r0 = ERRORID   ; Create Your Own Message to specify wich buffer it is.
			;r1 = Size of Object

			add r1, r1, r4  ; BufferPointer + Size
			add r2, r2, r3  ; Buffer + BufferSize

			cmp r1, r2
			jel CheckOverFlow_END

				Call CallError

				pop r4
				pop r3
				pop r2
				pop r1


				rts
				
			CheckOverFlow_END:

			pop r4
			pop r3
			pop r2
			pop r1


			rts



;----------- Error Messages   ; Examples Used for the tests
;
;
	; Error Mesages
	; 
	; Simply declare a String and add it to the Error MessageTable. The value in the + #num will be the Error ID.
	; 
		TestError : string "This is a Error Mesage, PC that called the error: "
		BufferOverFlowError1 : string "The OverFlow Function Failed: Test1.    PC:"
		BufferOverFlowError2 : string "The OverFlow Function Failed: Test2.    PC:"
		BufferOverFlowError3 : string "The OverFlow Function Failed: Test3.    PC:"
		BufferOverFlowError4 : string "The OverFlow Function Failed: Test4.    PC:"
		BufferOverFlowError5 : string "The OverFlow Function Failed: Test5.    PC:"
		AllTestsPassed : string "All Tests Passed, Nice!"



	ErrorMessageTable: var #256

		static ErrorMessageTable + #0, #TestError
		static ErrorMessageTable + #10, #BufferOverFlowError1
		static ErrorMessageTable + #11, #BufferOverFlowError2
		static ErrorMessageTable + #12, #BufferOverFlowError3
		static ErrorMessageTable + #13, #BufferOverFlowError4
		static ErrorMessageTable + #14, #BufferOverFlowError5
		static ErrorMessageTable + #100, #AllTestsPassed


; DO NOT COPY TO YOUR CODE, ALSO REMOVE THE JUMP MAIN ON THE TOP
; Library Tests
;
;
	;DO NOT COPY
	; Inverted Functions, Will Trow Errors if passed, Pass If Failed. 
		CheckOverFlowReversed: ; <ERRORID, Size, Buffer*, BufferSize, BufferPointer >  Used By the Memory Handler

			push r1
			push r2
			push r3
			push r4

			;r0 = ERRORID
			;r1 = Size of Object

			add r1, r1, r4  ; Pointer + Size
			add r2, r2, r3  ; Buffer + BufferSize

			cmp r1, r2
			jel CheckOverFlowReversed_END

				pop r4
				pop r3
				pop r2
				pop r1

				rts
				
				
			CheckOverFlowReversed_END:

			Call CallError

			pop r4
			pop r3
			pop r2
			pop r1

			rts
	;DO NOT COPY
	; Cleanup Functions
		CleanScreen: 

			loadn r0, #0  ; void
			loadn r1, #0
			loadn r2, #1200

			CleanScreen_loop:
			cmp r1, r2
			jeq CleanScreen_Exit
			outchar r0, r1
			inc r1
			jmp CleanScreen_loop
			CleanScreen_Exit:

			rts




	;DO NOT COPY
	; Actual Test Code
	;
	;
	; TEST DATA

		TestBuffer: var #2000
		TestBufferSize: var #1
			static TestBufferSize + #0, #2000
		TestBufferPointer: var #1   ; this point to the furthest WRITTEN data along the list. 
			static TestBufferPointer + #0, #TestBuffer

		;DO NOT COPY
	main:
	call CleanScreen
	; setup BufferOverFlow

			loadn r0, #1900
			load r1, TestBufferPointer
			add r1, r1, r0
			store TestBufferPointer, r1

		; Test1   ; Alocated Up to Boundry
			loadn r0, #10 ; Error ID
			loadn r1, #100 ; size of alocation
			loadn r2, #TestBuffer
			load r3, TestBufferSize
			load r4, TestBufferPointer

			call CheckOverFlow    ; expected pass 
			
		; Test2 - Clear overflow, should error
			loadn r0, #11
			loadn r1, #200        ; size too big
			loadn r2, #TestBuffer
			load r3, TestBufferSize
			load r4, TestBufferPointer  ; still at 1900
			call CheckOverFlowReversed    ; expected error so we use reverse, to allow tests to continue

		; Test3 - Pointer at start, small allocation, should pass
			loadn r0, #12
			loadn r1, #10
			loadn r2, #TestBuffer
			load r3, TestBufferSize
			loadn r4, #TestBuffer  ; pointer at start
			call CheckOverFlow    ; expected pass

		; Test4 - Pointer at start, allocation larger than buffer, should error
			loadn r0, #13
			loadn r1, #2001
			loadn r2, #TestBuffer
			load r3, TestBufferSize
			loadn r4, #TestBuffer
			call CheckOverFlowReversed    ; expected error so we use reverse, to allow tests to continue

		; Test5 - Pointer already past buffer end, should error
			loadn r0, #14
			loadn r1, #1   ; alocate a single word
			loadn r2, #TestBuffer
			load r3, TestBufferSize
			load r4, TestBufferPointer  ; still at 1900 range
			loadn r5, #300
			add r4, r4, r5  ; Buffer Pointer Is now Buffer + 2200
			call CheckOverFlowReversed    ; expected error so we use reverse, to allow tests to continue

			; All Tests Passed
				loadn r0, #100
				call CallError



