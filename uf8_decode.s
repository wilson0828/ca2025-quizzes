uf8_decode:
    andi  t0, a0, 0x0F       # mantissa = fl & 0x0F
    srli  t1, a0, 4          # exponent = fl >> 4

    li    t2, 1
    sll   t2, t2, t1         # t2 = 1 << e
    addi  t2, t2, -1         # t2 = (1<<e) - 1
    slli  t2, t2, 4          # offset = (2^e -1)*16

    sll   t0, t0, t1         # mantissa << e
    add   a0, t0, t2         # return
    ret
