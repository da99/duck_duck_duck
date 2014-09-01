#!/usr/bin/env bash
# -*- bash -*-
#
set -u -e -o pipefail

export SCHEMA_TABLE="_test_schema"
export DUCK_TEMPLATE="../../template.js" 

rm -f /tmp/duck_*
touch /tmp/duck_up
touch /tmp/duck_down
touch /tmp/duck_drop_it

function init {
  rm -f "migrates/002-two.js"
  rm -f "migrates/003-three.js"
  rm -f "migrates/004-four.js"
  rm -f "migrates/005-five.js"
  rm -f "migrates/006-six.js"

  cp "migrates/001-one.js"  "migrates/002-two.js"
  cp "migrates/001-one.js"  "migrates/003-three.js"
}

function init_last_three {
  cp "migrates/001-one.js"  "migrates/004-four.js"
  cp "migrates/001-one.js"  "migrates/005-five.js"
  cp "migrates/001-one.js"  "migrates/006-six.js"
}

# ==== reset
node tests/helpers/drop.js

cd tests/user
../../bin/duck_duck_duck up

cd ../raven_sword
../../bin/duck_duck_duck up

cd ../praying_mantis
rm -f "migrates/008-eight.js"
rm -f "migrates/010-ten.js"
cp "migrates/002-two.js"  "migrates/004-four.js"
cp "migrates/002-two.js"  "migrates/006-six.js"
../../bin/duck_duck_duck up
cp "migrates/002-two.js"  "migrates/008-eight.js"
cp "migrates/002-two.js"  "migrates/010-ten.js"
../../bin/duck_duck_duck down

cd ../lone_wolf
init
../../bin/duck_duck_duck up
init_last_three
../../bin/duck_duck_duck up

cd ../laughing_octopus
rm -rf migrates
../../bin/duck_duck_duck create one
../../bin/duck_duck_duck create two
../../bin/duck_duck_duck create three

# test .drop/.create
cd ../screaming_mantis
../../bin/duck_duck_duck up
../../bin/duck_duck_duck down

cd ../liquid
../../bin/duck_duck_duck up
../../bin/duck_duck_duck drop_it

cd ../..
bin/duck_duck_duck list > /tmp/duck_list
mocha tests/duck_duck_duck.js



