#!/bin/env python3
# =========================================================
# Author: YanCai <844757727@qq.com>
# Description: verilog parser & auto-generation ...
# --- Supported environment variables ---------------------
# VGEN_FLIST:  Specify list-file, that contains the required verilog-file
# VGEN_INCDIR: Specify path-file, including the path of verilog-file
# VGEN_DEFINE: Specify macro-file that contains the macro definition
# --- Note ------------------------------------------------
# The tool first searches the file from the filelist,
# and then searches the file in the path specified by include if it is not found,
# and finally searches the file in the local path
# --- Usage -----------------------------------------------
# vgen.py <subcmd> <file-target> [extra ... / +define+... / +incdir+...]
# =========================================================

import os
import sys
import re
import copy
import glob
#import json
import functools

# ---------------------------------------------------
# global varialbes
# ---------------------------------------------------
# debug mode
DEBUG = False
# Preset variables
FLIST = []
INCDIR = []
DEFINE = {}
MAXLEN = 79
PATH = os.getcwd()
STYLE = {'arg': 1, 'inst': 1}
# argv expand
CMD = sys.argv[1] if len(sys.argv) > 1 else None
VFILE = sys.argv[2] if len(sys.argv) > 2 else None
EXTRA = sys.argv[3:] if len(sys.argv) > 3 else [None]


# Environment configure
PROJ_DIR = os.getenv('PROJ_DIR', None)
if PROJ_DIR and PROJ_DIR in PATH: # Environment check
    if 'RTL_DIR' in os.environ:
        PATH = os.environ['RTL_DIR']
    WORK_DIR = os.getenv('WORK_DIR', os.path.join(PROJ_DIR, 'work'))
else: # self configure
    WORK_DIR = os.path.join(PATH, 'work')
# file set
VERILATOR = os.path.join(WORK_DIR, 'misc', 'verilator.syntax')
FILELIST = glob.glob(os.path.join(WORK_DIR, 'run_verdi', '*.f'))
FILELIST = FILELIST[0] if FILELIST else None


# ---------------------------------------------------
# function define
# ---------------------------------------------------
# main function
def main():
    global CMD, VFILE
    cmdVFile = {
        'vfile':      HDLVFile,
        'vfiles':     functools.partial(HDLVFile, searchAll=True),
        'flist':      HDLFlist,
        'incdir':     HDLIncdir,
        'define':     HDLDefine,
        'autofmt':    HDLAutoFmt,
        'autofile':   HDLAutoFile
        } # base on argument only
    cmdVStruct = {
        'autoarg':    HDLAutoArg,
        'autoinst':   functools.partial(HDLAutoInst, template=EXTRA[0]),
        'autowire':   HDLAutoWire,
        'autoreg':    HDLAutoReg,
        'struct':     HDLVStruct,
        'undef':      HDLUndef,
        'fake':       HDLFake
        } # Need to search for verilog file, then parsed to vstruct
    _check_argument(list(cmdVFile) + list(cmdVStruct)) # all allowed sub-cmd
    _initial_env() # initial INCDIR, FLIST and DEFINE for search verilog file
    # execue specified function
    if CMD in cmdVFile:
        content = cmdVFile[CMD](VFILE)
    elif CMD in cmdVStruct:
        vfile = _search_vfile(VFILE)
        if not vfile:
            _err_handle('err_vfile')
        content = cmdVStruct[CMD](_vstruct_analyze(vfile, isfile=True))
    # print result
    if isinstance(content, (list, set)):
        print('\n'.join(content))
    else:
        print(content)


def HDLVFile(vfile, searchAll=False):
    vfile = _search_vfile(vfile, searchAll=searchAll)
    if not vfile:
        return ''
    return vfile


# ---------------------------------------------------------------
# argument check
# ---------------------------------------------------------------
def _check_argument(subcmds):
    global CMD, VFILE
    err = 'err_arg' if not CMD else \
          'err_cmd' if CMD not in subcmds else \
          'err_arg' if not VFILE and CMD != 'define' else 'None'
    _err_handle(err)


def _err_handle(err):
    global CMD, VFILE
    # get msg & level
    err_msg = {'err_cmd':   ['ERR: Unrecongnized sub-command "'+str(CMD)+'"', 1],
               'err_arg':   ['ERR: missing argument', 2],
               'err_vfile': ['ERR: Cannot find verilog file "'+str(VFILE)+'"', 3]
              }.get(err, ['None', 0])
    if err_msg[1]:
        print(err_msg[0])
        sys.exit(err_msg[1])


# ---------------------------------------------------------------
# autogeneration function
# ---------------------------------------------------------------
# AUTOARG, AUTOWIRE, AUTOREG, STM, AUTOINST, AUTOTIE (todo)
# auto generate arg
def HDLAutoArg(vstruct):
    global MAXLEN, STYLE
    if not vstruct['module']:
        return ''
    ifdef, last_index = _AutoArg_ifdef(vstruct)
    if ifdef:
        last_index += 1 if STYLE['arg'] else 0
        content = (['module '+vstruct['module']+' ('] if STYLE['arg'] else []) \
                   + ifdef + ['    /*AUTOARG*/']
    else:
        content = ['module '+vstruct['module']+' ( /*AUTOARG*/'] if STYLE['arg'] else []
    for port in ('output', 'input', 'inout'):
        if vstruct[port]:
            content += ['    // '+port, '    ']
        for var in vstruct[port]:
            if 'ifdef' in vstruct['var'][var].get('attr', set()):
                continue
            if len(content[-1]) < MAXLEN:
                content[-1] += var + ', '
            else:
                if content:
                    content[-1] = content[-1].rstrip() # remove space
                content += ['    '+var+', ']
            last_index = len(content) - 1
        if len(content) > 1 and content[-1] == '    ' and content[-2] == '    // '+port:
            del content[-2:]
    if last_index > 0:
        content[last_index] = content[last_index].rstrip()[:-1] # remove ,
    return content + ([');'] if STYLE['arg'] else [])


