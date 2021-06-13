#!/bin/env python3

import os
import sys
import re
import copy
import glob
#import json
import functools

if len(sys.argv) < 3:
    print('ERR: not enough argument !!!')
    sys.exit(1)

# global varialbes
PATH = os.getcwd()
MAXLEN = 79
FLIST = []
INCDIR = []
STYLE = {'arg': 1, 'inst': 1}


# argv[0]: cmd, argv[1]: file
if len(sys.argv) > 3:
    extra_arg = sys.argv[3:]
else:
    extra_arg = [None]


def main():
    global PATH
    cmdVFile = {
        'vfile':      HDLVFile,
        'vfiles':     functools.partial(HDLVFile, searchAll=True)
        }
    cmdVStruct = {
        'autoarg':    HDLAutoArg,
        'autoinst':   functools.partial(HDLAutoInst, template=extra_arg[0]),
        'autowire':   HDLAutoWire,
        'autoreg':    HDLAutoReg,
        'struct':     HDLVStruct,
        'fake':       HDLFake,
        'input':      functools.partial(HDLNet, net='input'),
        'output':     functools.partial(HDLNet, net='output'),
        'inout':      functools.partial(HDLNet, net='inout'),
        'parameter':  functools.partial(HDLParam, param='parameter'),
        'localparam': functools.partial(HDLParam, param='localparam')
        }
    cmd = sys.argv[1]
    PATH, vfile = cmdVFile.get(cmd, HDLVFile)(sys.argv[2])
    if cmd in cmdVFile:
        content = vfile
    elif cmd in cmdVStruct:
        if not vfile:
            print(None)
            sys.exit(2)
        with open(vfile, 'r') as fh:
            vcontent = ''.join(fh.readlines())
        vstruct = _VStruct(vcontent)
        content = cmdVStruct[cmd](vstruct)
    if isinstance(content, (list, set)):
        print('\n'.join(content))
    else:
        print(content)


def HDLVFile(vfile, searchAll=False):
    global PATH, FLIST, INCDIR
    return _search_vfile(vfile, flist=FLIST, incdir=INCDIR, path=PATH, searchAll=searchAll)


# auto generate arg
def HDLAutoArg(vstruct):
    global MAXLEN, STYLE
    last_index = 0
    content = ['module '+vstruct['module']+' ( /*AUTOARG*/'] if STYLE['arg'] else []
    for port in ('output', 'input', 'inout'):
        if vstruct[port]:
            content += ['    // '+port, '    ']
        for var in vstruct[port]:
            if var not in vstruct['var']:
                continue
            if len(content[-1]) < MAXLEN:
                content[-1] += var + ', '
            else:
                if content[-1].endswith(', '):
                    content[-1] = content[-1][:-1]
                content += ['    '+var+', ']
        if content[-1].endswith(', '):
            content[-1] = content[-1][:-1]
        last_index = len(content) - 1
    if last_index > 0:
        content[last_index] = content[last_index][:-1]
    if STYLE['arg']:
        content += [');']
    return content


# generate auto instant
def HDLAutoInst(vstruct, template=None):
    inst_name, inst_struct = _AutoInstTemplate(vstruct['module'], template)
    comment = _AutoInstComment(vstruct, inst_struct)
    parameter = _AutoInstParameter(vstruct, inst_struct)
    port = _AutoInstConnect(vstruct, inst_struct)
    # content merge
    content = comment + ['', vstruct['module']]
    if parameter:
        content[-1] += ' #( // parameter'
        content += parameter + [')']
    # append inst name
    if len(content[-1] + inst_name) < 30:
        content[-1] += ' ' + inst_name + ' ( /*AUTOINST*/'
    else:
        content += [inst_name + ' ( /*AUTOINST*/']
    content += port + [');']
    return content


# get instant template
def _AutoInstTemplate(module, template):
    if not template:
        return 'u_'+module, None
    if os.path.isfile(template):
        with open(template, 'r') as fh:
            vcontent = ''.join(fh.readlines())
    else:
        vcontent = template
    vstruct = _VStruct(vcontent)
    for inst in vstruct['inst']:
        if vstruct['var'][inst]['module'] == module:
            return inst, vstruct['var'][inst]
    return 'u_'+module, None


