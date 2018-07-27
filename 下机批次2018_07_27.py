# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
# Author:      WIN7
# Created:     19/07/2018
# Copyright:   Python 3.0及以上
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import pandas as pd
from pandas import DataFrame,Series
import numpy as np
import re
import datetime

delta = datetime.timedelta(days=1)
now= datetime.datetime.now()
i=now.strftime('%m%d_%H.%M')
j=now.strftime('%m%d')
k=now.strftime('%Y%m%d')
m=(now - delta).strftime('%Y%m%d')
path = r'C:\Users\liushuqing506\Desktop\loading\%s.xlsx'%j
out_put = r'C:\Users\liushuqing506\Desktop\loading\%s.csv'%i

#外地批次汇总
sheet_1=pd.read_excel(path,'Sheet1')
sheet_1=DataFrame(sheet_1,columns=['医院','最新批次'])
format_1_1=lambda x : re.match(r'(\S*)_(\S*)_(\d{4})_(\w{10})',x).group(1)+'_'+re.match(r'(\S*)_(\S*)_(\d{4})_(\w{10})',x).group(2)
format_1_2=lambda x : re.match(r'(\S*)_(\S*)_(\d{4})_(\w{10})',x).group(1)
format_1_3=lambda x : re.match(r'(\S*)_(\S*)_(\d{4})_(\w{10})',x).group(2)
format_1_4=lambda x : re.match(r'(\S*)_(\S*)_(\d{4})_(\w{10})',x).group(4)
sheet_1["FC"]=sheet_1['最新批次'].map(format_1_4)
sheet_1.drop_duplicates("FC",'first', inplace=True)  #去掉重复的FC号，只保留第一次出现的
sheet_1["系统编号"]=sheet_1['最新批次'].map(format_1_1)
sheet_1["重复编号"]=(sheet_1["系统编号"][sheet_1["系统编号"].duplicated()]+'A')
del sheet_1["重复编号"]
list_del=['NS500821','CUOWU180524','2000','NS500430','NS500826','NS500262','NS500824','CUOWU180719']
sheet_1["最新批次"]=sheet_1['最新批次'][~ sheet_1['最新批次'].map(format_1_2).isin(list_del)]
sheet_1=sheet_1.dropna()
sheet_1["最新批次"]=sheet_1['最新批次'][~ sheet_1['最新批次'].map(format_1_3).isin(list_del)]
sheet_1=sheet_1.dropna()


#本地批次汇总
sheet_2=pd.read_excel(path,'Sheet2')
sheet_2=DataFrame(sheet_2,columns=['样品编号','FC号','机器编号','上机时间'])
#根据某一列数据中重复元素删除其他行，只保留第一次出现的行，见下面
sheet_2.drop_duplicates('FC号','first', inplace=True)
format_2_1=lambda x : re.match(r'\d{2}(\S*)-(\S*)-(\S*)',str(x)).group(1) + re.match(r'(\S*)-(\S*)-(\S*)',str(x)).group(2) + re.match(r'(\S*)-(\S*)-(\S*)',str(x)).group(3)
format_2_2=lambda x : re.match(r'(\S*)_(\S*)_(\S*)',str(x)).group(1) +'_'+ re.match(r'(\S*)_(\S*)_(\S*)',str(x)).group(2)
format_2_3=lambda x : re.match(r'(\S*)_(\S*)_(\S*)',str(x)).group(1) +'_'+ re.match(r'(\S*)_(\S*)_(\S*)',str(x)).group(3)
format_2_4=lambda x : re.match(r'(\S*)_(\S*)_(\S*)',str(x)).group(3)
format_2_5=lambda x : re.match(r'(\S*)_(\S*)',str(x)).group(2)
qingdao=['7001459','TPNB500155','NS500548','NS500822']
shanghai=['TPNB500170','D00169','NS500251','NS500280']
sheet_2["日期"]=sheet_2['上机时间'].map(format_2_1)

