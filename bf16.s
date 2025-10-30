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
    
main:                            # BF16 MUL  (1~5)
    li      a0, 0x7F80          #1 Inf * 0 = NaN
    li      a1, 0x0000
    jal     ra, mul
    li      t6, 0x7FC0
    bne     a0, t6, fail
    li      t0, 1
    mv      s0, t0

    li      a0, 0x0000          #2  0 * 3 = 0
    li      a1, 0x4040
    jal     ra, mul
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x4000          #3  2 * 3 = 6
    li      a1, 0x4040
    jal     ra, mul
    li      t6, 0x40C0
    bne     a0, t6, fail

    li      a0, 0xC000          #4 -2 * 3 = -6
    li      a1, 0x4040
    jal     ra, mul
    li      t6, 0xC0C0
    bne     a0, t6, fail

    li      a0, 0x3FC0          #5 1.5 * 2 = 3
    li      a1, 0x4000
    jal     ra, mul
    li      t6, 0x4040
    bne     a0, t6, fail

                                # BF16 ADD (6~10)
    li      a0, 0x3F80          #6 1 + 1 = 2
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      t6, 0x4000
    bne     a0, t6, fail

    li      a0, 0x3F80          #7 1 + 0.5 = 1.5
    li      a1, 0x3F00
    jal     ra, bf16_add
    li      t6, 0x3FC0
    bne     a0, t6, fail

    li      a0, 0x4000          #8 2 + (-0.5) = 1.5
    li      a1, 0xBF00
    jal     ra, bf16_add
    li      t6, 0x3FC0
    bne     a0, t6, fail

    li      a0, 0xBF80          #9 -1 + 1 = 0
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x7F80          #10 +Inf + (-Inf) = NaN
    li      a1, 0xFF80
    jal     ra, bf16_add
    li      t6, 0x7FC0
    bne     a0, t6, fail

                                # BF16 SUB  (11~15)
    li      a0, 0x4040          #11 3 - 1 = 2
    li      a1, 0x3F80
    jal     ra, bf16_sub
    li      t6, 0x4000
    bne     a0, t6, fail

    li      a0, 0x3F80          #12 1 - 1 = 0
    li      a1, 0x3F80
    jal     ra, bf16_sub
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x3F80          #13 1 - (-1) = 2
    li      a1, 0xBF80
    jal     ra, bf16_sub
    li      t6, 0x4000
    bne     a0, t6, fail

    li      a0, 0xC000          #14 -2 - 3 = -5
    li      a1, 0x4040
    jal     ra, bf16_sub
    li      t6, 0xC0A0
    bne     a0, t6, fail

    li      a0, 0x7F80          #15 +Inf - +Inf = NaN
    li      a1, 0x7F80
    jal     ra, bf16_sub
    li      t6, 0x7FC0
    bne     a0, t6, fail

                                # BF16 DIV  (16~20)
    li      a0, 0x4040          #16 3 / 2 = 1.5
    li      a1, 0x4000
    jal     ra, bf16_div
    li      t6, 0x3FC0
    bne     a0, t6, fail

    li      a0, 0x3F80          #17 1 / 2 = 0.5
    li      a1, 0x4000
    jal     ra, bf16_div
    li      t6, 0x3F00
    bne     a0, t6, fail

    li      a0, 0x0000          #18 0 / 3 = 0
    li      a1, 0x4040
    jal     ra, bf16_div
    li      t6, 0x0000
    bne     a0, t6, fail

    li      a0, 0x3F80          #19 1 / 0 = +Inf
    li      a1, 0x0000
    jal     ra, bf16_div
    li      t6, 0x7F80
    bne     a0, t6, fail

    li      a0, 0x0000          #20 0 / 0 = NaN
    li      a1, 0x0000
    jal     ra, bf16_div
    li      t6, 0x7FC0
    bne     a0, t6, fail
    
                                # BF16 ISNAN 測試 (21~23)
    li      a0, 0x7FC1          #21 isnan(+qNaN) = 1
    jal     ra, bf16_isnan
    li      t6, 1
    bne     a0, t6, fail     

 
    li      a0, 0x7F81          #22 isnan(+sNaN-ish) = 1
    jal     ra, bf16_isnan
    li      t6, 1
    bne     a0, t6, fail     

    li      a0, 0x7F80          #23 isnan(+Inf) = 0
    jal     ra, bf16_isnan
    li      t6, 0
    bne     a0, t6, fail     

                                  # BF16 ISINF 測試 (24~26)
    li      a0, 0x7F80            #24 isinf(+Inf) = 1    
    jal     ra, bf16_isinf
    li      t6, 1
    bne     a0, t6, fail     

    li      a0, 0xFF80                 #25 isinf(-Inf) = 1
    jal     ra, bf16_isinf
    li      t6, 1
    bne     a0, t6, fail        

    li      a0, 0x7FC0               #26 isinf(NaN) = 0
    jal     ra, bf16_isinf
    li      t6, 0
    bne     a0, t6, fail     
    
                                      # BF16 ISZERO 測試 (27~29)
    li      a0, 0x0000                #27 iszero(+0) = 1
    jal     ra, bf16_iszero
    li      t6, 1
    bne     a0, t6, fail     

    li      a0, 0x8000                  #28 iszero(-0) = 1
    jal     ra, bf16_iszero
    li      t6, 1
    bne     a0, t6, fail    

    li      a0, 0x0001             #29 iszero(subnormal != 0) = 0
    jal     ra, bf16_iszero
    li      t6, 0
    bne     a0, t6, fail    

                                        # f32_to_bf16 測試 (30~32)
    li      a0, 0x3F800000               #30 1.0f -> 0x3F80
    jal     ra, f32_to_bf16
    li      t6, 0x3F80
    bne     a0, t6, fail     

    li      a0, 0x3F7F8000                #31 0x3F7F8000 會 round to even -> 0x3F80
    jal     ra, f32_to_bf16
    li      t6, 0x3F80
    bne     a0, t6, fail        

    li      a0, 0x7FC00001                   #32 NaN 保留高 16 位 -> 0x7FC0
    jal     ra, f32_to_bf16
    li      t6, 0x7FC0
    bne     a0, t6, fail     

                                            # bf16_to_f32 測試 (33~35)
    li      a0, 0x3F80                    #33 0x3F80 -> 1.0f
    jal     ra, bf16_to_f32
    li      t6, 0x3F800000
    bne     a0, t6, fail     

    li      a0, 0x7F80                     #34 0x7F80 -> +Inf
    jal     ra, bf16_to_f32
    li      t6, 0x7F800000
    bne     a0, t6, fail     

    li      a0, 0xC000                    #35 0xC000 -> -2.0f
    jal     ra, bf16_to_f32
    li      t6, 0xC0000000
    bne     a0, t6, fail  
                                    # BF16 SQRT (36~38)
    li      a0, 0x7F80          #36 sqrt(+Inf) = +Inf
    jal     ra, bf16_sqrt
    li      t6, 0x7F80
    bne     a0, t6, fail

    li      a0, 0x3E80          #37 sqrt(0.25) = 0.5
    jal     ra, bf16_sqrt
    li      t6, 0x3F00
    bne     a0, t6, fail

    li      a0, 0x4110          #38 sqrt(9.0) = 3.0
    jal     ra, bf16_sqrt
    li      t6, 0x4040
    bne     a0, t6, fail
   

