# ek-konis
> *From fine dust we assemble*

Repo for libraries in development targeting the **ICMC Processor**:
[Processador-ICMC](https://github.com/simoesusp/Processador-ICMC/tree/master)

---

Students:
Ricardo Mozart Torres (16899607)
Mateus Bastazini (16391529)
Otávio Augusto Biasi (15004590)

## Linker

**Usage:**

In your `.asm` file:
```asm
;#Include String.asm
```

In terminal:
```bash
python linker.py input.asm output.asm
```

---

CPU/
    An optimized version of the ICMC processor developed
    alongside these libraries. Some instructions run up to 2 cycles
    faster than the reference implementation.

---

## Libraries

### Available & Working

#### 0 — Control
Provides a indirect call instruction

#### 1 — Strings
Simple `FString` implementation, easily extendable.
> TODO: edit the assembler to make string declarations easier.

#### 2 — ErrorHandling
Easy way to throw fatal errors. Customize error messages and IDs. Prints last called function *(unless you clobber the stack, you degenerate)*.

#### 3 — RLECompression
Compact any data you want — depending on structure, could achieve up to **88% space saved**.
> Feel free to implement bit packing if you're up for it.

---

### In Active Development

#### 4 — Memory Handler
Easily declare objects in memory — basically `free` and `malloc`. Few guardrails, but pretty useful.

#### 5 — DirtyRectangleRendering
Everyone knows programmers are lazy. Now your code can be lazy too. Easily re-render only what has changed. Doing the absolute minimum since 2026

Features:
- Supports different layers with z ordering
- Default colors per layer
- Custom colors per screen index
- Be lazier, *faster*

#### 6 — UiSystem
Create interactable menus with simple selection, confirm actions, and selection highlighting. Easily extendable.

How it works:
1. Provide an **RLE-compressed string** of the appearance
2. Define selectable regions
3. Write a function for each selectable region
4. It just works™

Stack as many elements as you want *(default limit: 20 — configurable)*.

#### 7 — ObjectSystem
Everything you need:
- Create objects *(you'll still write the constructor yourself 😔)*
- Dispatch behaviour functions easily
- Store custom data per object, accessible by its functions via a Object ID


Implementation of CPU: 

Compared to the reference implementation of the CPU, this one has several speedups, it reduces the cicle count of instructions like push, pop, call, rts, etc. Bringing them all to a constant of two cicles per instructions. The only instructions not yet optimized to two cycles were: load, store, trs. specificaly for load and store, they rely on two memory reads plus another write or read to memory, it is impossible to do so without changing how the CPU reads RAM. Allowing it to read 32 bits, would fix such a problem. RTS was optimized from 4 cicles to 3, but could likely be spedup further by making call store an already incremented PC. 

Another instruction that also does not have a 2 cycle count is the newly created SOUNDI instruction. It relies on sending two words of data to a separate device in the FPGA project. 

Implementation of the Sound-Card:

At the current moment, the sound card has a few main parts:

A frequency generator : Recieves the number from the CPU and will generate a sine wave with that freaquency. It has a resolution of 0.1 hz + a small <1% error. It works by adding a number to a 24 bit register every single clock cicle. from how far along the counter is until it overflows, we infer where in the wave we should be at the moment and perform a lookup. So the waveform is fully customizable as well. 

It also has a "Maquina de Controle", this way it can handle its own operation completly independent of the CPU, it also reduces the number of new instructions needed to be registred in the CPU it self, as everything falls under a single SOUND instruction for the CPU. 

A mixer: it blends the signals from different chanels 
