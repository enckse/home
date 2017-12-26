alias checksum='find -type f -exec sha512sum "{}" + | sort -k 2'
alias clip="xclip -selection 'clip-board'"
alias csv-processing="$HOME/.bin/modules/csv-stats/csvstats.sh"
alias nano="vim"
alias notes="vim notes"
alias pacman="sudo pacman"
alias reset-brightness="sudo tee /sys/class/backlight/intel_backlight/brightness <<< 2000"
alias ssid="sudo iwlist wlp3s0 scanning essid"
alias tree='tree -J | python -c "import sys, json; print(json.dumps(json.loads(sys.stdin.read()), indent=1, sort_keys=True, separators=(\",\", \":\")))"'
alias vimtext="touch /tmp/textmode && vim"
alias vi="vim"
alias weechat="rm -f /tmp/weechat.ready && weechat"
alias xhost-local="xhost +local:"
machinectl() {
    local did=0
    if [ ! -z "$1" ]; then
        if [[ "$1" == "shell" ]]; then
            sudo /usr/bin/machinectl shell $USER@$2
            did=1
        fi
    fi
    if [ $did -eq 0 ]; then
        sudo /usr/bin/machinectl $@
    fi
}
