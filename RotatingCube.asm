.data
stack_beg:
	.word 0:40
stack_end:

InitialVerts: .word 57, 54 #iv1
	      .word 71, 54 #iv2
	      .word 71, 66 #iv3
	      .word 57, 66 #iv4
	      .word 57, 69 #iv5
	      .word 71, 69 #iv6
	      .word 71, 81 #iv7
	      .word 57, 81 #iv8

WorkingVerts: .word 57, 54 #wv1
	      .word 71, 54 #wv2
	      .word 71, 66 #wv3
	      .word 57, 66 #wv4
	      .word 57, 69 #wv5
	      .word 71, 69 #wv6
	      .word 71, 81 #wv7
	      .word 57, 81 #wv8

SpinDir: .word 1
                       
Lines: 	.byte 1, 0 #jump table to working verticies, each number cooresponds to the 8 verts, each row is a line to be drawn
	.byte 1, 2
	.byte 2, 3
	.byte 0, 3
	.byte 0, 4
	.byte 1, 5
	.byte 2, 6
	.byte 3, 7
	.byte 5, 4
	.byte 5, 6
	.byte 6, 7
	.byte 4, 7

	      
.text

la $sp, stack_end
addiu $sp, $sp, -4
Main: 	la $a0, SpinDir
	jal GetUpdate

	
	addi $s6, $0, 8
	
MainLoop: addi $s6, $s6, -1
	  
	  jal ClearBoard
	  
	  la $a0, WorkingVerts
	  la $a1, Lines
	  jal DrawCube

	  la $a0, WorkingVerts
	  la $a1, InitialVerts
	  move $a2, $s6
	  la $a3, SpinDir
	  
	  sw $s6, 0($sp)
	  jal CalcNext
	  lw $s6, 0($sp)

	  bne $s6, $0, MainLoop
	  b Main

DrawCube: #Takes the address of the verticies of a cube in $a0, line information in $a1, draws the cube
	addiu $sp, $sp, -24
	sw $ra, 20($sp)
	sw $a0, 16($sp)
	sw $a1, 4($sp)
	
	move $t0, $a0
	move $t1, $a1
	li $t7, 12 #init loop counter
	
	DCLoop: lb $a0, 0($t1) #load vert offset numbers from Lines
		lb $a1, 1($t1) 
		sll $a0, $a0, 3 #mult by 8 (2 words per vertex)
		sll $a1, $a1, 3
		
		add $a0, $t0, $a0 #add offsets to our working vert base address
		add $a1, $t0, $a1	
		
		sw $t0, 12($sp)
		sw $t7, 8($sp)
		sw $t1, 0($sp)
		jal DrawLine
		lw $t0, 12($sp)
		lw $t7, 8($sp)
		lw $t1, 0($sp)
		addi $t1, $t1, 2 #increment to the next vertex pair in the "lines" list
		addi $t7, $t7, -1
		bne $t7, 0, DCLoop
	
	lw $a1, 4($sp)
	lw $a0, 16($sp)
	lw $ra, 20($sp)
	addiu $sp, $sp, 24
	jr $ra
	
