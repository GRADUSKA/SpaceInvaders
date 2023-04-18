; ==============================
; Définition des constantes
; ==============================
; Mémoire vidéo
; ------------------------------
VIDEO_START 	equ $ffb500 ; Adresse de départ
VIDEO_WIDTH 	equ 480 ; Largeur en pixels
VIDEO_HEIGHT 	equ 320 ; Hauteur en pixels
VIDEO_SIZE 		equ (VIDEO_WIDTH*VIDEO_HEIGHT/8) ; Taille en octets
BYTE_PER_LINE 	equ (VIDEO_WIDTH/8) ; Nombre d'octets par ligne
VIDEO_BUFFER 	equ (VIDEO_START-VIDEO_SIZE) ; Tampon vidéo

WIDTH			equ		0
HEIGHT			equ		2
MATRIX			equ		4

SHIP_STEP		equ		4
SHIP_SHOT_STEP	equ		4

INVADER_SHOT_STEP equ 1 
; ==============================
; Initialisation des vecteurs
; ==============================
				org 	$0
vector_000 		dc.l 	VIDEO_BUFFER ; Valeur initiale de A7
vector_001 		dc.l 	Main ; Valeur initiale du PC

PrintChar       incbin "PrintChar.bin"   

; GAME OVER
;-------------------------------
SHIP_WIN 			equ 100
SHIP_HIT 			equ 75
SHIP_COLLIDING 		equ 42
INVADER_LOW 		equ 18


; Sprites
; ------------------------------
STATE 			equ 	0 ; État de l'affichage
X 				equ 	2 ; Abscisse
Y 				equ 	4 ; Ordonnée
BITMAP1 		equ 	6 ; Bitmap no 1
BITMAP2 		equ 	10 ; Bitmap no 2
HIDE 			equ 	0 ; Ne pas afficher le sprite
SHOW 			equ 	1 ; Afficher le sprite
SIZE_OF_SPRITE 	equ 	14 ; Taille d'un sprite en octets

; Envahisseurs
; ------------------------------
INVADER_PER_LINE 	equ 10
INVADER_PER_COLUMN 	equ 5
INVADER_COUNT 		equ INVADER_PER_LINE*INVADER_PER_COLUMN
INVADER_SHOT_MAX	equ 5

MovingSprite 		dc.w SHOW
					dc.w 0,152
					dc.l InvaderB1_Bitmap
					dc.l 0
					
FixedSprite 		dc.w SHOW
					dc.w 228,152
					dc.l InvaderA1_Bitmap
					dc.l 0

INVADER_STEP_X 		equ 4
INVADER_STEP_Y 		equ 8
INVADER_X_MIN 		equ 0
INVADER_X_MAX 		equ (VIDEO_WIDTH-(INVADER_PER_LINE*32))

BONUS_STEP_X		equ	8
BONUS_STEP_Y		equ	4
BONUS_X_MIN			equ 0
BONUS_X_MAX 		equ VIDEO_WIDTH
BONUS_Y_MIN			equ	0
BONUS_Y_MAX			equ	VIDEO_HEIGHT
; Touches du clavier
; ------------------------------
SPACE_KEY 		equ 	$420
LEFT_KEY 		equ 	$46f
UP_KEY 			equ 	$470
RIGHT_KEY 		equ 	$471
DOWN_KEY 		equ 	$472
; ==============================
; Programme principal
; ==============================
			org 	$500
			
Main 		
			move.b	#0,IsColliding
			move.b	#42,WithBonus
\bonus
			lea	dybp,a0
			move.b #10,d1
            move.b #39,d2
            jsr     Print
			jsr PrintDYPN
			jsr PrintDYPB
			jsr PrintShip
			jsr PrintShipShot
			jsr BufferToScreen
			jsr MoveShip
			jsr	MoveShipShot
			jsr	NewShipShot
			lea.l	ShipShot,a1
			lea.l	DYPN,a2
			jsr	IsSpriteColliding
			beq	\Withbonus
			
			lea.l	ShipShot,a1
			lea.l	DYPB,a2
			jsr IsSpriteColliding
			beq	\Withoutbonus
			bra \bonusloop
			
\Withbonus
			move.b #1,WithBonus
			move.w #HIDE,STATE(a1)
			bra	\init
\Withoutbonus
			move.b #0,WithBonus
			move.w #HIDE,STATE(a1)
			bra	\init
			
\bonusloop
			cmp.b	#42,WithBonus
			beq		\bonus
\init
			jsr InitInvaders
			jsr InitInvaderShots
						
\loop 		jsr PrintShip
			jsr PrintShipShot
			jsr PrintInvaders
			jsr PrintInvaderShots
			jsr PrintBonus
			jsr BufferToScreen
			
			jsr DestroyInvaders
			jsr DestroyInvaders2
			jsr DestroyInvaders3
			
			jsr MoveShip
			jsr MoveInvaders
			jsr MoveBonus
			lea.l	ShipShot,a1
			lea.l	Bonus,a2
			jsr	IsSpriteColliding
			beq	\collision
			move.b	IsColliding,d5
			and.b	WithBonus,d5
			cmp.b	#1,d5
			bne		\uno
			jsr	MoveShipShot
			jsr	MoveShipShot2
			jsr	MoveShipShot3
			jsr MoveInvaderShots
			jsr	NewShipShot
			jsr NewInvaderShot
			jsr	NewShipShot2
			jsr	NewShipShot3
			
			jsr SpeedInvaderUp
			jsr IsGameOver
			beq \game_over
			bra \loop
			
