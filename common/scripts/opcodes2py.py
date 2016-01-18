#!/usr/bin/env python
import argparse
import re
import string
import pprint as pp

opcodes_args = ['rd', 'rs1', 'rs2', 'rs3', 'imm20', 'imm12', 'imm12lo', 'imm12hi', 'shamtw', 'shamt', 'rm', 'bimm12lo', 'bimm12hi']



inst_types_rv32i = {
    'R-type' : ['add','sub','sll','slt','sltu','xor','srl','sra','or','and'],
    'I-type' : ['jalr','addi','ssli','slti','sltiu','xori','srli','srai','ori','andi',
                'lb','lu','lw','ld','lbu','lwu','lhu'],
    'S-type' : ['sb','sh','sw','sd'],
    'SB-type' : ['beq','bne','blt','bge','bltu','bgeu'],
    'U-type' : ['lui','auipc'],
    'UJ-type' : ['jal'],
    'SYS-type': ['scall','sbreak'],
    'F-type': ['fence','fence.i'],
    'AS-type': ['slli','slti','srli','srai'],
}


tpl_u_type = """
spec['nanorv32']['rv32i']['{inst_name}']['spec'] = {
    'inst_type' : 'U-type',
    'decode' : {
        'opcode1' : '{opcode1}'
    }
}"""


def revert_inst_dic(d):
    """Return a dictionary indexed by instruction"""
    r = dict()
    for k,v in d.items():
        for i in v:
            r[i] = k
    return r

def r_type_opcode(line):
    #arg1 = re.compile(r'31\.\.25=(?P<arg1>\S+)')
    #arg2 = re.compile(r'14\.\.12=(?P<arg2>\S+)')
    #arg3 = re.compile(r'6\.\.2=(?P<arg3>\S+)')
    #arg4 = re.compile(r'1\.\.0=(?P<arg4>\S+)')



    r_type = re.compile(r'\S+\s+rd\s+rs1\s+rs2\s+31\.\.25=(\S+)\s+14\.\.12=(\S+)\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = r_type.match(line)
    if matchObj:
        print "-I-       R-type match found " + matchObj.group(1) + " " + matchObj.group(2) + " " + matchObj.group(3) + " " + matchObj.group(4) + " "

def i_type_opcode(line):
    #arg1 = re.compile(r'31\.\.25=(?P<arg1>\S+)')
    #arg2 = re.compile(r'14\.\.12=(?P<arg2>\S+)')
    #arg3 = re.compile(r'6\.\.2=(?P<arg3>\S+)')

    i_type = re.compile(r'\S+\s+rd\s+rs1\s+imm12\s+14\.\.12=(\S+)\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = i_type.match(line)
    if matchObj:
        print "-I-        I-type  match found " + matchObj.group(1) + " " + matchObj.group(2) + " " + matchObj.group(3)


def s_type_opcode(line):
    #arg1 = re.compile(r'31\.\.25=(?P<arg1>\S+)')
    #arg2 = re.compile(r'14\.\.12=(?P<arg2>\S+)')
    #arg3 = re.compile(r'6\.\.2=(?P<arg3>\S+)')

    s_type = re.compile(r'\S+\s+imm12hi\s+rs1\s+rs2\s+imm12lo\s+14\.\.12=(\S+)\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = s_type.match(line)
    if matchObj:
        print "-I-        S-type  match found " + matchObj.group(1) + " " + matchObj.group(2) + " " + matchObj.group(3)

def sb_type_opcode(line):
    #arg1 = re.compile(r'31\.\.25=(?P<arg1>\S+)')
    #arg2 = re.compile(r'14\.\.12=(?P<arg2>\S+)')
    #arg3 = re.compile(r'6\.\.2=(?P<arg3>\S+)')

    sb_type = re.compile(r'\S+\s+bimm12hi\s+rs1\s+rs2\s+bimm12lo\s+14\.\.12=(\S+)\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = sb_type.match(line)
    if matchObj:
        print "-I-        SB-type  match found " + matchObj.group(1) + " " + matchObj.group(2) + " " + matchObj.group(3)


def u_type_opcode(line):

    u_type = re.compile(r'\S+\s+rd\s+imm20\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = u_type.match(line)
    if matchObj:
        print "-I-        U-type  match found " + matchObj.group(1) + " " + matchObj.group(2)


def uj_type_opcode(line):
    d = dict()
    uj_type = re.compile(r'\S+\s+rd\s+jimm20\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = uj_type.match(line)
    if matchObj:
        print "-I-        UJ-type  match found " + matchObj.group(1) + " " + matchObj.group(2)
        opcode1 = int(matchObj.group(1),0)*4 + int(matchObj.group(2),0)
        d['opcode1'] = opcode1
        pp.pprint(d)
    else:
        return None

def as_type_opcode(line):

    as_type = re.compile(r'\S+\s+rd\s+rs1\s+31\.\.26=(\S+)\s+shamt\s+14\.\.12=(\S+)\s+6\.\.2=(\S+)\s+1\.\.0=(\S+)')
    matchObj = as_type.match(line)
    if matchObj:
        print "-I-        AS-type  match found " + matchObj.group(1) + " " + matchObj.group(2) + " " + matchObj.group(3) + " " + matchObj.group(4)




def get_args():
    """
    Get command line arguments
    """

    parser = argparse.ArgumentParser(description="""
    Parse opcodes for Risc-V intructions, output python data structure
                   """)
    parser.add_argument('--opcodes', action='store', dest='opcodes',
                        help='opcode file')

    parser.add_argument('--version', action='version', version='%(prog)s 0.1')

    return parser.parse_args()


if __name__ == '__main__':
    p = re.compile(r'\s*(?P<parameter>parameter)\s*(?P<name>\S+)\s*=\s*(?P<value>\S+)')
    args = get_args()
    insts = dict()
    type_inst_d  = revert_inst_dic(inst_types_rv32i)

    with open(args.opcodes) as f:
        lines = filter(None, (line.rstrip() for line in f))
        for line in lines:
            if line[0] != '#':

                # print ">" + line.strip('\n') + "<"
                items = string.split(line)
                # print items
                inst_name = items[0]
                type_inst = type_inst_d.get(inst_name,None)
                if type_inst is None:
                    # print "-E Unrecognized instruction : " +  inst_name
                    pass
                else:
                    print "-I inst : " + inst_name + " of type " + type_inst
                    r_type_opcode(line)
                    i_type_opcode(line)
                    s_type_opcode(line)
                    sb_type_opcode(line)
                    u_type_opcode(line)
                    uj_type_opcode(line)
                    as_type_opcode(line)



                #fields = []
                #i = 1
                #while items[i] in opcodes_args:
                #    d = dict()
                #    d['args'] = items[i]
                #    fields.append(d)
                #    i += 1
                #insts[inst_name] = fields


    pp.pprint(insts)

    pp.pprint(type_inst)
            #m = p.search(line.strip('\n'))
            #if m is not None:
            #    d = dict()
            #    d['name'] = m.group('name')
            #    d['value'] = m.group('value')
            #    print parameter_tpl.format(**d)
