/*
    2.
    Lego blocks ship under multiple themes. 
    Let us try to get a sense of how the number of themes shipped has varied over the years. 
    Get the number of unique themes released in 1999.
*/

--SOLUTION:
--There are plenty of LEGO themes. Each theme is consisted of one or more Lego sets (blocks). 

--Currently in registry there are 482 themes. Theme name is not unique. The only unique value is ID. (Hint: More detailed insight in Escape Room chapter.)
SELECT COUNT(DISTINCT ID) FROM THEMES; --482
SELECT COUNT(DISTINCT NAME) FROM THEMES; --414

--Every set belongs to some theme. One theme has multiple sets, but one set is tied only to one theme by its SET_NUM.
 --This is a list of themes with the number of sets created for that theme per year.
 SELECT s.THEME_ID,t.name, EXTRACT (YEAR FROM YEAR) YEAR_SET_CREATED, COUNT(DISTINCT SET_NUM)
 FROM SETS s
 join THEMES t
 ON s.theme_id = t.id 
 GROUP BY THEME_ID,t.name, EXTRACT (YEAR FROM YEAR)
 ORDER BY  THEME_ID,t.name, YEAR_SET_CREATED;
 
--This is a list of themes that were in use per year. -> If a set for some theme_id was created then that means that the theme was actively in use on the year the set was created.
 SELECT DISTINCT EXTRACT (YEAR FROM YEAR) YEAR_SET_CREATED, s.THEME_ID, t.name
 FROM SETS s
 join THEMES t
 ON s.theme_id = t.id 
 ORDER BY  YEAR_SET_CREATED, THEME_ID ;
 
--Which theme had the most sets released over the years? Show the list of all of them before answering.

SELECT s.THEME_ID,t.name, COUNT(DISTINCT SET_NUM) num_of_sets_created
 FROM SETS s
 join THEMES t
 ON s.theme_id = t.id 
 GROUP BY THEME_ID,t.name
 ORDER BY  num_of_sets_created DESC ,THEME_ID,t.name;
 
 
SELECT s.THEME_ID,t.name, COUNT(DISTINCT SET_NUM) num_of_sets_created
 FROM SETS s
 join THEMES t
 ON s.theme_id = t.id 
 GROUP BY THEME_ID,t.name
 ORDER BY  num_of_sets_created DESC ,THEME_ID,t.name
 FETCH FIRST 1 ROW ONLY; --158	Star Wars	993
 
 
 
 

    --Number of themes that were in use per year
     SELECT DISTINCT EXTRACT (YEAR FROM YEAR) YEAR_SET_CREATED, count(distinct THEME_ID) num_of_theme_id
     FROM SETS
     group BY  EXTRACT (YEAR FROM YEAR)
     ORDER BY  YEAR_SET_CREATED;
 
--List of themes that were introduced in each year

    SELECT  s.THEME_ID,t.name, MIN(EXTRACT (YEAR FROM YEAR)) START_YEAR -- the earliest year when theme appeared aka when first set_num that belonged to the theme appeared
    FROM SETS s
     join THEMES t
    ON s.theme_id = t.id 
    GROUP BY s.THEME_ID,t.name
    ORDER BY START_YEAR, THEME_ID;

--Number of themes that were introduced in each year

    with year_when_theme_introduced as(
            SELECT  THEME_ID, MIN(EXTRACT (YEAR FROM YEAR)) START_YEAR -- the earliest year when theme appeared aka when first set_num that belonged to the theme appeared
            FROM SETS 
            GROUP BY THEME_ID
            ORDER BY START_YEAR, THEME_ID
        )
        
        SELECT START_YEAR, COUNT(THEME_ID)
        FROM year_when_theme_introduced
        GROUP BY  START_YEAR
        ORDER BY START_YEAR;
    
--Number of themes that were introduced in 1999

    with year_when_theme_introduced as(
            SELECT  THEME_ID, MIN(EXTRACT (YEAR FROM YEAR)) START_YEAR -- the earliest year when theme appeared aka when first set_num that belonged to the theme appeared
            FROM SETS  
            GROUP BY THEME_ID
            HAVING  MIN(EXTRACT (YEAR FROM YEAR)) = 1999 
            ORDER BY START_YEAR, THEME_ID
        )
        
        SELECT START_YEAR, COUNT(THEME_ID)
        FROM year_when_theme_introduced
        GROUP BY  START_YEAR
        ORDER BY START_YEAR; -- 13 ID'S 
        
        ----Their names
         with year_when_theme_introduced as(
            SELECT  THEME_ID, MIN(EXTRACT (YEAR FROM YEAR)) START_YEAR -- the earliest year when theme appeared aka when first set_num that belonged to the theme appeared
            FROM SETS  
            GROUP BY THEME_ID
            HAVING  MIN(EXTRACT (YEAR FROM YEAR)) = 1999 
            ORDER BY START_YEAR, THEME_ID
        )        
            SELECT theme_id, NAME
            FROM year_when_theme_introduced yw
            JOIN THEMES t
            ON yw.theme_id = t.id
            ORDER BY  NAME; -- 12 Names - > Star Wars has two ID's
    

    
