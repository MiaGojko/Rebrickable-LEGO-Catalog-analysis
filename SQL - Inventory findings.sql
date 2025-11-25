-------------------------------------------------------------------------------------------------------
-------- Exploring foundations of each table and it's interactions with other tables
-------------------------------------------------------------------------------------------------------

-------------------------
---THEMES
-------------------------

SELECT * FROM THEMES;

--Total number of all rows 
    SELECT COUNT(*) FROM THEMES;

--ID is primary key so it mustn't be NULL and all ID values must be distinct 
    SELECT * FROM THEMES WHERE ID IS NULL; --empty
    SELECT COUNT(*) FROM THEMES WHERE ID IS NULL; --0 

    SELECT COUNT(ID) FROM THEMES; --482
    SELECT COUNT(DISTINCT ID) FROM THEMES; --482

--Is there a theme with no NAME defined?
    SELECT * FROM THEMES WHERE NAME IS NULL; --empty
    SELECT COUNT(*) FROM THEMES WHERE NAME IS NULL; --0

--How many distinct theme names there are?
    SELECT COUNT(NAME) FROM THEMES; --482  (NAME IS NEVER NULL SO THIS WORKS THE SAME AS COUNT(*))
    SELECT COUNT(DISTINCT NAME) FROM THEMES; --414
    --Since ID is primary key and the Themes table has only two more columns NAME and PARENT_ID from this mismatch in results ( 414 != 482 ) there is a hypotesis that there might be a theme that has the same name but different parent_id.
    -- Because of different combination of those (NAME, PARENT_ID) there are multiple rows with unique representation ID.

        --First, let's check if there are themes that do not have defined parents?
            SELECT * FROM THEMES WHERE PARENT_ID IS NULL; --not empty
            SELECT COUNT(*) FROM THEMES WHERE PARENT_ID IS NULL; --148
                --Yes, there are some themes that do not have parents and there is 148 of them.

--Are there themes that have multiple parents? 
    
    --Is the same (NAME, PARENT_ID) defined with two different IDs?
    with name_parent as (
    SELECT NAME, PARENT_ID 
    FROM THEMES 
    ORDER BY NAME, PARENT_ID)
    SELECT COUNT(*) FROM name_parent; --482
    
    with dis_name_parent as (
    SELECT DISTINCT NAME, PARENT_ID 
    FROM THEMES 
    ORDER BY NAME, PARENT_ID)
    SELECT COUNT(*) FROM dis_name_parent; --482
        --No, there isn't. Each pair (NAME, PARENT_ID) is unique in the table.
        --That now definately lead to conclusion that the same NAME theme has multiple parents.
        
    --Let's see parents of each theme NAME.
    SELECT NAME, PARENT_ID 
    FROM THEMES 
    GROUP BY NAME,PARENT_ID
    ORDER BY NAME, PARENT_ID;
    
    --Is there a theme that has at least 2 parents but one of them is not defined aka NULL?
    
    SELECT NAME, count (ID)  --if i put count(PARENT_ID) it would be incorect since count(column) doesn't count nulls and ID is never NULL so it is the same as count(*)
    FROM THEMES 
    GROUP BY NAME
    HAVING COUNT(ID) > 2
    ORDER BY COUNT(ID) DESC, NAME;
    --Here is a list of all 13 theme names that have multiple distinct parents (we know they are distinct because NAME, PARENT_ID combination is unique)
    
    --Now. let's take a look of all these theme names and check is some of them have parent_id null;
    with multipleparent_per_name as(
    SELECT NAME, count (ID)  --if i put count(PARENT_ID) it would be incorect since count(column) doesn't count nulls and ID is never NULL so it is the same as count(*)
    FROM THEMES 
    GROUP BY NAME
    HAVING COUNT(ID) > 2
    ORDER BY COUNT(ID) DESC, NAME)
    select name from themes where name in (select name from multipleparent_per_name) and parent_id is null; 
    --There is 11 theme names that have at least one parent not null and one that is NULL

    --Now. let's see which parents these names have?
    
    with multipleparent_per_name as(
    SELECT NAME, count (ID)  --if i put count(PARENT_ID) it would be incorect since count(column) doesn't count nulls and ID is never NULL so it is the same as count(*)
    FROM THEMES 
    GROUP BY NAME
    HAVING COUNT(ID) > 2
    ORDER BY COUNT(ID) DESC, NAME),
    at_least_one_null_parent_per_name as(
    select name 
    from themes 
    where name in (select name from multipleparent_per_name) 
    and parent_id is null)
    select name, parent_id, id 
    from themes 
    where name in (select name from at_least_one_null_parent_per_name)
    order by name, parent_id, id; 
    --If the parent is null than there might be a mistake while importing the data or that theme name is also in defined as "the first in it's own hierarchy separate from the rest"
    --To check ih any of these names that have parent_id null are "the first in it's own hierarchy separate from the rest" using their ID it will be checked id those ID's are parent_id to any row in Themes table
    
    with multipleparent_per_name as(
    SELECT NAME, count (ID)  --if i put count(PARENT_ID) it would be incorect since count(column) doesn't count nulls and ID is never NULL so it is the same as count(*)
    FROM THEMES 
    GROUP BY NAME
    HAVING COUNT(ID) > 2
    ORDER BY COUNT(ID) DESC, NAME
    ),
    at_least_one_null_parent_per_name as(
    select name 
    from themes 
    where name in (select name from multipleparent_per_name) 
    and parent_id is null
    ),
    only_parent_which_is_null as(
    select id 
    from themes 
    where name in (select name from at_least_one_null_parent_per_name) and parent_id is null
    order by name, parent_id, id 
    )
    select * from themes where parent_id in (select id from only_parent_which_is_null )
    ; 
    
    --After this it is obvious what was the assumption. Some theme names have multiple parent but also the eaither have value missing i parent_id column or they are starting their own journey also separate from other branches.
    --The second assumption is a bit weird.
    
--Which theme name has the most parents that are not null?

    SELECT NAME, count (PARENT_ID) num_of_parents --count will not count rows that have parent_id null
    FROM THEMES 
    GROUP BY NAME
    ORDER BY num_of_parents DESC, NAME;
    
--Also, lets turn around. Which theme has the most subthemes just per first level beneath?
    
    with parents_with_all_children as (
    SELECT PARENT_ID, COUNT(ID) num_of_children
    FROM THEMES 
    WHERE PARENT_ID IS NOT NULL
    GROUP BY PARENT_ID
    ORDER BY num_of_children DESC, PARENT_ID
    )
    select pc.parent_id  theme_id, t.name theme_name, pc.num_of_children num_of_children
    from parents_with_all_children pc
    join themes t
    on pc.parent_id =t.id
    order by num_of_children desc,theme_name, theme_id ;
    
--Now lets create the whole hierarchy and connect all childen and their parents.

SELECT PARENT_ID parent, ID  child, level  hierarchy_level, SYS_CONNECT_BY_PATH (ID, ' -> ') path_id, SYS_CONNECT_BY_PATH (NAME, ' -> ') path_name
FROM THEMES
START WITH PARENT_ID IS NULL
CONNECT BY PRIOR ID = PARENT_ID;

