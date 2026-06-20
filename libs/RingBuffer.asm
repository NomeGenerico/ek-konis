;#Include ErrorHandler.asm
;#Include String.asm

;START OF LIB
;-------------- Ring Buffer
;
;   Simple Ring Buffer implementation.
;
;       [Read Head][Write Head][Data][Data][Data]...[Data]
;       Size = Buffer Size + 2, because we need to store the read and write heads in the first two memory slots.
;
;       index 0 is the oldest data, while index size -1 is the newest data.
;

; private
RingBufferWrapPointer:   ; < r0 = *RingBuffer, r1 = size, r2 = *pointer to wrap>, <r2 = wrapped *pointer>

        push r3



        add r3, r0, r1
        cmp r2, r3
        jel RingBufferWrapPointer_Exit  ; if the pointer is still within the buffer, we can exit
            sub r2, r2, r1  ; if the pointer has gone past the buffer, we wrap it around by subtracting the buffer size
        RingBufferWrapPointer_Exit:

        pop r3


    rts

; RingBuffer Read and write must  not use regsiters below r3, as they are used by the wrap pointer function.

; Public
RingBufferPeek:   ; < r0 = *RingBuffer, r1 = size, r2 = index to read from >, <r3 = value at index>
        
        ; behavior depens if read head is ahead of write head or not. If read head is ahead, it means that the buffer has wrapped around and the data is split in two parts. If read head is behind, it means that the data is in a single contiguous block.
        ; if read head = write head, it means that the buffer is empty

        push r0
        push r4
        push r5

        load r4, r0   ; read head
        inc r0
        load r5, r0   ; write head
        inc r0 ; the start of the data is at r0

        cmp r4, r5
            jgr RingBufferPeek_ReadHeadAhead
            jeq RingBufferPeek_InvalidIndex

        RingBufferPeek_WriteHeadAhead:
            add r4, r4, r2   ; we can just add the index to the read head to get the value

            ; since write head is ahead of read head, we know that the data is in a single contiguous block, so we don't need to worry about wrapping around just checking if it is still valid
            cmp r4, r5
                jge RingBufferPeek_InvalidIndex

                loadi r3, r4 ; get the value at the index
                jmp RingBufferPeek_Exit 


        RingBufferPeek_ReadHeadAhead:

            ; since read head is ahead of write head, it means that the data is split in two parts, one from read head to the end of the buffer, and another from the start of the buffer to the write head. We need to check if the index is in the first part or the second part.
            add r4, r4, r2
            add r5, r0, r1 ; end of buffer

            cmp r4, r5   ; check if index is within the first part
                jge RingBufferPeek_CheckSecondPart ; r4 >= end of buffer, so it is in the second part

                loadi r3, r4
                jmp RingBufferPeek_Exit

            RingBufferPeek_CheckSecondPart:

                sub r4, r4, r1   ; if it is not within the first part, we need to wrap around by subtracting the buffer size

                dec r0
                load r5, r0   ; we need to reload the write head since we modified r5
                cmp r4, r5   ; check if index is still valid after wrapping around
                    jge RingBufferPeek_InvalidIndex
                loadi r3, r4
                jmp RingBufferPeek_Exit


        RingBufferPeek_InvalidIndex:

            ; handle error, index is out of bounds
            ; we can just return 0 or some error code, but for now we will just return 0
            loadn r3, #0

        RingBufferPeek_Exit:

        pop r5
        pop r4
        pop r0

        rts


RingBufferPush:   ; < r0 = *RingBuffer, r1 = size, r2 = value to write >, <r3 = 1 if push was successful, 0 if buffer is full>

        push r0
        push r4
        push r5

        load r4, r0   ; read head
        inc r0
        load r5, r0   ; write head
        inc r0 ; the start of the data is at r0

        




    rts

RingBufferPop: 
    rts