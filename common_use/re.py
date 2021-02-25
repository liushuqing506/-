https://www.cnblogs.com/xiaokuangnvhai/p/11213308.html

a = 'barcode02.2021-02-03.21.40.34.accumulated_composition.txt'
b = a.split('.accumulated_composition.txt')[0]
print(b)
print(re.match("barcode[0-9]*\.([0-9]{4}.*)",b).group(1))
>>>2021-02-03.21.40.34
