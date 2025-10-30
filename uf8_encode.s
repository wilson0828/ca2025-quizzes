uf8_encode:
    slti t0, a0 ,16
    bne  t0, x0, if1
    
    addi sp, sp, -8
    sw a0, 0(sp)
    sw ra, 4(sp)
    jal clz
    mv a1, a0        # leading zero
    lw a0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    
    li t0, 31
    sub t1, t0 , a1 # msb
    li t2 , 0       # exponent
    li t3 , 0       # overflow = offset
    
    slti t0, t1, 5
    bne  t0, x0, if2
    addi  t2, t1, -4
    slti  t0, t2, 15
    bne   t0, x0 ,if3
    li  t2, 15 
if3:
    li    t0, 1
    sll   t0, t0, t2  # t0 = 1 << e
    addi  t0, t0, -1  # t0 = (1<<e) - 1
    slli  t3, t0, 4   # overflow = t3 = (2^e -1)*16
wloop:
    beq  t2, x0, if2   
    bgeu a0, t3, if2
    addi  t3, t3, -16 # overflow = overflow - 16
    srli  t3, t3, 1 
    addi t2, t2, -1
    j    wloop
if2:
    slti t0, t2, 15
    beq  t0, x0, wdone
    slli t5, t3, 1
    addi t5, t5, 16
    mv   t4, t5      # next_overflow = (overflow << 1) + 16;
    sltu t0, a0, t4
    bne  t0, x0, wdone
    mv   t3, t4
    addi t2, t2, 1 
    j    if2
wdone:
    sub   a0, a0, t3        # a0 = value - overflow
    srl   a0, a0, t2        # a0 >>= exponent
    slli  t2, t2, 4         # t2 = exponent << 4
    or    a0, t2, a0        # a0 = (e<<4) | mantissa   
if1:
    ret
