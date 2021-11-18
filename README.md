# Random Query Generator


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