--Which theme(name, id) has the most levels developed underneath and what is the max hierarchy level?

with hierarchy as(
SELECT PARENT_ID parent, ID  child, level  hierarchy_level, SYS_CONNECT_BY_PATH (ID, ' -> ') path_id, SYS_CONNECT_BY_PATH (NAME, ' -> ') path_name
FROM THEMES
START WITH PARENT_ID IS NULL
CONNECT BY PRIOR ID = PARENT_ID
)
select MAX(distinct HIERARCHY_LEVEL) FROM hierarchy; --max level is 3


with hierarchy as(
SELECT PARENT_ID parent, ID  child, level  hierarchy_level, SYS_CONNECT_BY_PATH (ID, ' -> ') path_id, SYS_CONNECT_BY_PATH (NAME, ' -> ') path_name
FROM THEMES
START WITH PARENT_ID IS NULL
CONNECT BY PRIOR ID = PARENT_ID
)
select * 
FROM hierarchy 
where hierarchy_level = (select MAX(distinct HIERARCHY_LEVEL)from hierarchy);
    --This is a list of the whole result where hierarchy = 3
    
    --Now, let's just show the starter id-s of the path. Those will be the themes that have the most levels beneath  
    with hierarchy as(
    SELECT PARENT_ID parent, ID  child, level  hierarchy_level, SYS_CONNECT_BY_PATH (ID, ' -> ') path_id, SYS_CONNECT_BY_PATH (NAME, ' -> ') path_name
    FROM THEMES
    START WITH PARENT_ID IS NULL
    CONNECT BY PRIOR ID = PARENT_ID
    )
    select DISTINCT SUBSTR(PATH_NAME, INSTR(PATH_NAME,' -> ', 1,1) + LENGTH( ' -> ') , INSTR(PATH_NAME,' -> ', 1,2)- (INSTR(PATH_NAME,' -> ', 1,1) + LENGTH( ' -> '))) as Largest_hierarchy_theme_name,  
            SUBSTR(PATH_ID, INSTR(PATH_ID, ' -> ', 1,1) + LENGTH( ' -> ') , INSTR(PATH_ID, ' -> ', 1,2)- (  INSTR(PATH_ID, ' -> ', 1,1) + LENGTH( ' -> '))) as Largest_hierarchy_theme_id,
            hierarchy_level as Max_hierarchy_level
    FROM hierarchy 
    where hierarchy_level = (select MAX(distinct HIERARCHY_LEVEL)from hierarchy);   
    --Here is the list of the themes with the most hierarchies
 
 
 

 
---------------------------
----------SETS
----------------------------


--Display preview
SELECT * FROM SETS;

--Total number of rows
SELECT COUNT(*) FROM SETS;

--Check columns if there are NUll values.
SELECT COUNT(*) FROM SETS WHERE SET_NUM IS NULL;
SELECT COUNT(*) FROM SETS WHERE NAME IS NULL;
SELECT COUNT(*) FROM SETS WHERE YEAR IS NULL;
SELECT COUNT(*) FROM SETS WHERE THEME_ID IS NULL;
SELECT COUNT(*) FROM SETS WHERE NUM_PARTS IS NULL;
SELECT COUNT(*) FROM SETS WHERE IMG_URL IS NULL;
    --There ain't a value in Sets that is null.
    
--Is set_num unique value?
SELECT COUNT(SET_NUM) FROM SETS; 
SELECT COUNT(DISTINCT SET_NUM) FROM SETS;
    --Yes, there are 25669 different values. Set_num is a good primary key.

---Are there multipe Sets that have the same name?
SELECT COUNT(NAME) FROM SETS; --25669
SELECT COUNT(DISTINCT NAME) FROM SETS; --22040
    --Yes, there are some Sets that have the same NAME.
    --Which are those?
    
    SELECT NAME, COUNT(SET_NUM)
    FROM SETS
    GROUP BY NAME
    HAVING COUNT(SET_NUM)>2
    ORDER BY COUNT(SET_NUM), NAME;
        --These are number of sets that have the same name. (1 set = 1 row from table Sets)
    
    SELECT NAME, YEAR, COUNT(SET_NUM), COUNT(DISTINCT THEME_ID),  COUNT(DISTINCT NUM_PARTS), COUNT(DISTINCT IMG_URL)
    FROM SETS
    GROUP BY NAME, YEAR
    HAVING COUNT(SET_NUM)>2
    ORDER BY COUNT(SET_NUM) DESC,COUNT(DISTINCT THEME_ID) DESC, NAME, YEAR;
        --When Name and Year is specified there are some sets with that (Name, Year) pair that belong to the same theme and have the same number of parts but their style IMG_URL is different so that makes a set difference.   
        --Example 
        SELECT * FROM SETS WHERE NAME = 'Race Car' AND YEAR='01-NOV-25';
        
--Which set has the most number_of_parts?

    SELECT  NUM_PARTS , SET_NUM
    FROM SETS 
    GROUP BY NUM_PARTS , SET_NUM
    ORDER BY NUM_PARTS DESC, SET_NUM DESC;
    --Here is a list of all number of parts with their corresponding sets 
    
--Which set is the first one made, adn which is last one?
    SELECT MIN(YEAR) FROM SETS; -- 01-NOV-49 is the oldest set date
    SELECT MAX(YEAR) FROM SETS; -- 01-NOV-26 is the youngest set date
    
    SELECT * FROM SETS WHERE YEAR IN (SELECT MIN(YEAR) FROM SETS);
        --These are the oldest sets made.
    SELECT * FROM SETS WHERE YEAR IN (SELECT MAX(YEAR) FROM SETS);   
        --These are the youngest sets made.

