# Require the Quest class. Note that this kind of require won't work in your
# own quest projects, since sqlquest will be installed locally in `node_modules`
Quest = require '../../quest'

# This is all you need. Doesn't matter what your class is named as long as it is
# the only export. Extend {Quest} and be on your merry way. When you run this
# quest it'll look up `sql/basic.sql` and run it.
module.exports =
class BasicQuest extends Quest
