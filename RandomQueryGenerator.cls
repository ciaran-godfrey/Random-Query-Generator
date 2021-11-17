Include %occFunctions

Class Paratest.Random {
    ///Generate Random SQL query

    //tables = number of streams
    //tables(stream name) = number of fields in table
    //tables(stream name, field name) = 1

    ///Maximum depth of subquerues
    Parameter MAXDEPTH As %Integer = 3;

    ClassMethod Query() {
        ///Start recuresion (Generate Method) with initial values
        set tables = 0
        set subq = 0
        return ..Generate(.tables,.subq, 1, "base")
    }

    ClassMethod Generate(ByRef tables, ByRef subq, depth, subqname) {
        //the recursion has 3 pieces to consider
        //1: the new tables in the current subquery of the form "Paratest.<table>" which are used and deleted within the subquery 
        //   these are stored directly in the tables() array
        //2: the select list of the currentl subquery which provides the fields for upstream subquerys, these are aliased and stored
        //   in selstrs() before being merged into tables() when the processing of the subquery is complete
        //3: all the selected fields from downstream subqueries. These are returned by recursive calls and stored in temptables() 
        //   momentarily before being merged into tables()
        set selstrs = 0
        do ..PickTables(.tables,.subq, depth)
        set select = ..GenerateSELECT(.tables,.selstrs,subqname)
        set from = ..GenerateFROM(.tables, .subq, depth, subqname)
        set where = ..GenerateWHERE(.tables, .selstrs, subqname)
        set groupby = ..GenerateGROUPBY(.tables,$l(select,","))
        set orderby = ""
        if ((select["TOP") || (depth = 1)) {
            set orderby = ..GenerateORDERBY(.tables,$l(select,","))
        }
        return select _ from _ where _ groupby _ orderby
    }

    ClassMethod GenerateSELECT(ByRef tables, ByRef selstrs, name) {
        //selstrs holds info about the select list of the current stream. It has the structure of one table from the tables() array
        //and uses the newly created alis names, when processing of this subquery is complete it will be merged into tables() to be passed upstream
        set selstrs(name) = 0
        set selstrs = selstrs + 1
        set selind = 1
        set aggs = $lb("COUNT","SUM","MAX","MIN","AVG","LIST","%DLIST","XMLAGG")
        set select = "SELECT "
        set mode = $$$PRand(3)
        if (mode=2) { 
            set select = select _ "DISTINCT " 
        } elseif (mode=1) { 
            set scale = $lb(1,10,100,1000,10000)
            set select = select _ "TOP " _ $list(scale,$$$PRand(5)+1) _ " "
        }
        set empty = 1
        set tab = ""
        if $$$PRand(2) {
            for {
                set tab = $order(tables(tab))
                quit:(tab="")
                set fld = ""
                for {
                    set fld = $order(tables(tab,fld))
                    quit:(fld="")
                    if $$$PRand(2) {
                        if (empty = 0) { set select = select _ "," }
                        set empty = 0
                        if $$$PRand(2) {
                            set select = select _ tab _ "." _ fld _ " " _ name _selind
                            set selstrs(name, name _ selind) = 1
                            set selstrs(name) = selstrs(name) + 1
                            set selind = selind + 1
                        } else {
                            set select = select _ $list(aggs,$$$PRand(8)+1) _ "("_ tab _"." _ fld _ ") " _ name _  selind
                            set selstrs(name, name _ selind) = 1
                            set selstrs(name) = selstrs(name) + 1
                            set selind = selind + 1
                        }

                    }
                }
            }
            if empty {
                set tpos = $$$PRand(tables)+1
                set tab = ""
                for j=1:1:tpos {
                    set tab = $order(tables(tab))
                }
                set fpos = $$$PRand(tables(tab))+1
                set fld = ""
                for j=1:1:fpos {
                    set fld = $order(tables(tab,fld))
                }
                set select = select _ tab _ "." _ fld _ " " _ name _selind
                set selstrs(name, name _ selind) = 1
                set selstrs(name) = selstrs(name) + 1
                set selind = selind + 1
            }
        } else {
            //Only Aggregate
            set tpos = $$$PRand(tables)+1
            set tab = ""
            for j=1:1:tpos {
                set tab = $order(tables(tab))
            }
            set fpos = $$$PRand(tables(tab))+1
            set fld = ""
            for j=1:1:fpos {
                set fld = $order(tables(tab,fld))
            }
            set select = select _ $list(aggs,$$$PRand(8)+1) _ "("_ tab _"." _ fld _ ") " _ name _  selind
            set selstrs(name, name _ selind) = 1
            set selstrs(name) = selstrs(name) + 1
            set selind = selind + 1
        }
        return select
    }

    ClassMethod GenerateFROM(ByRef tables, ByRef subq, depth, subqname) {
        set temptables = 0
        set strind = 1
        set from = " FROM "
        if ($d(subq)>9) {
            set name = ""
            for {
                set name = $order(subq(name))
                quit:(name="")
                kill subtables
                kill newsubq
                set subtables = 0
                set newsubq = subq
                set text = ..Generate(.subtables,.newsubq, depth+1, name)
                set subq = newsubq
                merge temptables = subtables
                set tables(name) = 1
                set tables = tables + 1
                set subq(name) = text
            }
        }
        set order = ..ShuffleTables(.tables)
        set ordrange = tables
        set tab = ""
        set start = 0
        for i=1:1:ordrange {
            set tab = $list(order,1)
            if (tab["Paratest") {
                set from = from _ tab _ " "
                set start = i
                quit
            } elseif $data(subq(tab)) {
                set from = from _ "(" _ subq(tab) _ ")" _ " " _ tab
                set numsubtables = temptables
                merge tables(tab) = temptables(tab)
                set start = 1
                quit
            }
        }
        if (ordrange > 1) {
            for i=start+1:1:ordrange {
                set join = ""
                set rand = $$$PRand(3)
                if (rand=0) { set join = " INNER JOIN " }
                elseif (rand=1) { set join = " LEFT OUTER JOIN " }
                else { set join = " CROSS JOIN " }
                set tab = $list(order,i)
                if (tab["Paratest") {
                    set from = from _ join _ tab _ " "
                } elseif $data(subq(tab)) {
                    set from = from _ join _ "(" _ subq(tab) _ ")" _ " " _ tab
                    set numsubtables = temptables(tab)
                    merge tables(tab) = temptables(tab)
                }  else {
                    continue
                }
                //ON Clause
                if (join=" CROSS JOIN ") { continue }
                set tab2 = $list(order,$$$PRand(i-1)+1)
                set pos1 = $$$PRand(tables(tab))+1
                set pos2 = $$$PRand(tables(tab2))+1
                set fld1 = ""
                for j=1:1:pos1 {
                    set fld1 = $order(tables(tab,fld1))
                }
                set fld2 = ""
                for j=1:1:pos2 {
                    set fld2 = $order(tables(tab2,fld2))
                }
                set from = from _ " ON " _ tab _ "." _ fld1 _ " = " _ tab2 _ "." _ fld2
            }
        }
        return from
    }

    ClassMethod GenerateWHERE(ByRef tables, ByRef selstrs, subqname) {
        set where = " WHERE "
        //add "=" conditions
        set numconds = $$$PRand(5)
        set remaining = numconds
        set parencount = 0
        if (numconds '= 0) {
            for i=1:1:numconds {
                set tpos1 = $$$PRand(tables)+1
                set tab1 = ""
                for j=1:1:tpos1 {
                    set tab1 = $order(tables(tab1))
                }
                set tpos2 = $$$PRand(tables)+1
                set tab2 = ""
                for j=1:1:tpos2 {
                    set tab2 = $order(tables(tab2))
                }
                set fpos1 = $$$PRand(tables(tab1))+1
                set fld1 = ""
                for j=1:1:fpos1 {
                    set fld1 = $order(tables(tab1,fld1))
                }
                set fpos2 = $$$PRand(tables(tab2))+1
                set fld2 = ""
                for j=1:1:fpos2 {
                    set fld2 = $order(tables(tab2,fld2))
                } 
                if '((tab1=tab2) && (fld1=fld2)) {
                    if (where '= " WHERE ") {
                        if $$$PRand(2) { 
                            set where = where _ " AND " 
                        } else {
                            set where = where _ " OR " 
                        }
                    }
                    if (parencount = 0) {
                        if $$$PRand(2) {
                            if (remaining >= 2) {
                                set parencount = $$$PRand(remaining-1) + 2
                                set where = where _ "("
                            }
                        }
                    }
                    set mode = $$$PRand(4)
                    if (mode=0) {
                        set where = where _ tab1 _ "." _ fld1 _ " = " _ tab2 _ "." _ fld2
                    } elseif (mode=1) {
                        set where = where _ tab1 _ "." _ fld1 _ " != " _ tab2 _ "." _ fld2
                    } elseif (mode=2) {
                        set where = where _ tab1 _ "." _ fld1 _ " = " _ $$$PRand(2)
                    } else {
                        set where = where _ tab1 _ "." _ fld1 _ " != " _ $$$PRand(2)
                    }
                    if (parencount = 1) {
                        set where = where _ ")"
                    }
                    set remaining = remaining - 1
                    if (parencount > 0) { set parencount = parencount - 1}
                } else {
                    if ((remaining = 1) && (parencount = 1) && (where '= " WHERE (")) {
                        set where = where _ " AND 1=1)"
                    } else {
                        set remaining = remaining - 1
                        if (parencount > 1) { set parencount = parencount - 1}
                    }
                }
            }
        }
        //add range conditions
        set tab = ""
        for {
            set tab = $order(tables(tab))
            quit:(tab="")
            if ($data(tables(tab,"cont")) && $$$PRand(2)) {
                set upper = $$$PRand(100)
                set lower = ""
                if ($$$PRand(2) && (upper > 1)) {
                    set lower = $$$PRand(upper-1)
                }
                if (where '= " WHERE ") { set where = where _ " AND " }
                set where = where _ tab _ ".cont" _ " < " _ upper
                if ($get(lower) '= "") {
                    set where = where _ " AND " _ tab _ ".cont" _ " > " _ lower
                }
            }
        }
        if ((where = " WHERE ") || (where = " WHERE (")) { set where = "" }
        set ktab = ""
        for {
            set ktab = $order(tables(ktab))
            quit:(ktab="")
            if (ktab["Paratest") { 
                kill tables(ktab) 
                set tables = tables - 1
            }
        }
        set selstrs = tables + selstrs
        merge tables = selstrs
        set tables = tables + 1
        return where
    }

    ClassMethod GenerateGROUPBY(ByRef tables,sellen) {
        set groupby = ""
        set numfields = $s(sellen>2:$$$PRand(3),1:sellen)
        if (numfields '= 0) {
            set shuffled = ..Shuffle(sellen)
            set groupby = " GROUP BY "
            for i=1:1:numfields {
                set groupby = groupby _ $list(shuffled,i) _ ","       
            }
            set groupby = $ZSTRIP(groupby,">P")
        }
        return groupby
    }

    ClassMethod GenerateORDERBY(ByRef tables,sellen) {
        set orderby = ""
        set numfields = $s(sellen>2:$$$PRand(3),1:$$$PRand(sellen+1))
        if (numfields '= 0) {
            set shuffled = ..Shuffle(sellen)
            set orderby = " ORDER BY "
            for i=1:1:numfields {
                if $$$PRand(2) {
                    set orderby = orderby _ $list(shuffled,i) _ "," 
                } else {
                    set orderby = orderby _ $list(shuffled,i) _ " DESC,"
                }
            }
            set orderby = $ZSTRIP(orderby,">P")
        }
        return orderby
    }

    ClassMethod PickTables(ByRef tables, ByRef subq, depth) {
        set empty = 1
        set names(1) = "Paratest.Small"
        set names(2) = "Paratest.SmMed"
        set names(3) = "Paratest.Medium"
        set names(4) = "Paratest.MedLar"
        set names(5) = "Paratest.Large"
        set names(6) = "Paratest.LarEx"
        set names(7) = "Paratest.ExtraLarge"
        for i = 1:1:7 {
            if ($$$PRand(3)=2) { 
                set empty = 0
                set tables = tables + 1
                kill fields
                set fields = 0
                do ..PickFields(.fields)
                merge tables(names(i)) = fields
            }
        }
        set nsubq = $$$PRand(3)
        if ((nsubq '= 0) && (depth <= ..#MAXDEPTH)) {
            set depth  = depth + 1
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
            merge tables(names($$$PRand(7)+1)) = fields
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
            if $$$PRand(2) { 
                set empty = 0
                set fields = fields + 1
                set fields(names(i)) = 1 
            }
        }
        if empty {
            set fields = 1
            set fields(names($$$PRand(8)+1)) = 1 
        }
    }

    ClassMethod ShuffleTables(ByRef tables) {
        set shuffled = ..Shuffle(tables)
        set tablist = ""
        set tab = ""
        for i=1:1:tables {
            set tab = $order(tables(tab))
            set $list(tablist,$list(shuffled,i)) = tab
        }
        return tablist
    }

    ClassMethod Shuffle(length) {
        set shuffled = ""
        for i=1:1:length {
            set shuffled = shuffled _ $lb(i)
        }
        for i=length:-1:1 {
            set pos = $$$PRand(i) + 1
            set temp = $list(shuffled,pos)
            set $list(shuffled,pos) = $list(shuffled,i)
            set $list(shuffled,i) = temp
        }
        return shuffled
    }
}
