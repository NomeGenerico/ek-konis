# ek-konis
> *From fine dust we assemble*

Repo for libraries in development targeting the **ICMC Processor**:
[Processador-ICMC](https://github.com/simoesusp/Processador-ICMC/tree/master)

---

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
