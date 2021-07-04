#!/bin/env python3

import os
import sys
import re
#import copy
import glob
#import json
import functools

# ---------------------------------------------------
# global varialbes
# ---------------------------------------------------
PATH = os.getcwd()
MAXLEN = 79
FLIST = []
INCDIR = []
DEFINE = {}
STYLE = {'arg': 1, 'inst': 1}
# argv expand
CMD = sys.argv[1] if len(sys.argv) > 1 else None
VFILE = sys.argv[2] if len(sys.argv) > 2 else None
EXTRA = sys.argv[3:] if len(sys.argv) > 3 else [None]


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
        'incdir':     HDLIncdir
        } # VFILE
    cmdVStruct = {
        'autoarg':    HDLAutoArg,
        'autoinst':   functools.partial(HDLAutoInst, template=EXTRA[0]),
        'autowire':   HDLAutoWire,
        'autoreg':    HDLAutoReg,
        'struct':     HDLVStruct,
        'undef':      HDLUndef,
        'fake':       HDLFake
        } # vstruct
    _check_argument(list(cmdVFile) + list(cmdVStruct)) # all allowed sub-cmd
    _initial_env() # initial INCDIR, FLIST and DEFINE
    if CMD in cmdVFile:
        content = cmdVFile[CMD](VFILE)
    elif CMD in cmdVStruct:
        vfile = _search_vfile(VFILE)
        if not vfile:
            _err_handle('err_vfile')
        with open(vfile, 'r') as fh:
            vcontent = ''.join(fh.readlines())
        content = cmdVStruct[CMD](_vstruct_analyze(vcontent))
    if isinstance(content, (list, set)):
        print('\n'.join(content))
    else:
        print(content)


def HDLVFile(vfile, searchAll=False):
    return _search_vfile(vfile, searchAll=searchAll)


# ---------------------------------------------------------------
# argument check
# ---------------------------------------------------------------
def _check_argument(subcmds):
    global CMD, VFILE
    err = 'err_arg' if not CMD else \
          'err_cmd' if CMD not in subcmds else \
          'err_arg' if not VFILE else 'None'
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
    inst_name, inst_struct = _AutoInst_template(vstruct['module'], template)
    comment = _AutoInst_comment(vstruct, inst_struct)
    parameter = _AutoInst_parameter(vstruct, inst_struct)
    port = _AutoInst_connect(vstruct, inst_struct)
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
def _AutoInst_template(module, template):
    if not template:
        return 'u_'+module, None
    if os.path.isfile(template):
        with open(template, 'r') as fh:
            vcontent = ''.join(fh.readlines())
    else:
        vcontent = template
    vstruct = _vstruct_analyze(vcontent)
    for inst in vstruct['inst']:
        if vstruct['var'][inst]['module'] == module:
            return inst, vstruct['var'][inst]
    return 'u_'+module, None


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
    comment += ['*/']
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
            val = inst_port.get(var, var)
            content += [strFormat.format(var, val)]
    content[-1] = content[-1][:-1]
    return content


# Automatically generate undefined instance output/inout port
def HDLAutoWire(vstruct):
    _initial_define(os.getenv('VGEN_DEFINE', ''))
    content = ['/*AUTOWIRE*/', '// Automatically generate undefined instances output/inout port']
    wire_exists = vstruct['output'] + vstruct['inout'] + vstruct['wire']
    input_net = []
    # format wire declaration of instants output,inout port
    for inst in vstruct['inst']:
        subcontent = []
        length, nets = _AutoWire_connect(vstruct['var'][inst])
        if not nets:
            continue
        strFormat = 'wire {:'+str(length)+'} {};'
        for net, val in nets.items():
            if net in wire_exists:
                continue
            elif val['kind'] == 'input':
                input_net.append((net, val['width']))
                continue
            wire_exists.append(net)
            subcontent.append(strFormat.format(val['width'], net))
        if subcontent:
            content += ['// form instant of '+inst] + subcontent
    content += ['// End of automatics']
    # undefined net of instants input port
    input_content = []
    wire_exists += vstruct['input'] + vstruct['reg']
    for net, width in input_net:
        if net in wire_exists:
            continue
        input_content.append('reg '+width+' '+net+';')
    input_comment = ['// undefined net for instants input port'] if input_content else []
    return input_comment + input_content + content