DrawLine: #takes one vertex in $a0, another in $a1 draws a line between them.
	  #uses the equation Yi - Y1 = m(Xi - X1)
	addiu $sp, $sp, -64
	sw $ra, 28($sp)
	sw $a0, 24($sp)
	sw $a1, 20($sp)
	  
	lw $s0, 0($a0) #initial loading
	lw $s1, 4($a0)
	lw $s2, 0($a1)
	lw $s3, 4($a1)
	
	sw $s2, 16($sp) #keep our end vertex around
	sw $s3, 12($sp)
	
	move $a0, $s0 #our initial pixel to be drawn
	move $a1, $s1

	sub $t4, $s3, $s1 #deltaY
	abs $t4, $t4

	sub $t5, $s2, $s0 #deltaX 		#code to find m	
	beq $t5, 0, vertLine #special case for vertical lines
	abs $t5, $t5
	
			  #this is used instead of swapping verts if our vertB is closer to the origin than vertA/the line has negative slope
	slt $t6, $s0, $s2 #for x if this is the case we set an inc variable to 0 else 1
	sll $t6, $t6, 1   #shift left by 2, the var is now either 0 or 2
	addi $t6, $t6 -1  #subtract 1, our x inc var is now either -1 or 1, we'll calc a similar value for y
	
	slt $t7, $s1, $s3
	sll $t7, $t7, 1
	addi $t7, $t7, -1
	
	sub $t0, $t5, $t4 #calc our initial error value
	
	
	
	DLLoop: sw $t4, 8($sp)
		sw $a0, 4($sp)
		sw $a1, 0($sp)
		sw $t0, 32($sp)
		sw $t6, 36($sp)
		sw $t7, 40($sp)
		jal DrawPixel
		lw $t4, 8($sp)
		lw $a0, 4($sp)
		lw $a1, 0($sp)
		lw $t0, 32($sp)
		lw $t6, 36($sp)
		lw $t7, 40($sp)
		
		sll $t1, $t0, 1 #set our running error value
		mul $t3, $t4, -1 #flip sign bit of dy
		
		lw $t2, 16($sp)
		beq $t2, $a0, eqX #check if we have hit the end vertex's y
		stillIn:
		
		blt $t1, $t3, skipErrorY #if running error is > -dY
		
			add $t0, $t0, $t3
			add $a0, $a0, $t6
		
		skipErrorY:
		
		blt $t5, $t1, skipErrorX #if running error is < dX
			
			add $t0, $t0, $t5
			add $a1, $a1, $t7
		
		skipErrorX: b DLLoop

	
	eqX: #we'ev hit vertB's y value check x
		lw $t2, 12($sp)
		beq $t2, $a1, DLEnd #if we've hit y check x if we've hit y and x we're done drawing	
		b stillIn	
		
	vertLine: move $a0, $s0
		  move $a1, $s1
		  move $a3, $t4
		  jal DrawVertLine
	
	DLEnd:
	lw $ra, 28($sp)
	lw $a0, 24($sp)
	lw $a1, 20($sp)		
	addiu $sp, $sp, 64
	jr $ra
	
DrawVertLine: #takes $a0 as x coord, $a1 as y, $a2 as a color, and $a3 as a length, draws a vertical line as output
	addiu $sp, $sp, -24
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	sw $ra, 20($sp)
	
	add $t0, $a3, $0
	VertLoop: sw $t0, 0($sp) #loops drawing a pixel then adding to the y untill we've drawn the line
		   jal DrawPixel
		   lw $t0, 0($sp)
		   addi $a1, $a1, 1
		   addi $t0, $t0, -1
		   bne $t0, 0, VertLoop
		   
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	lw $a3, 16($sp)
	lw $ra, 20($sp)
	addiu $sp, $sp, 24
	jr $ra
	
DrawPixel: #takes $a0 as the x var, $a1 as y, draws a white dot as output
	addiu $sp, $sp, -24
	sw $a0, 8($sp)
	sw $a1, 12($sp)
	sw $a2, 16($sp)
	sw $ra, 20($sp)
	
	jal CalcAddr
	
	addi $t0, $0, 0xffffff
	sw $t0, 0($v0) #actual drawing part
	
	lw $a0, 8($sp)
	lw $a1, 12($sp)
	lw $a2, 16($sp)
	lw $ra, 20($sp)
	addiu $sp, $sp, 24
	jr $ra		
	

CalcAddr: #takes $a0 as the x coord, and $a1 as the y coord, returns the mem addr in $v0
	sll $t0, $a0, 2 #mult x by 4 for byte memory addresses
	sll $t1, $a1, 9 #mult y by 512 (128 = size of 1 line) (128 x 4for byte memory addresses)
	
	add $v0, $t0, $0 #add x to $v0
	add $v0, $v0, $t1 #add y
	addi $v0, $v0, 0x10040000 #add base addr
	
	jr $ra
		