--Another way to 1999 : 
 --Get the number of unique themes released in 1999.
        --This is a list of all of them. Name is not a unique column so ID has to be taken in result!!
         SELECT ID, NAME 
         FROM THEMES 
         WHERE ID IN (select DISTINCT THEME_ID
                     FROM SETS
                     WHERE EXTRACT(YEAR FROM YEAR) = 1999  -- all themes used in 1999
                     AND THEME_ID NOT IN (   SELECT DISTINCT THEME_ID
                                             FROM SETS
                                             WHERE EXTRACT(YEAR FROM YEAR) < 1999 ) ---all themes that have appeared before 1999
                     );
                     
        --Number of distinct themes -> by ID! : 
            with themes_id_name as (
                SELECT ID, NAME 
                 FROM THEMES 
                 WHERE ID IN (select DISTINCT THEME_ID
                             FROM SETS
                             WHERE EXTRACT(YEAR FROM YEAR) = 1999  -- all themes in 1999
                             AND THEME_ID NOT IN (   SELECT DISTINCT THEME_ID
                                                     FROM SETS
                                                     WHERE EXTRACT(YEAR FROM YEAR) < 1999 ) ---all themes that have appeared before 1999
                             )
            )
            SELECT COUNT(ID) FROM themes_id_name; --13 -> Star Wars has 2 ID's;
                  
        --***If we just want names:
            SELECT DISTINCT NAME 
             FROM THEMES 
             WHERE ID IN (select DISTINCT THEME_ID
                         FROM SETS
                         WHERE EXTRACT(YEAR FROM YEAR) = 1999  -- all themes in 1999
                         AND THEME_ID NOT IN (   SELECT DISTINCT THEME_ID
                                                 FROM SETS
                                                 WHERE EXTRACT(YEAR FROM YEAR) < 1999 ) ---all themes that have appeared before 1999
                         );
        --***Number if we just want names:
        --Number of distinct themes -> by NAMES : 
            with themes_id_name as (
                SELECT DISTINCT ID, NAME 
                 FROM THEMES 
                 WHERE ID IN (select DISTINCT THEME_ID
                             FROM SETS
                             WHERE EXTRACT(YEAR FROM YEAR) = 1999  -- all themes in 1999
                             AND THEME_ID NOT IN (   SELECT DISTINCT THEME_ID
                                                     FROM SETS
                                                     WHERE EXTRACT(YEAR FROM YEAR) < 1999 ) ---all themes that have appeared before 1999
                             )
            )
            SELECT COUNT(distinct NAME) FROM themes_id_name; --12

 
-- Is there a theme in themes registry that doesn't have any set in Sets?

SELECT ID, NAME 
FROM THEMES 
WHERE ID IN ( SELECT ID 
                FROM THEMES
                MINUS
                SELECT DISTINCT THEME_ID
                FROM SETS);

SELECT COUNT(DISTINCT ID) FROM THEMES; --482
SELECT COUNT(DISTINCT NAME) FROM THEMES;--414

select count(*) from sets; --25669
select set_num from sets where theme_id is null;

--statistics 
with statistics as (SELECT s.THEME_ID,t.name, COUNT(DISTINCT SET_NUM) num_of_sets_created
                                                             FROM SETS s
                                                             join THEMES t
                                                             ON s.theme_id = t.id 
                                                             GROUP BY THEME_ID,t.name
                                                             ORDER BY  num_of_sets_created DESC ,THEME_ID,t.name)
                                                             SELECT ROUND(AVG(num_of_sets_created)), MEDIAN(num_of_sets_created), MIN(num_of_sets_created), MAX(num_of_sets_created),ROUND(VARIANCE(num_of_sets_created),2), ROUND(STDDEV(num_of_sets_created),2)
                                                             FROM statistics
 
 
--statistics_num_of_themes_in_use_each_year 

with statistics as (SELECT DISTINCT EXTRACT (YEAR FROM YEAR) YEAR_SET_CREATED, count(distinct THEME_ID) num_of_theme_id
                                                 FROM SETS
                                                 group BY  EXTRACT (YEAR FROM YEAR)
                                                 ORDER BY  YEAR_SET_CREATED)
                                                 SELECT ROUND(AVG(num_of_theme_id)),ROUND(MEDIAN(num_of_theme_id)),MIN(num_of_theme_id), MAX(num_of_theme_id), ROUND(VARIANCE(num_of_theme_id),2), ROUND(STDDEV(num_of_theme_id),2)
                                                 FROM statistics ;
 
 
 
 
 
 
 
 