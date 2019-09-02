@lazyglobal off.
run lib.ks.

clear_screen().

function getShipPos {
    parameter t is 0.
    if time = 0 {
        return Ship:Position - Ship:Body:Position.
    } else {
        return PositionAt(Ship, Time:Seconds + t) - Ship:Body:Position.
    }
}

function toLocalPos {
    parameter p.
    return p + Ship:Body:Position.
}

function timeToImpact {
    parameter lastImpactPos.
    if Ship:Orbit:Periapsis > 0 {
        return -1.
    } else {
        local ecc is Ship:Orbit:Eccentricity.
        local sma is Ship:Orbit:SemiMajorAxis.
        local impactRad is Ship:Body:GeoPositionOf(toLocalPos(lastImpactPos)):TerrainHeight 
                            + Ship:Body:Radius.

        local currentRad is Ship:Altitude + Ship:Body:Radius.
        local impactTAcs is ((sma * (1-ecc^2) / impactRad) - 1) / ecc.
        local currentTAcs is ((sma * (1-ecc^2) / currentRad) - 1) / ecc.

        local impactEA is arccos((ecc + impactTAcs) / (1 + ecc*impactTAcs)).
        local currentEA is arccos(clamp((ecc + currentTAcs) / (1 + ecc * currentTAcs), -1, 1)).

        local impactMA is impactEA - Constant:RadToDeg * ecc * sin(impactEA).
        local currentMA is currentEA - Constant:RadToDeg * ecc * sin(currentEA).
    
        local n is 360 / Ship:Orbit:Period.
        return (currentMA - impactMA) / n.
    }

}

// suicide burn for straight down
// must be falling already

local cur_throttle is 1.0.

local G_body is Ship:Body:MU / (Ship:Body:Radius ^ 2).

local lock A_aprox to Ship:MaxThrust / Ship:Mass.

lg("G body: " + G_body).
lg("A aprox: " + A_aprox).

local lock A_total to A_aprox - G_body.
lg("A total: " + A_total).

lock STEERING to Ship:SRFRetroGrade.

local partlist is List().

list PARTS in partlist.

local lowest is 0.

for part in partlist {
    local dist is part:Position * Ship:Facing:Vector.
    if dist < lowest {
        set lowest to dist.
    }
}

lg("lowest part: " + lowest).


local lock V to Ship:Velocity:Surface:Mag.

local lock T_zero to V / A_total.
local lock D_zero to V * T_zero - A_total / 2 * T_zero * T_zero.

local impactPos is getShipPos(T_zero).
local T_impact is timeToImpact(impactPos).

local lock X to (Alt:Radar + (getShipPos(0) - impactPos):Mag) / 2.

until X <= D_zero {
    set impactPos to 0.5 * (getShipPos(T_impact) + impactPos).
    set T_impact to timeToImpact(impactPos).

    display("X: " + round(X, 2) + " Alt: " + round(Alt:Radar, 2),
            "D: " + round(D_zero, 2),
            "T-I: " + round(T_impact, 2) + " T-0: " + round(T_zero, 2)).
    wait 0.
}

lg("burning").

lock THROTTLE to cur_throttle.

local pidtest is PIDloop(1.5, 0.0, 0.0, 0.0, 1.0).

local T_lol is 2.0 / G_body.

until V < 2.0 {
    set impactPos to (getShipPos(T_impact) + impactPos) * 0.5.
    set T_impact to timeToImpact(impactPos).

    set cur_throttle to pidtest:update(Time:Seconds, T_impact - T_zero - T_lol).
    display("T-0: " + round(T_zero, 2),
            "T-I: " + round(T_impact, 2)).
    wait 0.
}

lock STEERING to UP.
lock THROTTLE to 0.

wait 0.5.

unlock STEERING.
SAS ON.

lg("done").
