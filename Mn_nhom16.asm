# Tên chương trình: floating point division in MARS_MIPS without using floating point instruction
.data
	#bien doc file
	str_dl1: .asciiz "Du lieu 1 = "
	str_dl2: .asciiz "Du lieu 2 = "
	str_loi: .asciiz "Mo file bi loi."
	tenfile: .asciiz "FLOAT2.BIN"
	fdescr: .word 0
	test: .word 1
	#bien phep chia
	fp_a:		.float	20		#so bi chia
	fp_b:		.float	3		#so chia
	fp_res:		.float  1.0		#ket qua
	# Chua cac cau output
	new_line:	.asciiz "\n"
	from_algo:	.asciiz "our algorithm: "
	from_divs:	.asciiz "result from div.s: "
	
.macro docfile(%tenfile,%dulieu1,%dulieu2)
	# mo file doc
	la 	$a0,%tenfile
	addi 	$a1,$zero,0 #a1=0 (read only)
	addi 	$v0,$zero,13
	syscall
	bltz 	$v0,baoloi
	sw 	$v0,fdescr
	# doc file
	# 4 byte dau
	lw 	$a0,fdescr
	la 	$a1,%dulieu1
	addi 	$a2,$zero,4
	addi 	$v0,$zero,14
	syscall
	# 4 byte sau
	la 	$a1,%dulieu2
	addi 	$a2,$zero,4
	addi 	$v0,$zero,14
	syscall
	# dong file
	lw 	$a0,fdescr
	addi 	$v0,$zero,16
	syscall
	# Xuat ket qua (syscall)
	# in du lieu 1
	la $a0,str_dl1
	addi $v0,$zero,4
	syscall
	lwc1 $f12,%dulieu1
	addi $v0,$zero,2
	syscall
	# xuong dong
	addi $a0,$zero,'\n'
	addi $v0,$zero,11
	syscall
	# in du lieu 2
	la $a0,str_dl2
	addi $v0,$zero,4
	syscall
	lwc1 $f12,%dulieu2
	addi $v0,$zero,2
	syscall
	# xuong dong
	addi $a0,$zero,'\n'
	addi $v0,$zero,11
	syscall
	j Kthuc
	baoloi: la $a0,str_loi
	addi $v0,$zero,4
	syscall
	# Ket thuc doc file
	Kthuc: 
.end_macro
.macro from_algo
	PRINT_STRING(from_algo)
	lwc1	$f12, fp_res
	addi	$v0, $zero, 2
	syscall
.end_macro
.macro from_divs
	PRINT_STRING(from_divs)
	lwc1	$f1, fp_a
	lwc1	$f2, fp_b
	div.s	$f12, $f1, $f2
	addi	$v0, $zero, 2
	syscall 
.end_macro
.macro PRINT_NEWLINE
	addi	$v0, $zero, 4
	la	$a0, new_line
	syscall
.end_macro
.macro  PRINT_STRING(%x)
	addi	$v0, $zero, 4
	la	$a0, %x
	syscall
.end_macro
	.globl main
.text

main:
	#doc_file
	#docfile(tenfile,fp_a,fp_b)
	#xu ly
	lw	$a0, fp_a
	lw	$a1, fp_b
	jal 	div_fp
	sw	$v0, fp_res
	from_algo
	PRINT_NEWLINE
	from_divs
	j ketthuc
