#-*- coding:utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
#
# Author:      liushuqing506
#
# Created:     21/11/2017
# Copyright:   (c) liushuqing506 2017
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import os,shutil
path = r"C:\Users\liushuqing506\Desktop\A今日批次"
dirs = os.listdir(path)
for i in dirs:
    if ".xls" in i:
        shutil.move(r"C:\Users\liushuqing506\Desktop\A今日批次\%s"%i,r"C:\Users\liushuqing506\Desktop\A今日批次\over\%s"%i)#前面是旧的路径文件，后面是新的路径文件
path = r"C:\Users\liushuqing506\Desktop\B今日写回"
dirs = os.listdir(path)
for i in dirs:
    if ".xls"  in i:
        shutil.move(r"C:\Users\liushuqing506\Desktop\B今日写回\%s"%i,r"C:\Users\liushuqing506\Desktop\B今日写回\over\%s"%i)
    elif ".txt"   in i:
        shutil.move(r"C:\Users\liushuqing506\Desktop\B今日写回\%s"%i,r"C:\Users\liushuqing506\Desktop\B今日写回\over\%s"%i)

