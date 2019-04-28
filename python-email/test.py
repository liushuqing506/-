#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: LiuShuqing
# Date  : 2019/4/28

import smtplib
from email.mime.text import MIMEText
from email.header import Header

mail_host = "smtp.ym.163.com" #发件人邮箱的host
mail_user="liushuqing@fuanhua.com"    #发件人的邮箱
mail_pass="xxx"   #发件人邮箱密码

sender = 'liushuqing@fuanhua.com' #发件人邮箱
receivers = ['546397641@qq.com']  # 接收邮件，可设置为你的QQ邮箱或者其他邮箱

message = MIMEText('Python 邮件发送测试...', 'plain', 'utf-8')  #邮件内容
message['From'] = Header("菜鸟教程", 'utf-8') #发件人
message['To'] = Header("测试", 'utf-8') #收件人

subject = 'Python SMTP 邮件测试'
message['Subject'] = Header(subject, 'utf-8') #邮件主题

try:
    smtpObj = smtplib.SMTP()
    smtpObj.connect(mail_host, 25)  # 25 为 SMTP 端口号
    smtpObj.login(mail_user, mail_pass)
    smtpObj.sendmail(sender, receivers, message.as_string())
    print("邮件发送成功")
except smtplib.SMTPException:
    print("Error: 无法发送邮件")