\uno	
			jsr	MoveShipShot
			jsr MoveInvaderShots
			jsr	NewShipShot
			jsr NewInvaderShot
			jsr IsGameOver
			beq \game_over
			bra \loop
			
			
\collision
			move.b	#1,IsColliding
			move.w #HIDE,STATE(a1)
			move.w #HIDE,STATE(a2)
			bra \loop
			
\game_over
			lea     win,a0
            cmp.l   #SHIP_WIN,d0
            beq     \print
            lea     lose,a0
            
\print      move.b #20,d1
            move.b #39,d2
            jsr     Print
            
            illegal			
			
;		

; ==============================
; Sous-programmes
; ==============================

Ship 		dc.w SHOW
			dc.w (VIDEO_WIDTH-24)/2,VIDEO_HEIGHT-32
			dc.l Ship_Bitmap
			dc.l 0
			
ShipShot 	dc.w HIDE
			dc.w 0,0
			dc.l ShipShot_Bitmap
			dc.l 0

ShipShot2 	dc.w HIDE
			dc.w 0,0
			dc.l ShipShot_Bitmap
			dc.l 0

ShipShot3 	dc.w HIDE
			dc.w 0,0
			dc.l ShipShot_Bitmap
			dc.l 0
			

FillScreen		
			move.l	a0,-(a7)
			move.l	#$ffb500,a0

\loop		cmpa.l	#$fffffc,a0
			beq		\quit
			move.l 	d0,(a0)+
			bra 	\loop
\quit		
			move.l d0,(a0)
			move.l	(a7)+,a0
			rts

PixelToByte 
			addq.w 	#7,d3
			
			lsr.w 	#3,d3
			
			rts
CopyBitmap 
			movem.l d3/d4/a0/a1,-(a7)
			
			move.w 	WIDTH(a0),d3
			jsr 	PixelToByte
			
			move.w 	HEIGHT(a0),d4
			subq.w 	#1,d4
			
			lea 	MATRIX(a0),a0
\loop 
			jsr 	CopyLine
			
			adda.l 	#BYTE_PER_LINE,a1
			
			dbra d4,\loop
			
			movem.l (a7)+,d3/d4/a0/a1
			rts

PixelToAddress 
			movem.l d1/d2,-(a7)
			
			move.w d1,d0
			lsr.w #3,d1
			andi.w #%111,d0
		
			mulu.w #BYTE_PER_LINE,d2
			
			lea VIDEO_BUFFER,a1
			adda.w d1,a1
			adda.l d2,a1
			
			movem.l (a7)+,d1/d2
			rts
			
CopyLine 
			movem.l d1-d4/a1,-(a7)
			
			subq.w #1,d3
\loop 
			move.b (a0)+,d1
			move.b d1,d2
			
			lsr.b d0,d1
			
			moveq.l #8,d4
			sub.w d0,d4
			lsl.b d4,d2
			
			or.b d1,(a1)+
			or.b d2,(a1)
			
			dbra d3,\loop
			
			movem.l (a7)+,d1-d4/a1
			rts	

PrintBitmap
			movem.l d0/a1,-(a7)

			jsr PixelToAddress

			jsr CopyBitmap
\quit 
			movem.l (a7)+,d0/a1
			rts
			
ClearScreen
			move.l	d0,-(a7)
			
			moveq.l	#0,d0
			jsr FillScreen
			
			move.l	(a7)+,d0
			rts
			
BufferToScreen
			movem.l	a0/a1/d7,-(a7)
			
			lea		VIDEO_BUFFER,a0
			
			lea		VIDEO_START,a1
			
			move.l	#(VIDEO_SIZE/4)-1,d7
			
\loop		move.l	(a0),(a1)+
			
			clr.l	(a0)+
			
			dbra	d7,\loop
			movem.l (a7)+,a0-a1/d7
			rts
PrintSprite 
			movem.l d1/d2/a0,-(a7)
			cmp.w #HIDE,STATE(a1)
			beq \quit
			move.w 	X(a1),d1
			move.w 	Y(a1),d2
			movea.l BITMAP1(a1),a0
			jsr 	PrintBitmap
\quit 
			movem.l (a7)+,d1/d2/a0
			rts

IsOutOfX
			move.l	d1,-(a7)
			tst.w	d1
			bmi		\true
			add.w	WIDTH(a0),d1
			cmp.w	#VIDEO_WIDTH,d1
			bhi		\true
			
\false
			move.l	(a7)+,d1
			andi.b	#%11111011,ccr
			rts
	
\true	
			move.l	(a7)+,d1
			ori.b	#%00000100,ccr
			rts

IsOutOfY
			move.l	d2,-(a7)
			tst.w	d2
			bmi		\true
			add.w	HEIGHT(a0),d2
			cmp.w	#VIDEO_HEIGHT,d2
			bhi		\true
			
\false
			move.l	(a7)+,d2
			andi.b	#%11111011,ccr
			rts
	
\true	
			move.l	(a7)+,d2
			ori.b	#%00000100,ccr
			rts