def _AutoArg_ifdef(vstruct):
    global MAXLEN
    content, lastindex = [], 0
    for ifdef in vstruct['ifdef']:
        if ifdef.startswith('`ifdef') or ifdef.startswith('`ifndef') or \
                ifdef.startswith('`elsif') or ifdef.startswith('`else') or \
                ifdef.startswith('`endif'):
            if content:
                content[-1] = content[-1].rstrip() # remove space
            if ifdef == '`endif' and content[-1] == '`else':
                content[-1] = ifdef
            elif ifdef == '`else' and content[-1].startswith('`ifdef'):
                content[-1] = '`ifndef '+content[-1].split()[-1]
            else:
                content += [ifdef]
        elif ifdef in vstruct['input'] + vstruct['output'] + vstruct['inout']:
            if content[-1].startswith('`'):
                content += ['    ']
            if len(content[-1]) < MAXLEN:
                content[-1] += ifdef+', '
            else:
                if content:
                    content[-1] = content[-1].rstrip() # remove space
                content += ['    '+ifdef+', ']
            lastindex = len(content) - 1
    if lastindex == 0:
        return None, 0
    return content, lastindex


# generate auto instant
def HDLAutoInst(vstruct, template=None):
    if not vstruct['module']:
        return ''
    inst_name, inst_struct = _AutoInst_template(vstruct['module'], template)
    comment = _AutoInst_comment(vstruct, inst_struct)
    parameter = _AutoInst_parameter(vstruct, inst_struct)
    ifdef, lastindex0 = _AutoInst_ifdef(vstruct, inst_struct)
    port = _AutoInst_connect(vstruct, inst_struct)
    if not ifdef and not port:
        return ''
    # content merge
    content = comment + ['', vstruct['module']]
    if parameter:
        content[-1] += ' #( // parameter'
        content += parameter + [')']
    preindex = len(content)
    # append inst name
    if ifdef:
        if len(content[-1] + inst_name) < 30:
            content[-1] += ' ' + inst_name + ' ('
        else:
            content += [inst_name + ' ( ']
        content += ifdef + ['    /*AUTOINST*/']
        lastindex0 += preindex
    else:
        if len(content[-1] + inst_name) < 30:
            content[-1] += ' ' + inst_name + ' ( /*AUTOINST*/'
        else:
            content += [inst_name + ' ( /*AUTOINST*/']
    if port:
        port[-1] = port[-1][:-1]
        content += port
    elif lastindex0 > 0:
        content[lastindex0] = content[lastindex0][:-1]
    return content + [');']


# get instant template
def _AutoInst_template(module, template):
    if not template:
        return 'u_'+module, None
    if isinstance(template, dict):
        vstruct = template
    elif os.path.isfile(template):
        vstruct = _vstruct_analyze(template, isfile=True, kinds=('module', 'inst'))
    else:
        vstruct = _AutoInst_template_format(module, template)
    for inst in vstruct['inst']:
        if vstruct['var'][inst]['module'] == module:
            return inst, vstruct['var'][inst]
    return 'u_'+module, None


def _AutoInst_template_format(module, template):
    vstruct = {'inst': [], 'var': {}}
    if not isinstance(template, str):
        return vstruct
    inst = re.match(r'[A-Za-z_]\w*', template.strip())
    inst = inst.group() if inst else 'u_'+module
    vstruct['inst'] = [inst]
    vstruct['var'][inst] = {'module': module, 'parameter': {}, 'port': {}}
    for net0, net1 in _regex_connect.findall(template):
        key = 'parameter' if net0.isupper() else 'port'
        vstruct['var'][inst][key][net0] = net1.replace(' ', '').strip()
    return vstruct


# for AUTOTEMPLATE
def _AutoInst_comment(vstruct, inst_struct):
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
    comment += ['); */']
    return comment


# format autoinst parameter
def _AutoInst_parameter(vstruct, inst_struct):
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


# ifdef port connect
def _AutoInst_ifdef(vstruct, inst_struct):
    content, lastindex = [], 0
    inst_port = inst_struct['port'] if inst_struct else {}
    # construct format string
    length0 = vstruct['len']
    length0 = max(length0['input']['var'], length0['output']['var'], length0['inout']['var']) + 1
    length1 = max(length0, max([len(val) for val in inst_port.values()] + [1]))
    strFormat = '    .{:'+str(length0)+'} ( {:'+str(length1)+'} ),'
    for ifdef in vstruct['ifdef']:
        if ifdef.startswith('`ifdef') or ifdef.startswith('`ifndef') or \
                ifdef.startswith('`elsif') or ifdef.startswith('`else') or \
                ifdef.startswith('`endif'):
            if ifdef == '`endif' and content[-1] == '`else':
                content[-1] = ifdef
            elif ifdef == '`else' and content[-1].startswith('`ifdef'):
                content[-1] = '`ifndef '+content[-1].split()[-1]
            else:
                content += [ifdef]
        elif ifdef in vstruct['input'] + vstruct['output'] + vstruct['inout']:
            val = inst_port.get(ifdef, ifdef)
            content += [strFormat.format(ifdef, val)]
            lastindex = len(content) - 1
    if lastindex == 0:
        return None, 0
    return content, lastindex


# format autoinst port connection
def _AutoInst_connect(vstruct, inst_struct):
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
            if 'ifdef' not in vstruct['var'][var].get('attr', set()):
                val = inst_port.get(var, var)
                content += [strFormat.format(var, val)]
        if content and content[-1] == '    // '+port:
            content.pop()
    return content


# Automatically generate undefined instance output/inout port
def HDLAutoWire(vstruct):
    content, input_net = [], []
    wire_exists = vstruct['output'] + vstruct['inout'] + vstruct['wire']
    # collect wire_net
    wire_net, comment = [], []
    for inst in vstruct['inst']:
        repeated, nets = _AutoWire_connect(vstruct['var'][inst])
        comment += ['// from instant of '+inst]
        if not nets:
            continue
        for net, val in nets.items():
            if net in wire_exists:
                continue
            if val['kind'] == 'input':
                input_net += [(net, val['width'])]
                continue
            wire_exists += [net]
            wire_net += [(val['width'], net, len(comment)-1)]
        if repeated:
            content += ['// repeated port in ifdef from instant of '+inst] + \
                       ['//  '+str(item) for item in repeated]
    # undefined input
    wire_exists += vstruct['input'] + vstruct['reg']
    input_net = ['reg '+width+' '+net+';' for net, width in input_net if net not in wire_exists]
    if input_net:
        content += ['// undefined net for instants input port'] + input_net
    # autowire
    content += ['/*AUTOWIRE*/',
                '// Automatically generate undefined instances output/inout port']
    ind_comment = -1
    length = max([len(item[0]) for item in wire_net] + [1])
    strFormat = 'wire {:'+str(length)+'} {};'
    for item in wire_net:
        if ind_comment != item[2]:
            ind_comment = item[2]
            content += [comment[ind_comment]]
        content += [strFormat.format(item[0], item[1])]
    content += ['// End of automatics']
    return content