#-----------------------------------
# Ham div_fp: phep chia 2 so thuc 32 bit theo chuan IEEE 754  
# Input:	$a0:	so bi chia - 32 bit so thuc theo dang IEEE 754
#		$a1:	so chia 32 - 32 bit so thuc theo dang IEEE 754
# output: 	$v0: ket qua cua phep chia
#-----------------------------------
div_fp:
	#$a0: so bi chia
	#$a1: so chia
	#t0:	= $a0: so bi chia	-> temp -> new exponent
	#t1:	= $a1: so chia		-> temp
	#t2:	= sign 1		-> temp
	#t3	= sign 2		-> new sign
	#t4	= exponent 1		-> temp ( sau khi co exponent moi)
	#t5 	= exponent 2		-> temp ( sau khi co exponent moi)
	#t6 	= fraction 1		->temp
	#t7	= fraction 2		->temp
	#t8	= bien loop 	
	#t9	= fraction1/fraction2
	
	#luu lai thanh ghi $ra vi ham khong phai ham la
	addi	$sp, $sp, -4
	sw	$ra,0($sp)
	
	add 	$t0, $a0, $zero
	add	$t1, $a1, $zero
	
	add	$a0, $t0, $zero
	jal	get_sign
	add	$t2, $v0, $zero
	
	add	$a0, $t1, $zero
	jal	get_sign
	add	$t3, $v0, $zero
	
	xor	$t3, $t2, $t3	#dau moi = $t3 = xor ($t2, $t3)
	
	add	$a0, $t0, $zero
	jal	get_exponent
	add	$t4, $v0, $zero
	
	add	$a0, $t1, $zero
	jal	get_exponent
	add	$t5, $v0, $zero
	
	add	$a0, $t0, $zero
	jal	get_fraction
	add	$t6, $v0, $zero
	
	add	$a0, $t1, $zero
	jal	get_fraction
	add	$t7, $v0, $zero
	
	#lay lai dia chi $ra
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	
	add	$t0, $t4, $t6	#t0 = exponent_1 + fraction_1
	add	$t1, $t5, $t7	#t1 = exponent_2 + fraction_2
	bnez 	$t0, div_num1_notZero  # nếu num1!=0, nhảy tới nhãn div_num1_notZero
	
		bnez $t1, div_returnZero	# nếu num2!=0, nhảy tới nhãn div_returnZero
			li	$v0, 0x7FFFFFFF	#num1 == 0, num2 == 0 ->rturn NaN
			jr	$ra
		div_returnZero:	#num1 == 0, num2 != 0 ->return 0
			add	$v0, $zero, $zero
			sll	$t3, $t3, 31 	# dich trai bit dau moi ve bit dau tien
			or	$v0,$v0, $t3	# ket hop bit dau va ket qua
			jr 	$ra
	div_num1_notZero:
	bnez	$t1, div_num2_notZero	# nếu num2!=0, nhảy tới nhãn div_num2_notZero
		sll	$t3, $t3, 31				
		li	$v0, 0x7F800000	#num1 != 0, num2 == 0 ->return INF
		or	$v0,$v0, $t3	# ket hop bit dau va ket qua
		jr	$ra
	div_num2_notZero:
	
	#two number are normal two divide
	ori 	$t6, $t6, 0x00800000	#cong 1 vao fraction ~= (1 + fraction)
	ori	$t7, $t7, 0x00800000 	#cong 1 vao fraction ~= (1 + fraction)
	#check denormalize: neu exponent = 0 -> denormalize -> khong cong 1 vao fraction
	bnez	$t4, notplus1
		addi	$t4, $t4, 1
		andi	$t6, $t6, 0x007fffff #khong cong 1 vao fraction
	notplus1:
	bnez	$t5, notplus2
		addi	$t5, $t5, 1
		andi	$t7, $t7, 0x007fffff #khong cong 1 vao fraction
	notplus2:
	
	#get new Exponent -> $t0 = new exponent
	sub	$t0, $t4, $t5	
	addi	$t0, $t0, 127	

	blt	$t6, $t7, notexception #nếu fraction 1 > fraction 2 -> normalize trước
		#	trừ fraction cho đến khi nào trừ lần tới sẽ không đủ để chia, 
		#	trong quá trình đó + 1 exponent & shift left fraction 2
		#sub	$t1, $t1, $a3
		#if t1 < a3 break
		#else	shift left a3, add 1 to exponent
		#again
		againn:
		sub	$t1, $t6, $t7
		blt	$t1, $t7, notexception
			sll	$t7, $t7, 1
			addi	$t0, $t0, 1
			j	againn
	notexception:
	add	$t9, $zero, $zero	#quotient register
	add	$t8, $zero, $zero	#counting register
	
	div_loop:
	bgtu	$t8, 31, div_exit
	sll	$t9, $t9, 1	
	blt	$t6, $t7, dont_minus	
		sub	$t6, $t6, $t7
		addi	$t9, $t9, 1
	dont_minus:
	sll	$t6, $t6, 1
	add	$t8, $t8, 1
	j 	div_loop
	
	div_exit:
	slti 	$t4, $t0, 1 #Nếu exponent mới <=0 ->$t4=1, ngược lại $t4=0
	beq 	$t4, 0, normalize # $t4=1 ->  cần denormalize, $t4=0 -> không cần denormalize
	#denormalize
	# cộng exponent mới với x sao cho exponent mới =0
	# x= -(exponent mới)
	# dịch phải phần mantissa sau khi chia (x+1) bit
	#end_denormalize : bỏ qua bước normalize
	#  $t5 : chứa x cần tìm
	neg 	$t5, $t0
	bgt 	$t5, 23, under_flow	#Nếu exponent mới <-23, kết quả bị tràn dưới 
	add 	$t0,$t0,$t5
	addi 	$t5,$t5,1
	srlv	$t9, $t9, $t5
	j 	dont_normalize 
	normalize:
	# kiểm tra điều kiện: hoàn thành việc normalize hoặc exponent mới =0 -> kết thúc normalize
	# trừ exponent mới 1 đơn vị
	# dịch trái phần mantissa sau khi chia 1 bit
	# quay lại kiểm tra điều kiện
	# $t4 : dùng để kiểm tra điều kiện normalize
	andi 	$t4, $t9, 0x80000000 # Kiểm tra bit đầu tiên của phần mantissa sau khi chia, bit =0 -> $t4=0; bit=1 -> $t4 != 0 
	bnez 	$t4, dont_normalize   # $t4=0 ->  cần normalize tiếp tục, $t4 != 0 -> hoàn thành việc normalize	
	subi	$t0,$t0, 1	 	
	sll	$t9, $t9, 1	  
	bnez 	$t0, normalize	#exponent mới =0 -> kết thúc normalize và denormalize bằng cách dịch phải phần mantissa sau khi chia 1 bit
	srl 	$t9, $t9, 1
	j 	dont_normalize #kết thúc denormalize
	dont_normalize:
	#xử lý phần mantissa sau khi chia chuyển thành fraction của thương số và làm tròn
	# $t4 : dùng để kiểm tra điều kiện làm tròn 
	bgt 	$t0, 254, over_flow	#Nếu exponent mới >254, kết quả bị tràn trên
	andi	$t9, $t9, 0x7fffffff	# loại bỏ bit đầu của phần mantissa sau khi chia, 23 bit sau là phần fraction của thương số
	andi	$t4, $t9, 0x00000080 # kiểm tra bit ngay sau 23 bit fraction của thương số, , bit =0 -> $t4=0; bit=1 -> $t4 !=0 
	srl	$t9, $t9, 8 		# dịch 23 bit phần fraction xuống 23 bit cuối thanh ghi $t9
	beq 	$t4,0, not_round_up   # $t4=0 ->  không cần làm tròn, $t4 != 0 -> làm tròn kết quả
	#làm tròn kết quả :
	# cộng 1 vào phần fraction của thương số
	# sau khi cộng, nếu phần fraction = 0 -> cộng phần exponent lên 1 đơn vị,  nếu phần fraction != 0-> kết thúc làm tròn
	addi 	$t9, $t9, 0x00000001 
	bne	$t9, 0x00800000, not_round_up	
	addi	$t0, $t0, 0x00000001
	bgt 	$t0, 254, over_flow #Nếu exponent sau khi làm tròn ->254, kết quả bị tràn trên
	not_round_up:
		#xử lý phần dấu của kết quả, đưa lên bit đầu tiên của thanh ghi $t6
		sll	$t3, $t3, 31
		#xử lý phần exponent của kết quả, đưa lên 8 bit sau bit đầu tiên của thanh ghi $t0
		sll	$t0, $t0, 23
		#phần fraction của kết quả là 23 bit cuối cùng
		#kết hợp các phần dấu, phần exponent, phần fraction của thương số đã xử lý để cho ra kết quả cuối cùng
		# $v0 : chứa kết quả của phép chia
		addi	$v0, $zero, 0
		or	$v0, $t0, $t3	
		or 	$v0, $v0, $t9
		jr 	$ra
	under_flow:
	#khi tràn dưới, kết quả phép chia là 0.0 hoặc -0.0 tùy thuộc vào dấu 
	addi	$v0, $zero, 0	
	sll	$t3, $t3, 31 # xử lý phần dấu của kết quả
	or	$v0,$v0, $t3	
	jr 	$ra
	over_flow:
	#khi tràn trên, kết quả phép chia là INF hoặc -INF tùy thuộc vào dấu 
	sll	$t3, $t3, 31 # xử lý phần dấu của kết quả
	li	$v0, 0x7F800000	
	or	$v0,$v0, $t3
	jr	$ra