IsOutOfScreen
			jsr 	IsOutOfX
			beq		\quit
			jsr		IsOutOfY
\quit
			rts
MoveSprite 
			movem.l d1/d2/a0,-(a7)
			
			add.w 	X(a1),d1
			add.w 	Y(a1),d2
			
			movea.l BITMAP1(a1),a0
			
			jsr 	IsOutOfScreen
			beq 	\false
			
			move.w 	d1,X(a1)
			move.w 	d2,Y(a1)

\true 
			ori.b 	#%00000100,ccr
			bra 	\quit
\false 
			andi.b 	#%11111011,ccr

\quit 		movem.l (a7)+,d1/d2/a0
			rts

MoveSpriteKeyboard 
			movem.l d1/d2,-(a7)
			
			clr.w d1
			clr.w d2
\up 

			tst.b UP_KEY
			beq \down
			sub.w #1,d2
\down 
			tst.b DOWN_KEY
			beq \right
			add.w #1,d2
\right 
			tst.b RIGHT_KEY
			beq \left
			add.w #1,d1
\left 
			tst.b LEFT_KEY
			beq \next
			sub.w #1,d1
\next 
			jsr MoveSprite
			movem.l (a7)+,d1/d2
			rts

GetRectangle
			move.l 	a0,-(a7)

			move.w 	X(a0),d1

			move.w 	Y(a0),d2

			movea.l	 BITMAP1(a0),a0

			move.w 	WIDTH(a0),d3
			add.w 	d1,d3
			subq.w 	#1,d3

			move.w 	HEIGHT(a0),d4
			add.w 	d2,d4
			subq.w 	#1,d4

			movea.l (a7)+,a0
			rts

IsSpriteColliding 
			movem.l d1-d4/a0,-(a7)
			
			cmp.w #SHOW,STATE(a1)
			bne \quit
			cmp.w #SHOW,STATE(a2)
			bne \quit
			
			movea.l a1,a0
			jsr GetRectangle
			movem.w d1-d4,-(a7)
			
			movea.l a2,a0
			jsr GetRectangle
			
			cmp.w 4(a7),d1
			bgt \false
			
			cmp.w 6(a7),d2
			bgt \false
			
			cmp.w (a7),d3
			blt \false
			
			cmp.w 2(a7),d4
			blt \false
\true 
			ori.b #%00000100,ccr
			bra \cleanStack
\false 
			andi.b #%11111011,ccr
\cleanStack 
			adda.l #8,a7
\quit 
			movem.l (a7)+,d1-d4/a0
			rts

PrintShip
			move.l a1,-(a7)

			lea Ship,a1
			jsr PrintSprite

			move.l (a7)+,a1
			rts

PrintBonus
			move.l a1,-(a7)

			lea Bonus,a1
			jsr PrintSprite

			move.l (a7)+,a1
			rts

PrintDYPN
			move.l a1,-(a7)

			lea DYPN,a1
			jsr PrintSprite

			move.l (a7)+,a1
			rts

PrintDYPB
			move.l a1,-(a7)

			lea DYPB,a1
			jsr PrintSprite

			move.l (a7)+,a1
			rts

MoveShip 
			movem.l d1/d2/a1,-(a7)

			clr.w d1
			clr.w d2
\right 
			
			tst.b RIGHT_KEY
			beq \left
			add.w #SHIP_STEP,d1
\left 
			
			tst.b LEFT_KEY
			beq \next
			sub.w #SHIP_STEP,d1
\next 
			lea Ship,a1
			jsr MoveSprite
			
			movem.l (a7)+,d1/d2/a1
			rts
PrintShipShot
			movem.l a1-a3,-(a7)
			
			lea	ShipShot,a1
			jsr PrintSprite
			
			lea	ShipShot2,a1
			jsr	PrintSprite
			
			lea	ShipShot3,a1
			jsr	PrintSprite
			
			movem.l (a7)+,a1-a3
			rts
			
MoveShipShot 
			movem.l a1/d1/d2,-(a7)

			lea ShipShot,a1
			
			cmp.w #HIDE,STATE(a1)
			beq \quit
			
			clr.w d1
			move.w #-SHIP_SHOT_STEP,d2
			jsr MoveSprite
			beq \quit
\outOfScreen 
			move.w #HIDE,STATE(a1)
\quit 
			movem.l (a7)+,a1/d1/d2
			rts

MoveShipShot2 
			movem.l a1/d1/d2,-(a7)

			lea ShipShot2,a1
			
			cmp.w #HIDE,STATE(a1)
			beq \quit
			
			clr.w d1
			move.w #-SHIP_SHOT_STEP,d2
			jsr MoveSprite
			beq \quit
\outOfScreen 
			move.w #HIDE,STATE(a1)
\quit 
			movem.l (a7)+,a1/d1/d2
			rts

MoveShipShot3 
			movem.l a1/d1/d2,-(a7)

			lea ShipShot3,a1
			
			cmp.w #HIDE,STATE(a1)
			beq \quit
			
			clr.w d1
			move.w #-SHIP_SHOT_STEP,d2
			jsr MoveSprite
			beq \quit
\outOfScreen 
			move.w #HIDE,STATE(a1)
\quit 
			movem.l (a7)+,a1/d1/d2
			rts

