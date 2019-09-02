@lazyglobal off.
run lib.ks.

clear_screen().

local LAUNCH_PATHS is List(
    List(3000, 8100, 15000, 21000, 28000, 34000, 41000),
    List(1200, 4400, 10000, 18000, 24000, 32000, 40000),
    List(700 , 3200, 8500 , 15000, 22000, 31000, 40000),
    List(200 , 1300, 4600 , 10000, 19000, 28000, 40000),
    List(200 , 600 , 3100 , 8200 , 19000, 28000),
    List(100 , 300 , 1400 , 5200 , 14000, 27000)
).

local LAUNCH_PITCH is List(
    85,
    75,
    60,
    45,
    30,
    15,
    0
).

// ----------- CONFIG ---------------

parameter ORBIT_ALT is 100000.
parameter LAUNCH_DIR is 90.

// ------------ END ----------------
lock Throttle to 0.0.

lg("Counting down:").
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    lg("..." + countdown).
    WAIT 1. // pauses the script here for 1 second.
}

STAGE.

wait 0.1.

local twr is Ship:MaxThrust / (Ship:Mass * 9.81).

local two_throt is clamp(2.0 / twr, 0.5, 1).

LOCK THROTTLE TO two_throt.   // 1.0 is the max, 0.0 is idle.

local LAUNCH_PATH is False.

if twr >= 1.0 and twr < 1.15 {
    set LAUNCH_PATH to LAUNCH_PATHS[0].
} else if twr >= 1.15 and twr < 1.25 {
    set LAUNCH_PATH to LAUNCH_PATHS[1].
} else if twr >= 1.25 and twr < 1.50 {
    set LAUNCH_PATH to LAUNCH_PATHS[2].
} else if twr >= 1.50 and twr < 1.70 {
    set LAUNCH_PATH to LAUNCH_PATHS[3].
} else if twr >= 1.70 and twr < 2.0  {
    set LAUNCH_PATH to LAUNCH_PATHS[4].
} else {
    set LAUNCH_PATH to LAUNCH_PATHS[5].
}

lg("twr: " + twr).

local MYSTEER is HEADING(LAUNCH_DIR, 90).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER

local cur_idx is 0.
local last_pitch is 90.
local last_height is 0.
local lock next_height to LAUNCH_PATH[cur_idx].
local lock next_pitch to LAUNCH_PITCH[cur_idx].


until Ship:APOAPSIS > ORBIT_ALT { //Remember, all altitudes will be in meters, not kilometers
    if ship:altitude > next_height and cur_idx < LAUNCH_PATH:Length {
        set last_pitch to next_pitch.
        set last_height to next_height.
        set cur_idx to min(cur_idx + 1, LAUNCH_PATH:Length - 1).
    }

    if check_staging() {
        lock THROTTLE to 1.0.
    }
    
    local height_diff is next_height - last_height.
    local pitch is 0.
    if height_diff > 0 {
        set pitch to ((ship:altitude - last_height) / (next_height - last_height)) * (next_pitch - last_pitch) + last_pitch.
    } else {
        set pitch to next_pitch.
    }

    set MYSTEER to Heading(LAUNCH_DIR, pitch).
    
    display("Pitch: " + round(pitch, 1),
            "Next Pitch: " + next_pitch + " at: " + next_height,
            "APO: " + ROUND(SHIP:APOAPSIS, 0)).

    WAIT 0.
}.

LOCK THROTTLE TO 0.

if Ship:Altitude < Body:ATM:Height {
    lock STEERING to Ship:Prograde.
    clear_screen().
    lg("below atmosphere, waiting").
    wait until Ship:Altitude >= Body:ATM:Height.
    lg("atm reached, burning toward prograde").
    lock STEERING to Heading(LAUNCH_DIR, 0).
    lock THROTTLE to 0.1.
    until Ship:Apoapsis >= ORBIT_ALT {
        display("Burning, apo: " + ROUND(SHIP:APOAPSIS, 0)).
        wait 0.
    }
    lock THROTTLE to 0.
}

clear_screen().
lg("apoapsis reached").

local ORBIT_RADIUS is Ship:Apoapsis + Body:Radius.

local ORBIT_VEL is SQRT(Body:MU / ORBIT_RADIUS).

// TODO: check with vis viva
local AP_VEL is SHIP:VELOCITY:ORBIT:MAG * (Body:Radius + SHIP:ALTITUDE) / (SHIP:APOAPSIS + Body:Radius).

local ap_dv is ORBIT_VEL - AP_VEL.

local lock mis_dv to ORBIT_VEL - Ship:Velocity:Orbit:Mag.

local burn_time is calc_burn_time(ap_dv).

steer_to({ return Heading(LAUNCH_DIR, 0). }).

wait_for({ return Eta:Apoapsis - burn_time / 2. }).

lock THROTTLE to 1.0.
until mis_dv <= 0 {
    display("burning",
            "missing dv: " + round(mis_dv, 2)).

    check_staging().

    if mis_dv < 50 {
        lock THROTTLE to 0.5.
    }

    wait 0.
}
lock THROTTLE to 0.

lg("done").

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
