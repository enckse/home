package main

import (
	"fmt"
	"github.com/mdirkse/i3ipc"
	"strings"
	"time"
)
func main() {
	ipcsocket, err := i3ipc.GetIPCSocket()
	if err != nil {
		panic("unable to open socket")
	}
	for {
		time.Sleep(1 * time.Second)
		tree, err := ipcsocket.GetTree()
		if err != nil {
			continue
		}
		workspaces := tree.Workspaces()
		for _, w := range workspaces {
			names := uncurl(w.Nodes)
			text := ""
			if len(names) > 0 {
				text = strings.Join(names, ",")
			}
			ids := strings.Split(w.Name, ":")
			text = fmt.Sprintf("%s:%s\n", ids[0], text)
			cmd := fmt.Sprintf("rename workspace \"%s\" to \"%s\"", w.Name, text)
			ipcsocket.Command(cmd)
		}
	}
}

func uncurl(nodes []i3ipc.I3Node) []string {
	var result []string
	if len (nodes) > 0 {
		for _, n := range nodes {
			name := n.Window_Properties.Class
			if len(name) > 0 {
				named := strings.Split(strings.ToLower(name), " ")
				result = append(result, named[0])
			}
			for _, r := range uncurl(n.Nodes) {
				result = append(result, r)
			}
		}
	}
	return result
}