def _AutoInstComment(vstruct, inst_struct):
    global STYLE
    comment = ['// ------------------------------------------',
               '// instant of ' + vstruct['module'] + '.v',
               '// ------------------------------------------']
    if not inst_struct or not inst_struct['port'] or not STYLE['inst']:
        return comment
    inst_port = inst_struct['port']
    comment += ['/* ' + vstruct['module'] + ' AUTO_TEMPLATE (']
    length0 = vstruct['len']
    length0 = max(length0['input']['var'], length0['output']['var'], length0['inout']['var']) + 1
    length1 = max([len(val) for val in inst_port.values()])
    strFormat = '    .{:'+str(length0)+'} ( {:'+str(length1)+'} ),'
    for port in ('output', 'input', 'inout'):
        if vstruct[port]:
            comment += ['    // '+port]
        for var in vstruct[port]:
            val = inst_port.get(var, var)
            if var == val:
                continue
            comment += [strFormat.format(var, val)]
    comment[-1] = comment[-1][:-1]
    comment += ['*/']
    return comment


# format autoinst parameter
def _AutoInstParameter(vstruct, inst_struct):
    content = []
    parameter = inst_struct['parameter'] if inst_struct else vstruct['parameter']
    if not parameter:
        pass
    elif isinstance(parameter, dict): # from inst_struct
        length0 = max((len(var) for var in parameter)) + 1
        length1 = max((len(var) for var in parameter.values())) + 1
        strFormat = '    .{:'+str(length0)+'} ( {:'+str(length1)+'} ),'
        for var, val in parameter.items():
            content += [strFormat.format(var, val)]
        content[-1] = content[-1][:-1]
    elif isinstance(parameter, list): # from vstruct
        length0 = vstruct['len']['parameter']['var'] + 1
        length1 = vstruct['len']['parameter']['val'] + 1
        strFormat = '    .{:'+str(length0)+'} ( {:'+str(length1)+'} ),'
        for var in vstruct['parameter']:
            content += [strFormat.format(var, vstruct['var'][var]['val'])]
        content[-1] = content[-1][:-1]
    return content


# format autoinst connect
def _AutoInstConnect(vstruct, inst_struct):
    content = []
    inst_port = inst_struct['port'] if inst_struct else {}
    # construct format string
    length0 = vstruct['len']
    length0 = max(length0['input']['var'], length0['output']['var'], length0['inout']['var']) + 1
    length1 = max(length0, max([len(val) for val in inst_port.values()] + [1]))
    strFormat = '    .{:'+str(length0)+'} ( {:'+str(length1)+'} ),'
    # generate connent
    for port in ('output', 'input', 'inout'):
        if vstruct[port]:
            content += ['    // '+port]
        for var in vstruct[port]:
            val = inst_port.get(var, var)
            content += [strFormat.format(var, val)]
    content[-1] = content[-1][:-1]
    return content



def HDLAutoWire(vstruct):
    pass


def HDLAutoReg(vstruct):
    pass


def HDLFake(vstruct):
    pass


def HDLNet(vstruct, net='input'):
    pass


def HDLParam(vstruct, param='parameter'):
    pass



def HDLVStruct(vstruct):
    return vstruct
#    print(json.dumps(vstruct, indent=4))

# ---------------------------------------------------------------
#    verilog file search .v .sv, search order: flist, incdir, path
# ---------------------------------------------------------------
def _search_vfile(vfile, flist=[], incdir=[], path='.', searchAll=False):
    if os.path.isfile(vfile) and (vfile.endswith('.v') or vfile.endswith('.sv')):
        return path, vfile
    # fullmatch, -1: search all file, 0: not search all file
    # add 'None' make sure fullmatch > 0
    fullmatch, matchs = -1 if searchAll else 0, [None]
    # search file in filelist first
    for subfile in flist:
        subfile = subfile.strip()
        if not os.path.isfile(subfile) or (not subfile.endswith('.v') and not subfile.endswith('.sv')):
            continue
        basename = os.path.basename(subfile)
        dirname = os.path.dirname(subfile)
        if dirname not in incdir: # update incdir
            incdir.append(dirname)
        fullmatch = _search_judge(vfile, subfile, basename, fullmatch, matchs)
        if fullmatch > 0:
            return path, matchs.pop(index=fullmatch)
    # search file in incdir second
    for root in incdir:
        if not os.path.isdir(root):
            continue
        for subfile in glob.glob(root + '/*.'):
            if not subfile.endswith('.v') and not subfile.endswith('.sv'):
                continue
            if subfile not in flist:
                flist.append(subfile) # update filelist
            basename = os.path.basename(subfile)
            fullmatch = _search_judge(vfile, subfile, basename, fullmatch, matchs)
            if fullmatch > 0:
                return path, matchs.pop(index=fullmatch)
    # search file in localpath third
    if isinstance(path, str):
        path = os.walk(path)
    while True:
        try:
            root, _, files = next(path)
        except StopIteration:
            break
        if root in incdir:
            continue
        for basename in files:
            if not basename.endswith('.v') and not basename.endswith('.sv'):
                continue
            incdir.append(root)  # update incdir
            subfile = os.path.join(root, basename)
            if subfile not in flist:
                flist.append(subfile) # update filelist
            fullmatch = _search_judge(vfile, subfile, basename, fullmatch, matchs)
            if fullmatch > 0:
                return path, matchs.pop(fullmatch)
    return path, matchs[1:] if searchAll else matchs[-1]