# get connect signal width from source file
_regex_identifier = re.compile(r'[A-Za-z_][A-Za-z_0-9]*')
def _AutoWire_connect(inst):
    repeated, connect = [], {}
    inst_vfile = _search_vfile(inst['module'], fullmatch=True)
    if not inst_vfile:
        return None, None
    kinds = ('ifdef', 'module', 'input', 'output', 'inout', 'parameter', 'localparam')
    inst_vstruct = _vstruct_analyze(inst_vfile, isfile=True, kinds=kinds)
    for var, net in inst['port'].items():
        net = _regex_identifier.match(net)
        port = inst_vstruct['var'].get(var, {'kind': 'None'})
        if not net or port['kind'] not in ('input', 'output', 'inout'):
            continue
        net = net.group()
        if {'repeated', 'ifdef'} <= port.get('attr', set()):
            repeated += [(var, net)]
            continue
        port['msb'] = _AutoWire_paramexpr(port['msb'], inst, inst_vstruct)
        port['lsb'] = _AutoWire_paramexpr(port['lsb'], inst, inst_vstruct)
        if port['msb'] and port['lsb']:
            width = '[' + port['msb'] + ':' + port['lsb'] + ']'
        else:
            width = ''
        connect[net] = {'kind': port['kind'], 'width': width}
    return repeated, connect


# define function used in verilog
# for eval function in _AutoWire_paramexpr
def log2(num):
    value = 1
    while 2**value < num:
        value += 1
    return value


_regex_upper_word = re.compile(r'[A-Z_][A-Z_0-9]*')
# parse parameter expression
def _AutoWire_paramexpr(expr, inst, vstruct):
    global DEFINE
    if not expr or expr.isdigit():
        return expr
    params = _regex_upper_word.findall(expr)
    while params:
        param = params.pop()
        define = '`'+param
        if param in DEFINE and define in expr:
            expr = expr.replace(define, DEFINE['define'])
        elif param in inst['parameter']:
            expr = expr.replace(param, inst['parameter'][param])
        elif param in vstruct['parameter'] or param in vstruct['localparam']:
            expr = expr.replace(param, vstruct['var'][param]['val'])
        else:
            continue
        params += _regex_upper_word.findall(expr)
    try:
        expr = int(eval(expr))
        return str(expr) if expr != 0 else ''
    #except (NameError, TypeError):
    except:
        return expr


def HDLAutoReg(vstruct):
    repeated = set()
    content = ['/*AUTOREG*/',
               '// Automatically generate register for undeclared output']
    length = vstruct['len']['output']
    length = length['msb'] + length['lsb'] + 3
    strFormat = 'reg  {:'+str(length)+'} {};'
    for output in vstruct['output']:
        if output in vstruct['eq'] and 'regtype' not in vstruct['var'][output].get('attr', set()):
            if {'ifdef', 'repeated'} <= vstruct['var'][output].get('attr', set()):
                repeated |= {'//  '+output}
            else:
                width = _Gen_Width(vstruct['var'][output], style='index')
                content += [strFormat.format(width, output)]
    if repeated:
        repeated = ['// repeated output (regtye) in ifdef'] + list(repeated)
    else:
        repeated = []
    content += ['// End of automatics']
    return repeated + content


# auto format&update code base on vcontent:
# AUTOSTM, AUTOINST, AUTOTIE
def HDLAutoFmt(vcontent, extra=EXTRA[0]):
    if os.path.isfile(vcontent):
        with open(vcontent, 'r') as fh:
            vcontent = ''.join(fh.readlines())
    content = _AutoFmt_stm(vcontent, extra) if r'/*STM' in vcontent or r'/*AUTOSTM' in vcontent else \
              _AutoFmt_inst(vcontent) if r'/*AUTOINST*/' in vcontent else \
              _AutoFmt_tie(vcontent, extra) if r'/*AUTOTIE*/' in vcontent else ''
    return content


# auto format state-matchine
def _AutoFmt_stm(vcontent, extra):
    vcontent += ' ' # Make sure there is at least one space
    content = _AutoFmt_stm_param(vcontent) if 'localparam ' in vcontent else \
              _AutoFmt_stm_case(vcontent, extra) if 'case(' in vcontent else \
              _AutoFmt_stm_wire(vcontent, extra) # if 'wire ' in vcontent else \
    return content


# auto-update localparam definition
def _AutoFmt_stm_param(vcontent):
    global MAXLEN
    maxlen = max(MAXLEN, 90)
    stm, arg = _AutoFmt_stm_get(vcontent)
    if not stm:
        return ''
    stm = stm.upper()
    # remove line-comment, block-comment, 'localparam', value, _WIDTH
    vcontent = re.sub(r'=[^,;]*[,;]|localparam|/\*.*?\*/|//.*?\n|[A-Za-z_]\w*_WIDTH', '', vcontent)
    # find all param
    words = _regex_word.findall(vcontent)
    if not words:
        return ''
    words = [(stm+'_' if not word.upper().startswith(stm) else '')+word.upper()
             for word in words]
    content = ['/*STM:'+stm+(' '+arg if arg else '') + '*/']
    length = max([len(word) for word in words])
    width = str(len(words) if arg else log2(len(words)))
    content += ['localparam '+stm+'_WIDTH = '+width+';']
    if arg:
        strFormat = '{} {:'+str(length)+'} = '+width+'\'b{},'
        for ind, word in enumerate(words):
            text = '          ' if ind else 'localparam'
            content += [strFormat.format(text, word, bin(1<<ind)[2:].rjust(int(width), '0'))]
    else:
        content += ['localparam']
        for ind, word in enumerate(words):
            ind = bin(ind)[2:]
            text = word.ljust(length, ' ')+' = '+width+'\'b'+ind.rjust(int(width), '0')+','
            if len(content[-1]) + len(text) + 1 > maxlen:
                content += ['           '+text]
            else:
                content[-1] = content[-1]+' '+text
    content[-1] = content[-1][:-1] + ';'
    return content


# auto-gen wire st_... = ... ;
def _AutoFmt_stm_wire(vcontent, extra):
    if not extra:
        return ''
    stm, _ = _AutoFmt_stm_get(vcontent)
    if not stm:
        return ''
    stm = stm.upper()
    content = ['/*STM:'+stm+'*/']
    kinds = ('localparam')
    vstruct = _vstruct_analyze(extra, isfile=os.path.isfile(extra), kinds=kinds)
    params = [param for param in vstruct['localparam']
              if param.startswith(stm+'_') and not param.endswith('_WIDTH')]
    if not params:
        return ''
    length = max([len(param) for param in params])
    strFormat = 'wire st_{:'+str(length)+'} = state_'+stm.lower()+' == {};'
    content += [strFormat.format(param.lower(), param) for param in params]
    return content


