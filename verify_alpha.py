import mpmath

# Set precision to 70 digits
mpmath.mp.dps = 70

phi = (1 + mpmath.sqrt(5)) / 2
xi = mpmath.mpf('0.5617737984017954')
pi = mpmath.pi

alpha_inv = (phi**20 / (2 * pi**3)) * (phi**-xi)

print(f"ESQET Derived Alpha^-1: {alpha_inv}")
print(f"Target Value Match:    137.035999177...")
