loadn r0, #65534
push r0    ; stop stack overflow in StackTrace of the error handler
jmp Tests

;-------------- RLE Library V0.1
;
;	RLE Stands for Run Lenght Enocding. It is a simple compression method that is incredibly simple, but very efective at
;	some kinds of repetitive sequential data. Strings like "00000000100000111111111" which would take 23 words in memory, would take [8,"0",1,"1",5,"0",9,"1"], which   
;	is just 8 words. More than 50% compression. It works by storing a count and a object pair, for each element it finds. But if repeated and sequential elements are found,
;	it only needs to increment the count, which does not use more memory. 
;
	;Private

	;Public
	; Fully Working
	RLEDecoder:   ; <*target, *source>, <> ; Decodes the data in r1 to the memory that starts in r0
		push r0
		push r1
		push r2
		push r3
		push r4
		; r0 is the string it will decode to. Pointer
		; r1 is the string it will decode from. Pointer
		
		loadn r3, #'\0'

		RLEDecoder_Loop:
			loadi r4, r1          ; Carrega no r4 o caractere apontado por r1
			cmp r4, r3            ; Compara o caractere atual com '\0'
			jeq RLEDecoder_Exit   ; Se for igual a '\0', salta para ImprimeStr_Sai, encerrando a impressão.
			

			mov r2, r4 ; loop lengh
			inc r1
			loadi r4, r1	; looped character
			inc r2 ; makes loop easier, no need to compare to zero
				CharacterDecode_Loop:
				dec r2
				jz CharacterDecode_Exit
				
					storei r0, r4
					inc r0	

					jmp CharacterDecode_Loop

				CharacterDecode_Exit:
				inc r1 
			jmp RLEDecoder_Loop    ; Volta ao início do loop para continuar imprimindo.

		RLEDecoder_Exit:	
		pop r4	; Resgata os valores dos registradores utilizados na Subrotina da Pilha
		pop r3
		pop r2
		pop r1
		pop r0
		rts



	RLEEncoder: ; <*target, *source, size> | < r2 = SizeOfCompressedData >    ; Encodes data from source to target.; Be carefull, output data here does not have a preditable output lenght 

		push r0
		push r1
		; r2 is output
		push r3
		push r4
		push r5
		push r6
		push r7

		loadn r7, #0

		mov r3, r2
		loadn r2, #0   ; char counter
		loadi r4, r1   ; preivous char
		loadn r6, #0   ; permanent counter

		RLEEncoder_loop:

			cmp r3, r6 ; size / chars read
			jel RLEEncoder_exit

			loadi r5, r1 ; char in source

			cmp r5, r4  ; compare current char with prev char
			jeq RLEEncoder_CharEqual
				; not equal
				storei r0, r2  ; store counter
				inc r0
				inc r7
				storei r0, r4 ; store previous char
				inc r0 ; *count of new char
				inc r7
				mov r4, r5   ; new char being counted
				loadn r2,  #0; re-start count

			RLEEncoder_CharEqual:  
				inc r2 ; count of char
				inc r1 ; *source
				inc r6 ; permanent counter
				
		jmp RLEEncoder_loop
		
		RLEEncoder_exit:

			storei r0, r2  ; store counter
			inc r0
			inc r7
			storei r0, r4 ; store previous char
			inc r0
			inc r7
			push r7
			loadn r7, #0
			storei r0, r7 ; count of 0 = terminator
			pop r7
			inc r7
			mov r2, r7

		pop r7
		pop r6
		pop r5
		pop r4
		pop r3
		; r2 = Size Of Data
		pop r1
		pop r0

		rts

	; Untested and likely to be very wrong
	RLETraverser: ; <Target Index, RLEstring*, Buffer*> , <r3 = Value>

			push r0
			push r1
			push r2
			push r4
			push r5
			push r6

			; What does the buffer coitain. A index in the RLE string and A Target index. What it tells us is 
			; adding up all counts up to where we are in the RLE String is the Target Index Stored. As such we can know 
			; somewhat where we are in the uncompressed RLE string. This speeds up massively reads that are sequential in nature without having to decompress data.
			; And with less overhead.

			; Compared with a full decode, there is no need to the decode the string, and it uses less memory
			; Compared With a Sequential read of the RLE, it speeds up reading things that are close to each other. 

			; get buffered data
		 	loadi r3, r2 ; Buffered Target Index
			inc r2
			loadi r4, r2 ; Buffered RLE index

			mov r6, r3				
			; Compare TargetIndex With its buffered version.
			cmp r0, r3
			jle RLETraverser_Backwards      ; a ascending usecase is more likely, so that must be faster,   ; jumps lesser
			jeq RLETraverser_CasheHit		; jump Equal
			
				; This code is executed if the target index is greater or equal:

				add r4, r1, r4 ; Pointer to memeory at index in RLE. 
				
				; since the index is the count that coresponds to the last parts of the buffered target index, we need to grab the next count
				RLETraverser_FowardsLoop:
				mov r6, r3
				loadi r5, r4  ; Dereference the pointer
				add r6, r6, r5   ; add buffererd count + next count
				cmp r6, r0  ; is the count now bigger or euqal than the target index. If so grab the data, if not loop back
				inc r4
				inc r4 ; the addres of the next count
				jle RLETraverser_FowardsLoop
					; executes if we found the data we need
					inc r4
					loadi r5, r4  ; Grabs the data; will be the output of the function.

					; now we need to buffer the data. 
					sub r4, r4, r1  ; get the index the data is at
					dec r4				; dec to find the count
					storei r2, r4   ; Store Buffered Rle Index
					dec r2  
					storei r2, r6  ; store Buffered Target Index

					mov r3, r5
					jmp RLETraverser_Exit
			
			RLETraverser_Backwards:   ; We will reach here if the data is inside the current cashed reagion or prior to it. 

				inc r4  ; just to make sure the loop starts at the right value
				inc r4
				mov r6, r3
				RLETraverser_BackwardsLoop:
				dec r4
				dec r4
				loadi r5, r4  ; Dereference the pointer
				sub r6, r6, r5   ; add buffererd count - next count
				cmp r6, r0  ; is the count now bigger or euqal than the target index. If so grab the data, if not loop back
				jel RLETraverser_BackwardsLoop
					; executes if we found the data we need
					inc r4
					loadi r5, r4  ; Grabs the data; will be the output of the function.

					; now we need to buffer the data. 
					sub r4, r4, r1  ; get the index the data is at
					dec r4				; dec to find the count
					storei r2, r4   ; Store Buffered Rle Index
					dec r2  
					storei r2, r6  ; store Buffered Target Index

					mov r3, r5
					jmp RLETraverser_Exit

			RLETraverser_CasheHit:

				add r1, r1, r4 ; add buffered index to rle*
				inc r1
				loadi r3, r1

			RLETraverser_Exit:

					pop r6
					pop r5
					pop r4
					pop r2
					pop r1
					pop r0
					rts


	RLEPartialDecoder: ; <Target*, Source*, target start index, Length>, < >   ; Could be buffered or not, i'm not sure which is better for now

		; Takes A RLEstring and decodes from a start index. Can be used to decode a part of interest faster. Could be edited in many ways to suit your code better. 
		; You might perfer to pass a index in the RLE instad of the expedcted decoded string, or whathver else you can cook up.

		rts 

	RLERectangleDecoder: ; <Target*, Source*, Width>
		;Takes a width and decodes in a special way. Supose you have a list 1200 addresses long, it represents the screen or something paralel to it. 
		; You have data that is shaped like a rectangle that is smaller than the screen, now you can save 2 words per unit of height in the encoded data,
		; and probably take less time decoding (Depends on the size, this one takes slightly longer per index)

		rts