ok:
    li      a0, 0               # all passed
    li      a7, 10
    ecall
fail:
    li      a7, 10
    ecall

clz8:
    andi  a0, a0, 0xFF
    la    t0, clz8_lut
    add   t0, t0, a0
    lbu   a0, 0(t0)
    ret

# --- 8x8 -> 16 無乘法器版本 ---
    .globl mul8x8_to16
mul8x8_to16:
    andi  a0, a0, 0xFF
    andi  a1, a1, 0xFF
    mv    t1, a0             # t1 = multiplicand
    mv    t2, a1             # t2 = multiplier
    li    t0, 0              # t0 = acc
    li    t3, 8
mul8_loop:
    andi  t4, t2, 1
    beqz  t4, mul8_skipadd
    add   t0, t0, t1
mul8_skipadd:
    slli  t1, t1, 1
    srli  t2, t2, 1
    addi  t3, t3, -1
    bnez  t3, mul8_loop
    mv    a0, t0
    ret

# --- BF16 乘法 ---
    .globl mul
mul:
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

    li    t0, 0xFF
    xor   t1, s0, s1
    bne   s2, t0, mul_a_exp
    bne   s4, x0, mul_ret_b
    bne   s3, x0, mul_inf1
    beq   s5, x0, mul_ret_nan
mul_inf1:
    slli  t2, t1, 15
    li    t3, 0x7F80
    or    a0, t2, t3
    j     mul_ans
mul_a_exp:
    bne   s3, t0, mul_b_exp
    bne   s5, x0, mul_ret_b
    bne   s2, x0, mul_inf2
    beq   s4, x0, mul_ret_nan