-- How many sets are there produced per year?
    
    --All sets per year of production
        SELECT EXTRACT(YEAR FROM YEAR) Year , SET_NUM 
        FROM SETS
        ORDER BY Year;
        
     --How many sets are there per year of production?
        SELECT EXTRACT(YEAR FROM YEAR) Year , count(SET_NUM) num_of_sets
        FROM SETS
        group by EXTRACT(YEAR FROM YEAR) 
        ORDER BY Year;
        
    --Which year did LEGO produce the most sets, the least sets, average?
      
        with num_of_sets_per_year as(
        SELECT EXTRACT(YEAR FROM YEAR) Year , count(SET_NUM) num_of_sets
        FROM SETS
        group by EXTRACT(YEAR FROM YEAR) 
        ORDER BY Year        
        )
        SELECT * from num_of_sets_per_year where num_of_sets in (SELECT MAX(num_of_sets) max_num_of_sets FROM num_of_sets_per_year); -- 1225 Is max number of sets in 2024
        
        with num_of_sets_per_year as(
        SELECT EXTRACT(YEAR FROM YEAR) Year , count(SET_NUM) num_of_sets
        FROM SETS
        group by EXTRACT(YEAR FROM YEAR) 
        ORDER BY Year        
        )
        SELECT * from num_of_sets_per_year where num_of_sets in (SELECT MIN(num_of_sets) min_num_of_sets FROM num_of_sets_per_year); -- 3 is  min number of sets in 1960
        
         with num_of_sets_per_year as(
        SELECT EXTRACT(YEAR FROM YEAR) Year , count(SET_NUM) num_of_sets
        FROM SETS
        group by EXTRACT(YEAR FROM YEAR) 
        ORDER BY Year        
        )
       SELECT ROUND(AVG(num_of_sets)) avg_num_of_sets FROM num_of_sets_per_year; -- 338 is  AVG per year
        
         with num_of_sets_per_year as(
        SELECT EXTRACT(YEAR FROM YEAR) Year , count(SET_NUM) num_of_sets
        FROM SETS
        group by EXTRACT(YEAR FROM YEAR) 
        ORDER BY Year        
        )
       SELECT ROUND(MEDIAN(num_of_sets)) avg_num_of_sets FROM num_of_sets_per_year; -- 138 is MEDIAN per year
       
       
       -- Which year LEGO didn't produce any new set and how many years there were like that?
       
       with years_of_produced_sets as(
            SELECT DISTINCT EXTRACT(YEAR FROM YEAR) Year
            FROM SETS
            ORDER BY Year
       ),
       start_end_history_years as(
            SELECT  EXTRACT(YEAR FROM MIN(YEAR)) start_year,
                    EXTRACT(YEAR FROM MAX(YEAR)) end_year,
                    EXTRACT(YEAR FROM MAX(YEAR)) - EXTRACT(YEAR FROM MIN(YEAR)) difference
            FROM SETS
       ),
       all_history_years as (
       SELECT start_year + level -1 history_year
       FROM start_end_history_years
       CONNECT BY level <= difference + 1
       ),
       no_newset_years as(
       select * from all_history_years
       MINUS
       select * from years_of_produced_sets
       )
       SELECT COUNT(history_year) as no_newset_years , 
              LISTAGG( history_year , ', ') WITHIN GROUP (ORDER BY history_year)
        FROM no_newset_years;      
            --There are 2 of them : 1951, 1952
    
--Are there some Themes that do not have any set from Sets?

    SELECT COUNT(*) FROM THEMES; --482 total number of themes
    SELECT COUNT(DISTINCT THEME_ID) FROM SETS; --476 total number of themes in Sets

    SELECT DISTINCT ID
    FROM THEMES
    MINUS
    SELECT DISTINCT THEME_ID
    FROM SETS;
        --Yes, there are some that do not have any set defined.

    with theme_without_set as(
    SELECT DISTINCT ID
    FROM THEMES
    MINUS
    SELECT DISTINCT THEME_ID
    FROM SETS
    )
    SELECT COUNT(*) FROM theme_without_set; -- There are 6 of them
        
-- Show themes by the number of sets that they have from the biggest to the smallest.
    
    SELECT THEME_ID, COUNT(SET_NUM) num_of_sets
    FROM SETS
    GROUP BY THEME_ID
    ORDER BY num_of_sets desc, theme_id;
    
    
    
    
    

---------------------------
---------- Inventories
----------------------------



--Display preview
SELECT * FROM INVENTORIES;

--Total number of rows
SELECT COUNT(*) FROM INVENTORIES; --43721

--Check NULL values in columns
SELECT COUNT(*) FROM INVENTORIES WHERE ID IS NULL; --0
SELECT COUNT(*) FROM INVENTORIES WHERE VERSION IS NULL; --0
SELECT COUNT(*) FROM INVENTORIES WHERE SET_NUM IS NULL; --0
    --There are no null values in columns
    
--Which are and how many versions there are per SET_NUM?

    SELECT SET_NUM, VERSION
    FROM INVENTORIES
    GROUP BY SET_NUM,VERSION
    ORDER BY SET_NUM, VERSION;
    
    SELECT SET_NUM, count(VERSION) num_of_versions
    FROM INVENTORIES
    GROUP BY SET_NUM
    ORDER BY num_of_versions DESC, SET_NUM ;
    
--Can SET_NUM be used as foreign key referencing Sets.SET_NUM?
    -- No, it can't because there are some SET_NUM that do not match with SET_NUM from Sets. That is the reason why this foreign key isn't created.
    SELECT DISTINCT SET_NUM
    FROM INVENTORIES
    MINUS
    SELECT SET_NUM 
    FROM SETS;
    
    


-------------------------------
---------- Inventory_sets
-------------------------------

    

--Display preview
SELECT * FROM INVENTORY_SETS;

--Total number of rows
SELECT COUNT(*) FROM INVENTORY_SETS; --4827

--Check NULL values in columns
SELECT COUNT(*) FROM INVENTORY_SETS WHERE INVENTORY_ID IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_SETS WHERE SET_NUM IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_SETS WHERE QUANTITY IS NULL; --0
    --There are no null values in columns
    
-- If the quantity is 0 is there a information about it?
SELECT count(*) FROM INVENTORY_SETS WHERE QUANTITY=0;
    --If the quantity is 0 then there is no information about it in the Inventory_sets. 
    --So, Inventory_set only stores pairs of (Inventory_id, Set_NUM) that have some amount of product available.

--Inventory_id can be considered as parent, and SET_NUM as child. 
    --In that way of thinking, lets see which parent has which children?
    SELECT INVENTORY_ID, SET_NUM
    FROM INVENTORY_SETS
    ORDER BY INVENTORY_ID, SET_NUM;
    
    --How many children each parent has?
    SELECT INVENTORY_ID, COUNT(SET_NUM) num_of_children
    FROM INVENTORY_SETS
    GROUP BY INVENTORY_ID
    ORDER BY COUNT(SET_NUM)DESC ,INVENTORY_ID;
    
    --Also, in different direction. How many parents does a child have?    
    SELECT SET_NUM, COUNT(INVENTORY_ID) num_of_parents
    FROM INVENTORY_SETS
    GROUP BY SET_NUM
    ORDER BY COUNT(INVENTORY_ID)DESC , SET_NUM;
    
--Does Inventory.SET_NUM has to match the Inventory_sets.SET_NUM?

    SELECT inv.SET_NUM, invset.SET_NUM
    FROM Inventories inv
    JOIN Inventory_sets invset
    ON inv.id = invset.inventory_id
    WHERE inv.SET_NUM != invset.SET_NUM; --No, it doesn't.
    
    SELECT inv.SET_NUM, invset.SET_NUM
    FROM Inventories inv
    JOIN Inventory_sets invset
    ON inv.id = invset.inventory_id
    WHERE inv.SET_NUM = invset.SET_NUM; --It, never matches!!
    
    --In Invetory_sets there is only infomation that the set no matter the version can't be it's own child.
    --Here, are stored only combinations od (inv.set_num, inv.version) that are parenty to some sets (SET_NUM) and that have quantity.
    
--Which and how many SET_NUM are not in the Inventory_sets -> Meaning which sets have zero amount in stock.
    --Which?
     with set_num_in_stock as (
         SELECT DISTINCT SET_NUM
         FROM INVENTORY_SETS
     ),
    all_sets as (
         SELECT SET_NUM 
         FROM SETS
         )
    SELECT * FROM all_sets 
    MINUS
    SELECT * FROM set_num_in_stock; 
    
    --How many?
    with set_num_in_stock as (
         SELECT DISTINCT SET_NUM
         FROM INVENTORY_SETS
     ),
    all_sets as (
         SELECT SET_NUM 
         FROM SETS
         ),
    sets_not_in_stock as (
    SELECT * FROM all_sets 
    MINUS
    SELECT * FROM set_num_in_stock
    )
    select count(*) from set_num_in_stock; --3530
    
