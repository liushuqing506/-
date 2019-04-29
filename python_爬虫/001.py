from bs4 import BeautifulSoup
import requests

def getHtml(url):
    html = requests.get(url)
    html = BeautifulSoup(html.text,'lxml')
    return html

def content(html):
    # 内容分割的标签
    str1 = '<article class="article-content">' # <article class="article-content"> 之后的部分
    content = str(html).partition(str1)[2] #[1]是str1的内容

    str2 = '<div class="article-social">' #<div class="article-social"> 之前的部分
    content = content.partition(str2)[0]  #[1]是str2的内容
    return content  # 得到网页的内容

def title(content, beg=0):
    # 思路是利用str.index()和序列的切片
    try:
        title_list = []
        while beg >= 0:
            num1 = content.index('】', beg)
            num2 = content.index('</p>', num1)
            title_list.append(content[num1+1:num2])
            beg = num2

    except ValueError:
        return title_list



content = content(getHtml("http://bohaishibei.com/post/10449/"))
# num = content.index('】')
title = title(content) #返回一个列表
print(title)
for i, e in enumerate(title): #列表索引和对应内容
    print('第%d个，title：%s' % (i, e))
