
# TODO: If a player selects a position that has already been chosen, ask them to choose a valid position.
# TODO BUGFIX: Sometimes when it's a draw, the program says someone won. Ex:1,9,5,8,7,4,6,3,2 - DRAW but shows as win for player 1
.data
	board: .space 36 #9 characters, assuming a character = 32 bits
	newLine: .asciiz "\n"
	winnerMessage_1: .asciiz "\nPlayer "
	winnerMessage_2: .asciiz " won the game!\n"
	drawMessage: .asciiz "\nIt's a draw!\n"

.text 
	main:
		#s0 will be the counter (when it gets to 9, which is the number of squares,
		# the board will be filled)
		addi $s0, $zero, 0
		#s1 will contain the board's address
		la $s1, board
		#s2 holds the player whose turn it is. Player 0 uses the symbol X and Player 1 uses the symbol O
		addi $s2, $zero, 0
		jal initialize_board
		jal print_board
		main_loop:
			
			add $a0, $s2, $zero
			jal turn_player_symbol
			
			add $t0, $v0, $zero
			
			# ask the player for where they want to place their symbol
			li $v0, 5
			syscall
			add $t1, $v0, $zero
			# X is 88 and O is 79
			add $a0, $zero, $t0
			add $a1, $t1, $zero
			jal input_user
			addi $s0, $s0, 1 # s0++
			
			jal print_board
			jal check_winner # this is a stop condition
			beq $s0, 9, draw # also a stop condition
			
			add $a0, $s2, $zero
			jal toggle_player
			add $s2, $v0, $zero
			
			j main_loop
		j exit
	
	#$a0 contains the player counter
	#$v0 contains the symbol associated with the player
	turn_player_symbol:
		#X eh 88 e O eh 79
		beq $a0, 0, player_one_symbol
		player_two_symbol:
			addi $v0, $zero, 79
			jr $ra
		player_one_symbol:
			addi $v0, $zero, 88
			jr $ra
			
	#$a0 contains the player counter
	#$v0 contains the new player counter		
	toggle_player:
		beq $a0, 0, player_one_toggle
		player_two_toggle:
			addi $v0, $zero, 0
			jr $ra
		player_one_toggle:
			addi $v0, $zero, 1 
			jr $ra
		
	initialize_board:
		
		addi $t1, $zero, 0 # board index
		addi $t0, $zero, 49 #printed value (ASCII)
		init_board_loop:
			# When t1 gets to 36, it means that the board is already full
			# We can't just write 4 bytes to board($t1) because that's not our space.
			beq $t1, 36, return_initialize_board
			sw $t0, board($t1)
			addi $t1, $t1, 4
			addi $t0, $t0, 1 # t0++
			j init_board_loop
		return_initialize_board:
			jr $ra
	
	print_board:
		# board index	
		addi $t1, $zero, 0
		# counter (whenever it reaches 3, print a new line. Since it is a 3x3 matrix)
		addi $t2, $zero, 1
		print_loop:
			beq $t1, 36, return_printed_board
			lw $t0, board($t1)
			
			#Print value of t0
			li $v0, 11
			add $a0, $zero, $t0
			syscall
			
			li $v0, 11
			addi $a0, $zero, 124 #separator ASCII
			syscall
			
			beq $t2, 3, print_new_line
			print_new_line_return: # there is no "conditional jal" in MIPS so we have to use labels
			
			addi $t1, $t1, 4
			addi $t2,$t2,1
			j print_loop
			
		print_new_line:
			# Here I have to get t2 back to 0 and not 1. Otherwise t2 becomes 4 when returning
			addi $t2, $zero, 0
			li $v0, 4
			la $a0, newLine
			syscall
			j print_new_line_return
		
		return_printed_board:
			jr $ra
	# $a0 = symbol; $a1 = position	
	input_user:
		# When the user inputs the position 2, it's actually the position 4*(2-1)
		# to our array in memory

		# symbol
		add $t0, $a0, $zero
		
		# position
		add $t1, $a1, $zero
		subi $t1, $t1, 1
		mul $t2, $t1, 4
		
		sw $t0, board($t2)
		
		jr $ra
	draw:
		li $v0, 4
		la $a0, drawMessage
		syscall
		j exit
	
	check_winner:
		
		#s4 will either be 0 or 1. 1 if there is a winner, 0 otherwise.
		j check_column_winner
		return_check_column_winner:
		beq $s4, 0, check_row_winner
		return_check_row_winner:
		beq $s4, 0, check_diagonal_winner
		return_check_diagonal_winner:
		beq $s4, 1, winner
		jr $ra
	
	check_column_winner:
		#t3 will count the CURRENT initial value index
		addi $t3, $zero, 0
		#t0 will iterate on each value of each column
		add $t0, $zero, $t3
		
		check_column_winner_loop:
			# 12 is already out of scope, so there are no winners on columns
			beq $t3, 12, return_check_column_winner
			# t1 has the first symbol of the column
			lw $t1, board($t0)
			# t0 now points to the next element of the column
			addi $t0, $t0, 12
			lw $t2, board($t0)
			# if t1 and t2 are not equal by now, it's not worth checking the third value of the column.
			bne $t1, $t2, forward_one_column
			# from here on we admit that the first row is equal to the second
			addi $t0, $t0, 12
			lw $t2, board($t0)
			# s4 = 1 if we found a winner
			seq $s4, $t1, $t2
			# going directly to the "winner" label would be less elegant
			beq $s4, 1, return_check_column_winner
			# When it gets here, the program has already checked the entire column
			j check_column_winner_loop
			
			forward_one_column:
				# Going to the right by 1 column
				addi $t3, $t3, 4
				# t0 starts in t3
				add $t0, $zero, $t3
				j check_column_winner_loop
	
	check_row_winner:
		#t3 will count the CURRENT initial value index 
		addi $t3, $zero, 0
		#t0 will iterate on each value of each row
		add $t0, $zero, $t3
		
		check_row_winner_loop:
		
			# 36 is already out of scope, so there are no winners on rows
			beq $t3, 36, return_check_row_winner
			# t1 has the first symbol of the row
			lw $t1, board($t0)
			addi $t0, $t0, 4
			lw $t2, board($t0)
			# if t1 and t2 are not equal by now, it's not worth checking the third value of the row.
			bne $t1, $t2, forward_one_row
			# from here on we admit that the first column is equal to the second
			addi $t0, $t0, 4
			lw $t2, board($t0)
			# s4 = 1 if we found a winner
			seq $s4, $t1, $t2
			# going directly to the "winner" label would be less elegant
			beq $s4, 1, return_check_row_winner 
			# When it gets here, the program has already checked the entire row
			j check_row_winner_loop
			
			forward_one_row:
				# Going down one row
				addi $t3, $t3, 12
				# t0 starts in t3 
				add $t0, $zero, $t3
				j check_row_winner_loop
	
	check_diagonal_winner:
		# It is enough to check each diagonal. No need for a loop.
		# First diagonal \
		first_diagonal:
			# t0 is the index for our board
			addi $t0, $zero, 0
			lw $t1, board($t0)
			addi $t0, $t0, 16
			lw $t2, board($t0)
			bne $t1, $t2, second_diagonal
			addi $t0, $t0, 16
			lw $t2, board($t0)
			seq $s4, $t1, $t2
			#beq $t1,$t2, return_check_diagonal_winner # there's no need for "seq" but just making this standard
			beq $s4, 1, return_check_diagonal_winner
			
		# Second diagonal /
		second_diagonal:
			addi $t0, $zero, 8 # index
			lw $t1, board($t0)
			addi $t0, $t0, 8
			lw $t2, board($t0)
			bne $t1, $t2, return_check_diagonal_winner
			addi $t0, $t0, 8
			lw $t2, board($t0)
			bne $t1, $t2, return_check_diagonal_winner
			seq $s4, $t1, $t2
			beq $s4, 1, return_check_diagonal_winner
	
	winner:
		# Since I want it to display Player 1 and Player 2 and not "Player 0" and "Player 1"
		# I incremented s2
		addi $s2, $s2, 1
		li $v0, 4
		la $a0, winnerMessage_1
		syscall
		li $v0, 1
		add $a0, $s2, $zero
		syscall
		li $v0, 4
		la $a0, winnerMessage_2
		syscall
		j exit
	exit:
		li $v0, 10
		syscall
		