--Each SET_NUM is in stock in different combinations with Inventory_id.
    -- What is the total quantity of each SET_NUM no matter the Inventory_Id that they are paired with?
        SELECT SET_NUM, SUM(QUANTITY)
        FROM INVENTORY_SETS
        GROUP BY SET_NUM
        ORDER BY SUM(QUANTITY) DESC, SET_NUM;
        
    --What is the SET_NUM with the highest amount in stock and what is the amount?
        WITH sets_quantity as(
        SELECT SET_NUM, SUM(QUANTITY) total_quantity
        FROM INVENTORY_SETS
        GROUP BY SET_NUM
        ORDER BY SUM(QUANTITY) DESC, SET_NUM
        )
        SELECT * 
        FROM sets_quantity 
        where total_quantity = (SELECT MAX(total_quantity) FROM sets_quantity );
        
    --What is the total quantity of each SET_NUM including Inventory id? 
        SELECT QUANTITY, SET_NUM, INVENTORY_ID
        FROM INVENTORY_SETS
        ORDER BY QUANTITY DESC, SET_NUM , INVENTORY_ID;
    
    
    

-------------------------------
---------- Minifigs
-------------------------------
   
   
   

--Display preview
SELECT * FROM MINIFIGS;

--Total number of rows
SELECT COUNT(*) FROM MINIFIGS; --16189

--Check NULL values in columns
SELECT COUNT(*) FROM MINIFIGS WHERE FIG_NUM IS NULL; --0
SELECT COUNT(*) FROM MINIFIGS WHERE NAME IS NULL; --0
SELECT COUNT(*) FROM MINIFIGS WHERE NUM_PARTS IS NULL; --0
SELECT COUNT(*) FROM MINIFIGS WHERE IMG_URL IS NULL; --0
    --There are no null values in columns   

--Is Minigfig Name Unique?
SELECT COUNT(NAME) FROM MINIFIGS; --16189
SELECT COUNT(DISTINCT NAME) FROM MINIFIGS; --15682
    --No, it is not.
    
    SELECT NAME, COUNT(FIG_NUM), COUNT(DISTINCT NUM_PARTS),  COUNT(DISTINCT IMG_URL)
    FROM MINIFIGS
    GROUP BY NAME
    ORDER BY  COUNT(FIG_NUM )DESC ,  COUNT(DISTINCT NUM_PARTS) DESC, COUNT(DISTINCT IMG_URL) DESC,  NAME;
        --One Minifig Name can have the same number of parts put the style IMG_URL is not the same so that will make a difference for each minifig_id.
        
--How is table Minifig connected to Inventories table? 
    
    SELECT FIG_NUM 
    FROM MINIFIGS
    MINUS
    SELECT SET_NUM
    FROM INVENTORIES;
    --There ain't a sigle FIG_NUM that isn't stored in Inventories
    
--Is Inventories table set up from all Sets. SET_NUM and Minifigs.FIG_NUM?

    SELECT SET_NUM 
    FROM SETS
    MINUS
    SELECT SET_NUM
    FROM INVENTORIES;
    --There ain't a sigle SET__NUM that isn't stored in Inventories

    SELECT SET_NUM
    FROM INVENTORIES
    MINUS
    SELECT FIG_NUM 
    FROM MINIFIGS
    MINUS
    SELECT SET_NUM 
    FROM SETS;
    
    SELECT * FROM INVENTORIES WHERE SET_NUM LIKE '%fig%' AND VERSION != 1;
    --Yes, Inventories is made of all Minifig.FIG_NUMS and Sets.SET_NUM with version=1 for all FIG_NUMs and multiple version values for Sets.SET_NUM.
    
--Minifigs by the number of parts they are consisted of from the most to the least.

    SELECT FIG_NUM, NUM_PARTS
    FROM MINIFIGS
    ORDER BY NUM_PARTS DESC, FIG_NUM;
    


    
----------------------------------
---------- Inventory_minifigs
----------------------------------




 --This table functions in the same way as Inventory_sets. 


--Display preview
SELECT * FROM INVENTORY_MINIFIGS;

--Total number of rows
SELECT COUNT(*) FROM INVENTORY_MINIFIGS; --24369

--Check NULL values in columns
SELECT COUNT(*) FROM INVENTORY_MINIFIGS WHERE INVENTORY_ID IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_MINIFIGS WHERE FIG_NUM IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_MINIFIGS WHERE QUANTITY IS NULL; --0
    --There are no null values in columns   

-- If the quantity is 0 is there a information about it?
    --If the quantity is 0 then there is no information about it in the Inventory_minifigs. 
    SELECT count(*) FROM INVENTORY_MINIFIGS WHERE QUANTITY=0;
    --So, Inventory_minifigs only stores pairs of (Inventory_id, FIG_NUM) that have some amount of product available.


--Inventory_id can be considered as parent, and FIG_NUM as a child. 
    --In that way of thinking, lets see which parent has which children?
    SELECT INVENTORY_ID, FIG_NUM
    FROM INVENTORY_MINIFIGS
    ORDER BY INVENTORY_ID, FIG_NUM;

    --How many children each parent has?
    SELECT INVENTORY_ID, COUNT(FIG_NUM) num_of_children
    FROM INVENTORY_MINIFIGS
    GROUP BY INVENTORY_ID
    ORDER BY COUNT(FIG_NUM)DESC ,INVENTORY_ID;

    --Also, in different direction. How many parents does a child have?    
    SELECT FIG_NUM, COUNT(INVENTORY_ID) num_of_parents
    FROM INVENTORY_MINIFIGS
    GROUP BY FIG_NUM
    ORDER BY COUNT(INVENTORY_ID)DESC , FIG_NUM;

--Does Inventory.SET_NUM has to match the Inventory_minifigs.FIG_NUM?

    SELECT inv.SET_NUM, invfig.FIG_NUM
    FROM Inventories inv
    JOIN Inventory_minifigs invfig
    ON inv.id = invfig.inventory_id
    WHERE inv.SET_NUM != invfig.FIG_NUM; --No, it doesn't.
    
    SELECT inv.SET_NUM, invfig.FIG_NUM
    FROM Inventories inv
    JOIN Inventory_minifigs invfig
    ON inv.id = invfig.inventory_id
    WHERE inv.SET_NUM = invfig.FIG_NUM; --It, never matches!!
    
    --In Invetory_minifigs there is only infomation that the minifig no matter the version can't be it's own child.
    --Here, are stored only combinations od (inv.set_num, inv.version) that are parent to some minifigs (FIG_NUM) and that have quantity.
    

--Which and how many FIG_NUM are not in the Inventory_minifigs -> Meaning which minifigs have zero amount in stock.
    --Which?
     with fig_num_in_stock as (
         SELECT DISTINCT FIG_NUM
         FROM INVENTORY_MINIFIGS
     ),
    all_figs as (
         SELECT FIG_NUM 
         FROM MINIFIGS
         )
    SELECT * FROM all_figs 
    MINUS
    SELECT * FROM fig_num_in_stock; 
    
    --How many?
    with fig_num_in_stock as (
         SELECT DISTINCT FIG_NUM
         FROM INVENTORY_MINIFIGS
     ),
    all_figs as (
         SELECT FIG_NUM 
         FROM MINIFIGS
         ),
    figs_not_in_stock as (
    SELECT * FROM all_figs 
    MINUS
    SELECT * FROM fig_num_in_stock
    )
    select count(*) from figs_not_in_stock; --318

    
