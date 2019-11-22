		.data

card:		.asciiz	"CARD X\n\n"
numbers:	.align	2
		.space	400
message:	.asciiz "\n\nIs your number shown above?"
Start:		.asciiz	"Think of a number between 1 and 63.\nSix cards will be displayed.\nAfter the last one, your number will be revealed."
End:		.asciiz	"Your number is: "
Again:	 	.asciiz "Do you want to play again?"
boo:		.asciiz	"Your number is: 0 or whatever except from 1 to 63.\n\nDO YOU ACTUAL WANT TO PLAY THIS GAME AND CLICK ALL NO BY MISTAKE???"
roundMessage:	.align	2
		.space	1024
cardDeck:	.align	2
		.space	252
beep: .byte 60
sound2: .byte 40
duration: .byte 5
volume: .byte 120
		.text
main:
	# load the cardDeck
	la	$a0,	cardDeck
	jal	loadCard
	addi	$s7,	$zero,	0	# user input
	# inform user how the game work
	li	$v0,	55
	la	$a0,	Start
	li	$a1,	1
	syscall
	li	$s0,	1		# position of 1 (000001B)
	li	$s1,	1		# card/round i
	mwhile:
		slti	$t0,	$s1,	7	# i < 7 ?
		beqz	$t0,	endmwhile	# No: goto endmwhile
		# prepare roundMessage: Copy the string in card into roundMessage
		la	$a0,	card
		la	$a1,	roundMessage
		jal	StrCpy
		move	$s6,	$a1
		# prepare roundMessage: Replace X by round number i
		addi	$t1,	$s1,	48	# convert integer round number i into char
		sb	$t1,	-3($s6)
		# shuffle the deck
		la	$a0,	cardDeck
		jal	shuffle
		# pick up numbers
		la	$a0,	cardDeck
		move	$a1,	$s0
		jal	draw
		# prepare roundMessage: Convert the selected numbers into string
		addi	$sp,	$sp,	-128
		la	$a0,	($sp)
		la	$a1,	numbers
		li	$a2,	32
		jal	arrayToString
		addi	$sp,	$sp,	128
		# prepare roundMessage: Copy converted numbers into roundMessage
		la	$a0,	numbers
		la	$a1,	($s6)
		jal	StrCpy
		move	$s6,	$a1
		# prepare roundMessage: Copy the string in message into roundMessage
		la	$a0,	message
		la	$a1,	($s6)
		jal	StrCpy
		move	$s6,	$a1
		# pop-up message dialog to ask user
		li	$v0,	50
		la	$a0,	roundMessage
		li	$a1,	1
		syscall				# Yes: 0, No: 1, Cancel: 2
		# act based on the dialog result
		beq	$a0,	1,	skipAdd	# No: goto prepare for the next card
		beq	$a0,	2,	exit	# Cancel: exit program
		or	$s7,	$s7,	$s0	# Yes: change present bit of user input into 1. e.g: 000100B OR 000010B = 000110B
		#################################################################################################
		#						SOUND
		#################################################################################################
		# insert sound feed back here for YES button
		li $v0, 31
		la $a0, beep		#pitch
		la $a1, duration		#duration in milliseconds
		la $a2, 7			#instrument
		la $a3, volume		#volume
		syscall 
		#################################################################################################
		j	prepareNextRound
		skipAdd:
		#################################################################################################
		#						SOUND
		#################################################################################################
		# insert sound feed back here for NO button
		
		li $v0, 31
		la $a0, beep		#pitch
		la $a1, duration		#duration in milliseconds
		la $a2, sound2		#instrument
		la $a3, volume		#volume
		syscall 
		#################################################################################################
		# prepare for the next card
		prepareNextRound:
		sll	$s0,	$s0,	1
		addi	$s1,	$s1,	1
		j	mwhile
	endmwhile:
		beqz	$s7,	boooo
		li	$v0,	56
		la	$a0,	End
		move	$a1,	$s7
		syscall
		j	again
	boooo:
		li	$v0,	50
		la	$a0,	boo
		syscall
		beq	$a0,	1,	exit
		beq	$a0,	2,	exit
	again:	# promt if user want to play again
		li	$v0,	50
		la	$a0,	Again
		syscall
		beqz	$a0,	main
exit:		# exit the program
	li	$v0,	10
	syscall

# create a set of numbers from 1 to 63, called cardDeck, and store to the memory
loadCard:
	li	$t0,	1			# set N = 1
	lcwhile:
		slti	$t1,	$t0,	64	# N < 64 ?
		beqz	$t1,	endLoadCard	# no: goto endLoadCard
		sw	$t0,	0($a0)		# store N to the deck
		addi	$a0,	$a0,	4	# increase position
		addi	$t0,	$t0,	1	# increase N
		j	lcwhile
