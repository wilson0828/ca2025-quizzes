.data
.align 4
clz8_lut:
    .byte 8,7,6,6,5,5,5,5,4,4,4,4,4,4,4,4
    .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.text
.globl clz8
clz8:
    andi a0, a0, 0xFF
    la   t0, clz8_lut
    add  t0, t0, a0
    lbu  a0, 0(t0)
    ret


.globl mul8x8_to16
mul8x8_to16:
    andi  a0, a0, 0xFF
    andi  a1, a1, 0xFF
    mv    t1, a0
    mv    t2, a1
    li    t0, 0
    li    t3, 8
mul8x8_to16_loop:
    andi  t4, t2, 1
    beqz  t4, mul8x8_to16_skip
    add   t0, t0, t1
mul8x8_to16_skip:
    slli  t1, t1, 1
    srli  t2, t2, 1
    addi  t3, t3, -1
    bnez  t3, mul8x8_to16_loop
    mv    a0, t0
    ret


.globl bf16_add
bf16_add:
    addi  sp, sp, -28
    sw    ra, 24(sp)
    sw    s0,  0(sp)
    sw    s1,  4(sp)
    sw    s2,  8(sp)
    sw    s3, 12(sp)
    sw    s4, 16(sp)
    sw    s5, 20(sp)

    srli  s0, a0, 15
    andi  s0, s0, 1          # s0 = sign_a
    srli  s1, a1, 15
    andi  s1, s1, 1          # s1 = sign_b

    srli  s2, a0, 7
    andi  s2, s2, 0xFF       # s2 = exp_a
    srli  s3, a1, 7
    andi  s3, s3, 0xFF       # s3 = exp_b

    andi  s4, a0, 0x7F       # s4 = mant_a
    andi  s5, a1, 0x7F       # s5 = mant_b

    li    t0, 0xFF
    bne   s2, t0, bf16_add_chk
    bnez  s4, bf16_add_ret_a
    bne   s3, t0, bf16_add_ret_a
    bnez  s5, bf16_add_ret_b
    bne   s0, s1, bf16_add_ret_nan
    j     bf16_add_ret_b

bf16_add_chk:
    beq   s3, t0, bf16_add_ret_b

    li    t0, 0x7FFF
    and   t1, a0, t0
    beq   t1, x0, bf16_add_ret_b
    and   t1, a1, t0
    beq   t1, x0, bf16_add_ret_a

    beq   s2, x0, bf16_add_a_den_done
    ori   s4, s4, 0x80
bf16_add_a_den_done:
    beq   s3, x0, bf16_add_b_den_done
    ori   s5, s5, 0x80
bf16_add_b_den_done:

    sub   t1, s2, s3
    blt   x0, t1, bf16_add_grt
    beq   t1, x0, bf16_add_equ
    mv    t2, s3
    li    t0, -8
    blt   t1, t0, bf16_add_ret_b
    sub   t0, x0, t1
    srl   s4, s4, t0
    j     bf16_add_exp_dif

bf16_add_grt:
    mv    t2, s2
    li    t0, 8
    blt   t0, t1, bf16_add_ret_a
    srl   s5, s5, t1
    j     bf16_add_exp_dif

bf16_add_equ:
    mv    t2, s2

bf16_add_exp_dif:
    bne   s0, s1, bf16_add_diff_signs
    mv    t3, s0
    add   t4, s4, s5
    li    t0, 0x100
    and   t1, t4, t0
    beq   t1, x0, bf16_add_pack
    srli  t4, t4, 1
    addi  t2, t2, 1
    li    t0, 0xFF
    blt   t2, t0, bf16_add_pack
    slli  a0, t3, 15
    li    t5, 0x7F80
    or    a0, a0, t5
    j     bf16_add_ans

bf16_add_diff_signs:
    blt   s4, s5, bf16_add_gt_ma
    mv    t3, s0
    sub   t4, s4, s5
    j     bf16_add_norm

bf16_add_gt_ma:
    mv    t3, s1
    sub   t4, s5, s4

bf16_add_norm:
    beq   t4, x0, bf16_add_ret_zero
    mv    a0, t4
    jal   ra, clz8
    mv    t0, a0
    sll   t4, t4, t0
    sub   t2, t2, t0
    blt   t2, x0, bf16_add_ret_zero
    beq   t2, x0, bf16_add_ret_zero
    j     bf16_add_pack

