# mips_guess_game
Please download Mars to run the game.

The procedure of this program are:
	

       Main()
	      loadCard()
	      weclomeDialog()
	      playGame()
	      displayResult()
	      playAgain() (or Exit)
            
       Sub routes:
            PlayGame()	
                 Shuffle()
	               Draw()
	               Display()
	               Sound()
            Display()	
                 ArrayToString()
	               Strcopy()



The main function will load enough space for the 64 cards(include 0), then ask the user to input a number between 1 and 63(inclusive). If the user choose to click the cancel button, the program will terminate immediately. Once the user input a number, the guess procesdure will start, the subroutine will begin works.

```
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

```

During the main while loop, we will display the 6 cards one by one and process all the subroutes including 

Here, we use the strcp() to combine the String "Card" and the round number of card, so we will get part of roundmessage.
```
	# prepare roundMessage: Copy the string in card into roundMessage
		la	$a0,	card
		la	$a1,	roundMessage
		jal	StrCpy
	# prepare roundMessage: Replace X by round number i
		addi	$t1,	$s1,	48	# convert integer round number i into char
		sb	$t1,	-3($s6)
```

Next, we need an String combined by random order integers(between 1 and 63), first, shuffle the integers we have got to make sure we make them random order:
```
	# shuffle the deck
		la	$a0,	cardDeck
		jal	shuffle
		# pick up numbers
		la	$a0,	cardDeck
		move	$a1,	$s0
		jal	draw

```
Then convert the array to string, then combine it to round message
```
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
```

At last, put this string message into dialog to interferce with user
```
	# pop-up message dialog to ask user
		li	$v0,	50
		la	$a0,	roundMessage
		li	$a1,	1
		syscall				# Yes: 0, No: 1, Cancel: 2
		# act based on the dialog result
		beq	$a0,	1,	skipAdd	# No: goto prepare for the next card
		beq	$a0,	2,	exit	# Cancel: exit program
		or	$s7,	$s7,	$s0	# Yes: change present bit of user input into 1
```
Before we to do the next round, we insert a sound() function to display sound when the user click buttons.
```
	# insert sound feed back here for YES button
		li $v0, 31
		la $a0, beep		#pitch
		la $a1, duration		#duration in milliseconds
		la $a2, 7			#instrument
		la $a3, volume		#volume
		syscall 
```

After we done all the 6 rounds, the program will display the number user input correctly, and ask the user if he/she still want to play again.

*
Description of Algorithm:
	The algorithm is based on the bit calculation. Each round we will display 32 numbers based on one special position's bit: 0 hide, 1 display.
	For example:
	1:  000001
	2:  000010
	3:  000011
	4:  000100
	First round: we will check the first position(from right to left)'s bit, so display 1 and 3, the second round, we check the second position's bit, so display 2 and 3, the third round, we check the third position's bit, so display 4. Through binary knowledge, we know from 1 to 63(inclusive), 6 bits length, each time we choose 1 position to check bit, there will always 32 numbers display.
	So, it is easy to do the calculation! During each round, user can input 'Yes' or 'No', record the user input, Yes means 1, No means 0. At last ouput the record register's decimal number directly.
	Pay attention, when do the record, need to reverse! For example, the first round will display: 1,3,5,7,.....63, if user input 1, he will click 'Yes', then program will record 1, then the last 5 rounds, the user will click 'No'. If dont reverse, the record register will record a binary number: 10000, which is 32, not 1. 
	
	```
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
	
	
	
