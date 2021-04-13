#!/usr/bin/env python
# coding=utf-8
# Author  : Chicho
# Function : draw the Histogram
# Date    : 2017-05-17

'''
引入必要的包
'''
import os
from numpy import array
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import plot,savefig

# 创建一个函数用来读取数据

def get_data(lines):  # 在这里lines = f.readlines()

    sizeArry = []  # 创建一个list,用来存储数据

    for line in lines:
        line = line.replace("\n", "")
        # 因为读出来的数据每一行都有一个回车符，我们要删除

        line = int(line)
        # 将其转换为整数

        sizeArry.append(line)
    # 转换为numpy 可以识别的数组

    return array(sizeArry)

def draw_hist(lenths):  #lenths 接受的其实是 sizeArry传来的数组 就是def get_data(lines) 返回的数据
    data = lenths
# 对数据进行切片，将数据按照从最小值到最大值分组，分成20组
#    bins = np.linspace(min(data),max(data),100)

# 这个是调用画直方图的函数，意思是把数据按照从bins的分割来画
    fig,ax0 = plt.subplots(ncols=2, figsize=(8, 4))
    ax0.hist(data,100, histtype='stepfilled', facecolor='g', alpha=0.75)
    ax0.set_title('stepfilled')
    plt.show()

# the path store the file
# 这里假设有一个文件叫做test.csv 存储的是我们要画的数据
#oriPath = "readLenTest.txt"
oriPath = 'read_len.txt'
# 首先打开文件从文件中读取数据
f = open(oriPath)  # path存储的是我们的目标文件所在的位置
# 我们先打开目标文件然后读取出这个文件中的每一行
lines = f.readlines()
linesList = [int(x.replace("\n", "")) for x in lines]
fig = plt.figure(figsize=(7,4),dpi=150)
#plt.hist(linesList,100,histtype='stepfilled',facecolor='#20B2AA',edgecolor='#4682B4',alpha=0.8)
plt.hist(linesList,300,histtype='stepfilled',facecolor='#20B2AA',alpha=0.8)
#plt.xticks(list(range(min(linesList), max(linesList)))[::2])
plt.xlabel("Read length")
plt.ylabel("Read count")
savefig("1.jpg")











