# Random-Query-Generator
The Query Method of RandomQueryGenerator.cls returns a random SQL query in intersystems iris. The table definitions ar intended to be 
filled with the Populate utility with adjusted sizes based on the name. This way the random generation will include tables of various
sizes each with fields of varied selectivity. 

The queries generated do not contain the entire bredth of possibilities available in SQL 

The maximum depth of subqueries is adjustable although there is currently a limitation where if it is raised to high queries can be generated the 
exceed the standard string MAXLEN and throw an error

