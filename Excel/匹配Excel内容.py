import pandas as pd
import numpy as  np
from pandas import Series, DataFrame
import re
import sys
import datetime
regex = re.compile('[0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
delta = datetime.timedelta(days=1)
now= datetime.datetime.now()
i=now.strftime('%m%d_%H.%M')
j=now.strftime('%m%d')
file = r'C:\Users\liushuqing506\Desktop\%s.xlsx'%j
out_put = r'C:\Users\liushuqing506\Desktop\%s.csv'%i

def data_systerm(file):
        #读取9.10系统录入样本信息
        data_systerm = pd.read_excel(file,sheet_name=0,header=0) #此处header=0，取每一列要详细的列头作为索引
        data_systerm = data_systerm[['Sample','Num','Good','chrY_C','Sex_Type']]
        data_systerm["Flowcell"] = data_systerm['Sample'].map(lambda x:x.split('_')[1])
        data_systerm['Sample'] = data_systerm['Sample'].map(lambda x:x.split('_')[2])
        data_systerm = data_systerm[['Sample',"Flowcell",'Num','Good','chrY_C','Sex_Type']]
        return(data_systerm)

def data_yiyuan(file):
        #读取医院邮件反馈样本
        list_1=[]
        list_2=[]
        data_yiyuan = pd.read_excel(file,sheet_name=1,header=None)
        data_yiyuan = data_yiyuan[0]
        for i in data_yiyuan:
            list_1.append(i)
        list_1.pop(0) #去掉第一个字符串即“样本编号”
        for j in list_1:
            list_2 += data_systerm(file)[data_systerm(file).Sample==j].index.tolist() #list_2 为 data_systerm中j样本的索引
        data_out_yiyuan = data_systerm(file).ix[list_2].reset_index(drop=True)
        return(data_out_yiyuan)

def data_F(file):
    #读取F样本
    list_3=[]
    list_4=[]
    list_5=[]
    data_F = pd.read_excel(file,sheet_name=2,header=0)#此处header=None，data_F[0]就是第一列,即没有列头
    data_F_Sample = data_F["Sample"]
    data_out=data_yiyuan(file)#必须将data_yiyuan(file)函数赋值给新变量，后面才能对变量进行修改（函数值是不能修改的）
    for i in data_F_Sample:
        list_3.append(i)
    #list_3.pop(0) #去掉第一个字符串即“Sample”
    for j in list_3:
        list_4 += data_out[data_out.Sample==j].index.tolist()
        list_5 += data_F[data_F.Sample==j].index.tolist()
    data_out['chrY_C'][list_4] = data_F.ix[list_5].reset_index(drop=True)['report_cffDNA(%)']
    return(data_out)

try:

        #data_F = pd.read_excel(file,sheet_name=2,header=0)
        if "F" not in list(data_yiyuan(file)['Sex_Type']):
            print("无F样本！")
            data_yiyuan(file).to_csv(out_put,index=False)
            input()

        #elif data_F.empty == True:
            #print('Sheet3为:空白')
            #input()
        else:
            #写入新CSV文件
            data_F(file).to_csv(out_put,index=False)  #去除data_out的索引，若需要去除列头可添加条件“header=False”

except BaseException as e:
        print(e)
        print("异常原因：未创建Sheet3 or 空白Sheet3 or Sheet3中编号不匹配")
        input()