endLoadCard:
	jr	$ra				# return

# shuffle the deck (cardDeck)
shuffle:
	li	$t0,	62			# i = 62
	move	$t7,	$a0			# store deck base address into $t7
	swhile:
		slti	$t1,	$t0,	0	# i < 0 ?
		bnez	$t1,	endShuffle	# Yes: goto endShuffle
		# pick random position (from 0 to i-1)
		li	$v0,	42		# random $v0 = 42
		addi	$a1,	$t0,	1	# set upper bound = i, random will result from 0 to i-1
		syscall				# random result is stored in $a0
		# set positions of two numbers
		sll	$t2,	$a0,	2	# index of random result = $a0 * 4
		sll	$t3,	$t0,	2	# index of last number = i * 4
		add	$t2,	$t2,	$t7	# position of random result = $a0 * 4 + base
		add	$t3,	$t3,	$t7	# position of last number = i * 4 + base
		# swap two numbers
		lw	$t4,	($t2)
		lw	$t5,	($t3)
		sw	$t4,	($t3)
		sw	$t5,	($t2)
		# decrease i and continue the shuffle
		addi	$t0,	$t0,	-1
		j	swhile
endShuffle:
	jr	$ra				# return

# draw cards (numbers)
draw:
	li	$t0,	0			# set number index i = 0
	addi	$sp,	$sp,	-128		# reserve to store selected numbers
	dwhile:
		slti	$t1,	$t0,	63	# i < 63 ?
		beqz	$t1,	endDraw		# No: goto endDraw
		lw	$t2,	($a0)		# $t2 = deck[i]
		and	$t3,	$a1,	$t2	# position of 1 in binary number. e.g.: 000001B AND 001111B = 000001B
		beqz	$t3,	skipdwhile	# if result = 000000B, goto skipdwhile
		sw	$t2,	($sp)		# store selected number into stack
		addi	$sp,	$sp,	4	# goto next address of stack
		skipdwhile:
		addi	$t0,	$t0,	1	# i++
		addi	$a0,	$a0,	4	# deck[i+1]
		j	dwhile
endDraw:
	jr	$ra				# return

# StrCpy (string sou, string des)
StrCpy:
	scwhile:
		lb	$t0,	($a0)
		beqz	$t0,	endStrCpy
		sb	$t0,	($a1)
		addiu	$a0,	$a0,	1
		addiu	$a1,	$a1,	1
		j	scwhile
endStrCpy:
	jr	$ra

# arrayToString(arrayOfIntegers, string, num count)
arrayToString:
	li	$t0,	0		# index of the array
	li	$t5,	10		# divider
	li	$t6,	0
	move	$t7,	$a2
	while:
		slt	$t1,	$t0,	$t7	# index < num count ?
		beqz	$t1,	end		# no: go to end
		
		li	$t1,	0		# digit count (how many digits in the number)
		lw	$t2,	($a0)		# load a number N from the array
		
		loop1:
			beqz	$t2,	endLoop1
			div	$t2,	$t5		# N / 10
			mflo	$t2			# N = N / 10
			mfhi	$t3			# $t3 = N % 10
			addi	$sp,	$sp,	-4	# reserve $sp for next word
			sw	$t3,	($sp)		# store $t3 into stack
			addi	$t1,	$t1,	1	# digit count += 1
			j	loop1
		endLoop1:

		loop2:
			beqz	$t1,	endLoop2
			addi	$t1,	$t1,	-1
			lw	$t2,	($sp)		# load from stack
			addi	$sp,	$sp,	4	# restore $sp
			addi	$t2,	$t2,	48	# convert integer to string
			sb	$t2,	($a1)		# store into text
			addi	$a1,	$a1,	1	# go to next byte of the text
			j	loop2
		endLoop2:
		addi	$t6,	$t6,	1
		beq	$t6,	8,	addNewLine
		li	$t4,	0x20		# 0x20 is a [space]
		j	cont
		addNewLine:
		li	$t4,	0xa		# 0xA is a [\n]
		li	$t6,	0
		cont:
		sb	$t4,	($a1)		# store a [space] into text
		addi	$a0,	$a0,	4	# go to next number in the array
		addi	$a1,	$a1,	1	# go to next byte of the text
		addi	$t0,	$t0,	1	# index += 1
		j	while
	end:
		li	$t0,	0xa		# 0xA is a [\n]
		sb	$t0,	-1($a1)		# replace the last byte ([space]) by a new line ([\n])
endArrayToString:
	jr	$ra		# return
