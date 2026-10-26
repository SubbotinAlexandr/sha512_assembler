# SHA-512 (FIPS 180-4) for x86-64, GNU as, AT&T syntax.
#
#   void sha512(const void *data, size_t len, unsigned char out[64]);
#
# SysV AMD64 ABI: rdi = data, rsi = len, rdx = out.
# Scratch frame (1024 bytes):
#   0   .. 255  padding buffer (two blocks max)
#   256 .. 319  running hash H[0..7]
#   320 .. 383  working vars a..h
#   384 .. 1023 message schedule W[0..79]

    .equ TAIL, 0
    .equ H,   256
    .equ V,   320
    .equ W,   384

    .section .rodata
    .align 8
IV512:
    .quad 0x6a09e667f3bcc908, 0xbb67ae8584caa73b
    .quad 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1
    .quad 0x510e527fade682d1, 0x9b05688c2b3e6c1f
    .quad 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179

K512:
    .quad 0x428a2f98d728ae22, 0x7137449123ef65cd
    .quad 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc
    .quad 0x3956c25bf348b538, 0x59f111f1b605d019
    .quad 0x923f82a4af194f9b, 0xab1c5ed5da6d8118
    .quad 0xd807aa98a3030242, 0x12835b0145706fbe
    .quad 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2
    .quad 0x72be5d74f27b896f, 0x80deb1fe3b1696b1
    .quad 0x9bdc06a725c71235, 0xc19bf174cf692694
    .quad 0xe49b69c19ef14ad2, 0xefbe4786384f25e3
    .quad 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65
    .quad 0x2de92c6f592b0275, 0x4a7484aa6ea6e483
    .quad 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5
    .quad 0x983e5152ee66dfab, 0xa831c66d2db43210
    .quad 0xb00327c898fb213f, 0xbf597fc7beef0ee4
    .quad 0xc6e00bf33da88fc2, 0xd5a79147930aa725
    .quad 0x06ca6351e003826f, 0x142929670a0e6e70
    .quad 0x27b70a8546d22ffc, 0x2e1b21385c26c926
    .quad 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df
    .quad 0x650a73548baf63de, 0x766a0abb3c77b2a8
    .quad 0x81c2c92e47edaee6, 0x92722c851482353b
    .quad 0xa2bfe8a14cf10364, 0xa81a664bbc423001
    .quad 0xc24b8b70d0f89791, 0xc76c51a30654be30
    .quad 0xd192e819d6ef5218, 0xd69906245565a910
    .quad 0xf40e35855771202a, 0x106aa07032bbd1b8
    .quad 0x19a4c116b8d2d0c8, 0x1e376c085141ab53
    .quad 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8
    .quad 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb
    .quad 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3
    .quad 0x748f82ee5defb2fc, 0x78a5636f43172f60
    .quad 0x84c87814a1f0ab72, 0x8cc702081a6439ec
    .quad 0x90befffa23631e28, 0xa4506cebde82bde9
    .quad 0xbef9a3f7b2c67915, 0xc67178f2e372532b
    .quad 0xca273eceea26619c, 0xd186b8c721c0c207
    .quad 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178
    .quad 0x06f067aa72176fba, 0x0a637dc5a2c898a6
    .quad 0x113f9804bef90dae, 0x1b710b35131c471b
    .quad 0x28db77f523047d84, 0x32caab7b40c72493
    .quad 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c
    .quad 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a
    .quad 0x5fcb6fab3ad6faec, 0x6c44198c4a475817

    .text
    .globl sha512
    .type sha512, @function
sha512:
    push %rbp
    mov  %rsp, %rbp
    push %rbx
    push %r12
    push %r13
    push %r14
    push %r15
    sub  $1024, %rsp

    mov  %rdi, %r12                # data
    mov  %rsi, %r13                # len
    mov  %rdx, %r14                # out
    mov  %rsp, %r15                # scratch base

    lea  H(%r15), %rdi
    lea  IV512(%rip), %rsi
    mov  $8, %ecx
1:  mov  (%rsi), %rax
    mov  %rax, (%rdi)
    add  $8, %rsi
    add  $8, %rdi
    dec  %ecx
    jnz  1b

    mov  %r13, %rbx
2:  cmp  $128, %rbx
    jb   3f
    mov  %r12, %rdi
    call process_block
    add  $128, %r12
    sub  $128, %rbx
    jmp  2b
3:
    lea  TAIL(%r15), %rdi
    xor  %eax, %eax
    mov  $32, %ecx
4:  mov  %rax, (%rdi)
    add  $8, %rdi
    dec  %ecx
    jnz  4b

    lea  TAIL(%r15), %rdi
    mov  %r12, %rsi
    mov  %rbx, %rcx
    rep movsb
    movb $0x80, TAIL(%r15,%rbx,1)

    mov  $1, %edx
    cmp  $112, %rbx
    jb   5f
    mov  $2, %edx
5:
    mov  %edx, %eax
    shl  $7, %eax
    sub  $16, %eax                 # offset of the 128-bit length field

    mov  %r13, %rcx
    shl  $3, %rcx                  # low 64 bits of the bit length
    mov  %r13, %rsi
    shr  $61, %rsi                 # high 64 bits
    mov  %rsi, %rdi
    bswap %rdi
    mov  %rdi, TAIL(%r15,%rax,1)
    mov  %rcx, %rdi
    bswap %rdi
    mov  %rdi, TAIL+8(%r15,%rax,1)

    lea  TAIL(%r15), %r13
    mov  %edx, %ebx
