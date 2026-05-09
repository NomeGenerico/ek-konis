
;--------- Memory
;
;
;

	MemMove: ; <*dest, *source, size>    

		push r4

		cmp r0, r1
		jgr MemMove_BackwardsLoop

		loadn r3, #0
		MemCopy_Loop:
			cmp r2, r3
			jeq MemCopy_LoopExit

			loadi r4, r1
			storei r0, r4

			inc r0
			inc r1
			dec r2

			jmp MemCopy_Loop
			MemCopy_LoopExit:

		jmp MemMove_Exit

		MemMove_BackwardsLoop:

		loadn r3, #0
		add r1, r1, r2
		dec r1
		add r0, r0, r2
		dec r0

		MemCopy_BackwardsLoop:
			cmp r2, r3
			jeq MemCopy_BackwardsLoopExit

			loadi r4, r1
			storei r0, r4

			dec r0
			dec r1
			dec r2

			jmp MemCopy_BackwardsLoop
			MemCopy_BackwardsLoopExit:


		MemMove_Exit:
		pop r4

		rts



;
;--------- ObjectPool
; 
	ObjectPool: var #2000   ; stores Constructed Objects
    ObjectPoolSize: var #1
	ObjectPoolPointer: var #1
	ObjectPoolFragments: var #50    ; These Arrays must be kept clean
	ObjecPoolFragmentsPointer: var #1

		static ObjectPoolSize + #0, #2000

	ObjectIDArray: var #256
    ObjectSizeArray: var #256  ; stores Size of objects 
	MaxObjectCount: var #1
	


	OnbjectIDCleanUpFlag: var #1    ; 1 if the ID array must be cleaned up

   ; Initialization
	static ObjectPoolFragments + #0, #ObjectPool
    static ObjectPoolFragments + #1, #ObjectPool
	static MaxObjectCount + #0 , #256

		
	; cleanup

		CleanAllObjects:

			; re Initialize everything as clean

			rts

		DeFragObjectPool:    ; Id's Should be Preserved, Pointing to their new places in memory

			; get pointers
			; call FragmentMerger

			rts

		CleanArray:		; Id's Can Change    . This might never get used, because how would we change The ids in the objects, It would require a lot more data and cicles.
		
			; get pointers
			; call FragmentMerger

			rts


	
	
	
	; Constructor Will Build the Object

	; Can be expanded to allow for dynamic objects and memory cleanup, not curently needed

		; Private
		ObjectPoolReserve:   ; <Lenght> / < , , RootMemoryAddres>

			push r1
			push r2
			push r3
			push r4
			push r5

			; Find First Gap The Object Can Fit into
			loadn r1, #ObjectPoolFragments
			loadn r4, #0

			ObjectPoolReserve_loop:

				inc r1
				loadi r2, r1
				inc r1
				loadi r3, r4

				; check if we reched the end
				cmp r3, r4
				jeq ObjectPoolReserve_MemReserve

				; check if free space is big enought
				sub r5, r3, r2
				cmp r5, r0
				jeq ObjectPoolReserve_MemReserve

				jmp ObjectPoolReserve_loop

			; put it there and update frags and ID

			ObjectPoolReserve_MemReserve: 

				; r2, r3  | end of frag , start of frag

				dec r1 
				add r5, r2, r0
				storei r1, r5     ; r5 - new end of frag

				; the frags could be cleaned up if r5 = r3  

				inc r2 ; this is the pointer that should be passed to ID

			pop r5
			pop r4
			pop r3
			pop r2
			pop r1

			rts

		; Private
		ObjectIDReserve:    ; < > / < , IDMemAddres>

			push r0

			push r2
			push r3
			push r4
			push r5

			mov r6, r2

			; Find First Gap The ID Can Fit into

			loadn r0, #1   
			loadn r1, #ObjectIDArray
			
			loadn r2, #256
			add r3, r1, r2
			loadn r2, #0

			ObjectIDReserve_loop:

				inc r1

				cmp r1, r3 				; check if we reched the end of the array
				jeq ObjectIDReserve_ArrayFull



				; check for free IDs
				loadi r4, r1
				cmp r4, r2
				jeq ObjectIDReserve_Exit ; if ID pointes to 0, aloc there

				jmp ObjectIDReserve_loop


			ObjectIDReserve_ArrayFull:

				; Trow Error
				jmp ObjectIDReserve_Exit

			ObjectIDReserve_Exit:

			; r1 is the IDAddres or a error was trown

			pop r5
			pop r4
			pop r3
			pop r2

			pop r0
			rts

		; Public
		ObjectPoolAlocate:  ; <Size> / <ID>

			push r1Lenght
			push r2

			call ObjectPoolReserve

			call ObjectIDReserve

			; alocate

				storei r1, r2   ; ID <- RootMem

			; Store Size

				load r2, MaxObjectCount
				add r1, r1, r2 ; since The Size and ID arrays are next in memeory ID + MaxObjectCount = Size
				storei r1, r0
				sub r1, r1, r2

			; return ID

				load r0, #ObjectIDArray
				sub r0, r1, r0

				; r0 is the ID

			pop r2
			pop r1

			rts

		; Private
		FragmentMerger: ; <Array*, ArrayEnd**>

			push r2
			push r3
			push r4
			push r5

			; r0 = start* of first fragment
			mov r5, r1
			loadi r4, r5

			FragmentMerger_Loop:
			inc r0
			cmp r4, r0 ; If End Reached, Exit
			jeq FragmentMerger_Exit
			loadi r2, r0
			inc r0
			loadi r3, r0
			cmp r3, r2 ; If Equal, merge
			jeq FragmentMerger_Merge
			jmp FragmentMerger_Loop
			FragmentMerger_Merge:
			sub r2, r4, r0 ; lengh 
			mov r1, r0
			dec r0
			dec r0
			call MemMove
			dec r4
			dec r4
			dec r0
			jmp FragmentMerger_Loop
			FragmentMerger_Exit: ; Once all eligible fragments merged, Exit.

			storei r5, r4
			pop r5
			pop r4
			pop r3
			pop r2
			rts


		; Public
		ObjectPoolDeAllocate: ; <ID> ; <>

			; Frag Object Pool
			; Find Frag That Contains Data, Find Size of data, Split or Shrink It
			; No need to clean up data or Size

			; Frag IDArray
			; Find Frag That contains ID, Split It
			; store IDArray* + ID, 0 ; needs to clean up; Instead Of Zero, it could be a thing that causes an error if read from. 

		rts
	
	;


; -------- RingBuffer
;
;
;
;

