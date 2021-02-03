def G_S_sort(some_list):
    G_S_SN = AutoVivification()
    G_GN = AutoVivification()
    S_info = AutoVivification()
    G_S_sort_list = []
    for i in some_list:
        info_text = i.split('\t')
        G_S_SN[info_text[6]][info_text[8]] = int(info_text[9])  #[属名][种名]=种的read数
        G_GN[info_text[6]] = int(info_text[7]) #[属名]=属的read数
        S_info[info_text[8]] = i #[]种的种名
    S_queue = []
    for i in sorted(G_GN.items(),key=operator.itemgetter(1), reverse=True):
        for j in sorted(G_S_SN[i[0]].items(), key=operator.itemgetter(1), reverse=True):
            S_queue.append(j[0])
    for i in S_queue:
        G_S_sort_list.append(S_info[i])
    return G_S_sort_list