mul_inf2:
    srli  t2, t1, 15
    li    t3, 0x7F80
    or    a0, t2, t3
    j     mul_ans
mul_b_exp:
    bne   s2, x0, mul_skip1
    beq   s4, x0, mul_l1
mul_skip1:
    bne   s3, x0, mul_skip2
    bne   s4, x0, mul_skip2
mul_l1:
    srli  a0, t1, 15
    j     mul_ans
mul_skip2:
    li    t2, 0
    bne   s2, x0, mul_else_a
    mv    a0, s4
    jal   ra, clz8
    mv    t0, a0
    sll   s4, s4, t0
    sub   t2, t2, t0
    li    s2, 1
mul_else_a:
    ori   s4, s4, 0x80
    bne   s3, x0, mul_else_b
    mv    a0, s5
    jal   ra, clz8
    mv    t0, a0
    sll   s5, s5, t0
    sub   t2, t2, t0
    li    s3, 1
mul_else_b:
    ori   s5, s5, 0x80
    mv    a0, s4
    mv    a1, s5
    jal   mul8x8_to16
    mv    t3, a0
    xor   t1, s0, s1
    add   t4, s2, s3
    addi  t4, t4, -127
    add   t4, t4, t2
    li    t5, 0x8000
    and   t0, t3, t5
    beq   t0, x0, mul_l2
    srli  t3, t3, 8
    andi  t3, t3, 0x7F
    addi  t4, t4, 1
    j     mul_mant
mul_l2:
    srli  t3, t3, 7
    andi  t3, t3, 0x7F
mul_mant:
    li    t0, 0xFF
    blt   t4, t0, mul_skip3
    srli  t1, t1, 15
    li    t0, 0x7F80
    or    a0, a0, t0
    j     mul_ans
mul_skip3:
    blt   x0, t4, mul_l3
    addi  t0, x0, -6
    blt   t4, t0, mul_l4
    li    t0, 1
    sub   t0, t0, t4
    srl   t3, t3, t0
    li    t4, 0
    j     mul_l3
mul_l4:
    srli  a0, t1, 15
    j     mul_ans
mul_l3:
    andi  t1, t1, 1
    slli  t1, t1, 15
    andi  t4, t4, 0xFF
    slli  t4, t4, 7
    andi  t3, t3, 0x7F
    or    a0, t1, t4
    or    a0, a0, t3
    li    t0, 0xFFFF
    and   a0, a0, t0
    j     mul_ans

mul_ret_inf:
    slli  a0, t1, 15
    li    t0, 0x7F80
    or    a0, a0, t0
    j     mul_ans
mul_ret_zero:
    slli  a0, t1, 15
    j     mul_ans
mul_ret_b:
    mv    a0, a1
    j     mul_ans
mul_ret_nan:
    li    a0, 0x7FC0
    j     mul_ans
mul_ret_a:
    j     mul_ans
mul_ans:
    lw    s0,  0(sp)
    lw    s1,  4(sp)
    lw    s2,  8(sp)
    lw    s3, 12(sp)
    lw    s4, 16(sp)
    lw    s5, 20(sp)
    lw    ra, 24(sp)
    addi  sp, sp, 28
    ret

# --- BF16 除法 ---
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
    li    t0, 0xFF
    bne   s3, t0, div_exp_b_f
    bne   s5, x0, div_ret_b
    bne   s2, t0, div_l1
    bne   s4, x0 ,div_l1
    j     div_ret_nan
div_l1:
    slli  a0, t1, 15
    j     div_ans
div_exp_b_f:
    bne   s3, x0, div_skip
    bne   s5, x0, div_skip
    bne   s2, x0, div_skip2
    beq   s4, x0, div_ret_nan
div_skip2:
    slli  t1, t1, 15
    li    t2, 0x7F80
    or    a0, t1, t2
    j     div_ans
div_skip:
    bne   s2, t0, div_exp_a_f
    bne   s4, x0, div_ret_a
    slli  t1, t1, 15
    li    t2, 0x7F80
    or    a0, t1, t2
    j     div_ans
div_exp_a_f:
    beq   s2, x0, div_exp_a_is_zero
    j     div_l2
div_exp_a_is_zero:
    beq   s4, x0, div_a_is_zero_return
    j     div_l2
div_a_is_zero_return:
    slli  a0, t1, 15
    j     div_ans
div_l2:
    beq   s2, x0, div_l3
    ori   s4, s4, 0x80
div_l3:
    beq   s3, x0, div_l4
    ori   s5, s5, 0x80
