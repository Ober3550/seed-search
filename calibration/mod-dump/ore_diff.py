#!/usr/bin/env python3
"""Diff two ore BMPs (ground truth vs generated). Green=both, red=gen-only
(overcount), blue=gt-only (missing). Usage: ore_diff.py <gt.bmp> <gen.bmp> [out.png]"""
import struct, sys, zlib
BG=(20,20,20)
def read_rows(p):
    d=open(p,'rb').read()
    off=struct.unpack('<I',d[10:14])[0]; w=struct.unpack('<i',d[18:22])[0]; h=struct.unpack('<i',d[22:26])[0]
    avail=len(d)-off; padded=((w*3+3)//4)*4
    stride=padded if avail>=padded*h else w*3
    return w,h,[d[off+y*stride:off+y*stride+w*3] for y in range(h)]
def chunk(t,dat): c=t+dat; return struct.pack('>I',len(dat))+c+struct.pack('>I',zlib.crc32(c)&0xffffffff)
def main(gtp,genp,outp='ore-diff.png'):
    wG,hG,G=read_rows(gtp); wN,hN,N=read_rows(genp)
    assert (wG,hG)==(wN,hN); w,h=wG,hG
    out=bytearray(w*h*3); gt=gen=both=0
    for y in range(h):
        rg=G[y]; rn=N[y]
        for x in range(w):
            i=x*3; og=(rg[i+2],rg[i+1],rg[i])!=BG; on=(rn[i+2],rn[i+1],rn[i])!=BG; o=(y*w+x)*3
            if og and on: both+=1; out[o:o+3]=b'\x3c\xb4\x3c'
            elif on: gen+=1; out[o:o+3]=b'\xdc\x32\x32'
            elif og: gt+=1; out[o:o+3]=b'\x3c\x78\xe6'
            else: out[o]=out[o+1]=out[o+2]=15
    raw=b''.join(b'\x00'+bytes(out[y*w*3:(y+1)*w*3]) for y in range(h))
    open(outp,'wb').write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,6))+chunk(b'IEND',b''))
    gtt=gt+both; gnt=gen+both
    print(f"GT={gtt} GEN={gnt} ({gnt/gtt:.2f}x) overlap={both} ({100*both/gtt:.1f}% of GT) overcount={gen} missing={gt}")
if __name__=='__main__': main(*sys.argv[1:])