NewShipShot 
			movem.l d1-d3/a0/a1,-(a7)
			
			tst.b SPACE_KEY
			beq \quit
			
			lea ShipShot,a0
			cmp.w #SHOW,STATE(a0)
			beq \quit
			
			lea Ship,a1
			move.w X(a1),X(a0)
			move.w Y(a1),Y(a0)
			
			movea.l BITMAP1(a1),a1
			move.w WIDTH(a1),d1
			
			movea.l BITMAP1(a0),a1
			move.w HEIGHT(a1),d2
			move.w WIDTH(a1),d3
			
			sub.w d3,d1
			lsr.w #1,d1
			add.w d1,X(a0)
			
			sub.w d2,Y(a0)
			
			move.w #SHOW,STATE(a0)
\quit
			movem.l (a7)+,d1-d3/a0/a1
			rts

NewShipShot2 
			movem.l d1-d4/a0/a1,-(a7)
			
			tst.b SPACE_KEY
			beq \quit
			
			lea ShipShot2,a0
			cmp.w #SHOW,STATE(a0)
			beq \quit
			
			lea Ship,a1
			move.w X(a1),d4
			add.w  #10,d4
			move.w d4,X(a0)
			move.w Y(a1),Y(a0)
			
			movea.l BITMAP1(a1),a1
			move.w WIDTH(a1),d1
			
			movea.l BITMAP1(a0),a1
			move.w HEIGHT(a1),d2
			move.w WIDTH(a1),d3
			
			sub.w d3,d1
			lsr.w #1,d1
			add.w d1,X(a0)
			
			sub.w d2,Y(a0)
			
			move.w #SHOW,STATE(a0)
\quit
			movem.l (a7)+,d1-d4/a0/a1
			rts
			
NewShipShot3 
			movem.l d1-d4/a0/a1,-(a7)
			
			tst.b SPACE_KEY
			beq \quit
			
			lea ShipShot3,a0
			cmp.w #SHOW,STATE(a0)
			beq \quit
			
			lea Ship,a1
			move.w X(a1),d4
			sub.w  #10,d4
			move.w d4,X(a0)
			move.w Y(a1),Y(a0)
			
			movea.l BITMAP1(a1),a1
			move.w WIDTH(a1),d1
			
			movea.l BITMAP1(a0),a1
			move.w HEIGHT(a1),d2
			move.w WIDTH(a1),d3
			
			sub.w d3,d1
			lsr.w #1,d1
			add.w d1,X(a0)
			
			sub.w d2,Y(a0)
			
			move.w #SHOW,STATE(a0)
\quit
			movem.l (a7)+,d1-d4/a0/a1
			rts


InitInvaderLine
			movem.l d1-d3/d7/a0,-(a7)

			move.w #INVADER_PER_LINE-1,d7

			move.w #32,d3
			sub.w WIDTH(a1),d3
			lsr.w #1,d3
			add.w d3,d1
\loop 
			move.w #SHOW,STATE(a0)
			move.w d1,X(a0)
			move.w d2,Y(a0)
			move.l a1,BITMAP1(a0)
			move.l a2,BITMAP2(a0)

			adda.l #SIZE_OF_SPRITE,a0
			addi.w #32,d1
			dbra d7,\loop

			movem.l (a7)+,d1-d3/d7/a0
			rts

PrintInvaders 
			movem.l d7/a1,-(a7)
		
			move.w #INVADER_COUNT-1,d7
		
			lea Invaders,a1
\loop 
			jsr PrintSprite
			
			adda.l #SIZE_OF_SPRITE,a1
			dbra d7,\loop
			
			movem.l (a7)+,d7/a1
			rts

InitInvaders
			movem.l d1/d2/a0-a2,-(a7)
			
			move.w InvaderX,d1
			move.w InvaderY,d2
			lea Invaders,a0
			lea InvaderC1_Bitmap,a1
			lea InvaderC2_Bitmap,a2
			jsr InitInvaderLine
			
			add.w #32,d2
			adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
			lea InvaderB1_Bitmap,a1
			lea InvaderB2_Bitmap,a2
			jsr InitInvaderLine
			
			add.w #32,d2
			adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
			jsr InitInvaderLine
			
			add.w #32,d2
			adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
			lea InvaderA1_Bitmap,a1
			lea InvaderA2_Bitmap,a2
			jsr InitInvaderLine
			
			add.w #32,d2
			adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
			jsr InitInvaderLine

			movem.l (a7)+,d1/d2/a0-a2
			rts

GetInvaderStep
			movem.l d0/d3,-(a7)
			
			move.w InvaderX,d0
			add.w InvaderCurrentStep,d0

			cmpi.w #INVADER_X_MIN,d0
			blt \change

			cmpi.w #INVADER_X_MAX,d0
			bgt \change
\noChange 
			move.w InvaderCurrentStep,d1
			clr.w d2
			move.w d0,InvaderX
			bra \quit
\change 
			clr.w d1
			move.w #INVADER_STEP_Y,d2
			move.w #INVADER_STEP_X,d3
			;add.w d3,InvaderX
			add.w d2,InvaderY
			neg.w InvaderCurrentStep
\quit
			movem.l (a7)+,d0/d3
			rts

MoveAllInvaders 
			movem.l d1/d2/a1/d7,-(a7)
			jsr GetInvaderStep			
			lea Invaders,a1			
			move.w #INVADER_COUNT-1,d7
