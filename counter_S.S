	.data
counter:	.quad 0
GPIO:		.quad 0
	.text
	.global setup
	.global interrupt

interrupt:
	pushq 	%rbx

	incq	counter			# +1
	andq	$15, counter	# %16
	call 	setLEDS

	popq	%rbx
	ret

setLEDS:
	movq	$4, %rdi		# 4 = sista pin
	movq	$1,	%rbx		# 1 = bitmask
setLEDSLoop:
	movq 	counter, %rax	# counter i rax
	andq	%rbx, %rax		# använd bitmask
	cmpq	%rbx, %rax		# kolla med bitmask
	# t.ex. 1010 & 0010 = 0010 == 0010
	jne		turnoff
turnon:
	call setLEDOn
	jmp continue
turnoff:
	call setLEDOff
	jmp continue
continue:
	decq	%rdi
	sal		$1, %rbx 
	cmpq	$0, %rdi
	jne		setLEDSLoop
	ret

setLEDOn:
	# gpio_addr + 3 |= ((0x3 << 4)+1) << (8*(GPIO_NR-1));
	# rdi = pin
	pushq	%rbx
	movq	$0x3, %rax	# 0x3
	salq	$4, %rax	# << 4
	incq	%rax		# +1
	movq	%rdi, %rbx	# GPIO_NR
	decq	%rbx		# -1
	salq	$3, %rbx	# *8
	movq 	%rbx, %rcx	
	salq	%cl, %rax	# ((0x3 << 4)+1) << (8*(GPIO_NR-1))
	movq	GPIO, %rbx	# gpio_addr
	addq	$3, %rbx	# + 3
	orq		%rax, (%rbx)# |=
	popq 	%rbx
	ret

setLEDOff:
	# gpio_addr + 3 &= ~(0xCF << (8*(GPIO_NR-1)));
	# rdi = pin
	pushq	%rbx

	movq	$0xCF, %rax	# 0xCF
	movq	%rdi, %rbx	# GPIO_NR
	decq	%rbx		# -1
	salq	$3, %rbx	# *8
	movq	%rbx, %rcx	
	salq	%cl, %rax	# (0xCF << (8*(GPIO_NR-1)))
	notq	%rax		# ~
	
	movq	GPIO, %rbx	# gpio_addr
	addq	$3, %rbx	# + 3
	andq	%rax, (%rbx)# &=
	popq 	%rbx
	ret

setup:
	# calculera gpio_addr = 
	# ((0x60 << 16) | (0xFFFF & 0x1000) | (~(0x9E) & 0xFF))
	pushq 	%rbx
	movq	$0x60, %rax   	# 0x60
	salq	$16, %rax	 	# << 16
	movq	$0xFFFF, %rbx 	# 0xFFFF
	andq	$0x1000, %rbx 	# & 0x1000
	orq		%rbx, %rax 	 	# |
	movq	$0x9E, %rbx		# 0x9E
	notq	%rbx			# ~
	andq	$0xFF, %rbx		# & 0xFF
	orq		%rbx, %rax		# |
	movq	%rax, GPIO		# spara i gpio
	popq	%rbx

	
	movq	$0, %rdi
	call 	setInPin	#sätt pin 0 till input

setOutPinLoop:
	
	#sätt pin 1,2,3,4 till output
	incq	%rdi		# nästa pin
	call 	setOutPin	# sätt pin
	cmpq	$4, %rdi 	# kolla om alla är satta
	jl	setOutPinLoop	# annars gör det igen
	ret

setInPin:
	# rdi = pin
	# gpio_addr
	# |= 0x3 << ((((3-GPIO_NR)*2) % 8)+8);
	pushq 	%rbx
	movq	$0x3, %rax		# 0x3
	movq	$3, %rbx		# 3
	subq	%rdi, %rbx		# -GPIO_NR
	salq	$1, %rbx		# * 2
	andq	$7, %rbx		# %8
	addq	$8, %rbx		# +8
	movq	%rbx, %rcx
	salq	%cl, %rax		# 0x3 << ((((3-GPIO_NR)*2) % 8)+8)
	movq 	GPIO, %rbx		# gpio_addr
	orq		%rax, (%rbx)	# |=
	popq	%rbx
	ret

setOutPin:
	# rdi = pin
	# gpio_addr |= (0x2 << 6) << ((4-GPIO_NR)*2)
	pushq	%rbx
	pushq	%rdi
	movq	$0x2, %rax		# 0x2
	salq	$6, %rax		# << 6
	movq	$4, %rbx		# 4
	subq	%rdi, %rbx		# -GPIO_NR
	salq	$1, %rbx		# *2
	movq	%rbx, %rcx		
	salq	%cl, %rax		# (0x2 << 6) << ((4-GPIO_NR)*2)
	movq 	GPIO, %rbx		# gpio_addr
	orq		%rax, (%rbx) 	# |=
	popq	%rdi
	popq	%rbx
	ret