6:  mov  %r13, %rdi
    call process_block
    add  $128, %r13
    dec  %ebx
    jnz  6b

    lea  H(%r15), %rdi
    mov  %r14, %rsi
    mov  $8, %ecx
7:  mov  (%rdi), %rax
    bswap %rax
    mov  %rax, (%rsi)
    add  $8, %rdi
    add  $8, %rsi
    dec  %ecx
    jnz  7b

    add  $1024, %rsp
    pop  %r15
    pop  %r14
    pop  %r13
    pop  %r12
    pop  %rbx
    pop  %rbp
    ret
    .size sha512, .-sha512

# process_block: compress one 128-byte block into H.
# in: rdi = block pointer, r15 = scratch base
# clobbers caller-saved registers and rbx
    .type process_block, @function
process_block:
    push %rbx
    push %rbp
    lea  W(%r15), %r9

    xor  %ecx, %ecx
1:  mov  (%rdi,%rcx,8), %rax
    bswap %rax
    mov  %rax, (%r9,%rcx,8)
    inc  %rcx
    cmp  $16, %rcx
    jb   1b

    mov  $16, %rcx
2:  mov  -16(%r9,%rcx,8), %rax     # W[t-2]
    mov  %rax, %rdx
    ror  $19, %rdx
    mov  %rax, %rbx
    ror  $61, %rbx
    xor  %rbx, %rdx
    mov  %rax, %rbx
    shr  $6, %rbx
    xor  %rbx, %rdx                # sigma1(W[t-2])
    add  -56(%r9,%rcx,8), %rdx     # + W[t-7]
    mov  -120(%r9,%rcx,8), %rax    # W[t-15]
    mov  %rax, %rbx
    ror  $1, %rbx
    mov  %rax, %rsi
    ror  $8, %rsi
    xor  %rsi, %rbx
    mov  %rax, %rsi
    shr  $7, %rsi
    xor  %rsi, %rbx                # sigma0(W[t-15])
    add  %rbx, %rdx
    add  -128(%r9,%rcx,8), %rdx    # + W[t-16]
    mov  %rdx, (%r9,%rcx,8)
    inc  %rcx
    cmp  $80, %rcx
    jb   2b

    lea  H(%r15), %rsi
    lea  V(%r15), %rdi
    mov  $8, %ecx
3:  mov  (%rsi), %rax
    mov  %rax, (%rdi)
    add  $8, %rsi
    add  $8, %rdi
    dec  %ecx
    jnz  3b

    lea  V(%r15), %r11
    lea  K512(%rip), %r10
    xor  %r8d, %r8d

.round:
    mov  56(%r11), %rax            # T1 = h
    mov  32(%r11), %rbx            # e
    mov  %rbx, %rdx
    ror  $14, %rdx
    mov  %rbx, %rsi
    ror  $18, %rsi
    xor  %rsi, %rdx
    mov  %rbx, %rsi
    ror  $41, %rsi
    xor  %rsi, %rdx                # Sigma1(e)
    add  %rdx, %rax
    mov  40(%r11), %rsi
    xor  48(%r11), %rsi
    and  %rbx, %rsi
    xor  48(%r11), %rsi            # Ch(e,f,g)
    add  %rsi, %rax
    add  (%r10,%r8,8), %rax        # + K[t]
    add  (%r9,%r8,8), %rax         # + W[t]

    mov  0(%r11), %rbx             # a
    mov  %rbx, %rdx
    ror  $28, %rdx
    mov  %rbx, %rsi
    ror  $34, %rsi
    xor  %rsi, %rdx
    mov  %rbx, %rsi
    ror  $39, %rsi
    xor  %rsi, %rdx                # Sigma0(a)
    mov  %rbx, %rsi
    and  8(%r11), %rsi             # a & b
    mov  %rbx, %rdi
    or   8(%r11), %rdi
    and  16(%r11), %rdi            # c & (a | b)
    or   %rdi, %rsi                # Maj(a,b,c)
    add  %rsi, %rdx                # T2

    mov  48(%r11), %rsi
    mov  %rsi, 56(%r11)
    mov  40(%r11), %rsi
    mov  %rsi, 48(%r11)
    mov  32(%r11), %rsi
    mov  %rsi, 40(%r11)
    mov  24(%r11), %rsi
    add  %rax, %rsi
    mov  %rsi, 32(%r11)            # e = d + T1
    mov  16(%r11), %rsi
    mov  %rsi, 24(%r11)
    mov  8(%r11), %rsi
    mov  %rsi, 16(%r11)
    mov  0(%r11), %rsi
    mov  %rsi, 8(%r11)
    add  %rdx, %rax
    mov  %rax, 0(%r11)             # a = T1 + T2

    inc  %r8
    cmp  $80, %r8
    jb   .round

    lea  H(%r15), %rdi
    mov  %r11, %rsi
    mov  $8, %ecx
4:  mov  (%rsi), %rax
    add  %rax, (%rdi)
    add  $8, %rsi
    add  $8, %rdi
    dec  %ecx
    jnz  4b

    pop  %rbp
    pop  %rbx
    ret
    .size process_block, .-process_block

    .section .note.GNU-stack,"",@progbits