# get connect signal width from source file
_regex_identifier = re.compile(r'[A-Za-z_][A-Za-z_0-9]*')
def _AutoWire_connect(inst):
    connect, length = {}, 1
    inst_vfile = _search_vfile(inst['module'], fullmatch=True)
    if not inst_vfile:
        return None, None
    with open(inst_vfile, 'r') as fh:
        vcontent = ''.join(fh.readlines())
    inst_vstruct = _vstruct_analyze(vcontent)
    for port, net in inst['port'].items():
        net = _regex_identifier.match(net)
        port = inst_vstruct['var'].get(port, {'kind': ''})
        if not net or port['kind'] not in ('input', 'output', 'inout'):
            continue
        net = net.group()
        port['msb'] = _AutoWire_paramexpr(port['msb'], inst, inst_vstruct)
        port['lsb'] = _AutoWire_paramexpr(port['lsb'], inst, inst_vstruct)
        if port['msb'] and port['lsb']:
            width = '[' + port['msb'] + ':' + port['lsb'] + ']'
        else:
            width = ''
        connect[net] = {'kind': port['kind'], 'width': width}
        length = max(length, len(width))
    return length, connect


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
        expr = eval(expr)
        return str(expr) if expr != 0 else ''
    except (NameError, TypeError):
        return expr



def HDLAutoReg(vstruct):
    content = ['/*AUTOREG*/',
               '// Automatically generate register for undeclared output']
    length = vstruct['len']['output']
    length = length['msb'] + length['lsb'] + 3
    strFormat = 'reg  {:'+str(length)+'} {};'
    for output in vstruct['output']:
        if output in vstruct['eq'] and output not in vstruct['reg']:
            width = _Gen_Width(vstruct['var'][output], style='index')
            content += [strFormat.format(width, output)]
    content += ['// End of automatics']
    return content




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
    if vfile.endswith('.f') and os.path.isfile(vfile):
        return _flist2incdir(vfile)
    vfile = _search_vfile(vfile)
    if not vfile:
        return []
    return _module2incdir(vfile)


# parsing module file and get flist
def HDLFlist(vfile):
    if vfile.endswith('.f') and os.path.isfile(vfile):
        return _flist2flist(vfile)
    vfile = _search_vfile(vfile)
    if not vfile:
        return []
    return _module2flist(vfile)


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
#    print(json.dumps(vstruct, indent=4))



# ---------------------------------------------------------------
#    verilog file search .v .sv, search order: flist, incdir, path
# ---------------------------------------------------------------
# initial global var: INCDIR, FLIST, DEFINE
# using environment default: VGEN_INCDIR, VGEN_FLIST, VGEN_DEFINES
def _initial_env(incdirs=os.getenv('VGEN_INCDIR', ''), flists=os.getenv('VGEN_FLIST', ''),
                 defines=os.getenv('VGEN_DEFINE', ''), target=('incdir', 'flist')):
    if 'incdir' in target:
        _initial_incdir(incdirs)
    if 'flist' in target:
        _initial_flist(flists)
    if 'define' in target:
        _initial_define(defines)


def _initial_incdir(incdirs):
    global INCDIR
    for incdir in incdirs.split(':'):
        if not os.path.isfile(incdir):
            continue
        with open(incdir, 'r') as fh:
            for line in fh:
                line = line.strip()
                if line.startswith('+incdir+'):
                    line = line[8:]
                if os.path.isdir(line):
                    INCDIR.append(line)


def _initial_flist(flists):
    global FLIST
    for flist in flists.split(':'):
        if not os.path.isfile(flist):
            continue
        with open(flist, 'r') as fh:
            for line in fh:
                line = line.strip()
                if os.path.isfile(line) and (line.endswith('.v') or line.endswith('.sv')):
                    FLIST.append(line)


def _initial_define(defines):
    global DEFINE
    for define in defines.split(':'):
        if not os.path.isfile(define):
            continue
        with open(define, 'r') as fh:
            for line in fh:
                line = line.strip().split()
                if len(line) < 2:
                    continue
                if line[0] == '`define':
                    val = ''.join(line[2:]) if len(line) > 2 else ''
                    DEFINE[line[1]] = val
                elif line[0] == '`undef' and line[1] in DEFINE:
                    del DEFINE[line[1]]



