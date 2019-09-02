function do_mission {
    if not HasTarget {
        print "need target".
        return.
    }

    run orbiter.
    run nkis.
    run node(true).

    wait_for({ return Eta:Apoapsis - 20. }).

    run touch(true).

    local ports is Target:DockingPorts.
    local minPort is False.

    for port in ports {
        if port:State = "Ready" and (minPort = False or port:Position:Mag < minPort:Position:Mag) {
            set minPort to port.
        }
    }

    if minPort <> False {
        set Target to minPort.
        run dock.
    }
}

do_mission().
