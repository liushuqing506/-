#-*- coding:utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        模块3
# Purpose:
#
# Author:      liushuqing506
#
# Created:     19/12/2017
# Copyright:   (c) liushuqing506 2017
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import requests
def login():
    session = requests.session()
    # res = session.get('http://my.its.csu.edu.cn/').content

    login_data = {
        'userName': '3903150327',
        'passWord': '136510',
        'enter': 'true'
    }
    session.post('http://my.its.csu.edu.cn//', data=login_data)
    res = session.get('http://my.its.csu.edu.cn/Home/Default')
    print(res.text)


login()
