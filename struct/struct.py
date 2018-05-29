#web:https://www.cnblogs.com/Simulation-Campus/p/8684692.html
import struct
pdb_format='6s5s1s4s1s3s1s1s4s1s3s8s8s8s6s6s10s2s3s'
def atom_line(line):
    tmp=struct.unpack(pdb_format,bytes(line.encode('utf-8')))
    atom=tmp[3].strip()
    res_type=tmp[5].strip()
    res_num=tmp[1].strip()
    chain=tmp[7].strip()
    x=float(tmp[11].strip())
    y=float(tmp[12].strip())
    z=float(tmp[13].strip())
    return chain ,res_type,res_num,atom,x,y,z
def main(pdf_file,residues,outfile):
    pdb=open(pdf_file)
    outfile=open(outfile,"a")
    for line in pdb:
        if line.startswith('ATOM'):
            res_data=atom_line(line)
            res2type=bytes.decode(res_data[1])
            res2num=bytes.decode(res_data[2])
            for aa,num in residues:
                if res2type == aa and res2num == num:
                    outfile.write(line)
    outfile.close()
residues=(['ASP','102'],['HIS','57'])
pdf_file=r'C:\Users\WIN7\Desktop\123\123.txt'
outfile=r'C:\Users\WIN7\Desktop\123\out.txt'
main(pdf_file,residues,outfile)
