#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/starrc"
mkdir -p logs outputs work

STARXTRACT=/data2/tools/starrc/R-2020.09-SP5/bin/StarXtract

"$STARXTRACT" -clean rcworst_125c.cmd > logs/rcworst_125c.log 2>&1
"$STARXTRACT" -clean rcbest_m40c.cmd > logs/rcbest_m40c.log 2>&1