# search verilog file (.v, .sv) base on flist, incdir, path
def _search_vfile(vfile, searchAll=False, fullmatch=False):
    global FLIST
    if os.path.isfile(vfile) and (vfile.endswith('.v') or vfile.endswith('.sv')):
        return vfile
    matchDict = {'most': '~!@#$%^&*'*100, 'full': None, 'all': []}
    # search file in filelist first
    FLIST = [subfile for subfile in FLIST if os.path.isfile(subfile)]  # Keep existing files only
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


# search file in filelist, the results are saved in the 'matchDict'
# return True if fullmatch else False
def _search_flist(vfile, matchDict, searchAll):
    global FLIST, INCDIR
    for subfile in FLIST:
        basename = os.path.basename(subfile)
        dirname = os.path.dirname(subfile)
        if dirname not in INCDIR: # update incdir
            INCDIR.append(dirname)
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
                FLIST.append(subfile) # update filelist
            basename = os.path.basename(subfile)
            if _search_judge(vfile, subfile, basename, matchDict, searchAll):
                return True
    return False


# search file in path, the results are saved in the 'matchDict'
# return True if fullmatch else False
def _search_path(vfile, matchDict, searchAll):
    global FLIST, INCDIR, PATH
    if isinstance(PATH, str):
        PATH = os.walk(PATH)
    while True:
        try:
            root, _, files = next(PATH)
        except StopIteration:
            break
        if root in INCDIR:
            continue
        for basename in files:
            if not basename.endswith('.v') and not basename.endswith('.sv'):
                continue
            subfile = os.path.join(root, basename)
            if subfile not in FLIST:
                FLIST.append(subfile) # update filelist
            if _search_judge(vfile, subfile, basename, matchDict, searchAll):
                return True
        INCDIR.append(root)
    return False


# Judge file match
def _search_judge(vfile, subfile, basename, matchDict, searchAll):
    if vfile in basename and subfile not in matchDict['all']:
        matchDict['all'].append(subfile)
    if not searchAll and basename in (vfile, vfile + '.v', vfile + '.sv'): # full match
        matchDict['full'] = subfile
        return True
    if len(subfile.replace(vfile, '')) < len(matchDict['most'].replace(vfile, '')): # most match
        matchDict['most'] = subfile
    return False


# ---------------------------------------------------------------
#    filelist/incdir relevent
# ---------------------------------------------------------------
# convert flist file to include file
def _flist2incdir(vfile):
    content = []
    with open(vfile, 'r') as fh:
        for line in fh:
            line = line.strip()
            if (line.endswith('constant.v') or line.endswith('define.v') or \
                    line.startswith('`define') or line.startswith('+incdir+')) and \
                    line not in content:
                content.append(line)
            elif line.endswith('.v') or line.endswith('.sv'):
                root = os.path.dirname(line)
                root = '+incdir+'+root
                if os.path.isdir(root[8:]) and root not in content:
                    content.append(root)
    return content


# Parsing module to filelist
def _module2flist(vfile):
    content = [vfile]
    with open(vfile, 'r') as fh:
        vcontent = ''.join(fh.readlines())
    vstruct = _vstruct_analyze(vcontent)
    module_exist = [vstruct['module']]
    module_search = [vstruct['var'][var]['module'] for var in vstruct['inst']]
    while module_search:
        module = module_search.pop()
        if module in module_exist:
            continue
        module_exist.append(module)
        vfile = _search_vfile(module, fullmatch=True)
        if not vfile:
            continue
        content.append(vfile)
        with open(vfile, 'r') as fh:
            vcontent = ''.join(fh.readlines())
        vstruct = _vstruct_analyze(vcontent)
        module_search += [vstruct['var'][var]['module'] for var in vstruct['inst']]
    return content


# Parsing module to incdir
def _module2incdir(vfile):
    return ['+incdir+'+os.path.dirname(line) for line in _module2flist(vfile)]


def _flist2flist(vfile):
    # for future
    return [vfile]

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
        'dir_ifdef':         r'`ifdef\s+\w+',
        'dir_ifndef':        r'`ifndef\s+\w+',
        'dir_elsif':         r'`elsif\s+\w+',
        'dir_else':          r'`else',
        'dir_endif':         r'`endif',
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
_regex_connect = re.compile(r'\.(\w+)\((.*?)\)')


