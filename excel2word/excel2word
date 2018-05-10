#-*- coding:utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块1
# Purpose:
#
# Author:      liushuqing506
#
# Created:     08/05/2018
# Copyright:   (c) liushuqing506 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------
## -*- coding: utf-8 -*-
## __author__ = Next
import xlrd
import win32com.client
import easygui as g
from os import getcwd
from tkinter import Tk, Text, Button, Label

'''
此处定义一个Function类，用来放需要用到的一些函数
'''
class Function():


    def __init__(self):
        self.path = getcwd()

    ## 使用说明
    def info(self):
        pass

    ## ----- 选择数据文件
    def choosedata(self):
        return g.fileopenbox(msg='请打开数据文件',  title=None, default='*', filetypes=None)

    ## ----- 选择模板文件
    def choosemodel(self):
        return g.fileopenbox(msg='请打开模板文件',  title=None, default='*', filetypes=None)

    def ready(self, place):
        return g.msgbox(msg='生成的文件将保存在'+str(place)+'文件中，现在开始吗', title='Are you ready??!!', ok_button='Ready Go...!!!')


    ## ----- 自定义保存的名称，定义一个CCbox
    def savename(self, c):
        choice = g.choicebox(msg='请选择一列内容作为保存Word文件的名称', title='文件名称选择', choices=c)
        return c.index(choice)

    ## ----- 自定义生成文件保存的位置
    def saveplace(self):
        place = g.buttonbox(msg='请选择保存结果文件的文件夹，默认文件夹为根目录下的User文件夹',
                title='选择文件夹', choices=('选择文件夹','使用默认文件夹','退出程序'))
        if place == '退出程序':
            return
        elif place == '使用默认文件夹':
            return self.path+'\\User\\'
        return g.diropenbox(msg='请选择文件夹保存结果文件', title='选择文件夹保存结果', default=self.path+'\\User')+'\\'


    ## ----- 打开主页面
    def index(self):
        database = ''
        model = ''
        while 1:
            databasetype = ('xls','xlsx',)
            modeltype = ('doc', 'docx',)
            choose = g.buttonbox(msg='轻松Word',title='智能Word填写软件__ByNext',
                             choices=('打开数据文件', '打开模板文件','下一步', '退出'))
            if choose == '打开数据文件':
                database = self.choosedata()   #database 数据文件名称
                continue
            elif choose == '打开模板文件':
                model = self.choosemodel()      #mode 模板文件名称
                continue
            elif choose == '下一步':
                if database.endswith(databasetype) and model.endswith(modeltype):
                    break
                elif not (database.endswith(databasetype) or model.endswith(modeltype)):
                    c = g.boolbox(msg='数据和模板文件错误',choices=('Yes', 'No'))
                elif not database.endswith(databasetype):
                    c = g.boolbox(msg='数据文件错误',choices=('Yes', 'No'))
                elif not model.endswith(modeltype):
                    c = g.boolbox(msg='模板文件错误',choices=('Yes', 'No'))
                if c:
                    continue
                else:
                    return   ## 退出
            elif choose == '退出':
                return

        return database, model  # 放回2个值，分别是 数据文件名称、模板名称

    ## ------ 写入word的函数
    def makeword(self, name, title, lenth, info, filename,saveplace):
        w = win32com.client.Dispatch("Word.Application")
        w.Visible = True
        while 1:
            try:
                doc = w.Documents.Open(str(name))   # 载入模板
                break
            except:
                if g.boolbox(msg='模板文件错误，请重新选择！',choices=('Yes', 'No，不选了，麻烦！')):
                    name = Func.index()[1]  # 重新调用index函数，重新选择
                    continue
                else:
                    return False
        w.Selection.Find.ClearFormatting()
        w.Selection.Find.Replacement.ClearFormatting()
        for i in range(1,lenth):
            OldStr = title[i]
            NewStr = info[i]
            w.Selection.Find.Execute(OldStr, False, False, False, False, False, True, 1, True, NewStr, 2)
        while 1:
            try:
                #if saveplace:
                doc.SaveAs(saveplace+info[filename]+'.doc')
                #else:
                    #doc.SaveAs(saveplace+info[filename]+'.doc')
                break
            except:
                if g.boolbox(msg='文件名称含有特殊字符或其他错误，请重新选择文件名称',choices=('Yes', 'No，不选了，麻烦！')):
                    filename = self.savename(title)
                    continue
                else:
                    break
        doc.Close()
        return True




'''
数据表中，第一行必须是标题，且标题的数据必须采用标准格式
第一列必须是序号，从1开始，一直到最后一组数据
'''
def run():
    Func = Function()                       #函数类的实例化
    try:
        database, model = Func.index()      #调用打开页面,返回 database 和 model 的文件名称
    except:
        return

    ## ----- 载入数据文件
    while 1:
        try:
            data = xlrd.open_workbook(str(database))
            break
        except:
            if g.boolbox(msg='数据文件错误，请重新选择！',choices=('Yes', 'No,我要退出！')):
                database, model = Func.index()  # 重新调用index函数，重新选择
            else:
                return
    table = data.sheets()[0]
    title = table.row_values(0)
    count = len(table.col_values(0)[1:])    # 数据总个数
    num = 1                                 # 计数
    filename = Func.savename(title)         # 自定义保存的文件名称
    saveplace = Func.saveplace()            # 自定义保存的文件位置
    if not saveplace:
        return
    if not Func.ready(saveplace):           # 准备开始
        return
    window = Tk()
    window.title('欢迎使用智能Word填写软件__ByNext')
    window.geometry('600x400')
    label = Label(window)
    label.pack()
    b = Button(window,text='退出', command = window.quit)
    b.pack()
    text = Text(label, font='宋体 -18')
    text.pack()



    # ------ 开始循环生成文件
    while num <= count:
        info = table.row_values(num)
        try:
            text.insert('1.0', ('正在处理第'+str(num)+'份文件......\n'))
        except:
            return
        window.update()
        flag = Func.makeword(model, title, len(title), info, filename, saveplace)
        if flag:
            num += 1
        else:
            if g.boolbox(msg='第'+ str(num)+'文件出错，是否继续生成剩余文件？',choices=('Yes', 'No，坚决退出！')):
                continue
            else:
                return
    window.destroy()
    if num == count:
        g.msgbox(msg='文件已全部处理完成',ok_button = 'OK,good job!')
    elif num > 1:
        g.msgbox(msg='完成了'+str(num)+'份文件',ok_button='OK')
    window.mainloop()


if __name__ == '__main__':
    run()

