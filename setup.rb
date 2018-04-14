require 'slack-ruby-bot'
require 'pg'

DATABASE = PG.connect(ENV['DATABASE_URL'])
DATABASE.exec 'CREATE TABLE stagings(id INTEGER PRIMARY KEY, number INT, owner VARCHAR(100))'
# ```
#
# 2. Create existing stagings
#
# ```
DATABASE.exec 'INSERT INTO stagings VALUES(1,2, NULL)'
DATABASE.exec 'INSERT INTO stagings VALUES(2,3, NULL)'
DATABASE.exec 'INSERT INTO stagings VALUES(3,4, NULL)'
DATABASE.exec 'INSERT INTO stagings VALUES(4,5, NULL)'
# ```
# ==========================================