CalcNext:  #Takes the address of the verticies of a cube in $a0, address of initial verts in $a1, loopnum in $a2, rotDir in $a3, changes $a0 to their next position

		blt $a2, 1, resetVerts #if we've done 1/4 a rotation resert our verticies
		
		lw $t1, 0($a3) #check rotation direction
		beq $t1, 1, counterClockWise
		beq $t1, -1, clockWise
		
		counterClockWise:
		blt $a2, 2, CCphase4
		blt $a2, 4, CCphase3
		blt $a2, 6, CCphase2
		b CCphase1
		
		clockWise:
		blt $a2, 2, Cphase4
		blt $a2, 4, Cphase3
		blt $a2, 6, Cphase2
		b Cphase1

		
		CCphase1: lw $t0, 0($a0) #x verts 0 and 4 <
			addi $t0, $t0, -1
			sw $t0,  0($a0)
			sw $t0, 32($a0)
			
			lw $t0, 4($a0) #y vert 0
			addi $t0, $t0, 1
			sw $t0,  4($a0)
		
			lw $t0, 36($a0)#y vert 4
			addi $t0, $t0, 1
			sw $t0, 36($a0) 
			
			lw $t0, 8($a0) #x verts 1 and 5 ^
			addi $t0, $t0, -2
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			#y vert 1
			lw $t0, 12($a0)
			addi $t0, $t0, -1
			sw $t0, 12($a0)
			
			#y vert 5
			lw $t0, 44($a0)
			addi $t0, $t0, -1
			sw $t0, 44($a0)			
			
			
			lw $t0, 16($a0) #x verts 2 and 6 >
			addi $t0, $t0, 1
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#y vert 2
			lw $t0, 20($a0)
			addi $t0, $t0, -1
			sw $t0, 20($a0)
			
			#y vert 6
			lw $t0, 52($a0)
			addi $t0, $t0, -1
			sw $t0, 52($a0)	
			
			#x verts 3 and 7 \/
			lw $t0, 24($a0)
			addi $t0, $t0, 2
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			
			#y vert 3
			lw $t0, 28($a0)
			addi $t0, $t0, 1
			sw $t0, 28($a0)
			
			#y vert 7
			lw $t0, 60($a0)
			addi $t0, $t0, 1
			sw $t0, 60($a0)	
										
			jr $ra
			
		CCphase2: lw $t0, 0($a0) #x verts 0 and 4 <
			addi $t0, $t0, -1
			sw $t0,  0($a0)
			sw $t0, 32($a0)
			
			lw $t0, 4($a0) #y vert 0
			addi $t0, $t0, 2
			sw $t0,  4($a0) 
		
			lw $t0, 36($a0)#y vert 4
			addi $t0, $t0, 2
			sw $t0, 36($a0)
			
	
			lw $t0, 8($a0) #x verts 1 and 5 ^
			addi $t0, $t0, -1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			lw $t0, 16($a0) #x verts 2 and 6 >
			addi $t0, $t0, 1
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#y vert 2
			lw $t0, 20($a0)
			addi $t0, $t0, -2
			sw $t0, 20($a0)
			
			#y vert 6
			lw $t0, 52($a0)
			addi $t0, $t0, -2
			sw $t0, 52($a0)	
			
			#x verts 3 and 7 \/
			lw $t0, 24($a0)
			addi $t0, $t0, 1
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			jr $ra
			
		
		CCphase3: lw $t0, 0($a0) #x verts 0 and 4 <
			addi $t0, $t0, 1
			sw $t0,  0($a0)
			sw $t0, 32($a0)
			
			lw $t0, 4($a0) #y vert 0
			addi $t0, $t0, 2
			sw $t0,  4($a0) 
		
			lw $t0, 36($a0)#y vert 4
			addi $t0, $t0, 2
			sw $t0, 36($a0) 	
	
			lw $t0, 8($a0) #x verts 1 and 5 ^
			addi $t0, $t0, -1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			lw $t0, 16($a0) #x verts 2 and 6 >
			addi $t0, $t0, -1
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#y vert 2
			lw $t0, 20($a0)
			addi $t0, $t0, -2
			sw $t0, 20($a0)
			
			#y vert 6
			lw $t0, 52($a0)
			addi $t0, $t0, -2
			sw $t0, 52($a0)	
			
			#x verts 3 and 7 \/
			lw $t0, 24($a0)
			addi $t0, $t0, 1
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			jr $ra
			
		CCphase4: lw $t0, 0($a0) #x verts 0 and 4 <
			addi $t0, $t0, 1
			sw $t0,  0($a0)
			sw $t0, 32($a0)
			
			lw $t0, 4($a0) #y vert 0
			addi $t0, $t0, 1
			sw $t0,  4($a0)
		
			lw $t0, 36($a0)#y vert 4
			addi $t0, $t0, 1
			sw $t0, 36($a0) 
						
			
			lw $t0, 8($a0) #x verts 1 and 5 ^
			addi $t0, $t0, -1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			#y vert 1
			lw $t0, 12($a0)
			addi $t0, $t0, 1
			sw $t0, 12($a0)
			
			#y vert 5
			lw $t0, 44($a0)
			addi $t0, $t0, 1
			sw $t0, 44($a0)			
			
			
			lw $t0, 16($a0) #x verts 2 and 6 >
			addi $t0, $t0, -1
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#y vert 2
			lw $t0, 20($a0)
			addi $t0, $t0, -1
			sw $t0, 20($a0)
			
			#y vert 6
			lw $t0, 52($a0)
			addi $t0, $t0, -1
			sw $t0, 52($a0)	
			
			#x verts 3 and 7 \/
			lw $t0, 24($a0)
			addi $t0, $t0, 2
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			
			#y vert 3
			lw $t0, 28($a0)
			addi $t0, $t0, -1
			sw $t0, 28($a0)
			
			#y vert 7
			lw $t0, 60($a0)
			addi $t0, $t0, -1
			sw $t0, 60($a0)	
										
			jr $ra
			
		Cphase1: lw $t0, 0($a0) #x verts 0 and 4 ^
			addi $t0, $t0, 2
			sw $t0,  0($a0)
			sw $t0, 32($a0)
			
			lw $t0, 4($a0) #y vert 0
			addi $t0, $t0, -1
			sw $t0,  4($a0) 
		
			lw $t0, 36($a0)#y vert 4
			addi $t0, $t0, -1
			sw $t0, 36($a0) 
						
			
			lw $t0, 8($a0) #x verts 1 and 5 >
			addi $t0, $t0, 1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			#y vert 1
			lw $t0, 12($a0)
			addi $t0, $t0, 1
			sw $t0, 12($a0)
			
			#y vert 5
			lw $t0, 44($a0)
			addi $t0, $t0, 1
			sw $t0, 44($a0)			
			
			
			lw $t0, 16($a0) #x verts 2 and 6 \/
			addi $t0, $t0, -2
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#y vert 2
			lw $t0, 20($a0)
			addi $t0, $t0, 1
			sw $t0, 20($a0)
			
			#y vert 6
			lw $t0, 52($a0)
			addi $t0, $t0, 1
			sw $t0, 52($a0)	
			
			#x verts 3 and 7 <
			lw $t0, 24($a0)
			addi $t0, $t0, -1
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			
			#y vert 3
			lw $t0, 28($a0)
			addi $t0, $t0, -1
			sw $t0, 28($a0)
			
			#y vert 7
			lw $t0, 60($a0)
			addi $t0, $t0, -1
			sw $t0, 60($a0)	
										
			jr $ra
			
		Cphase2: lw $t0, 0($a0) #x verts 0 and 4 ^
			addi $t0, $t0, 1
			sw $t0,  0($a0)
			sw $t0, 32($a0)
				
	
			lw $t0, 8($a0) #x verts 1 and 5 >
			addi $t0, $t0, 1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			#y vert 1
			lw $t0, 12($a0)
			addi $t0, $t0, 2
			sw $t0, 12($a0)
			
			#y vert 5
			lw $t0, 44($a0)
			addi $t0, $t0, 2
			sw $t0, 44($a0)	
			
			lw $t0, 16($a0) #x verts 2 and 6 \/
			addi $t0, $t0, -1
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#x verts 3 and 7 <
			lw $t0, 24($a0)
			addi $t0, $t0, -1
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			
			#y vert 3
			lw $t0, 28($a0)
			addi $t0, $t0, -2
			sw $t0, 28($a0)
			
			#y vert 7
			lw $t0, 60($a0)
			addi $t0, $t0, -2
			sw $t0, 60($a0)	
			jr $ra
			
		
		Cphase3: lw $t0, 0($a0) #x verts 0 and 4 ^
			addi $t0, $t0, 1
			sw $t0,  0($a0)
			sw $t0, 32($a0)
				
	
			lw $t0, 8($a0) #x verts 1 and 5 >
			addi $t0, $t0, -1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			#y vert 1
			lw $t0, 12($a0)
			addi $t0, $t0, 2
			sw $t0, 12($a0)
			
			#y vert 5
			lw $t0, 44($a0)
			addi $t0, $t0, 2
			sw $t0, 44($a0)	
			
			lw $t0, 16($a0) #x verts 2 and 6 \/
			addi $t0, $t0, -1
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#x verts 3 and 7 <
			lw $t0, 24($a0)
			addi $t0, $t0, 1
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			
			#y vert 3
			lw $t0, 28($a0)
			addi $t0, $t0, -2
			sw $t0, 28($a0)
			
			#y vert 7
			lw $t0, 60($a0)
			addi $t0, $t0, -2
			sw $t0, 60($a0)	
			jr $ra
			
		Cphase4: lw $t0, 0($a0) #x verts 0 and 4 ^
			addi $t0, $t0, 2
			sw $t0,  0($a0)
			sw $t0, 32($a0)
			
			lw $t0, 4($a0) #y vert 0
			addi $t0, $t0, 1
			sw $t0,  4($a0) 
		
			lw $t0, 36($a0)#y vert 4
			addi $t0, $t0, 1
			sw $t0, 36($a0) 
						
			
			lw $t0, 8($a0) #x verts 1 and 5 >
			addi $t0, $t0, -1
			sw $t0,  8($a0)
			sw $t0, 40($a0)
			
			#y vert 1
			lw $t0, 12($a0)
			addi $t0, $t0, 1
			sw $t0, 12($a0)
			
			#y vert 5
			lw $t0, 44($a0)
			addi $t0, $t0, 1
			sw $t0, 44($a0)			
			
			
			lw $t0, 16($a0) #x verts 2 and 6 \/
			addi $t0, $t0, -2
			sw $t0, 16($a0)
			sw $t0, 48($a0)
			
			#y vert 2
			lw $t0, 20($a0)
			addi $t0, $t0, -1
			sw $t0, 20($a0)
			
			#y vert 6
			lw $t0, 52($a0)
			addi $t0, $t0, -1
			sw $t0, 52($a0)	
			
			#x verts 3 and 7 <
			lw $t0, 24($a0)
			addi $t0, $t0, 1
			sw $t0, 24($a0)
			sw $t0, 56($a0)
			
			#y vert 3
			lw $t0, 28($a0)
			addi $t0, $t0, -1
			sw $t0, 28($a0)
			
			#y vert 7
			lw $t0, 60($a0)
			addi $t0, $t0, -1
			sw $t0, 60($a0)	
										
			jr $ra
			
	resetVerts: addi $t2, $0, 16
		resetLoop: lw $t1, 0($a1)
			   sw $t1, 0($a0)
			   addi $a1, $a1, 4
			   addi $a0, $a0, 4
			   addi $t2, $t2, -1
			   bne $t2, 0, resetLoop
			   jr $ra
			   		    

			

