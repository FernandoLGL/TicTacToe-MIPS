.data
	board: .space 36 #9 caracteres, supondo um caractere = 32 bits
	newLine: .asciiz "\n"
	winnerMessage_1: .asciiz "\nO jogador "
	winnerMessage_2: .asciiz " venceu a partida!\n"
	drawMessage: .asciiz "\nIt's a draw!\n"

.text 
	main:
		addi $s0, $zero, 0 # s0 vai ser o contador (quando chegar a 9, o tabuleiro vai estar preenchido)
		la $s1, board # s1 vai conter o endereço do tabuleiro
		addi $s2, $zero, 0 # jogador com a vez (jogadores 0 e 1). Jogador 0 tem o simbolo X e o 0 tem o simbolo O
		addi $s3, $zero, 0 # contador que quando chegar a 9 e nao ter vencedor eh porque eh empate
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
			# X eh 88 e O eh 79
			add $a0, $zero, $t0
			add $a1, $t1, $zero
			jal input_user
			addi $s3, $s3, 1 # s3++
			
			jal print_board
			jal check_winner # this is a stop condition
			beq $s3, 9, draw # also a stop condition
			
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
		
		addi $t1, $zero, 0 #board index
		addi $t0, $zero, 49 #printed value
		init_board_loop:
			beq $t1, 36, return_initialize_board
			sw $t0, board($t1)
			addi $t1, $t1, 4
			addi $t0, $t0, 1 # t0++
			j init_board_loop
		return_initialize_board:
			jr $ra
	
	print_board:	
		addi $t1, $zero, 0 #board index
		addi $t2, $zero, 1 # counter (whenever it reaches 3, print a new line)
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
			print_new_line_return: #nao tem jal condicional em mips
			# https://stackoverflow.com/questions/36299093/is-it-possible-use-a-conditional-jump-to-jump-to-ra-in-mips/36299190
			
			addi $t1, $t1, 4
			addi $t2,$t2,1
			j print_loop
			
		print_new_line:
			addi $t2, $zero, 0 # aqui preciso voltar para 0 e nao para 1. Caso contrario t2 vira 4 no retorno
			#(vide linha addi $t2,$t2,1 no codigo do print)
			li $v0, 4
			la $a0, newLine
			syscall
			j print_new_line_return
		
		return_printed_board:
			jr $ra
	# $a0 = simbolo; $a1 = posicao		
	input_user:
		# Quando o usuario digita que eh a posicao 2, na verdade eh a posicao 4*(2-1)
		# pro nosso array que ta na memoria
		
		# simbolo
		add $t0, $a0, $zero
		
		#pegando a posicao
		add $t1, $a1, $zero
		subi $t1, $t1, 1
		mul $t2, $t1, 4
		
		add $t3, $a0, $zero # t3 contem o simbolo
		
		sw $t3, board($t2)
		
		jr $ra
	draw:
		li $v0, 4
		la $a0, drawMessage
		syscall
		j exit
	
	check_winner:
		
		#s4 vai conter 0 ou 1 (0 se nao teve vencedor ainda)
		j check_column_winner
		return_check_column_winner:
		beq $s4, 0, check_row_winner
		return_check_row_winner:
		beq $s4, 0, check_diagonal_winner
		return_check_diagonal_winner:
		beq $s4, 1, winner
		jr $ra
	
	check_column_winner:
		addi $t3, $zero, 0 # vai contar o valor inicial atual
		add $t0, $zero, $t3 # vai iterar sobre cada valor de cada coluna
		
		check_column_winner_loop:
			
			beq $t3, 12, return_check_column_winner # 12 ja saiu do escopo, entao eh pq nao tem vencedor em colunas
			lw $t1, board($t0) # t1 tem o primeiro simbolo (88 se X e 79 se Y)
			addi $t0, $t0, 12
			lw $t2, board($t0)
			bne $t1, $t2, forward_one_column #se $t1 e $t2 ja nao forem iguais, n adianta checar adiante
			#daqui ja se admite que a primeira linha eh igual a segunda
			addi $t0, $t0, 12
			lw $t2, board($t0)
			seq $s4, $t1, $t2 # setando s4 pra 1 se encontrou vencedor
			beq $s4, 1, return_check_column_winner #ir direto pra winner seria melhor, mas menos elegante
			# quando chegar aqui, ja vai ter checado a coluna inteira
			j check_column_winner_loop
			
			forward_one_column:
				addi $t3, $t3, 4 # andando pra direita 1 coluna
				add $t0, $zero, $t3 #t0 vai comecar em t3
				j check_column_winner_loop
	
	check_row_winner:
		addi $t3, $zero, 0 # vai contar o valor inicial atual
		add $t0, $zero, $t3 # vai iterar sobre cada valor de cada linha
		
		check_row_winner_loop:
			
			beq $t3, 36, return_check_row_winner # 36 ja saiu do escopo, entao eh pq nao tem vencedor em linhas
			lw $t1, board($t0) # t1 tem o primeiro simbolo (88 se X e 79 se Y)
			addi $t0, $t0, 4
			lw $t2, board($t0)
			bne $t1, $t2, forward_one_row #se $t1 e $t2 ja nao forem iguais, n adianta checar adiante
			#daqui ja se admite que a primeira linha eh igual a segunda
			addi $t0, $t0, 4
			lw $t2, board($t0)
			seq $s4, $t1, $t2 # setando s4 pra 1 se encontrou vencedor
			beq $s4, 1, return_check_row_winner #ir direto pra winner seria melhor, mas menos elegante
			# quando chegar aqui, ja vai ter checado a coluna inteira
			j check_row_winner_loop
			
			forward_one_row:
				addi $t3, $t3, 12 # andando pra baixo 1 linha
				add $t0, $zero, $t3 #t0 vai comecar em t3
				j check_row_winner_loop
	
	check_diagonal_winner:
		#Basta checar uma diagonal e depois a outra. Nem precisa de loop.
		# Primeira diagonal \
		first_diagonal:
			addi $t0, $zero, 0 # index
			lw $t1, board($t0)
			addi $t0, $t0, 16
			lw $t2, board($t0)
			bne $t1, $t2, second_diagonal
			addi $t0, $t0, 16
			lw $t2, board($t0)
			seq $s4, $t1, $t2
			#beq $t1,$t2, return_check_diagonal_winner #nao precisaria de seq mas so pra deixar padronizado
			beq $s4, 1, return_check_diagonal_winner
			
		# Segunda diagonal /
		second_diagonal:
			addi $t0, $zero, 8 # index
			lw $t1, board($t0)
			addi $t0, $t0, 8
			lw $t2, board($t0)
			bne $t1, $t2, return_check_diagonal_winner
			addi $t0, $t0, 8
			lw $t2, board($t0)
			bne $t1, $t2, return_check_diagonal_winner #otherwise it would just fall down to "winner"
			seq $s4, $t1, $t2
			beq $s4, 1, return_check_diagonal_winner
	
	winner:
		addi $s2, $s2, 1 #ja que eu quero que mostre jogador 1 ou 2 e nao 0 ou 1
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
		
