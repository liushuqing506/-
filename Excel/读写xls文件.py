新版的xls, xlsx的读写方法， 推荐使用库
https://www.cnblogs.com/MrLJC/p/3715783.html
    
    
pandas 处理excel
https://www.cnblogs.com/liulinghua90/p/9935642.html
https://blog.csdn.net/qq_42156420/article/details/82813482

----------------------------------------------------------------------
以下是旧版，不建议使用
import pandas as pd
from pandas import DataFrame
path_1 = r'C:\Users\WIN7\Desktop\新建文件夹 (2)\tracefile.xls'
list=[]
with open (path_1) as f:
    file=f.readlines()
    for i in file:
        list.append(i.strip().replace('\t',',').split(','))
data=DataFrame(list)
j=data[0][1]
path_2=r'C:\Users\WIN7\Desktop\新建文件夹 (2)\%s.NIPTplus_pos.xls'%j
with open (path_1) as f:
    file=f.readlines()
    for i in file:
        with open (path_2,"a") as f:
            f.write(i)