bf16_add_ret_zero:
    li    a0, 0x0000
    j     bf16_add_ans

bf16_add_pack:
    slli  a0, t3, 15
    slli  t1, t2, 7
    or    a0, a0, t1
    andi  t4, t4, 0x7F
    or    a0, a0, t4
    j     bf16_add_ans

bf16_add_ret_b:
    mv    a0, a1
    j     bf16_add_ans

bf16_add_ret_nan:
    li    a0, 0x7FC0
    j     bf16_add_ans

bf16_add_ret_a:
    j     bf16_add_ans

bf16_add_ans:
    lw    s0,  0(sp)
    lw    s1,  4(sp)
    lw    s2,  8(sp)
    lw    s3, 12(sp)
    lw    s4, 16(sp)
    lw    s5, 20(sp)
    lw    ra, 24(sp)
    addi  sp, sp, 28
    ret


.globl bf16_sub
bf16_sub:
    addi  sp, sp, -8
    sw    ra, 4(sp)
    li    t0, 0x8000
    xor   a1, a1, t0
    jal   ra, bf16_add
    lw    ra, 4(sp)
    addi  sp, sp, 8
    ret


.globl bf16_div
bf16_div:
    addi  sp, sp, -24
    sw    s0,  0(sp)
    sw    s1,  4(sp)
    sw    s2,  8(sp)
    sw    s3, 12(sp)
    sw    s4, 16(sp)
    sw    s5, 20(sp)

    srli  s0, a0, 15
    andi  s0, s0, 1
    srli  s1, a1, 15
    andi  s1, s1, 1

    srli  s2, a0, 7
    andi  s2, s2, 0xFF
    srli  s3, a1, 7
    andi  s3, s3, 0xFF

    andi  s4, a0, 0x7F
    andi  s5, a1, 0x7F

    xor   t1, s0, s1
    li    t0, 0xff
    bne   s3, t0, bf16_div_exp_b_f
    bne   s5, x0, bf16_div_ret_b

    bne   s2, t0, bf16_div_l1
    bne   s4, x0, bf16_div_l1
    j     bf16_div_ret_nan
bf16_div_l1:
    slli  a0, t1, 15
    j     bf16_div_ans

bf16_div_exp_b_f:
    bne   s3, x0, bf16_div_skip
    bne   s5, x0, bf16_div_skip
    bne   s2, x0, bf16_div_skip2
    beq   s4, x0, bf16_div_ret_nan
bf16_div_skip2:
    slli  t1, t1, 15
    li    t2, 0x7F80
    or    a0, t1, t2
    j     bf16_div_ans

bf16_div_skip:
    bne   s2, t0, bf16_div_exp_a_f
    bne   s4, x0, bf16_div_ret_a
    slli  t1, t1, 15
    li    t2, 0x7F80
    or    a0, t1, t2
    j     bf16_div_ans

bf16_div_exp_a_f:
    beq   s2, x0, bf16_div_exp_a_is_zero
    j     bf16_div_l2
bf16_div_exp_a_is_zero:
    beq   s4, x0, bf16_div_a_is_zero_return
    j     bf16_div_l2
bf16_div_a_is_zero_return:
    slli  a0, t1, 15
    j     bf16_div_ans

bf16_div_l2:
    beq   s2, x0, bf16_div_l3
    ori   s4, s4, 0x80
bf16_div_l3:
    beq   s3, x0, bf16_div_l4
    ori   s5, s5, 0x80
bf16_div_l4:
    slli  t2, s4, 15
    mv    t3, s5
    li    t4, 0
    li    t5, 0

bf16_div_div_loop:
    li    t6, 16
    bge   t4, t6, bf16_div_out_loop
    slli  t5, t5, 1
    sub   t0, x0, t4
    addi  t0, t0, 15
    sll   t1, t3, t0
    bltu  t2, t1, bf16_div_cant_div
    sub   t2, t2, t1
    ori   t5, t5, 1
bf16_div_cant_div:
    addi  t4, t4, 1
    j     bf16_div_div_loop

