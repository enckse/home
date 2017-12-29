#!/usr/bin/python
"""
handles processing and naming i3 workspaces based on content
"""

import subprocess 
import os
import signal
import time
import json
import hashlib
from subprocess import check_output

window_cache = {}
devnull = open(os.devnull, 'w')

def _is_active():
    for proc in ["weechat"]:
        pid = get_pid(proc)
        if pid < 0:
            continue
        if not os.path.exists("/tmp/" + proc + ".ready"):
            continue
        os.kill(pid, signal.SIGUSR2)

def get_pid(name):
    """Get pid."""
    try:
        pid = check_output(["pidof", name]).decode("utf-8").strip()
        val = int(pid)
        return val
    except:
        return -1

def uncurl(obj):
    """uncurl nest nodes down."""
    children = []
    for node in obj["nodes"]:
        for opened in uncurl(node):
            children.append(opened)
        children.append(node)
    return children



def on_change(hashed, debug):
    """on interested changes, call this."""
    try:
        tree = check_output(["i3-msg", "-t", "get_tree"])
        m = hashlib.md5()
        m.update(tree)
        cur = m.digest()
        if cur == hashed:
            if debug:
                print("no change")
            return cur
        j = json.loads(tree)
        workspaces = _get_workspaces(j)
        _rename_workspaces(workspaces)
        _is_active()
        return cur
    except Exception as e:
        if debug:
            print(e)
        return hashed

def _get_workspaces(j):
    """Get workspaces."""
    matched = {}
    for node in uncurl(j):
        if "num" in node and "name" in node:
            n = node["num"]
            name = node["name"]
            if n and n >= 1:
                children = []
                for c in uncurl(node):
                    if "window_properties" in c:
                        props = c["window_properties"]
                        if "class" in props:
                            classed = props["class"]
                            children.append(classed)
                matched[n] = (name, children)
    return matched

def _rename_workspaces(workspaces):
    """rename a workspace."""
    for k in workspaces:
        vals = workspaces[k]
        if len(vals[1]) == 0:
            continue
        named = ",".join([x[0:20].lower() for x in vals[1]])
        named = str(k) + ":" + named
        subprocess.call(["i3-msg",
                         "rename workspace \"{}\" to \"{}\"".format(vals[0], named)],
                         stdout=devnull,
                         stderr=subprocess.STDOUT)

def main():
    """Main entry."""
    last_hash = None
    while True:
        last_hash = on_change(last_hash, False)
        time.sleep(1)


if __name__ == "__main__":
    main()
