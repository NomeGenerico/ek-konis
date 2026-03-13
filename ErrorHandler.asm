loadn r0, #65534
push r0    ; stop stack overflow
jmp main


;--------- ErrorSystem     Version 0.2
;
;	Minimalist Suit To Allow For Easier Error Catching: 
; 	Is required in all my libraries to allow you to know imediatly 
;	if the error is related to my shitty code or your code
;
;	Error Mesages and ErrorMessageTables can be moved at will, but they must exist somewhere
;	
;	The Usage Is prety simple, Define Error Mesages and Assing them to IDs. Call "CallFatalError" with the IDs to get a 
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

			loadn r5, #0   ; stops garbage


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

		TraceStack:    ; Only gets called on Fatal Error

			pop r5
			loadn r3, #65535
			loadn r4, #100

			TraceStack_loop:


				; if r2 = 65535, exit loop with next word of memory in the stack

					pop r2
					cmp r2, r3
					jeq TraceStack_getstack

				; if r2 = 65534, exit beacuse we reached the end of the stack
					dec r3
					cmp r2, r3
					jeq TraceStack_exit

				jmp TraceStack_loop
				TraceStack_getstack:
			pop r1    ; if found, update address
						  ; Else Exit
			TraceStack_exit:
			push r5
			rts



	; Public:
		CallI:   ; < r7 = Which Function To Call (Pointer) >
			push r7
			rts
		CallFatalError:  ; <ERRORID, Reserved>, < >   ;


			call PrintYellowScreen
			call PrintErrorMessage ; Puts

			; retrieve PC from stack
			
			pop r1

			; try to find stack marker

			call TraceStack

			call PrintHexNumberOnScreen
			; Print PC after the message

			halt

		PrintHexNumberOnScreen: ; <Index, Number>, < >   ; Prints On Screen

			; r0 is the Index to print the number
			loadn r3, #"x"
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


		CheckOverFlowSafe: ; <   , Size, Buffer*, BufferSize, BufferPointer >, < r2 = Error or not>  Used By the Memory Handler 

			push r1
			push r3
			push r4

			;r1 = Size of Object

			add r1, r1, r4  ; BufferPointer + Size
			add r2, r2, r3  ; Buffer + BufferSize

			cmp r1, r2
			jel CheckOverFlowSafe_END

				loadn r2, #1

				pop r4
				pop r3
				pop r1


				rts
				
			CheckOverFlowSafe_END:

			loadn r2, #0

			pop r4
			pop r3
			pop r1


			rts

		CheckOverFlow:   ; <  ErrorID , Size, Buffer*, BufferSize, BufferPointer > , <   >

			push r1
			push r2
			push r3
			push r4

			Call CheckOverFlowSafe

			mov r1, r2
			call CheckIfZero   ; Errors if not zero
			
			pop r4
			pop r3
			pop r2
			pop r1
			
			rts

		MemCompare: ; <*mem1 , *mem2, size> , < Equal (0 or 1)>  , 1 if equal, 0 if different  ; safe

			push r1
			push r2
			push r3
			push r4
			push r5

			loadn r5, #0

			MemCompare_loop:

				loadi r3, r0
				loadi r4, r1
				cmp r3, r4
				jeq MemCompare_equal

				loadn r0, #0
				jmp MemCompare_exit

				MemCompare_equal:

				inc r0
				inc r1
				dec r2
				cmp r2, r5
				jne MemCompare_loop
			loadn r0, #1
			MemCompare_exit:

			pop r5
			pop r4
			pop r3
			pop r2
			pop r1

			rts
		CheckIfOne: ; <Error ID, r1 = variable> , < >
			push r1
			push r2

			loadn r2, #1
			cmp r1, r2
			jne CheckIfOne_error

				pop r2
				pop r1
				rts

			CheckIfOne_error:

				pop r2
				pop r1
				call CallFatalError


		CheckIfZero: ; <Error ID, r1 = variable> , < >
			push r1
			push r2

			loadn r2, #0
			cmp r1, r2
			jne CheckIfZero_error

				pop r2
				pop r1
				rts

			CheckIfZero_error:

				pop r2
				pop r1
				call CallFatalError
		;Untested
		ErrorAwareCall: ;  < ErrorID, r7 = Which Function to Call (Pointer) > Clobers r1, make sure to save it before calling it. 

			push r1
			loadn r1, #65535   ; marker for call, to guarantee to find the original functions addres
			push r1

			call CallI   ; will call whatver is in r7

			pop r1
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
		BufferOverFlowError1 : string "The OverFlow Function Failed: Test 1.   PC:"
		BufferOverFlowError2 : string "The OverFlow Function Failed: Test 2.   PC:"
		BufferOverFlowError3 : string "The OverFlow Function Failed: Test 3.   PC:"
		BufferOverFlowError4 : string "The OverFlow Function Failed: Test 4.   PC:"
		BufferOverFlowError5 : string "The OverFlow Function Failed: Test 5.   PC:"
		MemCompareError1 : string "The MEMCompare Function Failed Test 1.  PC:"
		MemCompareError2 : string "The MEMCompare Function Failed Test 2.  PC:"
		MemCompareError3 : string "The MEMCompare Function Failed Test 3.  PC:"
		MemCompareError4 : string "The MEMCompare Function Failed Test 4.  PC:"
		MemCompareError5 : string "The MEMCompare Function Failed Test 5.  PC:"
		ErrorAwareCallError1 : string "The ErrorAwareCall Function Failed Test 1:"

		AllTestsPassed : string "All Tests Passed, Nice!"



		ErrorMessageTable: var #256

			static ErrorMessageTable + #0, #TestError
			static ErrorMessageTable + #10, #BufferOverFlowError1
			static ErrorMessageTable + #11, #BufferOverFlowError2
			static ErrorMessageTable + #12, #BufferOverFlowError3
			static ErrorMessageTable + #13, #BufferOverFlowError4
			static ErrorMessageTable + #14, #BufferOverFlowError5
			static ErrorMessageTable + #15, #MemCompareError1
			static ErrorMessageTable + #16, #MemCompareError2
			static ErrorMessageTable + #17, #MemCompareError3
			static ErrorMessageTable + #18, #MemCompareError4
			static ErrorMessageTable + #19, #MemCompareError5
			static ErrorMessageTable + #100, #AllTestsPassed


