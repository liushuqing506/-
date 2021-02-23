import re

#将数字格式化为带三位数逗号的字符串
def formatNumber(number):
    numStr='%d'%number
    formatStr=''
    numStr=numStr[::-1]
    i=0
    while i<len(numStr):
        formatStr+=numStr[i]
        i+=1
        if i%3==0:
            formatStr+=','
    formatStr=formatStr.strip(',')
    formatStr=formatStr[::-1]
    print formatStr
 
#从带逗号的字符串恢复成数字   
def restoreNumber(numStr):
    pattern=re.compile('\D')
    numList=pattern.split(numStr)
    numStr=''.join(numList)
    print int(numStr)

if __name__=='__main':   
    formatNumber(200000)
    restoreNumber('20,000,000')
    
结果输出：

>>>200,000

>>>20000000