\loop 
			cmp.w #HIDE,STATE(a1)
			beq \continue	
			jsr MoveSprite
			jsr SwapBitmap
\continue 
			adda.l #SIZE_OF_SPRITE,a1			
			dbra d7,\loop
\quit
			movem.l (a7)+,d1/d2/a1/d7
			rts
			
MoveInvaders
			subq.w #1,\skip
			bne \quit
			
			move.w InvaderSpeed,\skip
			
			jsr MoveAllInvaders
\quit
			rts
			
\skip 		dc.w 1

GetBonusStep
			movem.l d0/d3/d4,-(a7)
			
			move.w BonusX,d0
			move.w BonusY,d4
			add.w BonusCurrentStepX,d0
			add.w BonusCurrentStepY,d4

			cmpi.w #BONUS_X_MIN,d0
			blt \changeX

			cmpi.w #BONUS_X_MAX,d0
			bgt \changeX
			
			cmpi.w #BONUS_Y_MIN,d4
			blt \changeY

			cmpi.w #BONUS_Y_MAX,d4
			bgt \changeY
\noChange 
			move.w BonusCurrentStepX,d1
			clr.w  d2
			move.w BonusCurrentStepY,d2
			move.w d0,BonusX
			move.w d4,BonusY
			bra \quit
\changeX 
			clr.w d1
			move.w #BONUS_STEP_Y,d2
			move.w #BONUS_STEP_X,d3
			add.w d2,BonusY
			neg.w BonusCurrentStepX
			bra	\quit
\changeY
			clr.w d2
			move.w #BONUS_STEP_X,d1
			move.w #BONUS_STEP_Y,d3
			add.w d1,BonusX
			neg.w BonusCurrentStepY
\quit
			movem.l (a7)+,d0/d3/d4
			rts

MoveBonus
			movem.l d1/d2/a1/d7,-(a7)
			
			jsr GetBonusStep
			
			lea Bonus,a1
			
\loop 
			cmp.w #HIDE,STATE(a1)
			beq \continue
			
			jsr MoveSprite
			jsr SwapBitmap
\continue 
			adda.l #SIZE_OF_SPRITE,a1
			
\quit
			movem.l (a7)+,d1/d2/a1/d7
			rts

			
SwapBitmap 
			move.l BITMAP1(a1),-(a7)
			move.l BITMAP2(a1),BITMAP1(a1)
			move.l (a7)+,BITMAP2(a1)
			rts
			
DestroyInvaders 
			movem.l d7/a1/a2,-(a7)
			
			lea Invaders,a1
			lea ShipShot,a2
			
			move.w #INVADER_COUNT-1,d7
\loop 
			jsr IsSpriteColliding
			bne \next
\colliding 
			move.w #HIDE,STATE(a1)
			move.w #HIDE,STATE(a2)
			subq.w #1,InvaderCount
\next 
			adda.l #SIZE_OF_SPRITE,a1
			dbra d7,\loop
\quit 
			movem.l (a7)+,d7/a1/a2
			rts

DestroyInvaders2 
			movem.l d7/a1/a2,-(a7)
			
			lea Invaders,a1
			lea ShipShot2,a2
			
			move.w #INVADER_COUNT-1,d7
\loop 
			jsr IsSpriteColliding
			bne \next
\colliding 
			move.w #HIDE,STATE(a1)
			move.w #HIDE,STATE(a2)
			subq.w #1,InvaderCount
\next 
			adda.l #SIZE_OF_SPRITE,a1
			dbra d7,\loop
\quit 
			movem.l (a7)+,d7/a1/a2
			rts

DestroyInvaders3 
			movem.l d7/a1/a2,-(a7)
			
			lea Invaders,a1
			lea ShipShot3,a2
			
			move.w #INVADER_COUNT-1,d7
\loop 
			jsr IsSpriteColliding
			bne \next
\colliding 
			move.w #HIDE,STATE(a1)
			move.w #HIDE,STATE(a2)
			subq.w #1,InvaderCount
\next 
			adda.l #SIZE_OF_SPRITE,a1
			dbra d7,\loop
\quit 
			movem.l (a7)+,d7/a1/a2
			rts
			
SpeedInvaderUp
			movem.l d0/a0,-(a7)
			clr.w InvaderSpeed
			move.w InvaderCount,d0
			lea SpeedLevels,a0
\loop
			addq.w #1,InvaderSpeed
			cmp.w (a0)+,d0
			bhi \loop
			movem.l (a7)+,d0/a0
			rts
			
InitInvaderShots 
			movem.l d7/a0,-(a7)
			
			lea InvaderShots,a0
			
			move.w #INVADER_SHOT_MAX-1,d7
\loop
			move.w #HIDE,STATE(a0)
			move.l #InvaderShot1_Bitmap,BITMAP1(a0)
			move.l #InvaderShot2_Bitmap,BITMAP2(a0)
			
			adda.l #SIZE_OF_SPRITE,a0
			dbra d7,\loop
			
			movem.l (a7)+,d7/a0
			rts
			
GetHiddenShot
			move.l d7,-(a7)
			
			lea InvaderShots,a0
			
			move.w #INVADER_SHOT_MAX-1,d7