; DO NOT COPY TO YOUR CODE, ALSO REMOVE THE JUMP MAIN ON THE TOP
; Library Tests
;
;
	;DO NOT COPy
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

			Call CallFatalError

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
	; BufferOverFlow TESTS:

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

	; MEMCompare Tests:
		; setup
			TestMem1 : var #5
				static TestMem1 + #0 , #5
				static TestMem1 + #1 , #7
				static TestMem1 + #2 , #3
				static TestMem1 + #3 , #2
				static TestMem1 + #4 , #1
				TestMem1Over : var #1
				static TestMem1Over + #0 , #7

			TestMem2 : var #5       ; different from Mem1 only in overflow
				static TestMem2 + #0 , #5  
				static TestMem2 + #1 , #7
				static TestMem2 + #2 , #3
				static TestMem2 + #3 , #2
				static TestMem2 + #4 , #1
				TestMem2Over : var #1
				static TestMem2Over + #0 , #9

			TestMem3 : var #5		; Different from Mem1 Only in last valid addrs
				static TestMem3 + #0 , #5
				static TestMem3 + #1 , #7
				static TestMem3 + #2 , #3
				static TestMem3 + #3 , #2
				static TestMem3 + #4 , #6
				TestMem3Over : var #1
				static TestMem3Over + #0 , #7

			TestMem4 : var #5		; Different from Mem1 Only in start
				static TestMem4 + #0 , #2
				static TestMem4 + #1 , #7
				static TestMem4 + #2 , #3
				static TestMem4 + #3 , #2
				static TestMem4 + #4 , #1
				TestMem4Over : var #1
				static TestMem4Over + #0 , #7

			TestMem5 : var #5    	; Different drom Mem1 only in the middle
				static TestMem5 + #0 , #5
				static TestMem5 + #1 , #7
				static TestMem5 + #2 , #2
				static TestMem5 + #3 , #2
				static TestMem5 + #4 , #1
				TestMem5Over : var #1
				static TestMem5Over + #0 , #7

		; Test 1
			loadn r0, #TestMem1
			loadn r1, #TestMem1
			loadn r2, #5   ; Size
			call MemCompare
			; r0 is now 0, 1
			mov r1, r0
			loadn r0, #15   ; should give 1 (equal)
			call CheckIfOne
		
		; Test 2
			loadn r0, #TestMem1
			loadn r1, #TestMem2
			loadn r2, #5   ; Size
			call MemCompare
			; r0 is now 0, 1
			mov r1, r0
			loadn r0, #16   ; should give 1 (equal)
			call CheckIfOne
		
		; Test 3
			loadn r0, #TestMem1
			loadn r1, #TestMem3
			loadn r2, #5   ; Size
			call MemCompare
			; r0 is now 0, 1
			mov r1, r0
			loadn r0, #17   ; should give 0 (diff)
			call CheckIfZero

		; Test 4
			loadn r0, #TestMem1
			loadn r1, #TestMem4
			loadn r2, #5   ; Size
			call MemCompare
			; r0 is now 0, 1
			mov r1, r0
			loadn r0, #18   ; should give 0 (diff)
			call CheckIfZero
		
		; Test 5
			loadn r0, #TestMem1
			loadn r1, #TestMem5
			loadn r2, #5   ; Size
			call MemCompare
			; r0 is now 0, 1
			mov r1, r0
			loadn r0, #19   ; should give 0 (diff)
			call CheckIfZero



	; StackTraceTests
	
	; All Tests Passed
		loadn r0, #100
			call CallFatalError