div_l4:
    slli  t2, s4, 15      # dividend
    mv    t3, s5          # divisor
    li    t4, 0           # counter
    li    t5, 0           # quotient
div_loop:
    li    t6, 16
    bge   t4, t6, div_out_loop
    slli  t5, t5, 1
    sub   t0, x0, t4
    addi  t0, t0, 15
    sll   t1, t3, t0
    bltu  t2, t1, div_cant_div
    sub   t2, t2, t1
    ori   t5, t5, 1
div_cant_div:
    addi  t4, t4, 1
    j     div_loop
div_out_loop:
    sub   t2, s2, s3
    addi  t2, t2, 127

    bne   s2, x0, div_l5
    addi  t2, t2, -1
div_l5:
    bne   s3, x0, div_l6
    addi  t2, t2, 1
div_l6:
    li    t0, 0x8000
    and   t3, t5, t0
    bne   t3, x0, div_set
div_norm_loop:
    and   t3, t5, t0
    bne   t3, x0, div_norm_done
    li    t6, 2
    blt   t2, t6, div_norm_done
    slli  t5, t5, 1
    addi  t2, t2, -1
    j     div_norm_loop
div_norm_done:
    srli  t5, t5, 8
    j     div_l7
div_set:
    srli  t5, t5, 8
div_l7:
    andi  t5, t5, 0x7F
    li    t0, 0xFF
    bge   t2, t0, div_ret_inf
    blt   t2, x0, div_ret_zero
    beq   t2, x0, div_ret_zero
    slli  a0, t1, 15
    andi  t2, t2, 0xFF
    slli  t2, t2, 7
    or    a0, a0, t2
    or    a0, a0, t5
    j     div_ans

div_ret_inf:
    slli  a0, t1, 15
    li    t0, 0x7F80
    or    a0, a0, t0
    j     div_ans
div_ret_zero:
    slli  a0, t1, 15
    j     div_ans
div_ret_b:
    mv    a0, a1
    j     div_ans
div_ret_nan:
    li    a0, 0x7FC0
    j     div_ans
div_ret_a:
    j     div_ans
div_ans:
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

# --- BF16 減法（呼叫 add） ---
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

# --- BF16 加法 ---
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
    andi  s0, s0, 1
    srli  s1, a1, 15
    andi  s1, s1, 1

    srli  s2, a0, 7
    andi  s2, s2, 0xFF
    srli  s3, a1, 7
    andi  s3, s3, 0xFF

    andi  s4, a0, 0x7F
    andi  s5, a1, 0x7F

    li    t0, 0xFF
    bne   s2, t0, add_chk
    bnez  s4, add_ret_a
    bne   s3, t0, add_ret_a
    bnez  s5, add_ret_b
    bne   s0, s1, add_ret_nan
    j     add_ret_b
add_chk:
    beq   s3, t0, add_ret_b

    li    t0, 0x7FFF
    and   t1, a0, t0
    beq   t1, x0, add_ret_b
    and   t1, a1, t0
    beq   t1, x0, add_ret_a
    beq   s2, x0, add_l1
    ori   s4, s4, 0x80
add_l1:
    beq   s3, x0, add_l2
    ori   s5, s5, 0x80
add_l2:
    sub   t1, s2, s3
    blt   x0, t1, add_grt
    beq   t1, x0, add_equ
    mv    t2, s3
    li    t0, -8
    blt   t1, t0, add_ret_b
    sub   t0, x0 ,t1
    srl   s4, s4, t0
    j     add_exp_dif
add_grt:
    mv    t2, s2
    li    t0, 8
    blt   t0, t1, add_ret_a
    srl   s5, s5, t1
    j     add_exp_dif
add_equ:
    mv    t2, s2
add_exp_dif:
    bne   s0, s1, add_diff_signs
    mv    t3, s0
    add   t4, s4, s5
    li    t0, 0x100
    and   t1, t4, t0
    beq   t1, x0, add_pack
    srli  t4, t4, 1
    addi  t2, t2, 1
    li    t0, 0xFF
    blt   t2, t0, add_pack
    slli  a0, t3, 15
    li    t5, 0x7F80
    or    a0, a0, t5
    j     add_ans
add_diff_signs:
    blt   s4, s5, add_gt_ma
    mv    t3, s0
    sub   t4, s4, s5
    j     add_l3
add_gt_ma:
    mv    t3, s1
    sub   t4, s5, s4
add_l3:
    beq   t4, x0, add_ret_zero
    mv    a0, t4
    jal   ra, clz8
    mv    t0, a0
    sll   t4, t4, t0
    sub   t2, t2, t0
    blt   t2, x0, add_ret_zero
    beq   t2, x0, add_ret_zero
    j     add_pack