# auto-update case() ... endcase
def _AutoFmt_stm_case(vcontent, extra):
    if not extra:
        return ''
    stm, _ = _AutoFmt_stm_get(vcontent)
    if not stm:
        return ''
    stm = stm.upper()
    content = ['case(state_'+stm.lower()+') /*STM:'+stm+'*/']
    kinds = ('localparam')
    vstruct = _vstruct_analyze(extra, isfile=os.path.isfile(extra), kinds=kinds)
    params = [param for param in vstruct['localparam']
              if param.startswith(stm+'_') and not param.endswith('_WIDTH')]
    if not params:
        return ''
    vcontent = vcontent.strip().split('\n')
    params = [param+':' for param in params]
    length = max([len(param) for param in params])
    strFormat = '    {:'+str(length)+'} nxt_state_'+stm.lower()+' = ;'
    regex_param_start = re.compile(r'\s*[A-Z_][A-Z_0-9]*:')
    # find start: case() /*AUTOSTM*/
    while vcontent and 'STM' not in vcontent[0]:
        vcontent.pop(0)
    if vcontent:
        vcontent.pop(0)
    for param in params:
        text = strFormat.format(param)
        if vcontent and vcontent[0].strip().startswith(param):
            text = vcontent.pop(0).strip().split(':', 1)
            text[0] += ':'
            content += ['    '+text[0].ljust(length, ' ')+text[1].strip()]
            while vcontent and not regex_param_start.match(vcontent[0]):
                if 'endcase' in vcontent[0]:
                    vcontent = []
                    break
                content += [(' '*(18+length+len(stm)))+vcontent.pop(0).strip()]
        else:
            content += [text]
    content += ['endcase']
    return content


# get stm type & arg
def _AutoFmt_stm_get(vcontent):
    stm = re.search(r'/\*(?:AUTO)?STM:\s*([A-Za-z_][A-Za-z_0-9]*)\s*(\w+)?\s*\*/', vcontent)
    if not stm:
        return None, None
    return stm.groups()


def _AutoFmt_inst(vcontent):
    kinds = ('inst')
    inst_vstruct = _vstruct_analyze(vcontent, isfile=False, kinds=kinds)
    if not inst_vstruct['inst']:
        return ''
    module = inst_vstruct['var'][inst_vstruct['inst'][0]]['module']
    vfile = _search_vfile(module, fullmatch=True)
    if not vfile:
        return ''
    kinds = ('ifdef', 'module', 'parameter', 'localparam', 'input', 'output', 'inout')
    vstruct = _vstruct_analyze(vfile, isfile=True, kinds=kinds)
    if vstruct['module'] != module:
        return ''
    return HDLAutoInst(vstruct, inst_vstruct)


def _AutoFmt_tie(vcontent, extra):
    return vcontent


def HDLAutoFile(vfile):
    return ''

# ---------------------------------------------------------------
# Miscellaneous function
# ---------------------------------------------------------------
# Automatically generate undef file for define file
def HDLUndef(vstruct):
    content = ['// ------------------------------------------------',
               '// Automatically generate verilog undef-file by vgen.py',
               '// ------------------------------------------------']
    content += ['']
    for define in vstruct['define']:
        content += ['`ifdef '+define, '    `undef '+define, '`endif', '']
    return content


def HDLDefine(vfile):
    global DEFINE
    if vfile:
        vfile = _search_vfile(vfile)
        if vfile:
            _initial_define_vfile(vfile)
    return DEFINE


# generate fake file for verilog file
def HDLFake(vstruct):
    content = ['// ------------------------------------------------',
               '// Automatically generate verilog fake-file by vgen.py',
               '// ------------------------------------------------']
    content += [''] + HDLAutoArg(vstruct) + ['']
    # parameter
    for var in vstruct['parameter']:
        content += ['parameter ' + var + ' = ' + vstruct['var'][var]['val'] + ';']
    content += ['']
    # localparam
    for var in vstruct['localparam']:
        content += ['localparam ' + var + ' = ' + vstruct['var'][var]['val'] + ';']
    content += ['']
    # port
    for port in ('input', 'output', 'inout'):
        for var in vstruct[port]:
            width = _Gen_Width(vstruct['var'][var], 'index')
            content += [port + ' ' + width + var + ';']
        content += ['']
    # tie output
    for var in vstruct['output']:
        val = _Gen_Width(vstruct['var'][var], 'val')
        content += ['assign ' + var + ' = ' + val + ';']
    content += ['', 'endmodule', '']
    return content


# generate include file from flist or module
def HDLIncdir(vfile):
    content = []
    defines = ['+define+'+key+('='+val if val else '') for key, val in DEFINE.items()]
    # For the generated file list
    if vfile.endswith('.f') and os.path.isfile(vfile) and '/ft/' not in vfile:
        content = defines + _flist2incdir(vfile)
    else: # search match filelist or parse module
        content = HDLFlist(vfile)
        if content:
            content = defines + _flist2incdir(content)
    return content


# parsing module file and get flist
def HDLFlist(vfile):
    global DEFINE
    defines = ['+define+'+key+('='+val if val else '') for key, val in DEFINE.items()]
    flist_init, content = _flist2flist(vfile)
    if flist_init:
        content = defines + content
        flist_mco = flist_init[:-2]+'_mco.f'
        if os.path.isfile(flist_mco):
            _, content_mco = _flist2flist(flist_mco)
            content += content_mco
    else:
        vfile = _search_vfile(vfile)
        if vfile:
            content = defines + _module2flist(vfile)
    return content


# return vstruct
def HDLVStruct(vstruct):
    del vstruct['eq']
    del vstruct['len']
    del vstruct['assign']
    for key in ('parameter', 'localparam', 'input', 'output', 'inout',
                'define', 'inst', 'reg', 'wire'):
        if not vstruct[key]:
            del vstruct[key]
    return vstruct


# ---------------------------------------------------------------
#    verilog file search .v .sv, search order: flist, incdir, path
# ---------------------------------------------------------------
# initial global var: INCDIR, FLIST, DEFINE
# using environment default: VGEN_INCDIR, VGEN_FLIST, VGEN_DEFINES
def _initial_env(incdirs=os.getenv('VGEN_INCDIR', ''), flists=os.getenv('VGEN_FLIST', ''),
                 defines=os.getenv('VGEN_DEFINE', '')):
    global VERILATOR, FILELIST
    # initial include directories
    incdirs = (VERILATOR+':' if VERILATOR else '')+incdirs
    _initial_incdir(incdirs)
    # initial file list
    flists = (FILELIST+':' if FILELIST else '')+flists
    _initial_flist(flists)
    # initial define
    _initial_define(defines)