#将某一列中的元素含有特定字符串替换为目的字符串，见下面
sheet_2['机器编号']=sheet_2.apply(lambda x: x['机器编号'].replace('TPNS500822','NS500822') if 'TPNS500822' in x['机器编号'] else x['机器编号'], axis=1)
sheet_2['机器编号']=sheet_2.apply(lambda x: x['机器编号'].replace('D00169-B','D00169') if 'D00169-B' in x['机器编号'] else x['机器编号'], axis=1)
sheet_2["青岛机器号"]=sheet_2['机器编号'][sheet_2['机器编号'].isin(qingdao)]
sheet_2["上海机器号"]=sheet_2['机器编号'][sheet_2['机器编号'].isin(shanghai)]
sheet_2["北京机器号"]=sheet_2['机器编号'][~ sheet_2['机器编号'].isin(shanghai+qingdao)]
sheet_2["青岛编号"]=sheet_2["日期"]+'_'+sheet_2["青岛机器号"]
sheet_2["上海编号"]=sheet_2["日期"]+'_'+sheet_2["上海机器号"]
sheet_2["北京编号"]=sheet_2["日期"]+'_'+sheet_2['FC号'][sheet_2['北京机器号'].notnull()]
sheet_2["系统编号"]=sheet_2["北京编号"].fillna(sheet_2["上海编号"]).fillna(sheet_2["青岛编号"])
#出现重复元素，第二次或者第三次...全部末尾添加B，见下面
sheet_2["重复一次"]=(sheet_2["系统编号"][sheet_2["系统编号"].duplicated()]+'B')
#sheet_2["系统编号"]=sheet_2["重复一次"].fillna(sheet_2["系统编号"])
sheet_2["重复二次"]=(sheet_2["重复一次"][sheet_2["重复一次"].duplicated()]+'C')
if True in [x for x in sheet_2["重复二次"].notnull()]:
    sheet_2["重复一次"]=sheet_2["重复二次"].fillna(sheet_2["重复一次"])
    sheet_2["系统编号"]=sheet_2["重复一次"].fillna(sheet_2["系统编号"])
else:
    sheet_2["系统编号"]=sheet_2["重复一次"].fillna(sheet_2["系统编号"])

#系统批次汇总
sheet_3=pd.read_excel(path,'Sheet3',header=None)
sheet_3=DataFrame(sheet_3,columns=[1])
format_3=lambda x : re.match(r'(\S*)_(\S*)_(\S*)',x).group(1)+'_'+re.match(r'(\S*)_(\S*)_(\S*)',x).group(2)
sheet_3["系统编号"]=sheet_3[1].map(format_3)

#data_merge = Series().append(sheet_1["系统编号"]).append(sheet_2["系统编号"])

waidi_out = Series(np.setdiff1d(sheet_1["系统编号"],sheet_3["系统编号"]))
bendi_out = Series(np.setdiff1d(sheet_2["系统编号"],sheet_3["系统编号"]))

waidi_pici=sheet_1[['医院','最新批次','系统编号']][sheet_1['系统编号'].isin(waidi_out)]
bendi_pici=sheet_2[['样品编号','FC号','机器编号','上机时间','系统编号']][sheet_2['系统编号'].isin(bendi_out)]

waidi_pici[',']=','
bendi_pici[',']=','
waidi_pici['医院']=waidi_pici.apply(lambda x: x['医院'].strip(), axis=1)
waidi_pici=waidi_pici[[',','医院',',','最新批次',',','系统编号']].reset_index(drop=True)
bendi_pici=bendi_pici[[',','样品编号',',','FC号',',','机器编号',',','上机时间',',','系统编号']].reset_index(drop=True)

#输出文件
f = open(out_put,'wt',encoding='utf-8-sig')
f.write(','+'外地批次未导入系统批次：'+','+'（外地系统编号末尾加A，两批次都要查询）\n')
f.write(str(waidi_pici)+'\n')
f.write('\n')
f.write(','+'本地批次未导入系统批次：'+','+'（本地系统编号末尾加B，两批次都要查询）\n')
f.write(str(bendi_pici)+'\n')
f.close()