--Each FIG_NUM is in stock in different combinations with Inventory_id.
    -- What is the total quantity of each FIG_NUM no matter the Inventory_Id that they are paired with?
        SELECT FIG_NUM, SUM(QUANTITY)
        FROM INVENTORY_MINIFIGS
        GROUP BY FIG_NUM
        ORDER BY SUM(QUANTITY) DESC, FIG_NUM;
        
    --What is the FIG_NUM with the highest amount in stock and what is the amount?
        WITH fig_quantity as(
        SELECT FIG_NUM, SUM(QUANTITY) total_quantity
        FROM INVENTORY_MINIFIGS
        GROUP BY FIG_NUM
        ORDER BY SUM(QUANTITY) DESC, FIG_NUM
        )
        SELECT * 
        FROM fig_quantity 
        where total_quantity = (SELECT MAX(total_quantity) FROM fig_quantity );

    --What is the total quantity of each FIG_NUM including Inventory id? 
        SELECT  FIG_NUM, INVENTORY_ID, QUANTITY
        FROM INVENTORY_MINIFIGS
        ORDER BY QUANTITY DESC, FIG_NUM , INVENTORY_ID;
    
    
    
      
----------------------------------
---------- PART_CATEGORIES
----------------------------------



--Display preview
SELECT * FROM PART_CATEGORIES;

--Total number of rows
SELECT COUNT(*) FROM PART_CATEGORIES; --76 different categories of parts

--Check NULL values in columns
SELECT COUNT(*) FROM PART_CATEGORIES WHERE ID IS NULL; --0
SELECT COUNT(*) FROM PART_CATEGORIES WHERE NAME IS NULL; --0
    --There are no null values in columns   


    
----------------------------------
---------- PART_RELATIONSHIPS
----------------------------------



--Display preview
SELECT * FROM PART_RELATIONSHIPS;

--Total number of rows
SELECT COUNT(*) FROM PART_RELATIONSHIPS; --34848 different parent-child relationships between parts

--Check NULL values in columns
SELECT COUNT(*) FROM PART_RELATIONSHIPS WHERE REL_TYPE IS NULL; --0
SELECT COUNT(*) FROM PART_RELATIONSHIPS WHERE CHILD_PART_NUM IS NULL; --0
SELECT COUNT(*) FROM PART_RELATIONSHIPS WHERE PARENT_PART_NUM IS NULL; --0
    --There are no null values in columns   
   
--Is there the same combination of (parent,child) stored with more than one row?
    SELECT PARENT_PART_NUM,CHILD_PART_NUM, COUNT(*)
    FROM PART_RELATIONSHIPS
    GROUP BY PARENT_PART_NUM,CHILD_PART_NUM
    HAVING COUNT(*)> 2 ; 
    --No, there isn't. This means that each pair (parent, child) is unique and it has relationship type defined between them.
       
--How many different REL_TYPE is there and which are those?
SELECT COUNT(DISTINCT REL_TYPE),
    LISTAGG(DISTINCT REL_TYPE, ', ') WITHIN GROUP (ORDER BY REL_TYPE ) 
    FROM PART_RELATIONSHIPS; --There is 6 of them : A, B, M, P, R, T

--How many children one parent has and which are those?
    --Excluding relationship type 
    SELECT PARENT_PART_NUM, COUNT(CHILD_PART_NUM)
    FROM PART_RELATIONSHIPS
    GROUP BY PARENT_PART_NUM
    ORDER BY  COUNT(CHILD_PART_NUM) DESC;
    
    --Including relationship type 
    SELECT PARENT_PART_NUM, REL_TYPE, COUNT(CHILD_PART_NUM)
    FROM PART_RELATIONSHIPS
    GROUP BY PARENT_PART_NUM, REL_TYPE
    ORDER BY PARENT_PART_NUM, COUNT(CHILD_PART_NUM) DESC;
   
--How many parents one child has and which are those?
    --Excluding relationship type 
    SELECT CHILD_PART_NUM, COUNT(PARENT_PART_NUM)
    FROM PART_RELATIONSHIPS
    GROUP BY CHILD_PART_NUM
    ORDER BY COUNT(PARENT_PART_NUM) DESC;
    
    --Including relationship type 
    SELECT CHILD_PART_NUM, REL_TYPE, COUNT(PARENT_PART_NUM)
    FROM PART_RELATIONSHIPS
    GROUP BY CHILD_PART_NUM, REL_TYPE
    ORDER BY CHILD_PART_NUM, COUNT(PARENT_PART_NUM)DESC;
    

-- Is it ever parent = child?
select count(*) from PART_RELATIONSHIPS 
where parent_part_num = child_part_num; --No.



    
----------------------------------
---------- PARTS
----------------------------------
    


--Display preview
SELECT * FROM PARTS;

--Total number of rows
SELECT COUNT(*) FROM PARTS; --59870 different parts

--Check NULL values in columns
SELECT COUNT(*) FROM PARTS WHERE PART_NUM IS NULL; --0
SELECT COUNT(*) FROM PARTS WHERE NAME IS NULL; --0
SELECT COUNT(*) FROM PARTS WHERE PART_CAT_ID IS NULL; --0
SELECT COUNT(*) FROM PARTS WHERE PART_MATERIAL IS NULL; --0
    --There are no null values in columns   

--Is a part name unique?
SELECT COUNT(*) FROM PARTS; --59870
SELECT COUNT(DISTINCT NAME) FROM PARTS; --59156
    --No, name is not unique.

--Is there a category with no parts registered?
    SELECT ID 
    FROM PART_CATEGORIES
    MINUS
    SELECT DISTINCT PART_CAT_ID
    FROM PARTS; 
    --No, it doesn't.

--How many parts are there in each category?
    --Excluding material and name
        SELECT PART_CAT_ID, COUNT(PART_NUM)
        FROM PARTS
        GROUP BY PART_CAT_ID
        ORDER BY COUNT(PART_NUM) DESC, PART_CAT_ID;
        
    --By material
        SELECT PART_CAT_ID, PART_MATERIAL, COUNT(PART_NUM)
        FROM PARTS
        GROUP BY PART_CAT_ID, PART_MATERIAL
        ORDER BY PART_CAT_ID, PART_MATERIAL,COUNT(PART_NUM) DESC ;

--Is there a category that is not defined within Part_categories?
    SELECT PART_CAT_ID
    FROM PARTS
    MINUS
    SELECT ID
    FROM
    PART_CATEGORIES;
    --No, there isn't;

--How many parts are there by material?    
        SELECT PART_MATERIAL, COUNT(PART_NUM)
        FROM PARTS
        GROUP BY PART_MATERIAL
        ORDER BY COUNT(PART_NUM) DESC, PART_MATERIAL ;
        
