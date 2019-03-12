#!/usr/bin/python
"""Common environment processing."""
import os
from subprocess import Popen, PIPE, call

GMAIL_ACCOUNT = "gmail"
FMAIL_ACCOUNT = "fastmail"


def get_output_or_error(command, env=None):
    """Get output or error from command."""
    p = Popen(command, stdout=PIPE, env=env)
    output, err = p.communicate()
    if err:
        return (None, err)
    if p.returncode != 0:
        return (None, Exception("unable to read stdout"))
    return (output, None)


def notify(message, duration):
    """Notification creation."""
    call(["notify-send", "-t", str(duration * 1000), message])


def is_online():
    """Report if online (or not)."""
    return call(["wsw", "--mode", "online"]) == 0


class Object(object):
    """Environment object."""

    pass


def _text_color(color):
    """Output terminal text in a color."""
    import sys
    sys.stdout.write("\033[{}m".format(color))


def red_text():
    """Make red text in terminal."""
    _text_color("1;31")


def normal_text():
    """Reset text in terminal."""
    _text_color("0")


def touch(file_name):
    """Create an empty file."""
    open(file_name, 'a').close()


def read_env():
    """Read the environment for my user."""
    home_env = os.environ["HOME"]
    home = os.path.join(home_env, ".config", "home", "common")
    output, err = get_output_or_error(["bash",
                                       "-c",
                                       "source " + home + "; _exports"])
    if err is not None:
        raise err
    lines = [x for x in output.decode("utf-8").split("\n") if x]
    result = Object()
    result.HOME = home_env
    for l in lines:
        parts = l.split("=")
        key = parts[0]
        value = "=".join(parts[1:])
        setattr(result, key, value)
    return result