\loop 
			cmp.w #HIDE,STATE(a0)
			beq \true
			
			adda.l #SIZE_OF_SPRITE,a0
			dbra d7,\loop
\false 
			move.l (a7)+,d7
			andi.b #%11111011,ccr
			rts
\true 
			move.l (a7)+,d7
			ori.b #%00000100,ccr
			rts
			
ConnectInvaderShot 
			movem.l d1/d2/d3/a0/a1,-(a7)
			
			cmpi.w #HIDE,STATE(a1)
			beq \quit
			
			jsr GetHiddenShot
			bne \quit
			
			move.w X(a1),X(a0)
			move.w Y(a1),Y(a0)
		
			movea.l BITMAP1(a1),a1
			move.w WIDTH(a1),d1
			move.w HEIGHT(a1),d2
			
			movea.l BITMAP1(a0),a1
			move.w WIDTH(a1),d3
			
			sub.w d3,d1
			lsr.w #1,d1
			
			add.w d1,X(a0)
			add.w d2,Y(a0)
			
			move.w #SHOW,STATE(a0)
\quit 
			movem.l (a7)+,d1/d2/d3/a0/a1
			rts

Random 		move.l \old,d0
			muls.w #16807,d0
			and.l #$7fffffff,d0
			move.l d0,\old
			lsr.l #4,d0
			and.l #$7ff,d0
			rts
\old 		dc.l 425625

NewInvaderShot
		movem.l d0/a1,-(a7)

		jsr Random

		cmp.w #INVADER_COUNT,d0
		bhs \quit
		
		mulu.w #SIZE_OF_SPRITE,d0
		lea Invaders,a1
		adda.l d0,a1
		
		jsr ConnectInvaderShot
\quit 
		movem.l (a7)+,a1/d0
		rts
		
PrintInvaderShots 
		movem.l d7/a1,-(a7)
		
		move.w #INVADER_SHOT_MAX-1,d7
		
		lea InvaderShots,a1
\loop 
		jsr PrintSprite
		
		adda.l #SIZE_OF_SPRITE,a1
		dbra d7,\loop
		
		movem.l (a7)+,d7/a1
		rts
		
MoveInvaderShots
		movem.l a1/d7/d1/d2,-(a7)

		move.w #INVADER_SHOT_MAX-1,d7

		lea InvaderShots,a1
\loop
		cmp.w #HIDE,STATE(a1)
		beq \continue
	
		clr.w d1
		move.w #INVADER_SHOT_STEP,d2
		jsr MoveSprite
		beq \continue
\outOfScreen 
		move.w #HIDE,STATE(a1)
\continue 
		adda.l #SIZE_OF_SPRITE,a1
		dbra d7,\loop

		jsr SwapInvaderShots
		
		movem.l (a7)+,a1/d7/d1/d2
		rts
		
SwapInvaderShots
		subq.w #1,\skip
		bne \quit

		move.w #6,\skip

		movem.l d7/a1,-(a7)

		move.w #INVADER_SHOT_MAX-1,d7

		lea InvaderShots,a1
\loop
		jsr SwapBitmap
		adda.l #SIZE_OF_SPRITE,a1
		dbra d7,\loop

		movem.l (a7)+,d7/a1
\quit 	rts

\skip 	dc.w 6

IsShipHit
		movem.l d7/a1/a2,-(a7)

		lea Ship,a1

		lea InvaderShots,a2

		move.w #INVADER_SHOT_MAX-1,d7
\loop 
		jsr IsSpriteColliding
		beq \true
		
		adda.l #SIZE_OF_SPRITE,a2
		dbra d7,\loop
\false
		andi.b #%11111011,ccr
		bra \quit
\true 
		ori.b #%00000100,ccr
\quit 	movem.l (a7)+,d7/a1/a2
		rts
		
IsShipColliding 
		movem.l d7/a1/a2,-(a7)
		
		lea Ship,a1
	
		lea Invaders,a2
		
		move.w #INVADER_COUNT-1,d7
\loop 
		jsr IsSpriteColliding
		beq \true
		
		adda.l #SIZE_OF_SPRITE,a2
		dbra d7,\loop
\false
		andi.b #%11111011,ccr
		bra \quit
\true 
		ori.b #%00000100,ccr
\quit 	movem.l (a7)+,d7/a1/a2
		rts
		
IsInvaderTooLow 
		movem.l d7/a0,-(a7)

		lea Invaders,a0

		move.w #INVADER_COUNT-1,d7
\loop 
		cmp.w #HIDE,STATE(a0)
		beq \next
		
		cmpi.w #280,Y(a0)
		bhi \true
\next 
		adda.l #SIZE_OF_SPRITE,a0
		dbra d7,\loop
\false 
		andi.b #%11111011,ccr
		bra \quit
\true 
		ori.b #%00000100,ccr
\quit 	movem.l (a7)+,d7/a0
		rts

Print   
        movem.l d0/d1/a0,-(a7)
\loop   
        
        move.b (a0)+,d0
        beq  \quit
       
        jsr     PrintChar
        addq.b #1,d1
        bra  \loop
\quit   
        movem.l (a7)+,d0/d1/a0
        rts

         
                
                
IsGameOver		movem.l d7/a0,-(a7)

				lea Invaders,a0
				
                move.w 		#INVADER_COUNT-1,d7
