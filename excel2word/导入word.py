#-*- coding:utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
#
# Author:      liushuqing506
#
# Created:     10/05/2018
# Copyright:   (c) liushuqing506 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import win32com
from win32com.client import Dispatch, constants
w = win32com.client.Dispatch('Word.Application')
# 或者使用下面的方法，使用启动独立的进程：
# w = win32com.client.DispatchEx('Word.Application')
# 后台运行，不显示，不警告
w.Visible = 0
w.DisplayAlerts = 0
# 打开新的文件
FileName=r'C:\Users\liushuqing506\Desktop\ww\moban.doc'
title=['NO','data_duan_1','data_duan_2','data_duan_3','data_duan_4','data_duan_5','data_duan_6','data_duan_7','data_duan_8']
info=['1','智能手机','苏宁易购','苹果','Apple','iPhone8','201707001','6','6']
doc = w.Documents.Open(FileName)
w = win32com.client.Dispatch("Word.Application")
w.Visible = True
w.Selection.Find.ClearFormatting()
w.Selection.Find.Replacement.ClearFormatting()
for i in range(1,9):
            OldStr = title[i]
            NewStr = info[i]
            w.Selection.Find.Execute(OldStr, False, False, False, False, False, True, 1, True, NewStr, 2)#参数是固定的

w.Quit()