@lazyglobal off.
run lib.ks.

clear_screen().

local lock target_vel to Ship:Velocity:Orbit - Target:Ship:Velocity:Orbit.
local lock target_dir to Target:Position.

local lock current_pos to -target_dir.
local lock final_pos to Target:Facing:Vector * target_dir:Mag.

local lock up_dir to vcrs(current_pos, final_pos).
local lock v_dir to vcrs(up_dir, current_pos):normalized.

steer_to({ 
    if HasTarget {
        return target_dir. 
    } else {
        return Ship:Facing.
    }
}).

RCS ON.

local approach_vel is 3.

local Kp is 3.0.

local Control is Ship:Control.

function do_control {
    parameter fore, top, star. 

    set fore to clamp(fore, -1, 1).
    set top to clamp(top, -1, 1).
    set star to clamp(star, -1, 1).


    set Control:Fore to fore.
    set Control:Top to top.
    set Control:StarBoard to star.

}

lg("aligning").

local lock cur_angle to vang(current_pos, final_pos).

until cur_angle < 5 {
    if cur_angle < 20 {
        set approach_vel to 3 * cur_angle / 20.
    }
    local err_vel is (approach_vel * v_dir) - target_vel.

    display("angle: " + round(cur_angle, 2),
            "error: " + round(err_vel:Mag, 2)).
    
    local fore is err_vel * Ship:Facing:ForeVector.
    local top is err_vel * Ship:Facing:TopVector.
    local star is err_vel * Ship:Facing:StarVector.
    do_control(Kp * fore, Kp * top, Kp * star).
    wait 0.
}

set approach_vel to 3.0.

lg("approaching").

until not HasTarget {
    display("Dist: " + Target:Position:Mag).
    if Target:Position:Mag < 2.0 {
        RCS OFF.
    }
    if Target:Position:Mag < 20 {
        set approach_vel to 1.0.
    }

    local fore is target_vel * Ship:Facing:ForeVector.
    local top is target_vel * Ship:Facing:TopVector.
    local star is target_vel * Ship:Facing:StarVector.
    do_control(approach_vel - fore, -top, -star).
    wait 0.
}

do_control(0, 0, 0).
RCS OFF.

lg("done").