def _initial_incdir(incdirs):
    global INCDIR
    # parse from arguments
    for incdir in [VFILE] + EXTRA:
        if incdir and incdir.startswith('+incdir+'):
            incdir = incdir[8:]
            if os.path.isdir(incdir):
                INCDIR += [incdir]
    # parse from environment
    for incdir in incdirs.split(':'):
        if incdir.startswith('+incdir+'):
            incdir = incdir[8:]
            if os.path.isdir(incdir):
                INCDIR += [incdir]
        elif os.path.isfile(incdir):
            with open(incdir, 'r') as fh:
                for line in fh:
                    line = line.strip()
                    if line.startswith('+incdir+') and os.path.isdir(line[8:]):
                        INCDIR += [line[8:]]


def _initial_flist(flists):
    global FLIST
    for flist in flists.split(':'):
        if os.path.isfile(flist):
            with open(flist, 'r') as fh:
                for line in fh:
                    line = line.strip()
                    if os.path.isfile(line) and (line.endswith('.v') or line.endswith('.sv')):
                        FLIST += [line]


# parser define file
def _initial_define(defines):
    global DEFINE, VFILE, EXTRA
    # parse from arguments
    for define in [VFILE] + EXTRA:
        if define and define.startswith('+define+'):
            for item in define[8:].split('+'):
                item = item.split('=')
                if item[0]:
                    DEFINE[item[0]] = item[1] if len(item) > 1 else None
    # parse from environment
    for define in defines.split(':'):
        if define.startswith('+define+'):
            for item in define[8:].split('+'):
                item = item.split('=')
                if item[0]:
                    DEFINE[item[0]] = item[1] if len(item) > 1 else None
        # parse from file
        elif os.path.isfile(define):
            _initial_define_vfile(define)


def _initial_define_vfile(vfile):
    global DEFINE
    ifdef, elsif = [True], True
    with open(vfile, 'r') as fh:
        for line in fh:
            line = line.strip().split()
            if not line:
                continue
            length = len(line)
            if line[0] == '`ifdef' and length > 1:
                ifdef += [line[1] in DEFINE and ifdef[-1]]
                elsif = ifdef[-1]
            elif line[0] == '`elsif' and length > 1 and len(ifdef) > 1:
                ifdef[-1] = line[1] in DEFINE and ifdef[-2]
                elsif = elsif or ifdef[-1]
            elif line[0] == '`ifndef' and length > 1:
                ifdef += [line[1] not in DEFINE and ifdef[-1]]
                elsif = ifdef[-1]
            elif line[0] == '`else' and len(ifdef) > 1:
                ifdef[-1] = not (ifdef[-1] or elsif) and ifdef[-2]
            elif line[0] == '`endif' and len(ifdef) > 1:
                ifdef.pop()
                elsif = ifdef[-1]
            elif line[0] == '`define' and ifdef[-1] and length > 1:
                DEFINE[line[1]] = line[2] if length > 2 else None
            elif line[0] == '`undef' and ifdef[-1] and length > 1 and line[1] in DEFINE:
                del DEFINE[line[1]]


# search verilog file (.v, .sv) base on flist, incdir, path
def _search_vfile(vfile, searchAll=False, fullmatch=False):
    global FLIST
    if os.path.isfile(vfile) and (vfile.endswith('.v') or vfile.endswith('.sv')):
        return vfile
    matchDict = {'most': '~!@#$%^&*'*100, 'full': None, 'all': []}
    # search file in filelist first
    FLIST = [subfile for subfile in FLIST if os.path.isfile(subfile)]  # Keep existing files only
    vfile = _search_special(vfile)
    if _search_flist(vfile, matchDict, searchAll):
        return matchDict['full']
    # search file in incdir second
    if _search_incdir(vfile, matchDict, searchAll):
        return matchDict['full']
    # search file in localpath third
    if _search_path(vfile, matchDict, searchAll):
        return matchDict['full']
    return None if fullmatch else \
            matchDict['all'] if searchAll else \
            matchDict['most'] if os.path.isfile(matchDict['most']) else None


# specal case, single file multiple module
def _search_special(vfile):
    return 'mx_cell' if vfile.startswith('mx_cell_') else vfile


# search file in filelist, the results are saved in the 'matchDict'
# return True if fullmatch else False
def _search_flist(vfile, matchDict, searchAll):
    global FLIST, INCDIR
    for subfile in FLIST:
        basename = os.path.basename(subfile)
        dirname = os.path.dirname(subfile)
        if dirname not in INCDIR: # update incdir
            INCDIR += [dirname]
        if _search_judge(vfile, subfile, basename, matchDict, searchAll):
            return True
    return False


# search file in incdir, the results are saved in the 'matchDict'
# return True if fullmatch else False
def _search_incdir(vfile, matchDict, searchAll):
    global FLIST, INCDIR
    for root in INCDIR:
        for subfile in glob.iglob(os.path.join(root, '*')):
            if not subfile.endswith('.v') and not subfile.endswith('.sv'):
                continue
            if subfile not in FLIST:
                FLIST += [subfile] # update filelist
            basename = os.path.basename(subfile)
            if _search_judge(vfile, subfile, basename, matchDict, searchAll):
                return True
    return False


# search file in path, the results are saved in the 'matchDict'
# return True if fullmatch else False
def _search_path(vfile, matchDict, searchAll):
    global FLIST, INCDIR, PATH
    if not PATH:
        return False
    if isinstance(PATH, str):
        PATH = os.walk(PATH)
    while True:
        try:
            root, _, files = next(PATH)
        except StopIteration:
            PATH = None
            break
        if 'work/' in root or root in INCDIR: # mask work-dir
            continue
        for basename in files:
            if not basename.endswith('.v') and not basename.endswith('.sv'):
                continue
            subfile = os.path.join(root, basename)
            if subfile not in FLIST:
                FLIST += [subfile] # update filelist
            if _search_judge(vfile, subfile, basename, matchDict, searchAll):
                return True
        INCDIR += [root]
    return False


