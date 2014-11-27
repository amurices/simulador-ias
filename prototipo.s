.globl simulate 	@ torna o simbolo "main" visivel fora do arquivo


.extern scanf

.data 
	linhAtual: 		.asciz "%X %X %X %X %X"
	pc: 			.word 0
	esq: 			.word 0
	esqadr: 		.word 0
	dir: 			.word 0
	diradr: 		.word 0
	vetormemoria: 	.skip 4096*4
	
	_ac:			.word 0
	_mq:			.word 0
	_pc:			.word 0
	_ed:			.word 0


.text
	simulate:
		ldr r6, =vetormemoria
		armazenamento:
			ldr r0, =linhAtual			@ damos a mascara do nosso scanf para r0: "%X %X %X %X %X"
			ldr r1, =pc					@ Assim, a funcao scanf tera 6 parametros. de r0-r3 mais
			ldr r2, =esq				@ dois que devem ir para a pilha.
			ldr r3, =esqadr
			ldr r4, =dir
			ldr r5, =diradr

			push {r5}
			push {r4}
			bl scanf
			pop {r4}					@ Colocamos os valores da pilha de volta em r4
			pop {r5}					@ e r5.
			cmp r0, #0					@ Comparamos o retorno do scanf com 0. Ou seja, se nenhum "%X" pode ser lido
			beq fim_do_armazenamento	@ paramos de armazenar dados. deve acontecer quando o arquivo de entrada acaba
			
			ldr r1, [r1]
			ldr r2, [r2]
			ldr r3, [r3]
			ldr r4, [r4]
			ldr r5, [r5]
			
			add r7, r6, r1				@ r7 entao tem o endereco do comeco do vetor, mais r1 (valor de pc)
			ldr r7, r2					@ fazemos esse endereco conter o valor de r2 (inst. a esquerda)
			add r7, #4					@ deslocamos para a proxima posicao (comeco (r6) + PC (r1) + 1)
			ldr r7, r3					@ fazemos esse endereco conter o valor de r3 (endereco parametro da inst. a esquerda)
			add r7, #4					@ deslocamos para a proxima posicao	(comeco (r6) + PC (r1) + 2)
			ldr r7, r4					@ fazemos esse endereco conter o valor de r4 (inst. a direita)
			add r7, #4					@ deslocamos para a proxima posicao (comeco (r6) + PC (r1) + 3)
			ldr r7, r5					@ fazemos esse endereco conter o valor de r5 (endereco parametro da inst. a direita)
			
			bl armazenamento
			
		fim_do_armazenamento:

@ suponhamos que o armazenamento foi realizado com sucesso! Temos agora um vetor
@ com todas as instrucoes e dados armazenados, entao vamos percorre-los e tratar
@ cada caso de cada instrucao.

									@ sabemos que r6 ainda armazena a posicao inicial do vetor
		lacoeterno:
			ldr r1, =_ac
			ldr r2, =_mq

			ldr r3, =_pc
			ldr r3, [r3]
			ldr r4, =_ed
			ldr r4, [r4]
			
			cmp r4, #0
			bleq inst_esq
			bl inst_dir
			
			
			inst_esq:
				mov r5, r3			@ r5 agora tem o valor de PC.
				mul r5, r5, #4		@ multiplicamos esse valor por 4, pois nosso vetor e dividido em 4 partes.
				ldr r4, =_ed
				mov r7, #1			@ E assim, incrementamos o valor de ed. (esquerda-direita)
				str r7, [r4]
				bl continua1
			inst_dir:
				mov r5, r3			@ r5 agora tem o valor de PC.
				mul r5, r5, #4		@ multiplicamos esse valor por 4, pois nosso vetor e dividido em 4 partes.
				add r5, r5, #2		@ adicionamos 2, para acessarmos a posicao a direita.
				ldr r4, =_ed			
				mov r7, #0			@ E assim, zeramos o valor de ed, e incrementamos o de pc. (esquerda-direita)
				str r7, [r4]		@ Vale lembrar que essa operacao sera ignorada para instrucoes de salto, pois
									@ nessas, pc e ed serao sobrescritas com novos valores.
				ldr r3, =_pc
				ldr r7, [r3]
				add r7, r7, #1
				str r7, [r3]
				
				bl continua1
									@ lembrando, o vetor e organizado assim:
			@ v[PC] = InstEsq  || v[PC+1] = addrInstEsq || v[PC+2] = InstDir || v[PC+3 = addrInstDir || v[PC+4] = proximo pc
	
		continua1:
		@ r5 agora esta no endereco da instrucao que deve ser executada.
			add r7, r6, r5
			ldr r7, [r7] 			@ r7 agora contem o valor da instrucao.
			
		@ o que aconteceria agora, basicamente, eh so checar que instrucao esta para ser executada.
		@ qualquer uma que seja, temos todos os dados necessarios armazenados no vetor e toda a informacao
		@ que precisamos nos enderecos das instrucoes. Quer dizer, se uma funcao quer armazenar um valor
		@ de ac em um endereco, temos como acessar essa posicao do vetor e fazer as alteracoes necessarias.
		@ AJUDA ESTEVAM!
		
			bl lacoeterno
