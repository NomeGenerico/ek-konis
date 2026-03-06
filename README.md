# ek-konis
From fine dust we assemble

Repo for libraries im developing targeting the ICMC Processor:
https://github.com/simoesusp/Processador-ICMC/tree/master

1 - ErrorHandling
  Easy way to trow fatal errors. Customize error messages and IDs. Prints Last Called Function (Unless you clober the stack you degenerate)

In Active Development: 

2 - MemoryHandler
    Easily Declare Objects In memeory, Basicaly free and malloc. Little guardrails, but pretty usefull

3 - RLECompression
    Compact any data you want, depending on structure could achieve as much as 88% saved. If anyone wants to implement bit packing, feel free.

4 - DirtyRectangleRendering 
    Everyone Knows Programers are lazy. Unfortunatly sometimes we are too lazy and ofload our work into the hardware. Not anymore, Easily rerender only what has changed. Supoorts for 3 Layers, Default     colors for layers, Custom collors per screen index, Etc. this way we can be lazier, faster!

5 - UiSystem
    Create Interactable Menus, with a simple selection and confirm actions, and selection highlingting. easily extendable. Give a RLE comprresed
    string of the Apearence, Define slectable regions, Write a function for each selectable Region, and it just works. Also stack as many elements as you want (as long as you want less than 20 (Can be     Changed!))

6 - ObjectSystem 
    Everything you need: Create Objects (You will write the constructor tough :[ ), Dispatch Behaviour Functions Easily, Store Custum Data Per Object that can be useed by its functions