# Judge file match
def _search_judge(vfile, subfile, basename, matchDict, searchAll):
    if vfile in basename and subfile not in matchDict['all']:
        matchDict['all'] += [subfile]
        if len(subfile.replace(vfile, '')) < len(matchDict['most'].replace(vfile, '')): # most match
            matchDict['most'] = subfile
    if not searchAll and basename in (vfile, vfile + '.v', vfile + '.sv'): # full match
        matchDict['full'] = subfile
        return True
    return False


# ---------------------------------------------------------------
#    filelist/incdir relevent
# ---------------------------------------------------------------
# convert flist file to include file
def _flist2incdir(vfile):
    content = []
    if isinstance(vfile, list):
        lines = vfile
    else:
        with open(vfile, 'r') as fh:
            lines = fh.readlines()
    for line in lines:
        line = line.strip()
        if (line.endswith('constant.v') or line.endswith('define.v') or \
                line.startswith('`define') or line.startswith('+incdir+')) and \
                line not in content:
            content += [line]
        elif line.endswith('.v') or line.endswith('.sv'):
            root = os.path.dirname(line)
            root = '+incdir+'+root
            if os.path.isdir(root[8:]) and root not in content:
                content += [root]
    return content


# Parsing module to filelist
def _module2flist(vfile):
    global MAXLEN
    blackbox = []
    content = [vfile]
    kinds = ('module', 'inst')
    vstruct = _vstruct_analyze(vfile, isfile=True, kinds=kinds)
    module_exist = [vstruct['module']]
    module_search = [vstruct['var'][var]['module'] for var in vstruct['inst']]
    while module_search:
        module = module_search.pop()
        if module in module_exist:
            continue
        module_exist += [module]
        vfile = _search_vfile(module, fullmatch=True)
        if not vfile:
            blackbox += [module]
            continue
        content += [vfile]
        vstruct = _vstruct_analyze(vfile, isfile=True, kinds=kinds)
        module_search += [vstruct['var'][var]['module'] for var in vstruct['inst']]
    precontent = ['// black box', '// ']
    for item in blackbox:
        if len(precontent[-1] + item) > MAXLEN:
            precontent += ['// ' + item]
        else:
            precontent[-1] = precontent[-1] + ' ' + item
    return (precontent if precontent[1] != '// ' else []) + content


# Parsing module to incdir
def _module2incdir(vfile):
    content = []
    for line in _module2flist(vfile):
        line = '+incdir+'+os.path.dirname(line)
        if line not in content:
            content += [line]
    return content


def _flist2flist(vfile):
    global DEFINE
    flist_init = _flist2flist_search(vfile)
    if not flist_init:
        return None, None
    defines = copy.deepcopy(DEFINE)
    flists, vfiles, exists_flists = [flist_init], [], []
    while flists:
        ifdef, elsif = [True], True
        flist = flists.pop(0)
        exists_flists += [flist]
        rtl_path = os.path.join(os.path.split(flist)[0], 'rtl')
        with open(flist, 'r') as fh:
            for line in fh:
                line = line.strip().rstrip('/').split()
                if not line:
                    continue
                if line[0].startswith('`'):
                    elsif = _flist2flist_ifdef(defines, ifdef, elsif, line)
                elif not ifdef or not ifdef[-1]:
                    continue
                elif line[0] == '-f' and len(line) > 1:
                    new = _flist2flist_env(line[1], rtl_path)
                    if new and new not in exists_flists and os.path.isfile(new):
                        flists += [new]
                elif line[0].startswith('+define+'):
                    vfiles += [line[0]]
                elif line[0].startswith('+incdir+'):
                    new = _flist2flist_env(line[0][8:], rtl_path)
                    if new and os.path.isdir(new):
                        vfiles += ['+incdir+'+new]
                else:
                    new = _flist2flist_env(line[0], rtl_path)
                    if new and new not in vfiles and os.path.isfile(new):
                        vfiles += [new]
    return  flist_init, vfiles


def _flist2flist_search(vfile):
    if vfile.endswith('.f'):
        if os.path.isfile(vfile):
            return vfile
        return None
    for root, _, flists in os.walk(os.getcwd()):
        if not root.endswith('/ft') or '/work/' in root:
            continue
        for flist in flists:
            if flist in (vfile, vfile+'.f'):
                return os.path.join(root, flist)
    return None


def _flist2flist_ifdef(defines, ifdef, elsif, line):
    length = len(line)
    if line[0] == '`ifdef' and length > 1:
        ifdef += [line[1] in defines and ifdef[-1]]
        elsif = ifdef[-1]
    elif line[0] == '`elsif' and length > 1 and len(ifdef) > 1:
        ifdef[-1] = line[1] in defines and ifdef[-2]
        elsif = elsif or ifdef[-1]
    elif line[0] == '`ifndef' and length > 1:
        ifdef += [line[1] not in defines and ifdef[-1]]
        elsif = ifdef[-1]
    elif line[0] == '`else' and len(ifdef) > 1:
        ifdef[-1] = not (ifdef[-1] or elsif) and ifdef[-2]
    elif line[0] == '`endif' and len(ifdef) > 1:
        ifdef.pop()
        elsif = ifdef[-1]
    #elif line[0] == '`define' and ifdef[-1] and length > 1:
    #    defines[line[1]] = line[2] if length > 2 else None
    elif line[0] == '`undef' and ifdef[-1] and length > 1 and line[1] in defines:
        del defines[line[1]]
    return elsif


# get absolute path
def _flist2flist_env(line, rtl_path):
    rslt = None
    if line.startswith('./'):
        rslt = os.path.join(rtl_path, line[2:])
    elif line.startswith('../'):
        rslt = os.path.join(os.path.split(rtl_path)[0], line[3:])
    elif line.startswith('/'):
        rslt = line
    elif line.startswith('$'):
        line = line[1:].split('/', 1)
        env = os.getenv(line[0].strip('{}'), None)
        if not env:
            pass
        elif len(line) == 1:
            rslt = env.rstrip('/') 
        else:
            rslt = os.path.join(env, line[1])
    else:
        rslt = os.path.join(rtl_path, line)
    return rslt


def _flist2flist_log():
    pass

# ---------------------------------------------------------------
#    verilog file parser
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
        '`ifdef', '`ifndef', '`elsif', '`else', '`endif', '`define'
        }

# ---------------------------------------------------------------

# keywords to be ignored
_keywords_ignore = _keywords_all - _keywords_match
_compiler_directives_ignore = _compiler_directives_all - _compiler_directives_match

_keywords_ignore_str = '|'.join((r'\b'+item+r'\b' for item in _keywords_ignore))
_compiler_directives_ignore_str = '|'.join((item+r'\b' for item in _compiler_directives_ignore))

