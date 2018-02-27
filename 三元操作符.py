x=23
y=34
z=1
small = x if (x < y and x < z) else (y if y < z else z)
print(small)
