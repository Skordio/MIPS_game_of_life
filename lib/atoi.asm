.text
    .globl atoi
    
	# Name:		atoi
	#
	# Description:	takes a string buffer which is expected to contain only integers and return the integer representation
	#
	# Arguments:	a0 contains the address of the str buffer
	#
	# Destroys:		$t0, $t1, $t2, $t3
	#
	# Returns:	v0 contains the integer representation
    atoi:
		# Assume input string is in $a0
		li      $v0, 0          # Clear result register, this holds the converted number
		lb      $t0, 0($a0)     # Load the first byte of the string
		li      $t1, '-'        # Prepare '-' for comparison
		bne     $t0, $t1, atoi_skip_neg # If not negative, skip negation setup
		addi    $a0, $a0, 1     # Increment string pointer to skip '-' character
		li      $t2, -1         # Flag for negative number

	atoi_skip_neg:
		li      $t2, 1          # Flag for positive number (default)

	atoi_loop:
		lb      $t0, 0($a0)     # Load the current character from string
		beq     $t0, $zero, atoi_done # If it's '\0', we are done
		li      $t3, '0'        # Load ASCII value of '0'
		sub     $t0, $t0, $t3   # Convert ASCII to integer ('0' -> 0, '1' -> 1, ..., '9' -> 9)
		bltz    $t0, atoi_done  # If result is negative, character is not a numeric char
		li      $t3, 9          # Maximum single digit
		bgt     $t0, $t3, atoi_done # If result > 9, not a numeric char

		mul     $v0, $v0, 10    # Multiply current result by 10
		add     $v0, $v0, $t0   # Add new digit to result
		addi    $a0, $a0, 1     # Move to the next character
		j       atoi_loop       # Repeat the loop

	atoi_done:
		mul     $v0, $v0, $t2   # Apply the sign to the result
		jr      $ra             # Return to caller