_spec_token = {
        'line_comment':      r'//.*?\n',
        'block_comment':     r'/\*.*?\*/',
        'attributes':        r'\(\*.*?\*\)',
        'function':          r'\bfunction\b.*?\bendfunction\b',
        'task':              r'\btask\b.*?\bendtask',
        'if':                r'\bif\s*\(.*?\)',
        'elseif':            r'\belse\s+if\s*\(.*?\)',
        'for':               r'\bfor\s*\(.*?\)',
        'while':             r'\bwhile\s*\(.*?\)',
        'always':            r'\balways\s*@(\*|\(.*?\))',
        'case':              r'\bcase[xz]?\s*\(.*?\)',
        'dollar':            r'$\w+(\(.*?\))?;',                    # system call
        'direct':            _compiler_directives_ignore_str,       # Macro
        'keyword':           _keywords_ignore_str,                  # ignore unuseless keyword
        'module':            r'\bmodule\s+\w+',                     # module match start
        'define':            r'`define\s+.*?\n',
        'ifdef':             r'`(ifdef|ifndef|elsif)\s+\w+|`(else|endif)',
        'parameter':         r'(?<=\bparameter\b)\s+.*?[;)]',
        'input':             r'(?<=\binput\b).*?\n',
        'output':            r'(?<=\boutput\b).*?\n',
        'inout':             r'(?<=\binout\b).*?\n',
        'localparam':        r'(?<=\blocalparam\b).*?;',
        'reg':               r'(?<=\breg\b).*?;',
        'wire':              r'(?<=\bwire\b).*?;',
        'assign':            r'(?<=\bassign\b).*?;',
        'eq':                r'\w+\s*<?=[^=].*?;',
        'inst':              r'\w+\s+(#\(.*?\)\s+)?\w+\s*\(.*?\);'
        }

_regex_token = re.compile('|'.join('(?P<%s>%s)' % pair for pair in _spec_token.items()), re.S)
_regex_comment = re.compile(_spec_token['line_comment']+'|'+
                            _spec_token['block_comment']+'|'+
                            _spec_token['attributes'], re.S)
_regex_width = re.compile(r'\[(.*?)\]')
_regex_word = re.compile(r'[a-zA-Z_]\w*')
_regex_expression = re.compile(r'(\w+)\s*=\s*([^=,;][^,;]*)')
_regex_connect = re.compile(r'\.(\w+)\s*\((.*?)\)')


# ----------------------------------------
# parse verilog file/content to vstruct 
# ----------------------------------------
# get module name of verilog file
def _vparse_module(vstruct, kind, value):
    vstruct[kind] = value.split()[-1].strip()


# record condition define for all parse-function: `ifdef, `elsif
IFDEF_RECORD = {'insertion': 0, 'inside': [], 'ifdef': [], 'elsif': 0}

def _vparse_directive(vstruct, kind, value):
    global IFDEF_RECORD
    value = value.strip().split()
    if value[0] in ('`ifdef', '`ifndef', '`elsif'):
        IFDEF_RECORD[kind] += ['`ifdef '+value[1]]
        IFDEF_RECORD['inside'] += [value[0] != '`ifndef']
        if value[0] == '`elsif':
            IFDEF_RECORD['elsif'] += 1
            IFDEF_RECORD['inside'][-2] = not IFDEF_RECORD['inside'][-2]
    elif value[0] == '`else' and IFDEF_RECORD[kind]:
        IFDEF_RECORD['inside'][-1] = not IFDEF_RECORD['inside'][-1]
    elif value[0] == '`endif' and IFDEF_RECORD[kind]:
        while IFDEF_RECORD['elsif']:
            IFDEF_RECORD['ifdef'].pop()
            IFDEF_RECORD['inside'].pop()
            IFDEF_RECORD['elsif'] -= 1
        IFDEF_RECORD['ifdef'].pop()
        IFDEF_RECORD['inside'].pop()
    if IFDEF_RECORD[kind]:
        _ifdef_update(vstruct)


def _ifdef_update(vstruct):
    global IFDEF_RECORD
    start, end = 0, len(vstruct['ifdef'])
    for inside, ifdef in zip(IFDEF_RECORD['inside'], IFDEF_RECORD['ifdef']):
        start = _ifdef_update_find(vstruct, ifdef, start, end) # find `ifdef
        if start == end: # not find `ifdef, new
            vstruct['ifdef'] = vstruct['ifdef'][:start] + \
                               [ifdef, '`else', '`endif'] + \
                               vstruct['ifdef'][start:]
            IFDEF_RECORD['insertion'] = start + (1 if inside else 2)
            return
        start += 1
        ind = _ifdef_update_find(vstruct, '`else', start, end)
        if inside:
            end = ind
        else:
            start = ind + 1
            end = _ifdef_update_find(vstruct, '`endif', start, end)
    IFDEF_RECORD['insertion'] = end


def _ifdef_update_find(vstruct, tag, start, end):
    global IFDEF_RECORD
    match, ind = [False], start
    while ind < end and tag != vstruct['ifdef'][ind] or (match and match[-1]):
        if vstruct['ifdef'][ind].startswith('`ifdef'):
            match += [True]
        elif vstruct['ifdef'][ind].startswith('`endif') and match:
            match.pop()
        ind += 1
    return ind


# update attr info, include ifdef, regtype, repeated
def _attr_update(vstruct, var, attr):
    global IFDEF_RECORD
    if IFDEF_RECORD['ifdef']:
        attr |= {'ifdef'}
        exists, ind = False, IFDEF_RECORD['insertion'] - 1
        while ind >= 0 and not vstruct['ifdef'][ind].startswith('`'):
            if vstruct['ifdef'][ind] == var:
                exists = True
                break
            ind -= 1
        if not exists:
            vstruct['ifdef'].insert(IFDEF_RECORD['insertion'], var)
            IFDEF_RECORD['insertion'] += 1
    if attr:
        if 'attr' in vstruct['var'][var]:
            vstruct['var'][var]['attr'] |= attr
        else:
            vstruct['var'][var]['attr'] = attr


# define parser: `define
def _vparse_define(vstruct, kind, value):
    attr = set()
    define = value.strip().split()
    if len(define) < 2:
        return
    vstruct[kind] += [define[1]]
    val = ''.join(define[2:]) if len(define) >= 3 else ''
    define[1] = '`'+define[1]
    vstruct['var'][define[1]] = {'kind': kind, 'val': val}
    _attr_update(vstruct, define[1], attr)


