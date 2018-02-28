#-*- coding:utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
#
# Author:      liushuqing506
#
# Created:     28/02/2018
# Copyright:   (c) liushuqing506 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------
def find(arr,j):
    len1=len(arr)
    hasharr=[0]*(len1+5)
    arr2=[0]*(len1+5)
    i=0
    while i<len1:
        a=arr[i]%17
        while arr2[a] !=0:
            a+=1
            if i==len1:
                i=0
        hasharr[a]=arr[i]
        arr2[a]=1
        i+=1
    print(hasharr)
    print('\n')
    print(arr2)

    num=j%17
    while num<(len1+5):
        if arr2[num]==1:
            if hasharr[num]==j:
                print('找到，位置：%s'%num)
                num=len1+5
            else:
                num+=1
        else:
            print('不存在')
            num=len1+5
if __name__=="__main__":
    path=r"C:\Users\liushuqing506\Desktop\新建文件夹 (2)\num.txt"
    arr=[]
    with open (path) as f:
        str1=f.read()
        for i in str1.split():
            i = int(i)
            arr.append(i)
        print('原数组为：')
        print(arr)
        input=input('请输入你要查找的值：')
        find(arr,int(input))