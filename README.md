# Random-Query-Generator

The `Query()` Method of `QueryGenerator.Random` returns a random SQL query for InterSystems IRIS. The table definitions ar intended to be 
filled with the Populate utility with adjusted sizes based on the name. This way the random generation will include tables of various
sizes each with fields of varied selectivity. 

The queries generated do not contain the entire breadth of possibilities available in SQL 

The maximum depth of subqueries is adjustable although there is currently a limitation where if it is raised to high queries can be generated the 
exceed the standard string MAXLEN and throw an error

## Usage

First populate the `Paratest` schema to your liking:

```ObjectScript
do ##class(Paratest.Small).Populate(1000)
do ##class(Paratest.SmMed).Populate(1000)
do ##class(Paratest.Medium).Populate(1000)
do ##class(Paratest.MedLar).Populate(1000)
do ##class(Paratest.Large).Populate(1000)
do ##class(Paratest.LarEx).Populate(1000)
do ##class(Paratest.ExtraLarge).Populate(1000)
```

Then aim it at your package of choice using
```ObjectScript
do ##class(QueryGenerator.Random).Query("Paratest")
```