; ------ Example Data
;
;	RLETraverser buffer ; since counts wil
;





; ----- Tests: DO NOT COPY FROM HERE ON
;
;	 DO NOT COPY DO NOT COPY DO NOT COPY
;

		; Test DATA     ; DATA is arranged like this to make it easier to visualy comapre the memeory to verify results
			DecodeTarget: var #100 
			TestData1: var #11     ; Rle Compression of 100 long string
				static TestData1 + #0, #20 ; first count
				static TestData1 + #1, #"A"
				static TestData1 + #2, #10
				static TestData1 + #3, #"B"
				static TestData1 + #4, #10
				static TestData1 + #5, #"D"
				static TestData1 + #6, #30
				static TestData1 + #7, #"E"
				static TestData1 + #8, #30
				static TestData1 + #9, #"F"
				static TestData1 + #10, #0
			EncodeTarget: var #100  ; we dont know how big the encoded data will be

			TestTraverseBuffer: var #2
				static TestTraverseBuffer + #0, #0
				static TestTraverseBuffer + #1, #0



		Tests:
			; Test 1 Encode / Decode
				loadn r0, #DecodeTarget
				loadn r1, #TestData1
				call RLEDecoder

				loadn r0, #EncodeTarget
				loadn r1, #DecodeTarget
				loadn r2, #100
				call RLEEncoder


				loadn r0, #EncodeTarget
				loadn r1, #TestData1
				loadn r2, #11
				call MemCompare
				mov r1, r0
				loadn r0, #1
				call CheckIfOne

			; Test2 Traversal


				loadn r0, #0
				loadn r1, #TestData1
				loadn r2, #TestTraverseBuffer
				loadn r4, #"A"

				call RLETraverser
				cmp r3, r4
				jeq Skip_Test2Error1
					loadn r0, #2
					call CallFatalError
					Skip_Test2Error1:

				loadn r0, #20
				loadn r4, #"A"
				call RLETraverser
				cmp r3, r4
				jeq Skip_Test2Error2
					loadn r0, #3
					call CallFatalError
					Skip_Test2Error2:

				loadn r0, #21
				loadn r4, #"B"
				call RLETraverser
				cmp r3, r4
				jeq Skip_Test2Error3
					loadn r0, #4
					call CallFatalError
					Skip_Test2Error3:

				loadn r0, #39
				loadn r4, #"D"
				call RLETraverser
				cmp r3, r4
				jeq Skip_Test2Error4
					loadn r0, #4
					call CallFatalError
					Skip_Test2Error4:

				loadn r0, #10
				loadn r4, #"A"
				call RLETraverser
				cmp r3, r4
				jeq Skip_Test2Error5
					loadn r0, #5
					call CallFatalError
					Skip_Test2Error5:


				loadn r0, #100
				loadn r4, #"F"
				call RLETraverser
				cmp r3, r4
				jeq Skip_Test2Error6
					loadn r0, #6
					call CallFatalError
					Skip_Test2Error6:

				


			
			
			; all tests Passed
			loadn r0, #100
			call CallFatalError



