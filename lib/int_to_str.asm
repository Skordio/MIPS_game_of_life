.text
    .globl int_to_string

	# Name:		int_to_string
	#
	# Description:	takes an integer of up to 11 digits and converts it into a string representation
	#
	# Arguments:	a0 contains the integer
    #               a1 contains a buffer of .space 12, where the string will end up
	#
	# Destroys:		t0, t1, t2, t3, t4
	#
	# Returns:	nothing
    int_to_string:
        # Initial setup
        li $t0, 10               # Divider for mod and div operations
        move $t1, $a1            # Copy buffer address to $t1

        # Handle negative numbers
        bgez $a0, convert_loop   # If positive, skip to conversion
        li $t2, '-'              # Prepare minus sign for negative numbers
        sb $t2, 0($t1)           # Store '-' in buffer
        addiu $t1, $t1, 1        # Increment buffer address
        negu $a0, $a0            # Negate number

    convert_loop:
        # Prepare to reverse the digits since we extract them from least to most significant
        addi $sp, $sp, -12       # Make space on stack for up to 11 digits
        move $t3, $sp            # Temporary stack pointer

    # Extract digits
    extract_digit:
        div $a0, $t0             # $a0 / 10
        mflo $a0                 # Quotient back into $a0
        mfhi $t4                 # Remainder (current digit)
        addi $t4, $t4, '0'       # Convert to ASCII
        sb $t4, 0($t3)           # Store ASCII char on stack
        addiu $t3, $t3, 1        # Move temp stack pointer
        bnez $a0, extract_digit  # Repeat if more digits

    # Reverse digits into buffer
    reverse_digits:
        addi $t3, $t3, -1        # Move back to last valid digit
        lb $t4, 0($t3)           # Load byte
        sb $t4, 0($t1)           # Store byte into buffer
        addiu $t1, $t1, 1        # Increment buffer pointer
        bne $t3, $sp, reverse_digits

        # Null terminate the string
        sb $zero, 0($t1)         # Store null terminator

        jr $ra                   # Return from subroutine