--Which part is never a child?
    --Which?
    SELECT PART_NUM
    FROM PARTS
    MINUS 
    SELECT CHILD_PART_NUM
    FROM PART_RELATIONSHIPS; 
    
    --How many of them?
    WITH not_child as (
    SELECT PART_NUM
    FROM PARTS
    MINUS 
    SELECT CHILD_PART_NUM
    FROM PART_RELATIONSHIPS
    )
    SELECT COUNT(*) FROM not_child; --28482 is never a child 

--Which part is never a parent?
    --Which?
    SELECT PART_NUM
    FROM PARTS
    MINUS 
    SELECT PARENT_PART_NUM
    FROM PART_RELATIONSHIPS; 
    
    --How many of them?
    WITH not_parent as (
    SELECT PART_NUM
    FROM PARTS
    MINUS 
    SELECT PARENT_PART_NUM
    FROM PART_RELATIONSHIPS
    )
    SELECT COUNT(*) FROM not_parent; --54528 is never a parent 

--Which part is nor a child nor a parent?
    --Which?
    SELECT PART_NUM
    FROM PARTS
    MINUS 
    SELECT PARENT_PART_NUM
    FROM PART_RELATIONSHIPS
    MINUS 
    SELECT CHILD_PART_NUM
    FROM PART_RELATIONSHIPS; 
    
    --How many of them?
    WITH not_child_not_parent as (
    SELECT PART_NUM
    FROM PARTS
    MINUS 
    SELECT PARENT_PART_NUM
    FROM PART_RELATIONSHIPS
    MINUS 
    SELECT CHILD_PART_NUM
    FROM PART_RELATIONSHIPS
    )
    SELECT COUNT(*) FROM not_child_not_parent; --25044 is never a parent 

-- Can one part name be produced in different materials?
    SELECT NAME, COUNT(DISTINCT PART_MATERIAL)
    FROM PARTS
    GROUP BY NAME
    HAVING COUNT(DISTINCT PART_MATERIAL)>1
    ORDER BY COUNT(DISTINCT PART_MATERIAL) DESC;
    --Yes, it can!
    
    --Does the category have impact on that fact?
    SELECT NAME, COUNT(DISTINCT PART_CAT_ID), COUNT(DISTINCT PART_MATERIAL)
    FROM PARTS
    GROUP BY NAME
    HAVING COUNT(DISTINCT PART_MATERIAL)>1
    ORDER BY COUNT(DISTINCT PART_MATERIAL) DESC;
        --From te results it can be seen that within the same category the part of the same name can be produced in multiple materials.



    
----------------------------------
---------- COLORS
----------------------------------



--Display preview
SELECT * FROM COLORS;

--Total number of rows
SELECT COUNT(*) FROM COLORS; --273 colors

--Check NULL values in columns
SELECT COUNT(*) FROM  COLORS WHERE ID IS NULL; --0
SELECT COUNT(*) FROM  COLORS WHERE NAME IS NULL; --0
SELECT COUNT(*) FROM  COLORS WHERE RGB IS NULL; --0
SELECT COUNT(*) FROM  COLORS WHERE IS_TRANS IS NULL; --0
SELECT COUNT(*) FROM  COLORS WHERE NUM_PARTS IS NULL; --0
SELECT COUNT(*) FROM  COLORS WHERE NUM_SETS IS NULL; --0
    --There are no null values in columns   
    
SELECT COUNT(*) FROM  COLORS WHERE Y1 IS NULL; --12
SELECT COUNT(*) FROM  COLORS WHERE Y2 IS NULL; --12
SELECT COUNT(*) FROM  COLORS WHERE Y1 IS NULL AND Y2 IS NULL; --12
SELECT COUNT(*) FROM  COLORS WHERE Y1 IS NULL OR Y2 IS NULL; --12
SELECT COUNT(*) FROM  COLORS WHERE Y1 IS NULL AND Y2 IS NOT NULL; --0
SELECT COUNT(*) FROM  COLORS WHERE Y1 IS NOT NULL AND Y2 IS NULL; --0
    --There are 12 colors that do not have values from when and until when they were in use.
    --Which are those?
    SELECT * 
    FROM COLORS 
    WHERE Y1 IS NULL AND Y2 IS NULL;
    
--Which columns have unique values?
    SELECT COUNT(*) FROM COLORS; --273
    
    --Id is primary key so it should be unique.
        SELECT COUNT(DISTINCT ID) 
        FROM COLORS; 
            --273 Yes, it is uniqe.
            
    --Is Name unique?
    SELECT COUNT(DISTINCT NAME) 
    FROM COLORS;  
        --273 Yes, it is uniqe.
        
     --How many RGBs there are?
    SELECT COUNT(DISTINCT RGB) 
    FROM COLORS;  
        --231!   
        --Which RGBs belong to multiple colors?
        SELECT RGB, COUNT(ID)
        FROM COLORS
        GROUP BY RGB
        HAVING COUNT(ID)>1
        ORDER BY COUNT(ID); 
        
         with RGB_multiple_colors as(
        SELECT RGB, COUNT(ID)
        FROM COLORS
        GROUP BY RGB
        HAVING COUNT(ID)>1
        ORDER BY COUNT(ID))
        SELECT COUNT(*) 
        FROM RGB_multiple_colors;
            --There are 32 of them.
        
        --Let's see what is going on with these colors.
        with RGB_multiple_colors as(
        SELECT RGB, COUNT(ID)
        FROM COLORS
        GROUP BY RGB
        HAVING COUNT(ID)>1
        ORDER BY COUNT(ID))
        SELECT * 
        FROM COLORS 
        WHERE RGB IN (SELECT RGB FROM RGB_multiple_colors)
        ORDER BY RGB;
            --There are multiple color names defined by the same RGB code but what about transparency how does that affect RGB?
            --RGBs with multiple transparency values
             with RGB_multiple_transp as(
            SELECT RGB, COUNT(distinct is_trans)
            FROM COLORS
            GROUP BY RGB
            HAVING COUNT(distinct is_trans)>1
            ORDER BY COUNT(distinct is_trans)
            )
            SELECT RGB FROM RGB_multiple_transp;  
            
             with RGB_multiple_transp as(
            SELECT RGB, COUNT(distinct is_trans)
            FROM COLORS
            GROUP BY RGB
            HAVING COUNT(distinct is_trans)>1
            ORDER BY COUNT(distinct is_trans)
            )
            SELECT COUNT(RGB) FROM RGB_multiple_transp;   --There is 6 of them.
                
                
        --Let's see if there are any RGBs that belong to multiple colors and have more transparency values
         with RGB_multiple_transp as(
        SELECT RGB, COUNT(distinct is_trans)
        FROM COLORS
        GROUP BY RGB
        HAVING COUNT(distinct is_trans)>1
        ORDER BY COUNT(distinct is_trans)
        ),
        all_RGB_multiple_transp as ( 
        SELECT RGB FROM RGB_multiple_transp
        ),
        RGB_multiple_colors as(
        SELECT RGB, COUNT(ID)
        FROM COLORS
        GROUP BY RGB
        HAVING COUNT(ID)>1
        ORDER BY COUNT(ID)
        ),
        all_RGB_multiple_colors as (
        SELECT RGB
        FROM COLORS 
        WHERE RGB IN (SELECT RGB FROM RGB_multiple_colors)
        ORDER BY RGB
        ),
        RGB_multiple_variabile_trans AS (
        SELECT * FROM (
        select * FROM all_RGB_multiple_colors
        INTERSECT                                   -- MINUS -> show that all RGBs from all_RGB_multiple_transp are within the all_RGB_multiple_colors
        SELECT * FROM all_RGB_multiple_transp)
        )
        SELECT DISTINCT RGB, IS_TRANS , NAME, ID
        FROM COLORS 
        WHERE RGB IN (SELECT * FROM RGB_multiple_variabile_trans) 
        ORDER BY RGB, IS_TRANS , NAME, ID;    
         --There are RGBs that have the same transparency type but name is what makes the difference.
         --Is (RGB, IS_TRANS, NAME) UNIQUE?
         
         with unique_triple as(
         SELECT DISTINCT RGB, is_trans, NAME
         FROM COLORS
         )
         select count(*) from unique_triple; --273
         
          select count(*) from colors; --273
         --Yes, a triple is (RGB, IS_TRANS, NAME).  
        
        with unique_pair as(
         SELECT DISTINCT RGB, is_trans
         FROM COLORS
         )
         select count(*) from unique_pair; --237 
         --No, pair is not unique.
         
         --Name is unique so these result pairs should result as uniques.
         with unique_pair as(
         SELECT DISTINCT RGB, NAME
         FROM COLORS
         )
         select count(*) from unique_pair; --273
         --Yes, unique pair (RGB, NAME). 
         
         with unique_pair as(
         SELECT DISTINCT IS_TRANS, NAME
         FROM COLORS
         )
         select count(*) from unique_pair; --273
         --Yes, unique pair (RGB, NAME). 
         
         --So, since Name is Unique it is the only column that can be used instead of ID.
         
