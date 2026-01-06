.text

.globl isqrt16_pow4
isqrt16_pow4:
    li    t0, 0
    li    t1, 16384

isqrt16_pow4_loop:
    beqz  t1, isqrt16_pow4_done
    add   t2, t0, t1
    bgeu  a0, t2, isqrt16_pow4_ge
    srli  t0, t0, 1
    srli  t1, t1, 2
    j     isqrt16_pow4_loop

isqrt16_pow4_ge:
    sub   a0, a0, t2
    srli  t0, t0, 1
    add   t0, t0, t1
    srli  t1, t1, 2
    j     isqrt16_pow4_loop

isqrt16_pow4_done:
    mv    a0, t0
    ret


.globl bf16_sqrt
bf16_sqrt:
    addi  sp, sp, -32
    sw    s0,  0(sp)
    sw    s1,  4(sp)
    sw    s2,  8(sp)
    sw    s3, 12(sp)
    sw    s4, 16(sp)
    sw    s5, 20(sp)
    sw    s6, 24(sp)
    sw    ra, 28(sp)

    srli  s0, a0, 15
    andi  s0, s0, 1
    srli  s1, a0, 7
    andi  s1, s1, 0xFF
    andi  s2, a0, 0x7F

    li    t0, 0xFF
    bne   s1, t0, bf16_sqrt_a_exp
    beq   s2, x0, bf16_sqrt_a_mant
    j     bf16_sqrt_ret_a

bf16_sqrt_a_mant:
    beq   s0, x0, bf16_sqrt_a_sign
    li    a0, 0x7FC0
    j     bf16_sqrt_ans
bf16_sqrt_a_sign:
    j     bf16_sqrt_ret_a

bf16_sqrt_a_exp:
    bne   s1, x0, bf16_sqrt_skip
    bne   s2, x0, bf16_sqrt_skip
    li    a0, 0x0000
    j     bf16_sqrt_ans

bf16_sqrt_skip:
    beq   s0, x0, bf16_sqrt_negative_skip
    li    a0, 0x7FC0
    j     bf16_sqrt_ans

bf16_sqrt_negative_skip:
    bne   s1, x0, bf16_sqrt_denormals_skip
    li    a0, 0x0000
    j     bf16_sqrt_ans

bf16_sqrt_denormals_skip:
    addi  t1, s1, -127
    ori   t2, s2, 0x80

    andi  t0, t1, 1
    beq   t0, x0, bf16_sqrt_else

    slli  t2, t2, 1
    addi  t0, t1, -1
    srai  t0, t0, 1
    addi  t3, t0, 127
    j     bf16_sqrt_end_if

bf16_sqrt_else:
    srai  t0, t1, 1
    addi  t3, t0, 127

bf16_sqrt_end_if:
    mv    s6, t3
    slli  a0, t2, 7
    addi  a0, a0, 127
    jal   isqrt16_pow4
    mv    s5, a0
    mv    t3, s6
    j     bf16_sqrt_l3

bf16_sqrt_l3:
    andi  t5, s5, 0x7F
    li    t0, 0xFF
    blt   t3, t0, bf16_sqrt_no_overflow
    li    a0, 0x7F80
    j     bf16_sqrt_ans

bf16_sqrt_no_overflow:
    bgt   t3, x0, bf16_sqrt_no_underflow
    li    a0, 0
    j     bf16_sqrt_ans

bf16_sqrt_no_underflow:
    andi  t3, t3, 0xff
    slli  t3, t3, 7
    or    a0, t3, t5
    j     bf16_sqrt_ans

bf16_sqrt_ret_a:
    j     bf16_sqrt_ans

bf16_sqrt_ans:
    lw    s0,  0(sp)
    lw    s1,  4(sp)
    lw    s2,  8(sp)
    lw    s3, 12(sp)
    lw    s4, 16(sp)
    lw    s5, 20(sp)
    lw    s6, 24(sp)
    lw    ra, 28(sp)
    addi  sp, sp, 32
    ret
