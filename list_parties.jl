using SQLite, DBInterface, DataFrames, PrettyTables

db = SQLite.DB("main.sqlite")
sql_parties = read("sqls/party_names.sql", String)
parties = DataFrame(DBInterface.execute(db, sql_parties))
DBInterface.close!(db)

pretty_table(parties; fit_table_in_display_vertically = false)
