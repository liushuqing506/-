######  类具有属性和方法  ########
#self是特殊参数（每个函数必填）

class Ema:  #创建Ema类
    def __init__(self,number):  #number参数必须有
        self.nam = number['name']    #属性
        self.sco = number['score']  #属性

    def num_info(self,*params):  #统计*params参数的数量
        return len(params),params

    def get_maxscore(self,*params):  #*params参数可有可无
        maxscore = max(self.sco)
        return maxscore,self.num_info(params[1]) #同一个类的函数（或称作”方法“）调用其他函数使用 self.函数

number_dict  = {'name':['jay','lsq'],'score':[34,56]}

a = Ema(number_dict)

print(a.nam) #调用类的nam属性    返回:['jay', 'lsq'] 
b_list = ['1','3']
c_list = {'we':'121'}
print(a.num_info(b_list,c_list))  #返回:(2, (['1', '3'], {'we': '121'}))
print(a.get_maxscore(b_list,c_list)) #调用类的get_maxscore()方法   返回:(56, (1, ({'we': '121'},)))

另一种使用方式：
*************************
也可以从自定义的库来调用类 *
*************************
import number #自定义的number库，放在脚本的同级目录下

number_dict  = {'name':['jay','lsq'],'score':[34,56]}
a = number.Ema(number_dict) #调用number库的Ema类
a.name


结果返回：
['jay', 'lsq']