bf16_div_out_loop:
    sub   t2, s2, s3
    addi  t2, t2, 127

    bne   s2, x0, bf16_div_l5
    addi  t2, t2, -1
bf16_div_l5:
    bne   s3, x0, bf16_div_l6
    addi  t2, t2, 1
bf16_div_l6:
    li    t0, 0x8000
    and   t3, t5, t0
    bne   t3, x0, bf16_div_set

bf16_div_norm_loop:
    and   t3, t5, t0
    bne   t3, x0, bf16_div_norm_done
    li    t6, 2
    blt   t2, t6, bf16_div_norm_done
    slli  t5, t5, 1
    addi  t2, t2, -1
    j     bf16_div_norm_loop

bf16_div_norm_done:
    srli  t5, t5, 8
    j     bf16_div_l7

bf16_div_set:
    srli  t5, t5, 8

bf16_div_l7:
    andi  t5, t5, 0x7F
    li    t0, 0xFF
    bge   t2, t0, bf16_div_ret_inf
    blt   t2, x0, bf16_div_ret_zero
    beq   t2, x0, bf16_div_ret_zero
    slli  a0, t1, 15
    andi  t2, t2, 0xFF
    slli  t2, t2, 7
    or    a0, a0, t2
    or    a0, a0, t5
    j     bf16_div_ans

bf16_div_ret_inf:
    slli  a0, t1, 15
    li    t0, 0x7F80
    or    a0, a0, t0
    j     bf16_div_ans

bf16_div_ret_zero:
    slli  a0, t1, 15
    j     bf16_div_ans

bf16_div_ret_b:
    mv    a0, a1
    j     bf16_div_ans

bf16_div_ret_nan:
    li    a0, 0x7FC0
    j     bf16_div_ans

bf16_div_ret_a:
    j     bf16_div_ans

bf16_div_ans:
    li    t0, 0xFFFF
    and   a0, a0, t0
    lw    s0,  0(sp)
    lw    s1,  4(sp)
    lw    s2,  8(sp)
    lw    s3, 12(sp)
    lw    s4, 16(sp)
    lw    s5, 20(sp)
    addi  sp, sp, 24
    ret


.globl bf16_mul
bf16_mul:
    addi  sp, sp, -28
    sw    s0,  0(sp)
    sw    s1,  4(sp)
    sw    s2,  8(sp)
    sw    s3, 12(sp)
    sw    s4, 16(sp)
    sw    s5, 20(sp)
    sw    ra, 24(sp)

    srli  s0, a0, 15
    andi  s0, s0, 1
    srli  s1, a1, 15
    andi  s1, s1, 1

    srli  s2, a0, 7
    andi  s2, s2, 0xFF
    srli  s3, a1, 7
    andi  s3, s3, 0xFF

    andi  s4, a0, 0x7F
    andi  s5, a1, 0x7F

    li    t0, 0xff
    xor   t1, s0, s1
    bne   s2, t0, bf16_mul_a_exp
    bne   s4, x0, bf16_mul_ret_b
    bne   s3, x0, bf16_mul_inf1
    beq   s5, x0, bf16_mul_ret_nan
bf16_mul_inf1:
    slli  t2, t1, 15
    li    t3, 0x7F80
    or    a0, t2, t3
    j     bf16_mul_ans

bf16_mul_a_exp:
    bne   s3, t0, bf16_mul_b_exp
    bne   s5, x0, bf16_mul_ret_b
    bne   s2, x0, bf16_mul_inf2
    beq   s4, x0, bf16_mul_ret_nan
bf16_mul_inf2:
    slli  t2, t1, 15
    li    t3, 0x7F80
    or    a0, t2, t3
    j     bf16_mul_ans

bf16_mul_b_exp:
    bne   s2, x0, bf16_mul_skip1
    beq   s4, x0, bf16_mul_zero_ret
bf16_mul_skip1:
    bne   s3, x0, bf16_mul_skip2
    bne   s4, x0, bf16_mul_skip2
bf16_mul_zero_ret:
    srli  a0, t1, 15
    j     bf16_mul_ans

