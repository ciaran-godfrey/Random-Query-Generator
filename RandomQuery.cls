Class Paratest.Random {
    ClassMethod Query() {
        set tables = 0
        set subq = 0
        return ..Generate(.tables,.subq)
    }

    ClassMethod Generate(ByRef tables, ByRef subq) {
        //randomly pick included tables and fields
        do ..PickTables(.tables,.subq)
        set from = ..GenerateFROM(.tables)
        set select = ..GenerateSELECT(.tables)
        set where = ..GenerateWHERE(.tables)
        return select _ from _ where
    }

    ClassMethod GenerateSELECT(ByRef tables) {
        set select = "SELECT "
        set tab = ""
        for {
            set tab = $order(tables(tab))
            quit:(tab="")
            set fld = ""
            for {
                set fld = $order(tables(tab,fld))
                quit:(fld="")
                set select = select _ "Paratest." _ tab _ "." _ fld _ ","
            }
        }
        set select = $ZSTRIP(select,">P")
        return select
    }

    ClassMethod GenerateFROM(ByRef tables, ByRef subq) {
        set from = " FROM "
        if subq {
            set name = ""
            for i=1:1:subq {
                set subtables = 0
                set newsubq = subq+1
                set text = ..Generate(.subtables,.newsubq)
                set name = $order(subq(name))
                set subfields = 0
                set tab = ""
                for {
                    set tab=$order(subtables(tab))
                    quit:(tab="")
                    set fld = ""
                    for {
                        set fld=$order(subtables(tab,fld))
                        quit:(fld="")
                        set subfields(name,fld) = 1
                        set subfields = subfields + 1
                    }
                }
                merge tables(name) = subfields
                set subq(name) = text
                
            }
        }
        set order = ..ShuffleTables(.tables)
        set tab = $list(order,1)
        set from = from _ "Paratest." _ tab
        if (tables > 1) {
            for i=2:1:tables {
                set tab = $list(order,i)
                set from = from _ " JOIN " _ "Paratest." _ tab
                //Radomly pick ON clause
                if $RANDOM(2) {
                    //Randomly pick table from 
                    set tab2 = $list(order,$RANDOM(i-1)+1)
                    set pos1 = $RANDOM(tables(tab))
                    set pos2 = $RANDOM(tables(tab2))
                    set fld1 = ""
                    for i=1:1:pos1 {
                        set fld1 = $order(tables(tab,fld1))
                    }
                    set fld2 = ""
                    for i=1:1:pos2 {
                        set fld2 = $order(tables(tab,fld2))
                    }
                    set from = " ON " _ "Paratest." _ tab _ "." _ fld1 _ " = " _ "Paratest." _ tab2 _ "." _ fld2
                }

            }
        }
        return from
    }

    ClassMethod GenerateWHERE(ByRef tables) {
        set where = " WHERE "
        //add "=" conditions
        set numconds = $RANDOM(5)
        if (numconds '= 0) {
            for i=1:1:numconds {
                set tpos1 = $RANDOM(tables)
                set tab1 = ""
                for j=1:1:tpos1 {
                    set tab1 = $order(tables,tab1)
                }
                set tpos2 = $RANDOM(tables)
                set tab2 = ""
                for j=1:1:tpos2 {
                    set tab2 = $order(tables,tab2)
                }
                set fpos1 = $RANDOM(tables(tab1))
                set fld1 = ""
                for i=1:1:fpos1 {
                    set fld1 = $order(tables(tab1,fld1))
                }
                set fpos2 = $RANDOM(tables(tab2))
                set fld2 = ""
                for i=1:1:fpos2 {
                    set fld2 = $order(tables(tab2,fld2))
                }
                if (i'=1) { set where = where _ " AND " }
                set where = where _ "Paratest." _ tab1 _ "." _ fld1 _ " = " _ "Paratest." _ tab2 _ "." _ fld2
            }
        }
        //add range conditions
        set tab = ""
        for {
            set tab = $order(tables(tab))
            quit:(tab=0)
            if ($data(tables(tab,"cont")) && $RANDOM(2)) {
                set upper = $RANDOM(100)
                set lower = ""
                if $RANDOM(2) {
                    set lower = $RANDOM(upper - 1)
                }
                if (where '= " WHERE ") { set where = where _ " AND " }
                set where = where _ "Paratest." _ tab _ ".cont" _ " < " _ upper
                if ($get(lower) '= "") {
                    set where = where _ " AND " _ "Paratest." _ tab _ ".cont" _ " > " _ lower
                }
            }
        }
        return where
    }

    ClassMethod PickTables(Output tables, Output subq) {
        set empty = 1
        set names(1) = "Small"
        set names(2) = "SmMed"
        set names(3) = "Medium"
        set names(4) = "MedLar"
        set names(5) = "Large"
        set names(6) = "LarEx"
        set names(7) = "ExtraLarge"
        for i = 1:1:7 {
            if $RANDOM(2) { 
                set empty = 0
                set tables = tables + 1
                kill fields
                set fields = 0
                do ..PickFields(.fields)
                merge tables(names(i)) = fields
            }
        }
        set nsubq = $RANDOM(3)
        if (nsubq '= 0) {
            for i=1:1:nsubq {
                set subq($c(97+subq)) = ""
                set subq = subq + 1
            }
        }
        if empty {
            kill fields 
            set tables = 1
            set fields = 0
            do ..PickFields(.fields)
            merge tables(names($RANDOM(7)+1)) = fields
        }
    }

    ClassMethod PickFields(Output fields) {
        set empty = 1
        set names(1) = "one"
        set names(2) = "five"
        set names(3) = "ten"
        set names(4) = "twenty"
        set names(5) = "thirty"
        set names(6) = "forty"
        set names(7) = "fifty"
        set names(8) = "cont"
        for i = 1:1:8 {
            if $RANDOM(2) { 
                set empty = 0
                set fields = fields + 1
                set fields(names(i)) = 1 
            }
        }
        if empty {
            set fields = 1
            set fields(names($RANDOM(8)+1)) = 1 
        }
    }

    ClassMethod ShuffleTables(ByRef tables) {
        set sorted = ""
        for i=1:1:tables {
            set sorted = sorted _ $lb(i)
        }
        set shuffled = ""
        for i=tables:-1:1 {
            set pos = $RANDOM(i) + 1
            set $list(shuffled,$list(sorted,tables-i+1)) = pos
            set $list(sorted,pos) = i
            set $list(sorted,i) = pos
        }
        set tablist = ""
        set tab = ""
        for i=1:1:tables {
            set tab = $order(tables(tab))
            set $list(tablist,$list(shuffled,i)) = tab
        }
        return tablist
    }
}
