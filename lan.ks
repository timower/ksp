@lazyglobal off.
run lib.ks.

parameter warp is False.

clear_screen().

local targetNormal is vcrs(Target:Position - Body:Position, Target:Velocity:Orbit):Normalized.
local shipNormal is vcrs(Ship:Facing:Vector, Ship:Velocity:Orbit):Normalized.

local intersect is vcrs(shipNormal, targetNormal).

local angle is vang(Ship:Facing:Vector, intersect).

lg("angle to launch: " + round(angle, 2)).

local omega is 360 / Body:RotationPeriod.
local t_intersect is angle / omega.

lg("time to launch: " + round(t_intersect, 2)).

if warp {
    kuniverse:TimeWarp:WarpTo(Time:Seconds + t_intersect - 30).
}