# param parser: parameter and localparam
def _vparse_parameter(vstruct, kind, value):
    attr = set()
    value = value.strip()
    if value.endswith(')'): # #(parameter ...) may endswith ')'
        value = value[:-1]
    for var, val in _regex_expression.findall(value):
        val = val.replace(' ', '').strip()
        vstruct[kind] += [var]
        vstruct['var'][var] = {'kind': kind, 'val': val}
        vstruct['len'][kind] = {'var': max(len(var), vstruct['len'][kind]['var']),
                                'val': max(len(val), vstruct['len'][kind]['val'])}
        _attr_update(vstruct, var, attr)


# net parser: input ouput inout reg wire
_net_word_ignore = ('signed', 'scalared', 'vectored', 'supply0', 'supply1',
                    'strong0', 'strong1', 'pull0', 'pull1', 'weak0', 'weak1', 'small',
                    'medium', 'large', 'input', 'output', 'inout', 'reg', 'wire')
def _vparse_net(vstruct, kind, value):
    value = value.split('=', 1)[0].strip()  # consider: wire var = ...
    width = _regex_width.search(value)
    start = width.end() if width else 0
    value = value[start:]
    if width and ':' in width.group(1) and value[0] != ';':
        msb, lsb = width.group(1).split(':', 1)
    else:
        msb, lsb = '', ''
    regtype = False
    memWidth = _regex_width.search(value) # consider memory type
    if memWidth:
        value = value[:memWidth.start()]
    for var in _regex_word.findall(value):
        attr = set()
        if var == 'reg' and kind == 'output' and not regtype: # output reg for all var
            regtype = True
            continue
        if var in _net_word_ignore:
            continue
        if kind == 'reg' and var in vstruct['output']: # reg def for current var
            attr |= {'regtype'}
        elif not (kind == 'wire' and vstruct['var'].get(var, {'kind': 'None'})['kind'] in 
                  ('input', 'output', 'inout')):
            vstruct[kind] += [var]
            if var in vstruct['var']:
                attr |= {'repeated'}
            vstruct['var'][var] = {'kind': kind, 'msb': msb, 'lsb': lsb}
            vstruct['len'][kind] = {'var': max(len(var), vstruct['len'][kind]['var']),
                                    'msb': max(len(msb), vstruct['len'][kind]['msb']),
                                    'lsb': max(len(lsb), vstruct['len'][kind]['lsb'])}
        if regtype or 'regtype' in attr:
            vstruct['reg'] += [var]
        _attr_update(vstruct, var, attr | ({'regtype'} if regtype else set()))


# expression parser: assign statement or =,<= in always block
_regex_delay = re.compile(r'#\S+')
def _vparse_expression(vstruct, kind, value):
    global IFDEF_RECORD
    value = value.split('=', 1)[0].strip()
    value = _regex_delay.sub('', value)      # remove delay
    value = _regex_width.sub('', value)      # remove width [...]
    for word in _regex_word.findall(value):  # consider {a,b,..} = ...
        if word not in vstruct[kind]:
            vstruct[kind] += [_regex_word.search(value.strip()).group()]


# instant parser
_regex_inst_name = re.compile(r'(?<=\))\s*\w+\s*(?=\()')
def _vparse_inst(vstruct, kind, value):
    attr = set()
    global IFDEF_RECORD
    value = value.strip()
    module = _regex_word.match(value)
    if not module:
        return
    value = value[module.end():].strip()
    if value.startswith('#('):
        inst = _regex_inst_name.search(value)
    else:
        inst = _regex_word.match(value)
    if not inst:
        return
    inst_name = inst.group().strip()
    vstruct[kind] += [inst_name]
    vstruct['var'][inst_name] = {'kind': kind, 'module': module.group(),
                                 'parameter': {}, 'port': {}}
    _attr_update(vstruct, inst_name, attr)
    for net0, net1 in _regex_connect.findall(value[:inst.end()]):
        vstruct['var'][inst_name]['parameter'][net0] = net1.replace(' ', '').strip()
    for net0, net1 in _regex_connect.findall(value[inst.end():]):
        vstruct['var'][inst_name]['port'][net0] = net1.replace(' ', '').strip()

# ------------------------------------------------------------------
# parser main function
VPARSER_FUNC = {
    'define':      _vparse_define,
    'module':      _vparse_module,
    'parameter':   _vparse_parameter,
    'localparam':  _vparse_parameter,
    'input':       _vparse_net,
    'output':      _vparse_net,
    'inout':       _vparse_net,
    'reg':         _vparse_net,
    'wire':        _vparse_net,
    'assign':      _vparse_expression,
    'eq':          _vparse_expression,
    'ifdef':       _vparse_directive,
    'inst':        _vparse_inst
    }
VPARSER_FUNC_KINDS = VPARSER_FUNC.keys()

def _vstruct_analyze(vcontent, isfile=False, kinds=VPARSER_FUNC_KINDS):
    global DEBUG, VPARSER_FUNC
    vstruct = {
        'module': '', 'parameter': [], 'localparam': [],
        'input':  [], 'output':    [], 'inout':      [],
        'reg':    [], 'wire':      [], 'assign':     [],
        'define': [], 'eq':        [], 'var':        {},
        'inst':   [], 'ifdef':     [], # insertion position
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
    if isfile:
        with open(vcontent, 'r') as fh:
            vcontent = ''.join(fh.readlines())
    for mo in _regex_token.finditer(vcontent):
        if DEBUG: # debug mode
            print(mo.lastgroup, ':', mo.group())
        kind, value = mo.lastgroup, _regex_comment.sub('', mo.group()).strip()
        if kind in kinds:
            VPARSER_FUNC[kind](vstruct, kind, value)
        elif kind == 'keyword' and value == 'endmodule':
            break
    return vstruct

# ------------------------------------------------------------------



# TODO
def _Gen_Width(var, style='index'):
    msb, lsb = var['msb'], var['lsb']
    if style == 'index':
        return '' if not msb else '['+msb+':'+lsb+'] '
    if style == 'width':
        if not msb:
            return '1'
        if msb.isdigit() and lsb.isdigit():
            return str(int(msb)-int(lsb)+1)
    if style == 'val':
        if not msb:
            return "1'b0"
        if lsb.isdigit():
            if msb.isdigit():
                return str(int(msb)-int(lsb)+1)+"'d0"
            if lsb == '0':
                if msb.endswith('-1'):
                    return '{'+msb[:-2]+"{1'b0}}"
                return '{'+msb+"+1{1'b0}}"
        return '{'+msb+'-'+lsb+"+1{1'b0}}"
    return ''


if __name__ == '__main__':
    main()