ClearBoard: #draws black over entire display	
	addi $t0, $0, 262144 # (128 * 4) * (128 * 4) memory spaces to clear
	addiu $t0, $t0, 0x10040000
	BoxLoop: sw $0, 0($t0) #actual drawing part
		 addi $t0, $t0, -4
		 bne $t0, 0x10040000, BoxLoop

	jr $ra
	

####keyboard sim stuff
GetUpdate: #takes addr of updateRot in $a0, updates it if q or e has been pressed
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
	jal GetChar
	add $t0, $0, $0
	add $t1, $0, $0
	
	seq $t0, $v0, 0x71 #set if q
	seq $t1, $v0, 0x65 #set if e
	
	beq $t0, $0, notQ
	addi $t0, $0, 1	#if it is q then store 1 in $a0
	sw $t0, 0($a0)
	lw $ra, 0($sp)		    
	addiu $sp, $sp, 4
	jr $ra
	
  notQ: beq $t1, $0, notE
  	addi $t0, $0, -1	#if it is e then store -1 in $a0
	sw $t0, 0($a0)
	lw $ra, 0($sp)		    
	addiu $sp, $sp, 4
	jr $ra
  
  notE: #a rotation key was not entered continue with current rotation
	lw $ra, 0($sp)		    
	addiu $sp, $sp, 4
	jr $ra

GetChar: #returns $v0 with a typed ascii char, or 0 if none present
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
	
	lui $t0, 0xffff
        lw $t1, 0($t0) #load data
	andi $v0, $t1, 0x0001 #check if data != 0
	beq $v0, $0, endCheck
	lw $v0, 4($t0) #if there is data load it and return
		    
	endCheck: lw $ra, 0($sp)		    
		  addiu $sp, $sp, 4
		  jr $ra

		    

