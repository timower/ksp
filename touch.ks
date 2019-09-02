@lazyglobal off.
run lib.ks.

parameter kill is False.

clear_screen().

local Final_Dist is 50.

local Approach_Vel  is List(100,   50,   25,   10,   5,   3,   0).
local Approach_Dist is List(10000, 5000, 2500, 1000, 500, 100, 0).

lock VelDiff to Target:Velocity:Orbit - Ship:Velocity:Orbit.
lock TargetApo to -VelDiff.

function kill_target_vel {
    parameter end_vel is 0.5.
    parameter use_steer_comp is True.

    local lock reflDir to VelDiff:Normalized.
    local lock reflVec to -Target:Position:Normalized.
    lock burnDir to 2 * reflDir * (reflVec * reflDir) - reflVec.
    if not use_steer_comp {
        lock burnDir to VelDiff.
    }
    lg("killing target velocity").
    steer_to({ return burnDir. }).

    local lock rem_v to VelDiff:Mag - end_vel.
    local last_rem is rem_v + 1.

    lock THROTTLE to 1.0.
    until rem_v < 0.1 {
        if rem_v < 20 {
            lock THROTTLE to 0.25.
        }
        if rem_v < 2 {
            lock THROTTLE to (abs(end_vel - VelDiff:Mag) / 2) * 0.25.
        }

        if rem_v > last_rem {
            break.
        }
        set last_rem to rem_v.

        display("Vel Diff: " + round(VelDiff:Mag, 2)).
        check_staging().
        wait 0.
    }
    lock THROTTLE to 0.
}

function go_to_target {
    parameter vel.
    lg("moving to target").
    steer_to( { return Target:Direction. } ).
    lock THROTTLE to 1.0.

    until VelDiff:Mag >= vel {
        if vel - VelDiff:Mag < 20 {
            lock THROTTLE to 0.25.
        }
        display("Vel Diff: " + round(VelDiff:Mag, 2)).
        check_staging().
        wait 0.
    }

    lock THROTTLE to 0.
    lock STEERING to VelDiff.
}

local lock d to Target:Distance.

if kill {
    kill_target_vel(0.5, False).
}

local idx is 0.

local lock next_vel to Approach_Vel[idx].
local lock next_dist to Approach_Dist[idx].

until d > next_dist {
    set idx to idx + 1.
}

local cur_vel is Approach_Vel[max(idx-1, 0)].

local lock drift to vang(TargetApo, Target:Direction:Vector).

until d < Final_Dist {
    if d < next_dist {
        set cur_vel to next_vel.
        set idx to min(idx + 1, Approach_Vel:Length - 1).
    }
    if drift > 30 {
        kill_target_vel(0.1, False).
        go_to_target(cur_vel).
    }
    if VelDiff:Mag < cur_vel - 3 {
        go_to_target(cur_vel).
    }
    if VelDiff:Mag > cur_vel + 1 {
        kill_target_vel(cur_vel).
    }
    display("target_vel: " + round(cur_vel, 2),
            "drift: " + round(drift, 2)).
    wait 0.01.
}
kill_target_vel(0.1, False).

lock THROTTLE to 0.0.