#end div_fp

#-----------------------------------
# Ham get_sign: lay bit sign cau so thuc 32 bit
# Input: $a0: 32 bit so thuc theo dang IEEE 754 
# output: $v0: bit dau cua so thuc dau vao
#-----------------------------------
get_sign:	
	andi	$v0, $a0, 0x80000000
	srl	$v0, $v0, 31
	
	jr	$ra
#end get_sign

#-----------------------------------
# Ham get_exponent: lay phan exponent cau so thuc 32 bit theo dang IEEE 754 
# Input: $a0: 32 bit so thuc theo dang IEEE 754 
# output: $v0: phan exponent cua so thuc 32 bit theo dang IEEE 754
#-----------------------------------
get_exponent:
	andi	$v0, $a0, 0x7F800000	
	srl	$v0, $v0, 23	#shift the exponent to right
	
	jr	$ra
#end get_exponent


#-----------------------------------
# Ham get_fraction: lay phan fraction cua so thuc 32 bit theo dang IEEE 754 
# Input: $a0: 32 bit so thuc theo dang IEEE 754 
# output: $v0: phan fraction cua so thuc 32 bit theo dang IEEE 754
#-----------------------------------
get_fraction:
	andi	$v0, $a0, 0x007FFFFF	
	
	jr	$ra
#end get_fraction

ketthuc:
	addiu	$v0,$zero,10
	syscall
