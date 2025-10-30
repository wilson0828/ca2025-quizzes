clz: 
    li t0, 32 # n = 32 
    li t1, 16 # c = 16 
Lwhile: 
    beq t1, x0, ans 
    srl t2, a0, t1 
    beq t2, x0, skip 
    sub t0, t0, t1 
    mv a0, t2 
skip: 
    srli t1, t1, 1 
    j Lwhile 
ans: 
    sub a0, t0, a0 
    ret