bf16_mul_skip2:
    li    t2, 0
    bne   s2, x0, bf16_mul_else_a
    mv    a0, s4
    jal   ra, clz8
    mv    t0, a0
    sll   s4, s4, t0
    sub   t2, t2, t0
    li    s2, 1
bf16_mul_else_a:
    ori   s4, s4, 0x80
    bne   s3, x0, bf16_mul_else_b
    mv    a0, s5
    jal   ra, clz8
    mv    t0, a0
    sll   s5, s5, t0
    sub   t2, t2, t0
    li    s3, 1
bf16_mul_else_b:
    ori   s5, s5, 0x80
    mv    a0, s4
    mv    a1, s5
    jal   ra, mul8x8_to16
    mv    t3, a0

    xor   t1, s0, s1
    add   t4, s2, s3
    addi  t4, t4, -127
    add   t4, t4, t2

    li    t5, 0x8000
    and   t0, t3, t5
    beq   t0, x0, bf16_mul_l2
    srli  t3, t3, 8
    andi  t3, t3, 0x7F
    addi  t4, t4, 1
    j     bf16_mul_mant
bf16_mul_l2:
    srli  t3, t3, 7
    andi  t3, t3, 0x7F
bf16_mul_mant:
    li    t0, 0xFF
    blt   t4, t0, bf16_mul_skip3
    slli  a0, t1, 15
    li    t0, 0x7F80
    or    a0, a0, t0
    j     bf16_mul_ans

bf16_mul_skip3:
    blt   x0, t4, bf16_mul_pack
    addi  t0, x0, -6
    blt   t4, t0, bf16_mul_underflow
    li    t0, 1
    sub   t0, t0, t4
    srl   t3, t3, t0
    li    t4, 0
    j     bf16_mul_pack

bf16_mul_underflow:
    srli  a0, t1, 15
    j     bf16_mul_ans

bf16_mul_pack:
    andi  t1, t1, 1
    slli  t1, t1, 15
    andi  t4, t4, 0xFF
    slli  t4, t4, 7
    andi  t3, t3, 0x7F
    or    a0, t1, t4
    or    a0, a0, t3
    li    t0, 0xFFFF
    and   a0, a0, t0
    j     bf16_mul_ans

bf16_mul_ret_b:
    mv    a0, a1
    j     bf16_mul_ans

bf16_mul_ret_nan:
    li    a0, 0x7FC0
    j     bf16_mul_ans

bf16_mul_ret_a:
    j     bf16_mul_ans

bf16_mul_ans:
    lw    s0,  0(sp)
    lw    s1,  4(sp)
    lw    s2,  8(sp)
    lw    s3, 12(sp)
    lw    s4, 16(sp)
    lw    s5, 20(sp)
    lw    ra, 24(sp)
    addi  sp, sp, 28
    ret


.globl bf16_isnan
bf16_isnan:
    li    t0, 0x7F80
    and   t1, a0, t0
    bne   t1, t0, bf16_isnan_false
    andi  t1, a0, 0x007F
    beq   t1, x0, bf16_isnan_false
    li    a0, 1
    ret
bf16_isnan_false:
    li    a0, 0
    ret


.globl bf16_isinf
bf16_isinf:
    li    t0, 0x7F80
    and   t1, a0, t0
    bne   t1, t0, bf16_isinf_false
    andi  t1, a0, 0x007F
    bne   t1, x0, bf16_isinf_false
    li    a0, 1
    ret
bf16_isinf_false:
    li    a0, 0
    ret


.globl bf16_iszero
bf16_iszero:
    li    t0, 0x7FFF
    and   t1, a0, t0
    bne   t1, x0, bf16_iszero_false
    li    a0, 1
    ret
bf16_iszero_false:
    li    a0, 0
    ret


.globl f32_to_bf16
f32_to_bf16:
    srli t1, a0, 23
    andi t1, t1, 0xFF
    li   t2, 0xFF
    bne  t1, t2, f32_to_bf16_L1
    srli a0, a0, 16
    ret
f32_to_bf16_L1:
    srli t1, a0, 16
    andi t1, t1, 1
    add  a0, a0, t1
    li   t3, 0x7FFF
    add  a0, a0, t3
    srli a0, a0, 16
    ret


.globl bf16_to_f32
bf16_to_f32:
    slli a0, a0, 16
    ret