--Which color has the most numbers of parts?

SELECT ID, NAME, NUM_PARTS
FROM COLORS
ORDER BY NUM_PARTS DESC, ID, NAME ;
         
--Which color has the most numbers of sets?

SELECT ID, NAME, NUM_SETS
FROM COLORS
ORDER BY NUM_PARTS DESC, ID, NAME ;        

--Which color was valid in which year. Make a list!
    
    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    )
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2);
        
    --How much colors were there per each year? 
    --from the most valid color to the least
      with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT history_range, COUNT(ID)
    FROM history_range_years_all_colors
    GROUP BY history_range
    ORDER BY COUNT(ID) DESC, history_range;
    
    
    --from last year towards the starting one
      with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT history_range, COUNT(ID) num_of_colors
    FROM history_range_years_all_colors
    GROUP BY history_range
    ORDER BY history_range DESC, COUNT(ID) ;
    
    --What is the min, max, avg, med, stddev number of colors per year
       with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    ),
    num_of_colors_per_history_range as (
    SELECT history_range, COUNT(ID) as num_of_colors
    FROM history_range_years_all_colors
    GROUP BY history_range
    ORDER BY history_range DESC, COUNT(ID)
    )
    SELECT ROUND(AVG(num_of_colors)), MEDIAN(num_of_colors), MIN(num_of_colors), MAX(num_of_colors), ROUND(VARIANCE(num_of_colors)), ROUND(STDDEV(num_of_colors))
    FROM num_of_colors_per_history_range;
    
    --Is there a year that had no colors?
     
    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT history_range
    FROM history_range_years
    MINUS
    SELECT DISTINCT history_range
    FROM history_range_years_all_colors; 
        --No, there isn't. Every year had some valid colors.
        
    --How many colors are there available this year?
          with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT history_range, COUNT(ID)
    FROM history_range_years_all_colors
    where history_range = 2025
    GROUP BY history_range
    ORDER BY COUNT(ID) DESC, history_range;
    --79
    
--There is a list of years and which colors were valid in which year. 
--Now, lets turn the script arround.
--Let's make a list of all the colors with years from/to not NULL and see which ones were the most used ones!

    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    years_and_colors as (
    SELECT hry.history_range, c.NAME, c.ID
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT ID, NAME, COUNT(history_range)
    FROM years_and_colors
    GROUP BY ID, NAME
    ORDER BY COUNT(history_range) DESC;
    --max number of years is 77 and there are 6 of them : White, Bright Green, Yellow, Green, Blue, Red
    
    -- What was happening with colors based on their transparency through the years?
    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    years_and_colors as (
    SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT ID, NAME, IS_TRANS, COUNT(history_range)
    FROM years_and_colors
    GROUP BY ID, NAME, IS_TRANS
    ORDER BY COUNT(history_range) DESC;
    --Those first top 6 colors are all non tranparent colors.
    --But let's turn back around and count colors per year depending on their transparency.
    
          with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
    )
    SELECT history_range,IS_TRANS, COUNT(ID) num_of_colors
    FROM history_range_years_all_colors
    GROUP BY history_range, IS_TRANS
    ORDER BY history_range DESC,IS_TRANS, COUNT(ID) ;   
    --When LEGO was founded for the first few years transparent colors were not used at all. But as the years went by number of both categories started to rise. 
    --Non transparent ones are still the leaders.
    
    --Let's see the statistics per transparency.
            --Transparent ones
            
            with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
            ),
            history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
            ),
            history_range_years_all_colors as (
            SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
            FROM history_range_years hry
            JOIN COLORS c
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
            ),
            num_of_colors_transp_history_range as(
            SELECT history_range,IS_TRANS, COUNT(ID) num_of_colors
            FROM history_range_years_all_colors
            WHERE IS_TRANS = 'True'
            GROUP BY history_range, IS_TRANS
            ORDER BY history_range DESC,IS_TRANS, COUNT(ID)
            )
            SELECT ROUND(AVG(num_of_colors)), round(MEDIAN(num_of_colors)), MIN(num_of_colors), MAX(num_of_colors), ROUND(VARIANCE(num_of_colors)), ROUND(STDDEV(num_of_colors))
            FROM num_of_colors_transp_history_range;
            
           --Non-transparent ones
            
            with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
            ),
            history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
            ),
            history_range_years_all_colors as (
            SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
            FROM history_range_years hry
            JOIN COLORS c
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM c.Y1) and EXTRACT(YEAR FROM c.Y2)
            ),
            num_of_colors_transp_history_range as(
            SELECT history_range,IS_TRANS, COUNT(ID) num_of_colors
            FROM history_range_years_all_colors
            WHERE IS_TRANS = 'False'
            GROUP BY history_range, IS_TRANS
            ORDER BY history_range DESC,IS_TRANS, COUNT(ID)
            )
            SELECT ROUND(AVG(num_of_colors)), round(MEDIAN(num_of_colors)), MIN(num_of_colors), MAX(num_of_colors), ROUND(VARIANCE(num_of_colors)), ROUND(STDDEV(num_of_colors))
            FROM num_of_colors_transp_history_range;

--Which colors are the ones implemented this year. Which ones are the newest ones?

SELECT NAME 
FROM COLORS
WHERE EXTRACT(YEAR FROM Y1)=2025;
--Just one color named Ochre Yellow is new added to the colors palette in 2025.