add_ret_zero:
    li    a0, 0x0000
    j     add_ans
add_pack:
    slli  a0, t3, 15
    slli  t1, t2, 7
    or    a0, a0, t1
    andi  t4, t4, 0x7F
    or    a0, a0, t4
    j     add_ans
add_ret_b:
    mv    a0, a1
    j     add_ans
add_ret_nan:
    li    a0, 0x7FC0
    j     add_ans
add_ret_a:
    j     add_ans
add_ans:
    lw    s0,  0(sp)
    lw    s1,  4(sp)
    lw    s2,  8(sp)
    lw    s3, 12(sp)
    lw    s4, 16(sp)
    lw    s5, 20(sp)
    lw    ra, 24(sp)
    addi  sp, sp, 28
    ret

# --- 判斷 NaN / Inf / Zero ---
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

# --- f32 <-> bf16 轉換 ---
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

# --- BF16 平方根（使用現有 mul8x8_to16） ---
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
    andi  s0, s0, 1           # s0 = sign
    srli  s1, a0, 7
    andi  s1, s1, 0xFF        # s1 = exp
    andi  s2, a0, 0x7F        # s2 = mant

    li    t0, 0xFF
    bne   s1, t0, a_exp
    beq   s2, x0, a_mant
    j     ret_a
a_mant:
    beq   s0, x0, a_sign
    li    a0, 0x7FC0
    j     ans_sqrt
a_sign:
    j     ret_a
a_exp:
    bne   s1, x0, skip
    bne   s2, x0, skip
    li    a0, 0x0000
    j     ans_sqrt
skip:
    beq   s0, x0, negative_skip
    li    a0, 0x7FC0
    j     ans_sqrt
negative_skip:
    bne   s1, x0, denormals_skip
    li    a0, 0x0000
    j     ans_sqrt
denormals_skip:
    addi  t1, s1, -127        # t1 = e
    ori   t2, s2, 0x80        # t2 = m
    andi  t0, t1, 1
    beq   t0, x0 ,else
    slli  t2, t2, 1
    addi  t0, t1, 1
    srli  t0, t0, 1
    addi  t3, t0 ,127         # t3 = new_exp
    j     end_if
else:
    srli  t0, t1, 1
    addi  t3, t0, 127         # t3 = new_exp
end_if:
    li     s3, 90             # s3 = low
    li     s4, 256            # s4 = high
    li     s5, 128            # s5 = result
    mv     s6, t3             # s6 = new_exp backup
loop:
    bgtu   s3, s4, loop_done
    add    t0, s3, s4          # t0 = low+high
    srli   t1, t0, 1           # t1 = mid

    # --- 保護會被 callee 破壞的暫存器 ---
    mv     t5, t1              # t5 = mid (backup)
    mv     t6, t2              # t6 = m   (backup)

    mv     a0, t1              # a0 = mid
    mv     a1, t1              # a1 = mid
    jal    mul8x8_to16         # 回來後 t1/t2 可能已被破壞

    # --- 還原 ---
    mv     t1, t5              # t1 = mid (restore)
    mv     t2, t6              # t2 = m   (restore)

    srli   a0, a0, 7           # a0 = sq
    bleu   a0, t2, do_if
    addi   s4, t1, -1          # high = mid - 1
    j      end_if2
do_if:
    mv     s5, t1              # result = mid
    addi   s3, t1, 1           # low = mid + 1
end_if2:
    j      loop

loop_done:
    mv     t3, s6
    li     t0, 256
    bltu   s5, t0, l1
    srli   s5, s5, 1
    addi   t3, t3, 1
    j      l3
l1:
    li     t0, 128
    bgeu   s5, t0, l3
l2:
    li     t0, 128
    bgeu   s5, t0, l3
    slti   t2, t3, 2
    bne    t2, x0, l3
    slli   s5, s5, 1
    addi   t3, t3, -1
    j      l2
l3:
    andi  t5, s5, 0x7F        # t5 = new_mant
    li    t0, 0xFF
    blt   t3, t0, no_overflow
    li    a0, 0x7F80
    j     ans_sqrt
no_overflow:
    bgt   t3, x0, no_underflow
    li    a0, 0
    j     ans_sqrt
no_underflow:
    andi  t3, t3, 0xFF
    slli  t3, t3, 7
    or    a0, t3, t5
    j     ans_sqrt

ret_a:
    j     ans_sqrt

ans_sqrt:
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