def _search_judge(vfile, subfile, basename, fullmatch, matchs):
    if vfile in basename and subfile not in matchs:
        matchs.append(subfile)
    if fullmatch != -1 and basename in (vfile, vfile + '.v', vfile + '.sv'): # full match
        fullmatch = len(matchs) - 1
    return fullmatch


# ---------------------------------------------------------------
#    verilog parser
# ---------------------------------------------------------------
# verilog all keywords, copy from IEEE verilog 2001
_keywords_all = {
        'always', 'and', 'assign', 'automatic', 'begin', 'buf', 'bufif0', 'bufif1', 
        'case', 'casex', 'casez', 'cell', 'cmos', 'config', 'deassign', 'default', 
        'defparam', 'design', 'disable', 'edge', 'else', 'end', 'endcase', 'endconfig', 
        'endfunction', 'endgenerate', 'endmodule', 'endprimitive', 'endspecify',
        'endtable', 'endtask', 'event', 'for', 'force', 'forever', 'fork', 'function',
        'generate', 'genvar', 'highz0', 'highz1', 'if', 'ifnone', 'incdir', 'include',
        'initial', 'inout', 'input', 'instance', 'integer', 'join', 'large', 'liblist',
        'library', 'localparam', 'macromodule', 'medium', 'module', 'nand', 'negedge',
        'nmos', 'nor', 'noshowcancelled', 'not', 'notif0', 'notif1', 'or', 'output',
        'parameter', 'pmos', 'posedge', 'primitive', 'pull0', 'pull1', 'pulldown',
        'pullup', 'pulsestyle_onevent', 'pulsestyle_ondetect', 'rcmos', 'real',
        'realtime', 'reg', 'release', 'repeat', 'rnmos', 'rpmos', 'rtran', 'rtranif0',
        'rtranif1', 'scalared', 'showcancelled', 'signed', 'small', 'specify', 'specparam',
        'strong0', 'strong1', 'supply0', 'supply1', 'table', 'task', 'time', 'tran',
        'tranif0', 'tranif1', 'tri', 'tri0', 'tri1', 'triand', 'trior', 'trireg',
        'unsigned', 'use', 'vectored', 'wait', 'wand', 'weak0', 'weak1', 'while', 'wire',
        'wor', 'xnor', 'xor'
        }

# verilog all compiler directives, copy from IEEE verilog 2001
_compiler_directives_all = {
        '`celldefine', '`default_nettype', '`define', '`else', '`elsif',
        '`endcelldefine', '`endif', '`ifdef', '`ifndef', '`include',
        '`line', '`nounconnected_drive', '`resetall', '`timescale',
        '`unconnected_drive', '`undef'
        }

# ---------------------------------------------------------------

# Keywords to be matched
_keywords_match = {
        'module', 'parameter', 'input', 'output', 'inout', 'localparam', 'reg',
        'wire', 'assign'
        }

# compiler directives to be matched
_compiler_directives_match = {
        '`ifdef', '`ifndef', '`elsif', '`else', '`endif'
        }

# ---------------------------------------------------------------

# keywords to be ignored
_keywords_ignore = _keywords_all - _keywords_match
_compiler_directives_ignore = _compiler_directives_all - _compiler_directives_match

