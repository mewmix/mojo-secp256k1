P = (1 << 256) - (1 << 32) - 977
MASK = (1 << 64) - 1

def hex_arr(arr):
    return [hex(x) for x in arr]

# (-1) in limbs
neg1_limbs = [
    0xfffffffefffffc2e,
    0xffffffffffffffff,
    0xffffffffffffffff,
    0xffffffffffffffff,
]

# (-1) as integer
neg1 = 0
for i, limb in enumerate(neg1_limbs):
    neg1 += limb << (64 * i)

# Schoolbook multiplication
t = [0] * 8
for i in range(4):
    for j in range(4):
        t[i+j] += neg1_limbs[i] * neg1_limbs[j]

# Carry propagation
for i in range(7):
    carry = t[i] >> 64
    t[i] &= MASK
    t[i+1] += carry

print("t:", hex_arr(t))

# Reduction
r = t[:4] + [0, 0]
h = t[4:]

c = 0
r[0], c = (r[0] + (h[0] << 32) + c) & MASK, (r[0] + (h[0] << 32) + c) >> 64
r[1], c = (r[1] + ((h[1] << 32) | (h[0] >> 32)) + c) & MASK, (r[1] + ((h[1] << 32) | (h[0] >> 32)) + c) >> 64
r[2], c = (r[2] + ((h[2] << 32) | (h[1] >> 32)) + c) & MASK, (r[2] + ((h[2] << 32) | (h[1] >> 32)) + c) >> 64
r[3], c = (r[3] + ((h[3] << 32) | (h[2] >> 32)) + c) & MASK, (r[3] + ((h[3] << 32) | (h[2] >> 32)) + c) >> 64
r[4] = c + (h[3] >> 32)

print("r after << 32:", hex_arr(r))

c = 0
K = 977
for i in range(4):
    lo = h[i] * K
    r[i], c = (r[i] + lo + c) & MASK, (r[i] + lo + c) >> 64

r[4] += c

print("r after 977*H:", hex_arr(r))
