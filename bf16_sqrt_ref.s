.data
.align 4
.text

.globl mul8x8_to16
mul8x8_to16:
    andi  a0, a0, 0xFF
    andi  a1, a1, 0xFF
    mv    t1, a0             # multiplicand
    mv    t2, a1             # multiplier
    li    t0, 0
    li    t3, 8
label1:
    andi  t4, t2, 1
    beqz  t4, label2
    add   t0, t0, t1         # acc += multiplicand
label2:
    slli  t1, t1, 1          # multiplicand <<= 1
    srli  t2, t2, 1          # multiplier >>= 1
    addi  t3, t3, -1
    bnez  t3, label1
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
    andi  s0, s0, 1          # sign
    srli  s1, a0, 7
    andi  s1, s1, 0xFF       # exp
    andi  s2, a0, 0x7F       # mant

    li    t0, 0xFF
    bne   s1, t0, a_exp
    beq   s2, x0, a_mant
    j     ret_a

a_mant:
    beq   s0, x0, a_sign
    li    a0, 0x7FC0
    j     ans
a_sign:
    j     ret_a

a_exp:
    bne   s1, x0, skip
    bne   s2, x0, skip
    li    a0, 0x0000
    j     ans

skip:
    beq   s0, x0, negative_skip
    li    a0, 0x7FC0
    j     ans

negative_skip:
    bne   s1, x0, denormals_skip
    li    a0, 0x0000
    j     ans

denormals_skip:
    addi  t1, s1, -127       # t1 = e
    ori   t2, s2, 0x80       # t2 = m

    andi  t0, t1, 1
    beq   t0, x0, else_part
    slli  t2, t2, 1
    addi  t0, t1, -1
    srai  t0, t0, 1
    addi  t3, t0, 127        # t3 = new_exp
    j     end_if

else_part:
    srai  t0, t1, 1
    addi  t3, t0, 127        # t3 = new_exp

end_if:
    li     s3, 90            # low
    li     s4, 255           # high
    li     s5, 128           # result
    mv     s6, t3

loop:
    bgtu   s3, s4, loop_done
    add    t0, s3, s4
    srli   t1, t0, 1         # mid

    mv     a0, t1
    mv     a1, t1
    mv     t5, t1            # protect mid
    mv     t6, t2            # protect m
    jal    mul8x8_to16
    mv     t0, a0            # mid*mid
    mv     t1, t5
    mv     t2, t6

    srli   t0, t0, 7         # sq (scaled)

    # original: if (sq <= m) do_if
    # use: if (m >= sq) do_if
    bleu   t0, t2, do_if
    addi   s4, t1, -1
    j      end_if2

do_if:
    mv     s5, t1
    addi   s3, t1, 1

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
    andi  t5, s5, 0x7F       # new_mant
    li    t0, 0xFF
    blt   t3, t0, no_overflow
    li    a0, 0x7F80
    j     ans

no_overflow:
    # original had missing comma; keep meaning: if (t3 > 0) go no_underflow
    bgt   t3, x0  no_underflow
    li    a0, 0
    j     ans

no_underflow:
    andi  t3, t3, 0xFF
    slli  t3, t3, 7
    or    a0, t3, t5
    j     ans

ret_a:
    j     ans

ans:
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