; ##### Dependedncies For Tests


;--------- ErrorSystem     Version 0.2.0
;
;	Minimalist Suit To Allow For Easier Error Catching: 
; 	Is required in all my libraries to allow you to know imediatly 
;	if the error is related to my shitty code or your incredible code
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

			pop r6
			loadn r3, #65535
			loadn r5, #65534

			TraceStack_loop:


				; if r2 = 65535, add word to to TraceBuffer

					pop r2
					cmp r2, r3
					jne TraceStack_skipadd

						;pop r2    ; addres after the sentinel. Its actualy the callers r1
						pop r2    ; Actual return adrres
						call TraceBufferAdd  ; adds r2 to list

						TraceStack_skipadd:


				; if r2 = 65534, exit beacuse we reached the end of the stack
					cmp r2, r5
					jeq TraceStack_exit

				jmp TraceStack_loop
			TraceStack_exit:
			push r6
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

			call TraceBufferPrint
			; Print PC after the message

			halt

		PrintHexNumberOnScreen: ; <Index, Number>, < >   ; Prints On Screen

			push r2
			push r3

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

			pop r3
			pop r2

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
		ErrorAwareCall: ;  < ErrorID, r7 = Which Function to Call (Pointer) > Clobers r1!!! SAVE IT before calling

			loadn r1, #65535   ; marker for call, to guarantee to find the original functions addres
			push r1

			call CallI   ; will call whatver is in r7

			pop r1
			rts

;----------- StackTracer
;
;	For a stack trace that does not have unexpected behaviour we can do either a ring buffer or a just exit when the buffer gets filled
;
;	Lets Exit When Buffer Gets Filled, mostlikely, we will want calls that happenned later
;

	TraceBuffer: var #10   ; Can store up to 10 Traces
		TraceBufferSize: var #1
			static TraceBufferSize + #0, #10
		TraceBufferPointer: var #1
			static TraceBufferPointer + #0, #TraceBuffer


		TraceBufferAdd:  ; < r2 = Data>, <Signal: 1 if full, 0 otherwise>
			
			push r0
			push r1
			push r2

			mov r0, r2

			; check if buffer is full

			loadn r1, #TraceBuffer
			load r2, TraceBufferSize
			add r1, r1, r2


			load r2, TraceBufferPointer

			cmp r1, r2
			jne TraceBufferAdd_Continue

				; code executed if buffer out of space
				
				loadn r0, #1

				pop r2
				pop r1
				pop r0
				rts

				TraceBufferAdd_Continue:

			storei r2, r0 ; store Data in location pointed by TraceBufferPointer
			loadn r0, #0

			inc r2
			store TraceBufferPointer, r2 

			pop r2
			pop r1
			pop r0
			rts

			


		TraceBufferPrint: ; < r0 = index>

			loadn r2, #TraceBuffer
			load r3, TraceBufferPointer
			loadn r4, #35 ; the PrintHex Alredy increments 5


			TraceBufferPrint_loop:

				cmp r2, r3 ; compare with end of buffer
				jeg TraceBufferPrint_exit

				loadi r1, r2
				add r0, r0, r4

				call PrintHexNumberOnScreen

				inc r2

				jmp TraceBufferPrint_loop
				TraceBufferPrint_exit:

				rts



;----------- Error Messages
;
;
	; Error Mesages
	; 
	; Simply declare a String and add it to the Error MessageTable. The value in the + #num will be the Error ID.
	; 
		TestError : string "This is a Error Mesage, PC that called the error: "
		EncodeDecodeError1: string "Test 1 failed"
		TraverseError1 : string "Traverse Failed Test 1"
		TraverseError2 : string "Traverse Failed Test 2"
		TraverseError3 : string "Traverse Failed Test 3"
		TraverseError4 : string "Traverse Failed Test 4"
		TraverseError5 : string "Traverse Failed Test 5"



		AllTestsPassed : string "All Tests Passed, Nice!"


		ErrorMessageTable: var #256

			static ErrorMessageTable + #0, #TestError
			static ErrorMessageTable + #1, #EncodeDecodeError1
			static ErrorMessageTable + #2, #TraverseError1
			static ErrorMessageTable + #3, #TraverseError2
			static ErrorMessageTable + #4, #TraverseError3
			static ErrorMessageTable + #5, #TraverseError4
			static ErrorMessageTable + #6, #TraverseError5		
			static ErrorMessageTable + #100, #AllTestsPassed
