|--function.py
|--mainProcedures.py


---function.py

def add(list_temp):
    return sum(list_temp)

def merge(list_temp):
    return '_'.join([str(x) for x in list_temp])
    
    
---mainProcedures.py

import function

list_a = [1,3]

result1 = function.add(list_a)
result2 = function.merge(list_a)
print(result1)  返回4
print(result2)  返回1_3