_keywords_ignore_str = '|'.join((r'\b'+item+r'\b' for item in _keywords_ignore))
_compiler_directives_ignore_str = '|'.join((item+r'\b' for item in _compiler_directives_ignore))

_token_spec = [
        ('line_comment',      r'//.*\n'),
        ('block_comment',     r'/\*.*?\*/'),
        ('attributes',        r'\(\*.*?\*\)'),
        ('function',          r'\bfunction\b.*?\bendfunction\b'),
        ('task',              r'\btask\b.*?\bendtask'),
        ('if',                r'\bif\s*\(.*?\)'),
        ('elseif',            r'\belse\s+if\s*\(.*?\)'),
        ('for',               r'\bfor\s*\(.*?\)'),
        ('while',             r'\bwhile\s*\(.*?\)'),
        ('always',            r'\balways\s*@(\*|\(.*?\))'),
        ('case',              r'\bcase[xz]?\s*\(.*?\)'),
        ('dollar',            r'$\w+(\(.*?\))?;'),                    # system call
        ('direct',            _compiler_directives_ignore_str),       # Macro
        ('keyword',           _keywords_ignore_str),                  # ignore unuseless keyword
        ('module',            r'\bmodule\s+\w+'),                     # module match start
        ('dir_ifdef',         r'`ifdef\s+\w+'),
        ('dir_ifndef',        r'`ifndef\s+\w+'),
        ('dir_elsif',         r'`elsif\s+\w+'),
        ('dir_else',          r'`else'),
        ('dir_endif',         r'`endif'),
        ('parameter',         r'(?<=\bparameter\b)\s+.*?[;)]'),
        ('input',             r'(?<=\binput\b).*?\n'),
        ('output',            r'(?<=\boutput\b).*?\n'),
        ('inout',             r'(?<=\binout\b).*?\n'),
        ('localparam',        r'(?<=\blocalparam\b).*?;'),
        ('reg',               r'(?<=\breg\b).*?;'),
        ('wire',              r'(?<=\bwire\b).*?;'),
        ('assign',            r'(?<=\bassign\b).*?;'),
        ('eq',                r'\w+\s*<?=[^=].*?;'),
        ('inst',              r'\w+\s+(#\(.*?\)\s+)?\w+\s*\(.*?\);')
        ]

_token_regex = re.compile('|'.join('(?P<%s>%s)' % pair for pair in _token_spec), re.S)
_comment_regex = re.compile('|'.join([pair[1] for pair in _token_spec[0:3]]), re.S)
_width_regex = re.compile(r'\[(.*?)\]')
_word_regex = re.compile(r'[a-zA-Z_]\w*')
_expression_regex = re.compile(r'(\w+)\s*=\s*([^=][^,;]+)')
_connect_regex = re.compile(r'\.(\w+)\((.*?)\)')

_vstruct_template = {
        'module': '', 'parameter': [], 'localparam': [],
        'input':  [], 'output':    [], 'inout':      [],
        'reg':    [], 'wire':      [], 'assign':     [],
        'eq':     [], 'var':       {}, 'inst':       [],
        'len':    { # record length for string format
            'parameter':  {'var': 0, 'val': 0},
            'localparam': {'var': 0, 'val': 0},
            'input':      {'var': 0, 'msb': 0, 'lsb': 0},
            'output':     {'var': 0, 'msb': 0, 'lsb': 0},
            'inout':      {'var': 0, 'msb': 0, 'lsb': 0},
            'reg':        {'var': 0, 'msb': 0, 'lsb': 0},
            'wire':       {'var': 0, 'msb': 0, 'lsb': 0}
            }
        }

# ----------------------------------------
# parse verilog code to vstruct 
# ----------------------------------------
def _VStruct(vcontent, dbg=0):
    parse_func = {
        'module':      _parse_module,
        'parameter':   _parse_parameter,
        'localparam':  _parse_parameter,
        'input':       _parse_net,
        'output':      _parse_net,
        'inout':       _parse_net,
        'reg':         _parse_net,
        'wire':        _parse_net,
        'assign':      _parse_expression,
        'eq':          _parse_expression,
        'inst':        _parse_inst
        }
    define = []
    vstruct = copy.deepcopy(_vstruct_template)
    for mo in _token_regex.finditer(vcontent):
        if dbg:
            print(mo.lastgroup, ':', mo.group())
        kind, value = mo.lastgroup, _comment_regex.sub('', mo.group()).strip()
        if kind in parse_func:
            parse_func[kind](vstruct, kind, value)
        elif kind.startswith('dir_'):
            _parse_directives(define, kind, value)
        elif kind == 'keyword' and value == 'endmodule':
            break
    return vstruct


