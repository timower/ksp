@lazyglobal off.
SAS OFF.

global G is 9.80665.

global DIVIDER is "".
FROM {local x is Terminal:Width.} UNTIL x = 0 STEP {set x to x-1.} DO {
  set DIVIDER to DIVIDER + "-".
}

function clamp {
    parameter x, mi, ma.
    if x > ma {
        return ma.
    } else if x < mi {
        return mi.
    } else {
        return x.
    }
}


function clear_line {
    parameter line is 0.
    print " ":PadRight(Terminal:Width) at (0, line).
}

function clear_screen {
    clearscreen.
    print " ":PadRight(Terminal:Width).
    print " ":PadRight(Terminal:Width).
    print " ":PadRight(Terminal:Width).
    print DIVIDER.
}

function display {
    parameter a.
    parameter b is " ".
    parameter c is " ".
    print a:PadRight(Terminal:Width) at (0, 0).
    print b:PadRight(Terminal:Width) at (0, 1).
    print c:PadRight(Terminal:Width) at (0, 2).
    print DIVIDER at (0, 3).

}

function lg {
    parameter x.
    print "> " + x.
}

function sign {
    parameter x.
    if x < 0 {
        return -1.
    } else {
        return 1.
    }
}

// calculates the isp of all active engines.
function calc_isp {
    local engs is List().
    list Engines in engs.

    local sum_thrusts is 0.
    local sum_denom is 0.

    for eng in engs {
        if eng:Ignition {
            set sum_thrusts to sum_thrusts + eng:MaxThrust.
            set sum_denom to sum_denom + eng:MaxThrust / eng:ISP.
        }
    }
    if sum_denom = 0 {
        return 0.
    } else {
        return sum_thrusts / sum_denom.
    }
}

function calc_burn_time {
    parameter delta_v.
    parameter thrtl is 1.0.
    parameter mass is -1.

    if mass = -1 {
        set mass to Ship:Mass * 1000.
    }

    local I is calc_isp() * G.
    local M is mass.
    local T is thrtl * Ship:MaxThrust * 1000.
    local F is T / I.
    
    return (M / F) * (1 - constant:E ^ (-delta_v / I)).
}

function calc_mass_expended {
    parameter burn_time.
    parameter thrtl is 1.0.

    local I is calc_isp() * G.
    local T is thrtl * Ship:MaxThrust * 1000.
    local F is T / I.
    
    return F * burn_time.
}

function calc_dist_burn {
    parameter t_burn.
    local I is calc_isp() * G.
    local F is Ship:MaxThrust * 1000 / I.
    local M_prop is calc_mass_expended(t_burn).
    local M_total is Ship:Mass * 1000.
    local M is M_total - M_prop.
    return (I / F) * (M_prop - M * ln(M_total / M)).
}
// function exec_burn {
//     parameter delta_v.
//     parameter thrtl is 1.0.
// 
//     local mass_start is Ship:Mass * 1000.
//     local burn_time is calc_burn_time(delta_v, thrtl, mass_start).
// 
//     local isp is calc_isp(). 
// 
//     local start_t is Time:Seconds.
//     lock THROTTLE to thrtl.
//     wait 0.
//     local lock dtime to burn_time - (Time:Seconds - start_t).
//     until dtime < 0.0 {
//         display("Burning until T-" + round(dtime, 2) + "s").
// 
//         if need_staging() {
//             lg("staging").
//             local mass_end is Ship:Mass * 1000.
//             local delta_v_passed is isp * G * ln(mass_start / mass_end).
//             local delta_v_remaining is delta_v - delta_v_passed.
//             until not need_staging() {
//                 Stage.
//                 wait 0.1.
//             }
//             set delta_v to delta_v_remaining.
//             set isp to calc_isp().
//             set mass_start to Ship:Mass * 1000.
//             set start_t to Time:Seconds.
//             set burn_time to calc_burn_time(delta_v, thrtl).
//             lg("done, deltaV: " + delta_v + " burn time: " + burn_time).
//         }
// 
//         wait 0.
//     }
//     lock THROTTLE to 0.0.
// }

global Engine_List is List().

function check_staging {
    if Engine_List:Length = 0 {
        list ENGINES in Engine_List.
    }

    for engine in Engine_List {
        if engine:FlameOut {
            STAGE.
            lg("staged").
            until Stage:Ready {
                wait 0.
            }
            list ENGINES in Engine_List.
            return True.
        }
    }
    return False.
}

function steer_to {
    parameter dir.
    lg("steering").
    local is_vec is dir():typename = "vector".
    local vec is dir.
    if not is_vec {
        set vec to { return dir():Vector. }.
    }
    lock STEERING to dir().
    local lock diff to vang(vec(),  Ship:Facing:Vector).
    until diff < 0.75 {
        display("angle diff: " + round(diff, 2)).   
        wait 0.
    }
    clear_line().
    lg("done").
}

function wait_for {
    parameter time_f.
    
    until time_f() <= 0 {
        display("ETA: " + round(time_f(), 1)).
        wait 0.01.
    }
    clear_line().
}
// function exec_manoeuvre {
//     parameter delta_v, direction, start_cond.
// 
//     parameter last_throttle is 0.5.
//     parameter last_dv is 100.
// 
//     local first_dv is max(delta_v - last_dv, 0).
//     if first_dv = 0 {
//         set last_dv to delta_v.
//     }
// 
//     local first_burn_time is calc_burn_time(first_dv).
//     local expended_mass is calc_mass_expended(first_burn_time).
//     local remaining_mass is Ship:Mass * 1000 - expended_mass.
// 
//     local last_burn_time is calc_burn_time(last_dv, last_throttle, remaining_mass).
// 
//     local total_burn_time is first_burn_time + last_burn_time.
// 
//     //clear_screen().
//     lg("will execute burn for " + round(first_burn_time, 1) + "s and: " + round(last_burn_time, 1) + "s").
//     lg("turning..").
//     steer_to(direction).
//     lg("waiting for start condition").
// 
//     local start is start_cond(total_burn_time).
// 
//     until start {
//         set start to start_cond(total_burn_time).
//         wait 0.
//     }
// 
//     lg("starting, fast").
//     exec_burn(first_dv).
//     lg("slowing").
//     exec_burn(last_dv, last_throttle).
//     lg("DONE").
// }

function exec_node {
    parameter warp is False.
    local nd is NextNode.

    local lock dv to nd:DeltaV:Mag.
    local lock dir to nd:DeltaV.

    steer_to({ return dir. }).

    local burn_time_est is calc_burn_time(dv).
    
    if warp { 
        Kuniverse:TimeWarp:WarpTo(Time:Seconds + nd:eta - burn_time_est / 2 - 10).
    }
    wait_for({ return nd:eta - burn_time_est / 2. }).

    local myThrottle is 1.0.
    lock THROTTLE to myThrottle.

    local last_dv  is dv + 5.

    until dv < 0.1 {
        if dv < 50 {
            set myThrottle to dv / 50.
        }
        if dv > last_dv {
            break.
        }
        set last_dv to dv + 5.

        display("burning, dv remaining: " + round(dv, 2)).

        check_staging().

        wait 0.
    }
    lock THROTTLE to 0.
    remove nd.
    lg("done").
    lock THROTTLE to 0.0.
    unlock THROTTLE.
    unlock STEERING.
}

