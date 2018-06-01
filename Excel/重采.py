# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块2
# Purpose:
# Author:      WIN7
# Created:     31/05/2018
# Copyright:   Python 3.0及以上
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import pandas as pd
import numpy as  np
from pandas import Series, DataFrame
import sys
import datetime
import os,shutil
import xlwt


delta = datetime.timedelta(days=1)
now= datetime.datetime.now()
i=now.strftime('%m%d_%H.%M')
j=now.strftime('%m%d')
k=now.strftime('%m-%d')

out_put = r'C:\Users\liushuqing506\Desktop\重采血\%s.xls'%i
path = r'C:\Users\liushuqing506\Desktop\重采血'
dirs = os.listdir(path)
for i in dirs:
    if ".xls" in i:
        if  k in i:
            file = r'C:\Users\liushuqing506\Desktop\重采血\%s'%i


def data_systerm(file):
        #读取9.10系统录入样本信息
        data_systerm = pd.read_excel(file,sheet_name=0,header=0) #此处header=0，取每一列要详细的列头作为索引
        data_systerm = data_systerm[['样品编号','FC号','机器编号','上机时间','重采血类型','重采血原样品编号','重采血样品编号','原样本重采血原因','原样本重采血原因备注']]
        return(data_systerm)
if str in [type(x) for x in list(data_systerm(file)['重采血样品编号'])]:
    if str in [type(x) for x in list(data_systerm(file)['原样本重采血原因备注'])]:
        data_systerm(file).to_excel(out_put,index=False,encoding='gbk')
    else:
        data_systerm(file).drop("原样本重采血原因备注", axis=1).to_excel(out_put,index=False,encoding='gbk')

else:
    if str in [type(x) for x in list(data_systerm(file)['原样本重采血原因备注'])]:
        data_systerm(file).drop("重采血样品编号", axis=1).to_excel(out_put,index=False,encoding='gbk')
    else:
        data_systerm(file).drop(["重采血样品编号",'原样本重采血原因备注'], axis=1).to_excel(out_put,index=False,encoding='gbk')