def _parse_directives(define, kind, value):
    value = value.strip()
    if kind in ('dir_ifdef', 'dir_ifndef'):
        define.append(value)
    elif kind in ('dir_elsif', 'dir_else') and define:
        define[-1] = value
    elif kind == 'dir_endif':
        define.pop()



# get module name of verilog file
def _parse_module(vstruct, kind, value):
    vstruct[kind] = value.split()[-1].strip()


# param parser: parameter and localparam
def _parse_parameter(vstruct, kind, value):
    value = value.strip()
    if value.endswith(')'): # #(parameter ...) may endswith ')'
        value = value[:-1]
    for var, val in _expression_regex.findall(value):
        val = val.replace(' ', '').strip()
        vstruct[kind].append(var)
        vstruct['var'][var] = {'kind': kind, 'val': val}
        vstruct['len'][kind] = {'var': max(len(var), vstruct['len'][kind]['var']),
                                'val': max(len(val), vstruct['len'][kind]['val'])}


# net parser: input ouput inout reg wire
_net_word_ignore = ('signed', 'scalared', 'vectored', 'supply0', 'supply1',
                    'strong0', 'strong1', 'pull0', 'pull1', 'weak0', 'weak1', 'small',
                    'medium', 'large', 'input', 'output', 'inout', 'reg', 'wire')
def _parse_net(vstruct, kind, value):
    regtype = False  # used for output scene
    value = value.split('=', 1)[0].strip()  # consider: wire var = ...
    width = _width_regex.search(value)
    start = width.end() if width else 0
    value = value[start:]
    if width and ':' in width.group(1) and value[0] != ';':
        msb, lsb = width.group(1).split(':', 1)
    else:
        msb, lsb = '', ''
    memWidth = _width_regex.search(value) # consider memory type
    if memWidth:
        value = value[:memWidth.start()]
    for var in _word_regex.findall(value):
        if kind == 'output' and var == 'reg': # output reg
            regtype = True
        elif kind == 'reg' and var in vstruct['output']: # reg def for output
            vstruct['reg'].append(var)
        elif var not in _net_word_ignore:
            vstruct[kind].append(var)
            vstruct['var'][var] = {'kind': kind, 'msb': msb, 'lsb': lsb}
            vstruct['len'][kind] = {'var': max(len(var), vstruct['len'][kind]['var']),
                                    'msb': max(len(msb), vstruct['len'][kind]['msb']),
                                    'lsb': max(len(lsb), vstruct['len'][kind]['lsb'])}
            if regtype:
                vstruct['reg'].append(var)


# expression parser: assign statement or =,<= in always block
_delay_regex = re.compile(r'#\S+')
def _parse_expression(vstruct, kind, value):
    value = value.split('=', 1)[0].strip()
    value = _delay_regex.sub('', value)      # remove delay
    value = _width_regex.sub('', value)      # remove width [...]
    for word in _word_regex.findall(value):  # consider {a,b,..} = ...
        if word not in vstruct[kind]:
            vstruct[kind].append(_word_regex.search(value.strip()).group())


# instant parser
_inst_name_regex = re.compile(r'(?<=\))\s*\w+\s*(?=\()')
def _parse_inst(vstruct, kind, value):
    value = value.strip()
    module = _word_regex.match(value)
    if not module:
        return
    value = value[module.end():].strip()
    if value.startswith('#('):
        inst = _inst_name_regex.search(value)
    else:
        inst = _word_regex.match(value)
    if not inst:
        return
    inst_name = inst.group().strip()
    vstruct[kind].append(inst_name)
    vstruct['var'][inst_name] = {'module': module.group(), 'parameter': {}, 'port': {}}
    for net0, net1 in _connect_regex.findall(value[:inst.end()]):
        vstruct['var'][inst_name]['parameter'][net0] = net1.replace(' ', '').strip()
    for net0, net1 in _connect_regex.findall(value[inst.end():]):
        vstruct['var'][inst_name]['port'][net0] = net1.replace(' ', '').strip()


if __name__ == '__main__':
    main()
