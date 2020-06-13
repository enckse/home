#!/usr/bin/python3
import configparser
import os
import tempfile
import subprocess

def _chunk(section, key):
    if key not in section:
        return []
    parts = section[key]
    components = []
    for p in parts.split(" "):
        for n in p.split("\n"):
            components.append(n.strip())
    return components

def _stringify(command, objects, is_install=False, no_dest=False, system=True):
    if len(objects) == 0:
        return []
    results = []
    for o in objects:
        if o == "":
            continue
        dest = "$(DESTDIR)/"
        if no_dest:
            dest = ""
        if is_install and system:
            d = os.path.dirname(o)
            results.append("install -d {}".format(dest + d))
        destfile = dest + o
        if not system:
            destfile = dest + os.path.basename(o)
        obj = []
        if is_install:
            obj += [o]
        obj += [destfile]
        results.append(" ".join(command + obj))
    return ["\t{}".format(x) for x in results]

def main():
    config_file = "local.pkg"
    if not os.path.exists(config_file):
        return
    cfg = configparser.ConfigParser()
    with open(config_file, 'r') as f:
        cfg.read_file(f)
    options = []
    for o in os.listdir("."):
        if o.endswith(".pkg.tar.xz"):
            options += [o]
    if len(options) == 0:
        print("no source xz found")
        return
    choice = list(reversed(sorted(options)))[0]
    with tempfile.TemporaryDirectory(prefix="localpkg_") as td:
        subprocess.call(["tar", "xf", choice, "-C", td])
        for s in cfg.sections():
            print('building: {}'.format(s))
            lines = []
            section = cfg[s]
            syspkg = True
            if "local_package" in section:
                syspkg = not bool(section["local_package"])
            needs = _chunk(section, "needs")
            i644 = _chunk(section, "install_644")
            i755 = _chunk(section, "install_755")
            rem = _chunk(section, "remove")
            cwd = os.getcwd()
            tar_name = "{}.tar.gz".format(s)
            archive = os.path.join(cwd, tar_name)
            if os.path.exists(archive):
                os.remove(archive)
            needs = _stringify(["test", "-x"], [os.path.join("/usr/bin/", x) for x in needs], no_dest=True)
            rem = _stringify(["rm", "-f"], rem + i644 + i755, system=syspkg)
            install = _stringify(["install", "-Dm644"], i644, is_install=True, system=syspkg)
            install += _stringify(["install", "-Dm755"], i755, is_install=True, system=syspkg)
            d = [("needs", needs), ("remove", rem), ("install", install)]
            d = [x for x in d if len(x[1]) > 0]
            has_needs = d[0][0] == "needs"
            with open(os.path.join(td, "Makefile"), 'w') as f:
                destdir = ""
                if not syspkg:
                    destdir = "/usr/local/bin"
                f.write("DESTDIR={}\n\n".format(destdir))
                f.write("all: {}\n\n".format(" ".join(x[0] for x in d)))
                for obj in d:
                    dep = ""
                    if obj[0] == "install" and has_needs:
                        dep = " needs"
                    f.write("{}:{}\n".format(obj[0], dep))
                    for item in obj[1]:
                        f.write("{}\n".format(item))
                    f.write("\n")
            if os.path.exists(archive):
                os.remove(archive)
            subprocess.call(["tar", "-czf", archive, "."], cwd=td)
            version = "-".join(choice.replace(s, "").split("-")[1:3])
            installer_name = s + "." + version + ".tar.gz"
            installer = os.path.join(cwd, installer_name)
            rms = "rm {}\n".format(" ".join([tar_name, "configure", "deploy"]))
            with open("configure", "w") as f:
                f.write("#!/bin/bash\n")
                f.write("if [ $UID -eq 0 ]; then\n")
                f.write("    echo 'do not run as root'\n")
                f.write("    {}".format(rms))
                f.write("    exit 1\n")
                f.write("fi\n")
                f.write("echo {}\n".format(s))
                f.write("tmpdir=$(mktemp -d)\n")
                f.write("tar xf {} -C $tmpdir\n".format(tar_name))
                f.write('read -p \'"install" or "remove"? \' target\n')
                f.write('if [[ "$target" != "remove" ]]; then\n')
                f.write('    if [[ "$target" != "install" ]]; then\n')
                f.write('        echo "invalid target"\n')
                f.write('        exit 1\n')
                f.write('    fi\n')
                f.write('fi\n')
                f.write('echo "$(date +%Y-%m-%d:%H:%M:%S) -> $target {}" >> $HOME/.localpkg.log\n'.format(installer))
                f.write(rms)
                f.write("cd $tmpdir && sudo make $target | tee -a $HOME/.localpkg.log\n")
            with open("deploy", "w") as f:
                f.write("#!/bin/bash\n")
                f.write("tar xf {}\n".format(tar_name))
                f.write("make install\n")
                f.write(rms)
            for fname in ["configure", "deploy"]:
                os.chmod(fname, 0o755)
            subprocess.call(["tar", "-czf", installer, "deploy", "configure", tar_name])
            os.remove(archive)
            os.remove('configure')
            os.remove("deploy")
            os.rename(installer, "/home/enck/store/managed/binaries/{}".format(installer_name))

if __name__ == "__main__":
    main()