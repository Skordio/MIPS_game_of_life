# File:		life_age.asm
# Author:	Steven Wells
# Description:	This program simulates Conway's game life


# CONSTANTS

# syscall codes
PRINT_STR 	= 4004
READ_STR	= 4003

# Linux stuff
STDIN 	= 0
STDOUT 	= 1

# input check values
MAX_BOARD_SIZE 		= 30
MIN_BOARD_SIZE 		= 4
ONE_PLUS_MAX_GENS 	= 21


.data
	integerInputBuffer:		.space 16
	integerInputBufferLen:	.word 16

	bannerBorder: 	.asciiz "*************************************\n"
	bannerMiddle: 	.asciiz "****    Game of Life with Age    ****\n"
	bannerLen:		.word 	38
		
	inBoardSizeErr:			.ascii	"WARNING: illegal board size - enter an integer in the range [4, 30]: "
	inBoardSizeErrLen:		.word	69
	inBoardSizePrompt:		.asciiz	"Enter board size: "
	inBoardSizePromptLen:	.word	18
		
	inGenErr: 		.asciiz	"WARNING: illegal number of generations, try again: "
	inGenErrLen:	.word	51
	genPrompt: 		.asciiz	"Enter number of generations to run: "
	genPromptLen: 	.word 	36
		
	# live cell num prompt and error message ########################
	inNumErr:		.asciiz	"WARNING: illegal number of live cells, try again: "
	numPrompt:		.asciiz	"Enter number of live cells: "
		
	# locations prompt and error message ########################
	inLocErr:
		.asciiz	"ERROR: illegal point location\n"
	locPrompt:
		.asciiz	"Start entering locations\n"
		
	gen_header:
		.asciiz	"====    GENERATION "
		
	gen_header_end:
		.asciiz	"    ====\n"
		
	new_line:
		.asciiz	"\n"
		
	# data for the live cell locations: ########################
	live_cells:
		.align 2
		.space 1800
		
	# table A ########################
	table_A:
		.align 2
		.space 900

	# table B ########################
	table_B:
		.align 2
		.space 900
		
	# asciiz stuff needed for printing board
	charA:	.asciiz "A"
	charB:	.asciiz "B"
	charC:	.asciiz "C"
	charD:	.asciiz "D"
	charE:	.asciiz "E"
	charF:	.asciiz "F"
	charG:	.asciiz "G"
	charH:	.asciiz "H"
	charI:	.asciiz "I"
	charJ:	.asciiz "J"
	charK:	.asciiz "K"
	charL:	.asciiz "L"
	charM:	.asciiz "M"
	charN:	.asciiz "N"
	charO:	.asciiz "O"
	charP:	.asciiz "P"
	charQ:	.asciiz "Q"
	charR:	.asciiz "R"
	charS:	.asciiz "S"
	charT:	.asciiz "T"
	charU:	.asciiz "U"
		
	plus:		.asciiz	"+"
	dash:		.asciiz	"-"
	sideBar:	.asciiz	"|"
	emptySpace:	.asciiz " "
		
	ages:	
		.word	charA, charB, charC, charD, charE, charF, charG, charH, charI, charJ
		.word	charK, charL, charM, charN, charO, charP, charQ, charR, charS, charT
		.word	charU
		
