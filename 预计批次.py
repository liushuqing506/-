### NIPT预计下机批次处理 ###
#Author:Shu Jingchao
import pandas as pd
import numpy as  np
import matplotlib.pyplot as plt
from pandas import Series, DataFrame
import re
import datetime
delta = datetime.timedelta(days=1)
regex = re.compile('[0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
now= datetime.datetime.now()
i=now.strftime('%m%d_%H.%M')
j=now.strftime('%m%d')
k=now.strftime('%Y%m%d')
m=(now - delta).strftime('%Y%m%d')
file = r'C:\Users\liushuqing506\Desktop\loading\%s.xlsx'%j
out_put = r'C:\Users\liushuqing506\Desktop\loading\%s.txt'%i
shanghai = ['TPNB500170','TPNB500170B','D00169','NS500251','NS500251B']
qingdao = ['7001459','TPNB500155','NS500548','TPNS500822']

#读取外地数据
data_waidi_1 = pd.read_excel(file,header=0)
data_waidi = data_waidi_1[['医院','最新批次']]
#data_waidi_pici=data_waidi_1[['最新批次']]#
#data_waidi_pici = data_waidi_pici.drop_duplicates(['最新批次']).reset_index(drop=True)#
data_waidi = data_waidi.drop_duplicates(['最新批次']).reset_index(drop=True)
data_waidi["日期"] = data_waidi["最新批次"].map(lambda x:x.split('_')[0])
data_waidi["机器编号"] = data_waidi["最新批次"].map(lambda x:x.split('_')[1])
data_waidi["系统编号"] = data_waidi["日期"] + '_' + data_waidi["机器编号"]
del data_waidi["日期"]
del data_waidi["机器编号"]
#del data_waidi["最新批次"]
data_waidi = DataFrame(data_waidi,columns=['医院','最新批次',"系统编号"])
for i in range(len(data_waidi.index)):
    if data_waidi['医院'][i] == '华西二院':
        data_waidi=data_waidi.drop(i)
    elif data_waidi['医院'][i] == '苏州市立医院(本部)':
        data_waidi=data_waidi.drop(i)
    elif data_waidi['医院'][i] == '郑州大学第一附属医院':
        data_waidi=data_waidi.drop(i)
    elif data_waidi['医院'][i] == '山东大学附属生殖医院':
        data_waidi=data_waidi.drop(i)
    elif data_waidi["系统编号"][i] == '2000_NS500255':
        data_waidi=data_waidi.drop(i)
    else:
        pass
data_waidi = data_waidi.reset_index(drop=True)
number_waidi = len(data_waidi.index)

#读取本地数据
data_bendi = pd.read_excel(file,sheet_name=1,header=0)
data_bendi = data_bendi[["样品编号",'FC号','机器编号','上机时间']]
data_bendi['上机时间'] = data_bendi['上机时间'].astype(str)
data_bendi = data_bendi.drop_duplicates(['FC号']).reset_index(drop=True)
for i in range(len(data_bendi.index)):
    if data_bendi['机器编号'][i] == 'Hiseq_SN1459_B':
        data_bendi['机器编号'][i] = "7001459"
    elif data_bendi['机器编号'][i] == 'Hiseq_SN1459_A':
        data_bendi['机器编号'][i] = "7001459"
    elif data_bendi['机器编号'][i] == 'D00169-B':
        data_bendi['机器编号'][i] = "D00169"
    else:
        pass
number_bendi =len(data_bendi.index)

#提取上海数据
data_shanghai = data_bendi[data_bendi['机器编号'].isin(shanghai)]
data_shanghai['上机时间'] = data_shanghai['上机时间'].str.findall(regex).str.join('-').str.split('-').str.join('')
data_shanghai['系统编号'] = data_shanghai['上机时间'] + '_' + data_shanghai['机器编号']
del data_shanghai['上机时间']
number_shanghai = len(data_shanghai.index)

#提取青岛数据
data_qingdao = data_bendi[data_bendi['机器编号'].isin(qingdao)]
for i in data_qingdao["机器编号"].index:
    if data_qingdao["机器编号"][i] == 'TPNS500822':
        data_qingdao["机器编号"][i] = 'NS500822'
    else:
        pass
data_qingdao['上机时间'] = data_qingdao['上机时间'].str.findall(regex).str.join('-').str.split('-').str.join('')
data_qingdao['系统编号'] = data_qingdao['上机时间'] + '_' + data_qingdao['机器编号']
del data_qingdao['上机时间']
number_qingdao = len(data_qingdao.index)

#提取北京数据
del_qingdao = np.setdiff1d(data_bendi.index.values,data_qingdao.index.values)
del_shanghaiandqingdao = np.setdiff1d(del_qingdao,data_shanghai.index.values)
data_beijing = data_bendi.loc[del_shanghaiandqingdao]
data_beijing['上机时间'] = data_beijing['上机时间'].str.findall(regex).str.join('-').str.split('-').str.join('')
data_beijing['系统编号'] = data_beijing['上机时间'] + '_' + data_beijing['FC号']
del data_beijing['上机时间']
number_beijing = len(data_beijing.index)

#合并数据
number_all = number_waidi + number_bendi
data_future = Series().append(data_waidi["系统编号"]).append(data_shanghai['系统编号']).append(data_qingdao['系统编号']).append(data_beijing['系统编号'])
data_future = data_future.reset_index(drop=True)
data_future[data_future.duplicated()] = data_future[data_future.duplicated()] + 'B'
#for  i in data_future:
#    if "NS500252B" in i:
#        data_future[list(data_future).index(i)] = i.replace("252B","252A")
#    elif "TPNB500170B" in i:
#        data_future[list(data_future).index(i)] = i.replace("170B","170A")
#    else:
#        pass

#读取NIPT系统数据
data_systerm = pd.read_excel(file,sheet_name=2,header=None)
data_systerm = data_systerm[1]
data_systerm1 = data_systerm.map(lambda x:x.split('_')[0])
data_systerm2 = data_systerm.map(lambda x:x.split('_')[1])


data_systerm = data_systerm1 + '_' + data_systerm2
#未进入系统的批次
data_out = Series(np.setdiff1d(data_future,data_systerm))
data_in = Series(np.setdiff1d(data_systerm,data_future))
for i in range(len(data_in)):
    if 'NB501478' in data_in[i]:
        data_in[i] += "---香港"
    elif 'NB501520' in data_in[i]:
        data_in[i] += "---香港"
    else:
        pass

#输出文件
f = open(out_put,'wt',encoding='utf-8')
f.write('外地批次数量：' + str(number_waidi) + '\n' + '本地批次数量：' + str(number_bendi))
f.write('\t'+"---"+'\t'+'北京' + str(number_beijing) + '批' + '\t'  + '上海' + str(number_shanghai) + '批' + '\t' + '青岛' + str(number_qingdao) + '批' + '\n')
f.write('\n外地批次：\n')
f.write(str(data_waidi))
f.write('\n\n北京批次：\n')
f.write(str(data_beijing))
f.write('\n\n上海批次：\n')
f.write(str(data_shanghai))
f.write('\n\n青岛批次：\n')
f.write(str(data_qingdao))
f.write('\n\n未进入系统批次(预计)(###今日%s###)：\n'%k)
f.write(str(data_out))
f.write('\n\n预计文件未统计进入(9.10)的批次(###今日%s###)：\n'%k)
f.write(str(data_in))
f.close()