# ----------------------------------------
# parse verilog code to vstruct 
# ----------------------------------------
def _vstruct_analyze(vcontent, dbg=False):
    vstruct = {
        'module': '', 'parameter': [], 'localparam': [],
        'input':  [], 'output':    [], 'inout':      [],
        'reg':    [], 'wire':      [], 'assign':     [],
        'define': [], 'eq':        [], 'var':        {},
        'inst':   [],
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
    parse_func = {
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
        'inst':        _vparse_inst
        }
    define = []
    for mo in _regex_token.finditer(vcontent):
        if dbg:
            print(mo.lastgroup, ':', mo.group())
        kind, value = mo.lastgroup, _regex_comment.sub('', mo.group()).strip()
        if kind in parse_func:
            parse_func[kind](vstruct, kind, value)
        elif kind.startswith('dir_'):
            _vparse_directives(define, kind, value)
        elif kind == 'keyword' and value == 'endmodule':
            break
    return vstruct


# get module name of verilog file
def _vparse_module(vstruct, kind, value):
    vstruct[kind] = value.split()[-1].strip()


def _vparse_directives(define, kind, value):
    value = value.strip()
    if kind in ('dir_ifdef', 'dir_ifndef'):
        define.append(value)
    elif kind in ('dir_elsif', 'dir_else') and define:
        define[-1] = value
    elif kind == 'dir_endif':
        define.pop()


# define parser: `define
def _vparse_define(vstruct, kind, value):
    define = value.strip().split()
    if len(define) < 2:
        return
    vstruct[kind].append(define[1])
    val = ''.join(define[2:]) if len(define) >= 3 else ''
    vstruct['var']['`'+define[1]] = {'kind': kind, 'val': val}



# param parser: parameter and localparam
def _vparse_parameter(vstruct, kind, value):
    value = value.strip()
    if value.endswith(')'): # #(parameter ...) may endswith ')'
        value = value[:-1]
    for var, val in _regex_expression.findall(value):
        val = val.replace(' ', '').strip()
        vstruct[kind].append(var)
        vstruct['var'][var] = {'kind': kind, 'val': val}
        vstruct['len'][kind] = {'var': max(len(var), vstruct['len'][kind]['var']),
                                'val': max(len(val), vstruct['len'][kind]['val'])}


# net parser: input ouput inout reg wire
_net_word_ignore = ('signed', 'scalared', 'vectored', 'supply0', 'supply1',
                    'strong0', 'strong1', 'pull0', 'pull1', 'weak0', 'weak1', 'small',
                    'medium', 'large', 'input', 'output', 'inout', 'reg', 'wire')
def _vparse_net(vstruct, kind, value):
    regtype = False  # used for output scene
    value = value.split('=', 1)[0].strip()  # consider: wire var = ...
    width = _regex_width.search(value)
    start = width.end() if width else 0
    value = value[start:]
    if width and ':' in width.group(1) and value[0] != ';':
        msb, lsb = width.group(1).split(':', 1)
    else:
        msb, lsb = '', ''
    memWidth = _regex_width.search(value) # consider memory type
    if memWidth:
        value = value[:memWidth.start()]
    for var in _regex_word.findall(value):
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
_regex_delay = re.compile(r'#\S+')
def _vparse_expression(vstruct, kind, value):
    value = value.split('=', 1)[0].strip()
    value = _regex_delay.sub('', value)      # remove delay
    value = _regex_width.sub('', value)      # remove width [...]
    for word in _regex_word.findall(value):  # consider {a,b,..} = ...
        if word not in vstruct[kind]:
            vstruct[kind].append(_regex_word.search(value.strip()).group())


# instant parser
_regex_inst_name = re.compile(r'(?<=\))\s*\w+\s*(?=\()')
def _vparse_inst(vstruct, kind, value):
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
    vstruct[kind].append(inst_name)
    vstruct['var'][inst_name] = {'kind': kind, 'module': module.group(),
                                 'parameter': {}, 'port': {}}
    for net0, net1 in _regex_connect.findall(value[:inst.end()]):
        vstruct['var'][inst_name]['parameter'][net0] = net1.replace(' ', '').strip()
    for net0, net1 in _regex_connect.findall(value[inst.end():]):
        vstruct['var'][inst_name]['port'][net0] = net1.replace(' ', '').strip()


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