--What is the number of colors implemented on each year? Which ones are those?
    --Which ones?
    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range = EXTRACT(YEAR FROM c.Y1)
    )
    SELECT history_range, NAME
    FROM history_range_years_all_colors
    ORDER BY history_range;
    
    --How many of them per year were introduced?
    --all in chronological order
    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range = EXTRACT(YEAR FROM c.Y1)
    )
    SELECT history_range, count( NAME)
    FROM history_range_years_all_colors
    group by history_range
    ORDER BY history_range;
    
    --from the most new colors to the least per year
    with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range = EXTRACT(YEAR FROM c.Y1)
    )
    SELECT history_range, count( NAME)
    FROM history_range_years_all_colors
    group by history_range
    ORDER BY count( NAME)DESC, history_range;
    
    --Statistics on the new colors per year 
    
        with start_end_year as (
    SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
            EXTRACT(YEAR FROM MAX(Y2)) end_year
    FROM COLORS
    ),
    history_range_years as(
    SELECT start_year + level -1 as history_range
    FROM start_end_year
    CONNECT BY LEVEL <= end_year - start_year + 1
    ),
    history_range_years_all_colors as (
    SELECT hry.history_range, c.NAME, c.ID, c.IS_TRANS
    FROM history_range_years hry
    JOIN COLORS c
    ON hry.history_range = EXTRACT(YEAR FROM c.Y1)
    ),
    years_new_colors as(
    SELECT history_range, count( NAME) new_colors
    FROM history_range_years_all_colors
    group by history_range
    ORDER BY history_range
    )
    SELECT ROUND(AVG(new_colors)), round(MEDIAN(new_colors)), MIN(new_colors), MAX(new_colors), ROUND(VARIANCE(new_colors)), ROUND(STDDEV(new_colors))
    FROM years_new_colors;

    
----------------------------------
---------- ELEMENTS
----------------------------------
    

--Display preview
SELECT * FROM ELEMENTS;

--Total number of rows
SELECT COUNT(*) FROM ELEMENTS; --106760 different elements

--Check NULL values in columns
SELECT COUNT(*) FROM ELEMENTS WHERE ELEMENT_ID IS NULL; --0
SELECT COUNT(*) FROM ELEMENTS WHERE PART_NUM IS NULL; --0
SELECT COUNT(*) FROM ELEMENTS WHERE COLOR_ID IS NULL; --0
    --There are no null values in columns   
    
--From the ER schema and by the style of the column name Design_id there is assumption that that column is used as foreign key to refrence ID column of "Design" table.
SELECT COUNT(*) FROM ELEMENTS WHERE DESIGN_ID IS NULL; --20932
--But, results implicate that column has some NULL values so that means that the style is not defined for some element.
SELECT COUNT(DISTINCT DESIGN_ID) FROM ELEMENTS ; --32681 not null ones

--Since ER Schema is more concentrated on other columns Desing_ID won't be taken into consideration.

--Every PART_NUM can be produced in multiple colors? If so, how many of them and which those are through the history?

    SELECT PART_NUM, COUNT(DISTINCT COLOR_ID)
    FROM ELEMENTS
    GROUP BY PART_NUM
    ORDER BY COUNT(DISTINCT COLOR_ID) DESC, PART_NUM;
    --Result of all the colors that the part was produced througout the whole history.
    
    --If we join with Color table, also there is a possibility to check which year had how may colors for the specific part_num.

--Multiple parts can be produced in the same color. Which color has how many parts produced? Which one is the most popular?

    SELECT COLOR_ID, COUNT(DISTINCT PART_NUM)
    FROM ELEMENTS
    GROUP BY COLOR_ID
    ORDER BY COUNT(DISTINCT PART_NUM) DESC;
    --This is the result through the througout the whole history time. 
    
    --If we join with Color table, also there is a possibility to check which year had how may part_num for the specific color.
    

 
----------------------------------
---------- INVENTORY_PARTS
----------------------------------


--Display preview
SELECT * FROM INVENTORY_PARTS;

--Total number of rows
SELECT COUNT(*) FROM INVENTORY_PARTS; --1430956

--Check NULL values in columns
SELECT COUNT(*) FROM INVENTORY_PARTS WHERE INVENTORY_ID IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_PARTS WHERE PART_NUM IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_PARTS WHERE COLOR_ID IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_PARTS WHERE QUANTITY IS NULL; --0
SELECT COUNT(*) FROM INVENTORY_PARTS WHERE IS_SPARE IS NULL; --0

    --There are no null values in columns   
SELECT COUNT(*) FROM INVENTORY_PARTS WHERE IMG_URL IS NULL; --6915 missing images of the parts in specific color.

--Inventory has spare parts and originals. How much of each group there is?

SELECT IS_SPARE, COUNT(*)
FROM INVENTORY_PARTS
GROUP BY IS_SPARE;
    --True: 99484   False: 1331472

--Can one (part, color) be an original and a spare?
SELECT PART_NUM, color_id, COUNT(DISTINCT IS_SPARE)
FROM INVENTORY_PARTS
GROUP BY PART_NUM, color_id
HAVING COUNT(DISTINCT IS_SPARE)>1;
    --Yes, it can.

--Is there some inventory_id in Inventory_parts that is not in Inventories?

SELECT DISTINCT INVENTORY_ID 
FROM INVENTORY_PARTS
MINUS
SELECT ID
FROM INVENTORIES;
    --No, there isn't.

--Some colors do not have defined years from/until they are valid. 
--This way this is a control to see if there is any color_id included in Inventory_parts that does not have value like NULL.
SELECT DISTINCT COLOR_ID FROM INVENTORY_PARTS
INTERSECT
SELECT DISTINCT ID FROM COLORS WHERE Y1 IS NULL OR Y2 IS NULL;
--Intersect is empty so that means that there are no colors in Inventory_part without timeframe.
    
--Inside one inventory there is the same (part, color) but it has difFerent meaning - one is original,and other is reserve. 
SELECT INVENTORY_ID, PART_NUM, COLOR_ID, COUNT (DISTINCT IS_SPARE)
FROM INVENTORY_PARTS
GROUP BY INVENTORY_ID, PART_NUM, COLOR_ID
HAVING COUNT (DISTINCT IS_SPARE) >1
ORDER BY INVENTORY_ID, PART_NUM, COLOR_ID;
    --But that still makes it the same product in the inventory so let's see which product is in which inventory
    SELECT INVENTORY_ID, PART_NUM, COLOR_ID
    FROM INVENTORY_PARTS
    ORDER BY INVENTORY_ID, PART_NUM, COLOR_ID;
    
    --The IMG_URL is the same no matter if it is the part+color is spare or not. IMG_url and QUANTITY is defined by (PART_NUM, COLOR_ID)
    --So, IF IT IS NOT IMPORTANT what spare role is the part in the inventory then just by the combination of (part_num, color_id) we can count how many parts is in each inventory
   --How many parts+color are there is each inventory
    SELECT  INVENTORY_ID, count( distinct PART_NUM ||' - ' || COLOR_ID ) AS count_part_in_color --i have to put distinct because is_spare doubles the rows of the parts in the same color
    FROM INVENTORY_PARTS
    GROUP BY INVENTORY_ID
    ORDER BY count_part_in_color DESC, INVENTORY_ID;




