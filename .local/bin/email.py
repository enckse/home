#!/usr/bin/python3
import common
import sys
import os
import time
import datetime
import subprocess

_ACCOUNTS = [common.GMAIL_ACCOUNT, common.FMAIL_ACCOUNT]


def _countdirs(dirs, account, ind):
    """Count dir emails."""
    cnt = 0
    for d in dirs:
        cnt += len(os.listdir(d))
    if cnt > 0:
        print("{} {}({})".format(cnt, account, ind))


def _count(env):
    """Get unread counts."""
    for a in _ACCOUNTS:
        unread = []
        new = []
        acct = os.path.join(env.MAIL_DIR, a)
        for root, dirs, files in os.walk(acct):
            for d in dirs:
                rootd = os.path.join(root, d)
                if "Trash" in rootd:
                    continue
                if d == "cur":
                    if "Filtered" in rootd or "Spam" in rootd:
                        if "Filtered/Automated" not in rootd:
                            unread.append(rootd)
                elif d == "new":
                    new.append(rootd)
        _countdirs(new, a, "n")
        _countdirs(unread, a, "u")


def _run_logged(cmd, log_name):
    """Run a logged command."""
    mode = 'w'
    created = True
    failure = False
    log = log_name + ".log"
    if os.path.exists(log):
        mode = 'a'
        created = False
    with open(log, mode) as f:
        r = subprocess.call(cmd, stdout=f)
        failure = r != 0
    return (failure, created)


def _mbsync(env):
    """Run mbsync."""
    if subprocess.call(["pidof", "mbsync"]) == 0:
        print("mbsync already running")
        return
    for d in [env.INDEX_DIR, env.INDEX_CUR, env.INDEX_NEW]:
        if not os.path.exists(d):
            os.mkdir(d)
    dt = datetime.datetime.now().strftime("%Y-%m-%d-%H")
    log_file = os.path.join(env.USER_TMP, "mbsync.{}".format(dt))
    failed, created = _run_logged(["mbsync", "-aV"], log_file)
    if failed:
        common.notify("mbsync failure", 30)
    if created:
        _clean_index(env)
    _run_logged(["notmuch", "new"], log_file + ".index")


def _clean_index(env):
    for f in os.listdir(env.INDEX_CUR):
        fpath = os.path.join(env.INDEX_CUR, f)
        if os.path.islink(fpath):
            os.unlink(fpath)


def _imap(env):
    """Run imap sync."""
    if not common.is_online():
        return
    _mbsync(env)


def _client(env, account):
    """Connect an email client."""
    if account not in _ACCOUNTS:
        return
    trigger = os.path.join(env.USER_TMP, "mail.trigger")
    open(trigger, 'w').close()
    time.sleep(0.5)
    muttrc = os.path.join(env.HOME, ".mutt", "{}.muttrc".format(account))
    subprocess.call(["mutt", "-F", muttrc], cwd=env.XDG_DOWNLOAD_DIR)
    time.sleep(0.25)


def _search(env, terms):
    """Search terms."""
    out, err = common.get_output_or_error(["notmuch",
                                           "search",
                                           "--output=files"] + terms)
    if err is not None:
        print('search failed')
        return
    _clean_index(env)
    found = False
    for f in [x.strip() for x in out.decode("utf-8").split("\n")]:
        if not f:
            continue
        bname = os.path.basename(f)
        lname = os.path.join(env.INDEX_CUR, bname)
        os.symlink(f, lname)
        found = True
    if not found:
        print("nothing found...")


def main():
    """Program entry."""
    args = sys.argv
    env = common.read_env()
    env.INDEX_DIR = os.path.join(env.MAIL_DIR, "Indexed")
    env.INDEX_CUR = os.path.join(env.INDEX_DIR, "cur")
    env.INDEX_NEW = os.path.join(env.INDEX_DIR, "new")
    if len(args) <= 1:
        _imap(env)
        return
    commands = args[1:]
    cmd = commands[0]
    has_sub = False
    if len(commands) > 1:
        has_sub = True
        commands = commands[1:]
    if cmd == "client":
        if not has_sub:
            print("client required")
            return
        _client(env, commands[0])
    elif cmd == "search":
        if not has_sub:
            print("search term(s) required")
            return
        _search(env, commands)
    elif cmd == "connected":
        _connected(env)
    elif cmd == "count":
        _count(env)
    else:
        print("unknown command")


if __name__ == "__main__":
    main()
