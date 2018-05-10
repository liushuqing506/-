#-*- coding:utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
#
# Author:      liushuqing506
#
# Created:     09/05/2018
# Copyright:   (c) liushuqing506 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import xlrd
import win32com.client
import easygui as g
from os import getcwd
from tkinter import Tk, Text, Button, Label
self = getcwd()
def choosedata():
    return g.fileopenbox(msg='请打开数据文件',  title=None, default='*', filetypes=None)
def savename(c):
    choice = g.choicebox(msg='请选择一列内容作为保存Word文件的名称', title='文件名称选择', choices=c)#选择文件中的一个标题为word文件名
    return choice
choose = g.buttonbox(msg='轻松Word',title='智能Word填写软件__ByNext',
                             choices=('打开数据文件', '打开模板文件','下一步', '退出'))
def saveplace(self):
        place = g.buttonbox(msg='请选择保存结果文件的文件夹，默认文件夹为根目录下的User文件夹',
                title='选择文件夹', choices=('选择文件夹','使用默认文件夹','退出程序'))
        if place == '退出程序':
            return
        elif place == '使用默认文件夹':
            return self +'\\User\\'
        return g.diropenbox(msg='请选择文件夹保存结果文件', title='选择文件夹保存结果', default=self+'\\User')+'\\'
if choose == '打开数据文件':
    database = choosedata() #excel文件的路径'C:\\Users\\liushuqing506\\Desktop\\ww\\data.xlsx'
    while 1:
        try:
            data = xlrd.open_workbook(str(database))
            break
        except:
            if g.boolbox(msg='数据文件错误，请重新选择！',choices=('Yes', 'No,我要退出！')):
                database, model = Func.index()  # 重新调用index函数，重新选择
    table = data.sheets()[0]
    title = table.row_values(0)






