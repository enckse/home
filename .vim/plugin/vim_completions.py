#!/usr/bin/python
import vim
import sys

# https://docs.python.org/3/library/stdtypes.html
ADDED_ATTRS = ["__" + x + "__" for x in ["dict",
                                         "class",
                                         "bases",
                                         "name",
                                         "qualname",
                                         "mro",
                                         "subclasses"]]

def get_selections(segment, inputs, reversing):
    before = []
    matched = None
    after = []
    print(segment)
    for ins in inputs:
        if matched is not None:
            after.append(ins)
        if segment.startswith(ins):
            matched = ins
        if not matched:
            before.append(ins)
    if reversing:
        result = after
    else:
        result = list(reversed(before))
    if matched is None:
        matched = ""
    return (result, matched)

try:
    built = dir(__builtins__)
    print(built)
    pos = vim.current.window.cursor
    if pos and pos[0] > 0 and pos[1] > 0:
        row = pos[0] - 1
        col = pos[1]
        cur = vim.current.buffer[row]
        ch = cur[col]
        reversing = vim.eval("a:direction") == "1"
        # test.__init__(test test)
        col_off = col + 1
        if ch == ".":
            dot_attr = set(dir(object) + ADDED_ATTRS)
            after = cur[col_off:]
            results = get_selections(after, dot_attr, reversing)
            remaining = results[0]
            if len(remaining) == 0:
                replacing = ""
            else:
                replacing = remaining[0]
            after_attr = results[1]
            new_cur = cur[0:col_off] + replacing + cur[col_off + len(after_attr):]
            vim.current.buffer[row] = new_cur
except Exception as e:
    print(str(e))
