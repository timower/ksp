@lazyglobal off.
run lib.ks.

clear_screen().

local is_sol is Target:Body <> Ship:Body.

local r_target is Target:Obt:SemiMajorAxis.
local r_ship is Ship:Obt:SemiMajorAxis.

if is_sol {
    set r_ship to Ship:Body:Obt:SemiMajorAxis.
}

local t_transfer is constant:PI * sqrt(((r_target + r_ship) ^ 3) / (8 * Target:Body:MU)).
lg("transfer time: " + t_transfer).

local delta_v is sqrt(Target:Body:MU / r_ship) * (sqrt((2*r_target) / (r_ship + r_target)) - 1).
lg("dv: " + delta_v).

local w_target is sqrt(Target:Body:MU / (r_target ^ 3)).
local phi is 180 - w_target * t_transfer * constant:RadToDeg.
if phi < -180 {
    set phi to phi + 360.
}
lg("phi: " + phi).

local lock ship_pos to Ship:Position - Ship:Body:Position.
if is_sol {
    lock ship_pos to Ship:Body:Position - Target:Body:Position.
}
local lock target_pos to Target:Position - Target:Body:Position.

local s_normal is vcrs(Ship:Velocity:Orbit, ship_pos).
if is_sol {
    set s_normal to vcrs(Ship:Body:Velocity:Orbit - Sun:Velocity:Orbit, ship_pos).
}
local lock s_t_cross to vcrs(ship_pos, target_pos).

local lock sign_a to -sign(vdot(s_normal, s_t_cross)).

local lock tetha to sign_a * vang(ship_pos, target_pos).

lg("tetha: " + tetha).

local w_ship is sqrt(Target:Body:MU / (r_ship ^ 3)).

local diff is tetha - phi.
if r_target < r_ship {
    set diff to -diff.
}
if diff < 0 {
    set diff to diff + 360.
}

lg("difference in angle: " + diff).

local dteta is abs(w_target - w_ship) * constant:RadToDeg.

lg("dteta: " + dteta).

local t_diff is diff / dteta.

lg("time: " + t_diff).

local nd is Node(Time:Seconds + t_diff, 0, 0, delta_v).

ADD nd.

lg("done").