.text
	.align	2

	.globl	__start

	__start:
		# canonical entry...
		addi    $sp, $sp, -36  # space for the s registers
		sw      $ra, 0($sp)    # store the ra on the stack
		sw      $s0, 4($sp)
		sw      $s1, 8($sp)
		sw      $s2, 12($sp)
		sw      $s3, 16($sp)
		sw      $s4, 20($sp)
		sw      $s5, 24($sp)
		sw      $s6, 28($sp)
		sw      $s7, 32($sp)

		# Move to the next line in the terminal
		li	$v0, PRINT_STR
		li	$a0, STDOUT
		la	$a1, new_line
		li	$a2, 1
		syscall
		
		# Print game banner
		li	$v0, PRINT_STR
		la	$a1, bannerBorder
		lw	$a2, bannerLen
		syscall

		li	$v0, PRINT_STR
		la	$a1, bannerMiddle	
		syscall

		li	$v0, PRINT_STR
		la	$a1, bannerBorder
		syscall
		
		li	$v0, PRINT_STR
		la	$a1, new_line	
		li	$a2, 1			
		syscall

		# Setup syscall for board size input prompt
		li	$v0, PRINT_STR
		la	$a1, inBoardSizePrompt
		lw	$a2, inBoardSizePromptLen

	_in_board_size_loop:
		syscall

		# Read input from user up to 16 characters
		li	$v0, READ_STR
		li	$a0, STDIN
		la	$a1, integerInputBuffer
		lw	$a2, integerInputBufferLen
		syscall
		
		# Convert input string into integer
		la	$a0, integerInputBuffer
		jal atoi						# after this $v0 should contain the integer representation

		add	$t1, $v0, $zero				# now t1 contains integer representation
		
		addi	$t2, $zero, MAX_BOARD_SIZE 	# t2 is max board size now
		addi	$t3, $zero, MIN_BOARD_SIZE	# t3 is min board size
		
		# Setup to write error message to user if bad input
		li	$v0, PRINT_STR
		li	$a0, STDOUT
		la	$a1, inBoardSizeErr
		lw	$a2, inBoardSizeErrLen
		
		# remember: t1 is user's int, t2 is max, and t3 is min

		slt	$t0, $t2, $t1						# if max is less than input, t0 is 1
		bne	$t0, $zero, _in_board_size_loop		# jump to retry if t0 is 1
		
		slt	$t0, $t1, $t3						# if input is less than min, t0 is 1
		beq	$t0, $zero, _board_size_ok
		j	_in_board_size_loop

	_board_size_ok:	
		move	$s0, $v0	# $s0 is now the user's valid input for the board size
		
		mul		$s1, $s0, $s0	# s1 is now the number of cells on the board
		
		# print generation count input prompt to user
		li	$v0, PRINT_STR
		li	$a0, STDOUT
		la	$a1, genPrompt
		lw	$a2, genPromptLen

	_in_gen_loop:
		# syscall for printing the prompt
		syscall
		
		## fixed up to here #################################

		li	$v0, PRINT_STR
		li	$a0, STDOUT
		la	$a1, new_line
		li	$a2, 1
		syscall
		j _exit

		## fixed up to here #################################

		#li	$v0, READ_INT	# read int, this is the number of generations
		syscall
		
		addi	$t1, $zero, ONE_PLUS_MAX_GENS 	#t1 is 1+max board size now
		la		$a0, inGenErr
		
		#check it is below max
		slt	$t0, $v0, $t1	#if it is less, t0 is 1
		beq	$t0, $zero, _in_gen_loop	#jump to retry if the number is more than max
		
		slt	$t0, $v0, $zero	#if val is less, t0 is 1 and we must error, if 0 it is ok
		
		beq	$t0, $zero, _in_gen_ok
		j	_in_gen_loop

	_in_gen_ok:	
		move	$s2, $v0	# $s2 is now the number of generations we will run for
		
		#now input for the num of live cells
		la	$a0, numPrompt

	_in_num_retry:
		li	$v0, PRINT_STR
		syscall
		#li	$v0, READ_INT	# read int, this is the number of live cells
		syscall
		
		add		$t1, $zero, $s1 	# t1 is max num of cells now
		addi	$t1, $t1, 1		# and now it is 1 more for ease of use
		la		$a0, inNumErr
		
		#check it is below max
		slt	$t0, $v0, $t1	#if it is less, t0 is 1
		beq	$t0, $zero, _in_num_retry	#jump to retry if the number is more than max
		
		slt	$t0, $v0, $zero	#if val is less, t0 is 1 and we must error, if 0 it is ok
		
		beq	$t0, $zero, _in_num_ok
		j	_in_num_retry

	_in_num_ok:	
		move	$s3, $v0	# $s3 is now the number of alive cells for the program to have
		
		# now for the live cell locations
		la	$a0, locPrompt
		li	$v0, PRINT_STR
		syscall

		la		$t6, live_cells	# now t6 has the address of the live cell "array"
		move	$s4, $zero	# s4 will be the amount of live cells we have already entered
		
		j enter_new_live_cell

	enter_new_live_cell_error:
		la	$a0, inLocErr
		li	$v0, PRINT_STR
		syscall
		j _exit		# terminate the program if we get this error

	enter_new_live_cell:
		beq	$s4, $s3, enter_new_live_cell_done
		#li	$v0, READ_INT	# read int, the row for a potential new live cell
		syscall
		move	$t3, $v0	# now t3 is the row for a potential new live cell
		
		#li	$v0, READ_INT	# read int, the row for a potential new live cell
		syscall
		move	$t4, $v0	# now t4 is the col for a potential new live cell
		
		# now check if it is valid
		move	$t5, $zero
		slt	$t5, $t3, $s0	#if row is less than board size, t5 is 1, otherwise it is 0
		beq	$t5, $zero, enter_new_live_cell_error	#jump to error if error
		
		move	$t5, $zero
		slt	$t5, $t4, $s0	#if row is less than board size, t5 is 1, otherwise it is 0
		beq	$t5, $zero, enter_new_live_cell_error	#jump to error if error
		
		move	$a0, $t3	# for the function that checks if it is valid
		move	$a1, $t4
		
		jal	live_cell_check # now if it is still valid v0 is 1
		beq	$v0, $zero, enter_new_live_cell_error
		
		#if we made it all the way down here our new cell is valid
		addi	$s4, $s4, 1
		sw	$a0, 0($t6)
		addi	$t6, $t6, 4
		sw	$a1, 0($t6)
		addi	$t6, $t6, 4
		
		j	enter_new_live_cell

	enter_new_live_cell_done:
		move	$s4, $zero	#not using s4 for anything anymore, it will be used next

		########## input done ####################
		
		# put empty space into the tables
		
		la	$a0, table_A
		jal 	fill_with_emptyspace
		la	$a0, table_B
		jal 	fill_with_emptyspace
		
		#now take the cell locations and put new cells there
		# tools: 	live_cells 
		#		$s3 is num of alive cells
		
		move	$s4, $zero	#s4 will be the counter
		la	$s5, live_cells	#t1 points to the live cells table, increment by 4

	initialize_cells_A:
		beq	$s4, $s3, done_initializing_cells_A
		
		la	$a0, table_A	#initialize into table a
		
		lw	$a1, 0($s5)	# now a1 has the row value	
		addi	$s5, $s5, 4
		
		lw	$a2, 0($s5)	# now a2 has the col value
		
		jal	create_life	#create life
		
		addi	$s5, $s5, 4	# counters
		addi	$s4, $s4, 1
		j	initialize_cells_A

	done_initializing_cells_A:

		#now take the cell locations and put new cells there
		# tools: 	live_cells 
		#		$s3 is num of alive cells
		
		move	$s4, $zero	#s4 will be the counter
		la	$s5, live_cells	#t1 points to the live cells table, increment by 4

	initialize_cells_B:
		beq	$s4, $s3, done_initializing_cells_B
		
		la	$a0, table_B	#initialize into table a
		
		lw	$a1, 0($s5)	# now a1 has the row value	
		addi	$s5, $s5, 4
		
		lw	$a2, 0($s5)	# now a2 has the col value
		
		jal	create_life	#create life
		
		addi	$s5, $s5, 4	# counters
		addi	$s4, $s4, 1
		j	initialize_cells_B

	done_initializing_cells_B:

		move	$s4, $zero
		move	$s5, $zero	#done with these registers
		
		

		# now it is time to move onto the main loop of the program
		la	$a0, table_A
		move	$a1, $zero
		jal 	print_board

		move	$s4, $zero	# s4 will be the generation counter

	main_loop:
		beq	$s4, $s2, _exit
		la	$a0, table_B
		la	$a1, table_A
		jal	print_board
		jal	next_gen
		
		la	$a0, table_B
		addi	$a1, $s4, 1
		jal	print_board
		addi	$s4, $s4, 1
		
		beq	$s4, $s2, _exit
		la	$a0, table_A
		la	$a1, table_B
		jal 	next_gen
		
		
		la	$a0, table_A
		addi	$a1, $s4, 1
		jal	print_board
		addi	$s4, $s4, 1
		
		j	main_loop
		

	_exit:
		# canonical exit...
		#
		li		$v0, 4001		# nominal exit
		li		$a0, 0			# 0 for no error
		
		lw      $s7, 32($sp)	# clean up stack
		lw      $s6, 28($sp)
		lw      $s5, 24($sp)
		lw      $s4, 20($sp)
		lw      $s3, 16($sp)
		lw      $s2, 12($sp)
		lw      $s1, 8($sp)
		lw      $s0, 4($sp)
		lw      $ra, 0($sp)
		addi    $sp, $sp, 36

		# jr	$ra
		syscall
	#
	########## end main ##########

	###### begin functions #######
	#
	#
	# Name:		live_cell_check
	#
	# Description:	Traverse the already recorded live cell locations to see if a
	#				new one coincides with any, if it does it is not valid
	#
	# Arguments:	a0 contains the row number of a potential new cell
	#				a1 contains the col number of a potential new cell
	#
	# Returns:		1 in v0 if the input space is valid, 0 if not
	#
	# Destroys:		$t0, $t1, $t2
	#
	live_cell_check:
		la	$t0, live_cells	# now t0 has the address of the live cell "array"
		move	$t1, $zero	# t1 will be the counter, when it equals s4 we stop
					# this is because s4 is the number of alive cells that have been entered
		addi	$v0, $zero, 1	# v0 is 1 until we find a square that is invalid
		j	cell_check_loop
		
	cell_check_loop_retry:	
		addi	$t0, $t0, 4
		addi	$t1, $t1, 1
	cell_check_loop:
		# right now t0 points to the next row value to check
		beq	$t1, $s4, cell_check_loop_done	# if t1 == s4 then we are done
		lw	$t2, 0($t0)	# load the current value from live cell array into t2
		addi	$t0, $t0, 4	# now t0 points to the col value
		
		bne	$t2, $a0, cell_check_loop_retry	# check against a0 and if they aren't =
							# then just restart the loop
		lw	$t2, 0($t0)	# load the col value from the array into t2			
		bne	$t2, $a1, cell_check_loop_retry	# if t2 and a1 arent = restart loop
		
		#otherwise we have found a match and it is invalid
		move 	$v0, $zero
		
	cell_check_loop_done:
		jr 	$ra


	# Name:			print_board
	#
	# Description:	print out the given generation
	#
	# Arguments:	a0 contains the address of the table
	#				a1 contains the the generation number
	#
	# Returns:		1 in v0 if the input space is valid, 0 if not
	
	print_board:
		addi	$sp, $sp, -32	# stack stuff except s0 because we will use it
		sw	$ra, 28($sp)		# for board size
		sw	$s7, 24($sp)
		sw	$s6, 20($sp)
		sw	$s5, 16($sp)
		sw	$s4, 12($sp)
		sw	$s3, 8($sp)
		sw	$s2, 4($sp)
		sw	$s1, 0($sp)
		
		move	$s1, $a0	# s1 is addr of table
		move	$s2, $a1	# s2 is generation num
		
		li	$v0, PRINT_STR	#generation header stuff
		la	$a0, new_line
		syscall			# prints a new line
		
		li	$v0, PRINT_STR
		la	$a0, gen_header
		syscall			# prints the start of the gen header
		
		#li	$v0, PRINT_INT
		move	$a0, $s2	# seperated to print the number
		syscall
		
		li	$v0, PRINT_STR
		la	$a0, gen_header_end
		syscall			# prints the end of the gen header
		
		li	$v0, PRINT_STR
		la	$a0, plus	# first plus
		syscall
		
		# now onto the border
		move	$t0, $zero	# t0 is now a counter
	print_initial_border_loop:
		beq	$t0, $s0, print_initial_border_loop_done	
						# if t0 = boardsize we done with border
		li	$v0, PRINT_STR
		la	$a0, dash
		syscall
		addi	$t0, $t0, 1	#increment counter
		j	print_initial_border_loop
	print_initial_border_loop_done:
		li	$v0, PRINT_STR
		la	$a0, plus
		syscall
		li	$v0, PRINT_STR
		la	$a0, new_line
		syscall
		
		move	$t0, $zero	# t0 will be the counter for the row num
	print_game_rows_loop:
		beq	$t0, $s0, print_game_rows_loop_done	# if t0 greater than board size we end loop
		li	$v0, PRINT_STR
		la	$a0, sideBar
		syscall
		move	$t1, $zero	# t1 will be the counter for the col num
		mul	$t2, $s0, $t0	# t2 will be the address of the cell we are currently
					# looking at
		mul	$t2, $t2, 4
		add	$t2, $t2, $s1	# s1 is board addr
	print_cells_in_row_loop:
		beq	$t1, $s0, print_cells_in_row_loop_done	
					# if t1 greater than boardsize we end loop
		lw	$a0, 0($t2)	# load the word contained in the current cell to print
		li	$v0, PRINT_STR
		syscall			# print it
		addi	$t1, $t1, 1	# increment col
		addi	$t2, $t2, 4	# next address
		j	print_cells_in_row_loop
	print_cells_in_row_loop_done:
		li	$v0, PRINT_STR
		la	$a0, sideBar
		syscall			# print the sidebar now
		li	$v0, PRINT_STR
		la	$a0, new_line
		syscall			# and a new line, to go onto the next row
		addi	$t0, $t0, 1
		j	print_game_rows_loop
	print_game_rows_loop_done:
		li	$v0, PRINT_STR
		la	$a0, plus
		syscall			# the first plus
		
		move	$t0, $zero	# border counter
	print_final_border:
		beq	$t0, $s0, print_final_border_done	# above boardsize then end
		li	$v0, PRINT_STR
		la	$a0, dash
		syscall
		addi	$t0, $t0, 1
		j	print_final_border
	print_final_border_done:
		li	$v0, PRINT_STR
		la	$a0, plus
		syscall
		li	$v0, PRINT_STR
		la	$a0, new_line
		syscall

		lw	$ra, 28($sp)	#stack stuff
		lw	$s7, 24($sp)
		lw	$s6, 20($sp)
		lw	$s5, 16($sp)
		lw	$s4, 12($sp)
		lw	$s3, 8($sp)
		lw	$s2, 4($sp)
		lw	$s1, 0($sp)
		addi	$sp, $sp, 32
		jr	$ra


	# Name:			fill_with_emptyspace
	#
	# Description:	fill a table with emptyspace
	#
	# Arguments:	a0 contains the address of the table
	#
	# Returns:		nothing
	#
	# Destroys:		t0, t1, t2
	#emptySpace is label
	fill_with_emptyspace:
		addi	$sp, $sp, -4
		sw	$ra, 0($sp)

		#s1 is the number of cells on the board
		move	$t0, $zero	# t0 will be the counter
		move	$t1, $a0	# t1 is the addr of the current cell
		la	$t2, emptySpace	# t3 is what we will put into every word
		
	empty_space_filler_loop:
		beq	$t0, $s1, empty_space_loop_done
		sw	$t2, 0($t1)
		addi	$t1, $t1, 4
		addi	$t0, $t0, 1
		j empty_space_filler_loop
		
	empty_space_loop_done:
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra


	# Name:		create_life
	#
	# Description:	turn an empty cell into a living one
	#
	# Arguments:	a0 contains the address of the table
	#				a1 contains the row value
	#				a2 contains the col value
	#		
	#		#we can use this formula: memory location = (row*boardsize+col)*4
	#
	# Returns:	nothing
	create_life:

		addi	$sp, $sp, -4
		sw	$ra, 0($sp)
		
		li	$t1, 4
		mul	$t0, $s0, $a1	# row*boardsize
		add	$t0, $t0, $a2	# +col)
		mul	$t0, $t0, $t1	# *4
		add	$t0, $t0, $a0	# + og board memory location
		
		#now t0 has the mem loc of the cell to give life
		
		la	$t2, ages	# load addr of the ages into t2
		lw	$t3, 0($t2)	# load the first age value into t3
		sw	$t3, 0($t0)	# and save it into the cell that is newly alive	
		
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra
		
	# Name:			next_gen
	#
	# Description:	does a round of the game of life
	#
	# Arguments:	a0 contains the address of the table to generate into
	#				a1 contains the address of the previous generation
	#
	# Returns:		nothing
	next_gen:
		addi	$sp, $sp, -28
		sw	$ra, 24($sp)
		sw	$s7, 20($sp)
		sw	$s6, 16($sp)
		sw	$s5, 12($sp)
		sw	$s4, 8($sp)
		sw	$s3, 4($sp)
		sw	$s2, 0($sp)
		
		move	$s6, $a0	#s6 is the addr of the new table
		move	$s5, $a1	#s5 is the addr of the old table
		
		move	$s2, $a1	#s2 is the addr of the current cell, old gen
		move	$s3, $zero	#s3 is a cell counter
		
	loop_through_all_cells:
		beq	$s3, $s1, loop_through_all_cells	# if the counter goes over cell num, end
		lw	$s4, 0($s2)		# s4 has the current cell old gen value
		mul	$t0, $s3, 4		# cell counter*4 is t0
		add	$t1, $s6, $t0		# then it becomes the mem loc for current cell new table
		sw	$s4, 0($t1)		# then save the value into the new array
		
		#now we need to check the neighbors
		move	$a0, $s5
		move	$a1, $s2
		jal	find_neighbors
		#now v0 has the number of neighbors for the current cell
		
		la	$t0, emptySpace		# now t0 has emptyspace
		beq	$s4, $t0, cell_is_dead	# if the current cell old gen value is empty
						# then it is currently dead
						
		#every cell that makes it here will be alive
						
		li	$t0, 1			# need to check neighbors against 1
		li	$t1, 3
		
		beq	$v0, $zero, cell_is_dead	# if 0 neighbors, then death
		beq	$v0, $t0, cell_is_dead		# if 1 neighbor, then death
		slt	$t2, $t1, $v0			# if 3 < neighbors
		bne	$t2, $zero, cell_is_dead	# then death
		li	$t0, 2
		beq	$v0, $t0, cell_is_dead		# if 2 or three neighbors, cell ages
		beq	$v0, $t1, cell_is_dead
	next_cell_time:
		addi	$s2, $s2, 4		# increment addr of current cell, old gen
		addi	$s3, $s3, 1		# increment cell counter
		j	loop_through_all_cells
	cell_is_dead:
		li	$t0, 3
		beq	$v0, $t0, become_alive	# if it has three neighbors, live
		j	next_cell_time
	become_alive:
		mul	$t0, $s3, 4		# 
		add	$t1, $s6, $t0
		la	$t3, ages
		lw	$t2, 0($t3)
		sw 	$t2, 0($t1)
		j	next_cell_time
	cell_dies:
		mul	$t0, $s3, 4
		add	$t1, $s6, $t0
		la	$t2, emptySpace
		sw 	$t2, 0($t1)
		j	next_cell_time
	cell_ages:
		mul	$t0, $s3, 4
		add	$t1, $s6, $t0
		lw	$t2, 0($s2)
		addi	$t2, $t2, 2
		sw 	$t2, 0($t1)
		j	next_cell_time
	loop_through_all_cells_done:
		move	$a0, $s7
		move	$a1, $s6
		move	$a2, $s5

		lw	$ra, 24($sp)
		lw	$s7, 20($sp)
		lw	$s6, 16($sp)
		lw	$s5, 12($sp)
		lw	$s4, 8($sp)
		lw	$s3, 4($sp)
		lw	$s2, 0($sp)
		addi	$sp, $sp, 28
		jr	$ra
		
		
			
	# Name:		find_neighbors
	#
	# Description:	takes a cell in the current board and finds all neighbors
	#
	# Arguments:	a0 contains the address of the table to generate into
	#		a1 contains the address of the current cell
	#
	# Returns:	v0 contains the number of neighbors for the current cell
	find_neighbors:
		addi	$sp, $sp, -32
		sw	$ra, 28($sp)
		sw	$s7, 24($sp)
		sw	$s6, 20($sp)
		sw	$s5, 16($sp)
		sw	$s4, 12($sp)
		sw	$s3, 8($sp)
		sw	$s2, 4($sp)
		sw	$s1, 0($sp)
		
		
		
		sub		$t0, $a1, $a0	#subtract offset loc from tabl addr to get the offset
		div		$t0, $t0, 4	#divide by 4 to get the current index
		div		$t0, $s0	#and divide this again to put the 
		mflo	$s2		#row here and the
		mfhi	$s3		#col here
		
		addi	$t0, $s2, 1	#t0 is the row+1
		div		$t0, $s0	#row/board size
		mfhi	$t2		#t2 is (row+1)%boardsize
					# so it is 0 if max row, and just 1+row otherwise
		
		addi	$t0, $s2, -1	#t0 is the row-1
		div		$t0, $s0		
		mfhi	$t3		#t3 is row-1%boardsize
		
		slt		$t1, $t3, $zero			#if t3 is -1 then we are at the bottom row
		bne		$t1, $zero, on_the_bottom_row	#if t1=1, row_negative
		j		row_is_correct
	on_the_bottom_row:
		addi	$t3, $s0, -1		#if we are at the bottom, t3 is max col
		
		
	row_is_correct:
		addi	$t0, $s3, 1		#t0 is col + 1
		div		$t0, $s0		#mfhi is col + 1%boardsize
		mfhi	$t4			#t4 is col+1%boardsize
		addi	$t0, $s3, -1		#t0 is col - 1
		div		$t0, $s0		#mfhi is col - 1%boardsize
		mfhi	$t5			#t5 is col - 1%boardsize
		slt		$t1, $t5, $zero		#t1 is 1 if col - 1%boardsize is negative
		bne		$t1, $zero, on_the_bottom_col
		j		col_is_correct
	on_the_bottom_col:
		addi	$t5, $s0, -1		# if t5 is at the bottom it is max
	col_is_correct:


		#now we have what we need to check for neighbors, and live ones
		#t2	is wraparound row+1
		#t3 	is wraparound row-1
		#t4 	is wraparound col+1
		#t5	is wraparound col-1
		#we will compare the row and col of the currently selected square


		move	$v0, $zero	#v0 is the counter for all the neighbors
		move	$s4, $zero	#s4 = loop counter
	scan_table_for_neighbors_loop:
		beq		$s4, $s1, scan_table_for_neighbors_loop_done	#end loop if counter too far
		div		$s4, $s0							
		mflo	$t0				#t0 is now the row num
		mfhi	$t1				#t1 is now the col num
		
		#check if row is the right row for the cell to be a neighbor
		beq		$t0, $t2, col_check_wraparound	# if the current loop row num matches t2
							# then we are in the right row but on the
		beq		$t0, $t3, col_check_wraparound	# top or bottom row
		beq		$t0, $s2, col_check		# if it is s2 then we are in the middle
		
	#check this when the col # is at the top or bottom
	col_check_wraparound:
		beq		$t1, $t4, cell_is_neighbor
		beq		$t1, $t5, cell_is_neighbor
		beq		$t1, $s3, cell_is_neighbor
		j		go_to_next_neighbor
	#check this when the col # is in the middle
	col_check:
		beq		$t1, $t4, cell_is_neighbor
		beq		$t1, $t5, cell_is_neighbor
		j		go_to_next_neighbor
	cell_is_neighbor:
		lw		$t6, 0($a0)		#if it is a neighbor then load the current cell into t6
		la		$t7, emptySpace		#and check it against emptySpace
		bne		$t6, $t7, neighbor_is_alive	#if they aren't equal it's a live one
		j		go_to_next_neighbor
	neighbor_is_alive:
		addi	$v0, $v0, 1
	go_to_next_neighbor:
		addi	$a0, $a0, 4	#increment
		addi	$s4, $s4, 1
		j		scan_table_for_neighbors_loop
		
	scan_table_for_neighbors_loop_done:
		lw		$ra, 32($sp)
		lw		$s7, 28($sp)
		lw		$s6, 24($sp)
		lw		$s5, 20($sp)
		lw		$s4, 16($sp)
		lw		$s3, 12($sp)
		lw		$s2,  8($sp)
		lw		$s1,  4($sp)
		lw		$s0,  0($sp)
		addi	$sp, $sp, 36
		jr	$ra
