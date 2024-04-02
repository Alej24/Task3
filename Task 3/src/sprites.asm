.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
pad1: .res 1
playerWalkState: .res 1
playerFrameCounter: .res 1
.exportzp player_x, player_y, pad1, playerWalkState, playerFrameCounter

.segment "CONST"
standingState = $00
firstStepState = $01
secondStepState = $02
animationSpeed = $20  ; Higher value means slower animation speed

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import readController1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00

  ; Read controller
  JSR readController1

  ; Update tiles *after* DMA transfer
  JSR updatePlayer
  JSR draw_player

  LDA #20
  LDA #$00
  RTI
.endproc

.import reset_handler

.export main
.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  ; Increase frame counters
  INC playerFrameCounter

  ; Delay to control the update frequency
  LDX #180  ; The higher the vlue the longer the delay
delayLoop:
  DEX
  BNE delayLoop
  
  ; Check if it's time to update animation frame
  LDA playerFrameCounter
  CMP animationSpeed
  BNE skipUpdatePlayer

  ; Reset frame counter
  LDA #$00
  STA playerFrameCounter

  ; Update animation frame
  JSR updatePlayer

  skipUpdatePlayer:

  ; Continue with the main loop
  JMP forever
.endproc

.proc updatePlayer
  PHP  ; Start by saving registers,
  PHA  
  TXA
  PHA
  TYA
  PHA

checkLeft:
  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ checkRight ; If result is zero, left not pressed
  DEC player_x    ; If the branch is not taken, move player left
checkRight:
  LDA pad1
  AND #BTN_RIGHT
  BEQ checkUp
  INC player_x
checkUp:
  LDA pad1
  AND #BTN_UP
  BEQ checkDown
  DEC player_y
checkDown:
  LDA pad1
  AND #BTN_DOWN
  BEQ doneChecking
  INC player_y

doneChecking:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA playerWalkState
  AND #$03 ; Keep playerWalkState between 0 and 3

checkRight:
  ; Check if the player is moving to the right
  LDA pad1
  AND #BTN_RIGHT
  BEQ checkLeft ; Skip to check left if right button is not pressed
  INC playerWalkState ; Increase walk state only if moving right
  JMP drawSpriteRight ; Jump to draw sprite facing right

checkLeft:
  ; Check if the player is moving to the left
  LDA pad1
  AND #BTN_LEFT
  BEQ checkUp ; Skip to check up if left button is not pressed
  INC playerWalkState ; Increase walk state only if moving left
  JMP drawSpriteLeft ; Jump to draw sprite facing left

checkUp:
  ; Check if the player is moving up
  LDA pad1
  AND #BTN_UP
  BEQ checkDown ; Skip to check down if up button is not pressed
  INC playerWalkState ; Increase walk state only if moving up
  JMP drawSpriteUp ; Jump to draw sprite facing up

checkDown:
  ; Check if the player is moving down
  LDA pad1
  AND #BTN_DOWN
  BEQ drawSpriteRight ; Skip to draw sprite right if down button is not pressed
  INC playerWalkState ; Increase walk state only if moving down
  JMP drawSpriteDown ; Jump to draw sprite facing down

drawSpriteRight:
  ; Increase the walk state for the player only when moving right
  LDA playerWalkState
  AND #$03 ; Keep playerWalkState between 0 and 3
  CMP #standingState
  BEQ standing_right
  CMP #firstStepState
  BEQ step1_right
  CMP #secondStepState
  BEQ step2_right

  step2_right:
  ; write player ship tile numbers
  LDA #$04
  STA $0201
  LDA #$05
  STA $0205
  LDA #$0a
  STA $0209
  LDA #$0b
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  step1_right:
  ; write player ship tile numbers
  LDA #$04
  STA $0201
  LDA #$05
  STA $0205
  LDA #$08
  STA $0209
  LDA #$09
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  standing_right:
  ; write player ship tile numbers
  LDA #$04
  STA $0201
  LDA #$05
  STA $0205
  LDA #$06
  STA $0209
  LDA #$07
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

drawSpriteLeft:
  
  ; Increase the walk state for the player only when moving left
  LDA playerWalkState
  AND #$03 ; Keep playerWalkState between 0 and 3
  CMP #standingState
  BEQ standing_left
  CMP #firstStepState
  BEQ step1_left
  CMP #secondStepState
  BEQ step2_left

  step2_left:
  ; write player ship tile numbers
  LDA #$0c
  STA $0201
  LDA #$0d
  STA $0205
  LDA #$12
  STA $0209
  LDA #$13
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  step1_left:
  ; write player ship tile numbers
  LDA #$0c
  STA $0201
  LDA #$0d
  STA $0205
  LDA #$10
  STA $0209
  LDA #$11
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  standing_left:
  ; write player ship tile numbers
  LDA #$0c
  STA $0201
  LDA #$0d
  STA $0205
  LDA #$0e
  STA $0209
  LDA #$0f
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

drawSpriteUp:
  
  ; Increase the walk state for the player only when moving up
  LDA playerWalkState
  AND #$03 ; Keep playerWalkState between 0 and 3
  CMP #standingState
  BEQ standing_up
  CMP #firstStepState
  BEQ step1_up
  CMP #secondStepState
  BEQ step2_up

  step2_up:
  ; write player ship tile numbers
  LDA #$28
  STA $0201
  LDA #$29
  STA $0205
  LDA #$2a
  STA $0209
  LDA #$2b
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  step1_up:
  ; write player ship tile numbers
  LDA #$24
  STA $0201
  LDA #$25
  STA $0205
  LDA #$26
  STA $0209
  LDA #$27
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  standing_up:
  ; write player ship tile numbers
  LDA #$20
  STA $0201
  LDA #$21
  STA $0205
  LDA #$22
  STA $0209
  LDA #$23
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

drawSpriteDown:
  
  ; Increase the walk state for the player only when moving down
  LDA playerWalkState
  AND #$03 ; Keep playerWalkState between 0 and 3
  CMP #standingState
  BEQ standing_down
  CMP #firstStepState
  BEQ step1_down
  CMP #secondStepState
  BEQ step2_down

  step2_down:
  ; write player ship tile numbers
  LDA #$1c
  STA $0201
  LDA #$1d
  STA $0205
  LDA #$1e
  STA $0209
  LDA #$1f
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  step1_down:
  ; write player ship tile numbers
  LDA #$18
  STA $0201
  LDA #$19
  STA $0205
  LDA #$1a
  STA $0209
  LDA #$1b
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

  standing_down:
  ; write player ship tile numbers
  LDA #$14
  STA $0201
  LDA #$15
  STA $0205
  LDA #$16
  STA $0209
  LDA #$17
  STA $020d
  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  JMP drawDone

drawDone:
  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $2c, $12, $23, $27
.byte $2c, $2b, $3c, $39
.byte $2c, $0c, $07, $13
.byte $2c, $19, $09, $29

.byte $2c, $0f, $07, $30
.byte $2c, $19, $09, $29
.byte $2c, $19, $09, $29
.byte $2c, $3a, $24, $11

.segment "CHR"
.incbin "spriteMovement.chr"
