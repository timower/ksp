@lazyglobal off.
run lib.ks.

clear_screen().

global r_ship is Ship:Obt:SemiMajorAxis.

function calc_trans_time {
    parameter rad.
    return constant:PI * sqrt(((rad + r_ship) ^ 3) / (8 * Target:Body:MU)).
}

function get_target_rad {
    parameter t.
    return (PositionAt(Target, Time:Seconds + t) - Ship:Body:Position):Mag.
}

local t_target is calc_trans_time(get_target_rad(60)). // random in future

local r_target is get_target_rad(t_target).

local t_trans is calc_trans_time(r_target).

lg("t_target: " + t_target).
lg("r_target: " + r_target).
lg("t_trans: " +  t_trans).