\loop           
                cmp.w 		#HIDE,STATE(a0)
                bne   		\touched 
                adda.l 		#SIZE_OF_SPRITE,a0
                dbra 		d7,\loop
                
                move.l 		#SHIP_WIN,d0
                bra 		\true


\touched		jsr 		IsShipHit
				move.l 		#SHIP_HIT,a0
				beq 		\true
				jsr 		IsShipColliding
				move.l 		#SHIP_COLLIDING,a0
				beq 		\true
				jsr 		IsInvaderTooLow
				move.l 		#INVADER_LOW,a0
				beq 		\true
				


\false          ; Renvoie false .
                andi.b #%11111011,ccr
                bra \quit
\true           ; Renvoie true.
                ori.b #%00000100,ccr
\quit           movem.l (a7)+,d7/a0
                rts
; ==============================
; Données
; ==============================
InvaderA1_Bitmap		
					dc.w    24,16
                    dc.b    %00000000,%11111111,%00000000
                    dc.b    %00000000,%11111111,%00000000
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111100,%00111100,%00111111
                    dc.b    %11111100,%00111100,%00111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %00000011,%11000011,%11000000
                    dc.b    %00000011,%11000011,%11000000
                    dc.b    %00001111,%00111100,%11110000
                    dc.b    %00001111,%00111100,%11110000
                    dc.b    %11110000,%00000000,%00001111
                    dc.b    %11110000,%00000000,%00001111

InvaderB1_Bitmap     
					dc.w    22,16
                    dc.b    %00001100,%00000000,%11000000
                    dc.b    %00001100,%00000000,%11000000
                    dc.b    %00000011,%00000011,%00000000
                    dc.b    %00000011,%00000011,%00000000
                    dc.b    %00001111,%11111111,%11000000
                    dc.b    %00001111,%11111111,%11000000
                    dc.b    %00001100,%11111100,%11000000
                    dc.b    %00001100,%11111100,%11000000
                    dc.b    %00111111,%11111111,%11110000
                    dc.b    %00111111,%11111111,%11110000
                    dc.b    %11001111,%11111111,%11001100
                    dc.b    %11001111,%11111111,%11001100
                    dc.b    %11001100,%00000000,%11001100
                    dc.b    %11001100,%00000000,%11001100
                    dc.b    %00000011,%11001111,%00000000
                    dc.b    %00000011,%11001111,%00000000

InvaderC1_Bitmap     
					dc.w    16,16
                    dc.b    %00000011,%11000000
                    dc.b    %00000011,%11000000
                    dc.b    %00001111,%11110000
                    dc.b    %00001111,%11110000
                    dc.b    %00111111,%11111100
                    dc.b    %00111111,%11111100
                    dc.b    %11110011,%11001111
                    dc.b    %11110011,%11001111
                    dc.b    %11111111,%11111111
                    dc.b    %11111111,%11111111
                    dc.b    %00110011,%11001100
                    dc.b    %00110011,%11001100
                    dc.b    %11000000,%00000011
                    dc.b    %11000000,%00000011
                    dc.b    %00110000,%00001100
                    dc.b    %00110000,%00001100

InvaderA2_Bitmap 
					dc.w 	24,16
					dc.b 	%00000000,%11111111,%00000000
					dc.b 	%00000000,%11111111,%00000000
					dc.b 	%00111111,%11111111,%11111100
					dc.b 	%00111111,%11111111,%11111100
					dc.b 	%11111111,%11111111,%11111111
					dc.b 	%11111111,%11111111,%11111111
					dc.b 	%11111100,%00111100,%00111111
					dc.b 	%11111100,%00111100,%00111111
					dc.b 	%11111111,%11111111,%11111111
					dc.b 	%11111111,%11111111,%11111111
					dc.b 	%00001111,%11000011,%11110000
					dc.b 	%00001111,%11000011,%11110000
					dc.b 	%00111100,%00111100,%00111100
					dc.b 	%00111100,%00111100,%00111100
					dc.b 	%00001111,%00000000,%11110000
					dc.b 	%00001111,%00000000,%11110000

InvaderB2_Bitmap 
					dc.w 	22,16
					dc.b 	%00001100,%00000000,%11000000
					dc.b 	%00001100,%00000000,%11000000
					dc.b 	%00000011,%00000011,%00000000
					dc.b 	%00000011,%00000011,%00000000
					dc.b 	%11001111,%11111111,%11001100
					dc.b 	%11001111,%11111111,%11001100
					dc.b 	%11001100,%11111100,%11001100
					dc.b 	%11001100,%11111100,%11001100
					dc.b 	%00111111,%11111111,%11110000
					dc.b 	%00111111,%11111111,%11110000
					dc.b 	%00001111,%11111111,%11000000
					dc.b 	%00001111,%11111111,%11000000
					dc.b 	%00001100,%00000000,%11000000
					dc.b 	%00001100,%00000000,%11000000
					dc.b 	%00110000,%00000000,%00110000
					dc.b 	%00110000,%00000000,%00110000

