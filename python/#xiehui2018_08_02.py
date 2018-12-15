# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
# Author:      WIN7
# Created:     23/11/2017
# Copyright:   Python 3.0及以上
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import pandas as pd
from pandas import DataFrame,Series
import numpy as np
import re
import datetime
import os
delta = datetime.timedelta(days=1)
now= datetime.datetime.now()
date=now.strftime('%m%d')
path = r"C:\Users\liushuqing506\Desktop\B今日写回"
out_put = r'C:\Users\liushuqing506\Desktop\B今日写回\Libary\%s.txt'%date
lib_path=r'C:\Users\liushuqing506\Desktop\B今日写回\Libary'
lib_dirs = os.listdir(lib_path)
if lib_dirs != []:
    if (date+'.txt') not in lib_dirs:
        with open(out_put,'w') as f:
            pass
else:
    with open(out_put,'w') as f:
        pass

dirs = os.listdir(path)
dirs=[x for x in dirs if re.match('\d{6}', x)]#开头6位是数字的

def lib(x):
    with open(x,encoding='utf-8-sig') as file:
        file=file.readlines()
        file=[x.strip() for x in file]
    return file

list_1=[]
for i in dirs:
    if i not in lib(out_put):
        list_1.append(i)
if list_1 != []:
    path_1= r"C:\Users\liushuqing506\Desktop\B今日写回\%s"%list_1[0]
    path_2= r"C:\Users\liushuqing506\Desktop\B今日写回\%s"%list_1[1]
    sheet_1=pd.read_excel(path_1,'网下IPO')
    sheet_1=DataFrame(sheet_1,columns=['SAMPLENO','CHR13_ZVALUE','CHR18_ZVALUE','CHR21_ZVALUE','STATUS','NOTE'])
    Normal=sheet_1[sheet_1['STATUS'].isin(['Normal'])]
    a=len(Normal[Normal['CHR13_ZVALUE']<=-3])
    A=len(Normal[Normal['CHR13_ZVALUE']>=3])
    b=len(Normal[Normal['CHR18_ZVALUE']<=-3])
    B=len(Normal[Normal['CHR18_ZVALUE']>=3])
    c=len(Normal[Normal['CHR21_ZVALUE']<=-3])
    C=len(Normal[Normal['CHR21_ZVALUE']>=3])
    print('正在检测批次为%s'%list_1[0])
    print("\n")
    if (a==0 and A==0) and (b==0 and B==0) and (c==0 and C==0):
        print('Normal样本三大染色体z值：正常')
    else:
        print('Normal样本三大染色体z值：异常')
    print("\n")
    N_note=sheet_1[~ sheet_1['NOTE'].isin(['--'])]
    del N_note['NOTE']
    print(N_note.reset_index(drop=True))
    print("\n")
    print('审核文件非Normal数量：%s'%len(N_note.index))
    with open (path_2) as f:
        lines=f.readlines()
    print('Comments文件非--数量：%s'%len(lines))
    #input()

else:
    print("检测文件不存在")
    input()

f = open(out_put,'a',encoding='utf-8-sig')
for i in dirs:
    if i not in lib(out_put):
        f.write(i+'\n')
f.close()

print("\n")
print('         记得写回！！！    记得写回！！！    记得写回！！！')

input()