InvaderC2_Bitmap 
					dc.w 	16,16
					dc.w 	%0000001111000000
					dc.w 	%0000001111000000
					dc.w 	%0000111111110000
					dc.w 	%0000111111110000
					dc.w 	%0011111111111100
					dc.w 	%0011111111111100
					dc.w 	%1111001111001111
					dc.w 	%1111001111001111
					dc.w 	%1111111111111111
					dc.w 	%1111111111111111
					dc.w 	%0000110000110000
					dc.w 	%0000110000110000
					dc.w 	%0011001111001100
					dc.w 	%0011001111001100
					dc.w 	%1100110000110011
					dc.w 	%1100110000110011
Ship_Bitmap         
					dc.w    24,14
                    dc.b    %00000000,%00011000,%00000000
                    dc.b    %00000000,%00011000,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    
Invader_A 			dc.w 	SHOW 
					dc.w 	0,0 
					dc.l 	InvaderA1_Bitmap 
					dc.l 	InvaderA2_Bitmap




					
ShipShot_Bitmap 	dc.w 2,6
					dc.b %11000000
					dc.b %11000000
					dc.b %11000000
					dc.b %11000000
					dc.b %11000000
					dc.b %11000000
					
InvaderShot1_Bitmap dc.w 4,6
					dc.b %11000000
					dc.b %11000000
					dc.b %00110000
					dc.b %00110000
					dc.b %11000000
					dc.b %11000000

InvaderShot2_Bitmap dc.w 4,6
					dc.b %00110000
					dc.b %00110000
					dc.b %11000000
					dc.b %11000000
					dc.b %00110000
					dc.b %00110000

Bonus1_Bitmap		dc.w 16,13
					dc.b    %00111111,%11100000
                    dc.b    %01000000,%00010000
                    dc.b    %10000000,%00001000
                    dc.b    %10111111,%11101000
                    dc.b    %10000000,%00001000
                    dc.b    %10000000,%00001000
                    dc.b    %10111111,%11101000
                    dc.b    %10000000,%00001000
                    dc.b    %10000000,%00001000
                    dc.b    %10111111,%11101000
                    dc.b    %10000000,%00001000
                    dc.b    %01000000,%00010000
                    dc.b    %00111111,%11100000

Bonus2_Bitmap		dc.w 16,13
					dc.b    %00111111,%11100000
                    dc.b    %01000000,%00010000
                    dc.b    %10000000,%00001000
                    dc.b    %10010010,%01001000
                    dc.b    %10010010,%01001000
                    dc.b    %10010010,%01001000
                    dc.b    %10010010,%01001000
                    dc.b    %10010010,%01001000
                    dc.b    %10010010,%01001000
                    dc.b    %10010010,%01001000
                    dc.b    %10000000,%00001000
                    dc.b    %01000000,%00010000
                    dc.b    %00111111,%11100000
                    
DYPB_Bitmap			dc.w 16,11
					dc.b	%01100000,%00000100
					dc.b	%01010000,%00000100
					dc.b	%01001000,%00000100
					dc.b	%01000100,%00000100
					dc.b	%01000010,%00000100
					dc.b	%01000001,%00000100
					dc.b	%01000000,%10000100
					dc.b	%01000000,%01000100
					dc.b	%01000000,%00100100
					dc.b	%01000000,%00010100
					dc.b	%01000000,%00001100



DYPN_Bitmap			dc.w 16,11
					dc.b	%01000000,%01000000
					dc.b	%00100000,%10000000
					dc.b	%00010001,%00000000
					dc.b	%00001010,%00000000
					dc.b	%00000100,%00000000
					dc.b	%00000100,%00000000
					dc.b	%00000100,%00000000
					dc.b	%00000100,%00000000
					dc.b	%00000100,%00000000
					dc.b	%00000100,%00000000
					dc.b	%00000100,%00000000



DYPB				dc.w	SHOW
					dc.w	100,100
					dc.l	DYPB_Bitmap
					dc.l	0
					
DYPN				dc.w	SHOW
					dc.w	200,100
					dc.l	DYPN_Bitmap
					dc.l	0
					
					
Bonus 				dc.w 	SHOW 
					dc.w 	150,150
					dc.l 	Bonus1_Bitmap 
					dc.l 	Bonus2_Bitmap
			
InvaderSpeed 		dc.w 8 ; Vitesse (1 -> 8)
SpeedLevels 		dc.w 1,5,10,15,20,25,35,50 ; Paliers de vitesse
Invaders 			ds.b INVADER_COUNT*SIZE_OF_SPRITE
InvaderCount 		dc.w INVADER_COUNT
IsColliding			ds.b 1
WithBonus			ds.b 0
InvaderX 			dc.w (VIDEO_WIDTH-(INVADER_PER_LINE*32))/2 ; Abscisse globale
InvaderY 			dc.w 32 ; Ordonnée globale
InvaderCurrentStep 	dc.w INVADER_STEP_X ; Pas en cours
BonusX				dc.w (VIDEO_WIDTH-(11))/2
BonusY				dc.w 32
BonusCurrentStepX	dc.w BONUS_STEP_X
BonusCurrentStepY	dc.w BONUS_STEP_Y
InvaderShots 		ds.b SIZE_OF_SPRITE*INVADER_SHOT_MAX

win                  dc.b "===== YOU WIN  =====",0
lose                 dc.b "===== YOU LOSE =====",0

dybp                 dc.b "PLAY WITH THE BONUS ? Y (YES) OR N (NO)",0
;😃 ❤️ ❤️ 😡
