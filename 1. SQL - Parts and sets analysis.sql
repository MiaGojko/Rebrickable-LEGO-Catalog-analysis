/*
    1. 
    We have a comprehensive list of sets over the years and the number of 
    parts that each of these sets contained. What is the trend in the number of parts by years?
    
*/
---------------------------------------------------------------------------------------------------
/* RESULT table should look like year, set, number of parts_in_color per set


    - let's see which part+color is available in each year:
        In Colors table there is information from when until when each color was available.
        First, there will be a list created which color_id was available at what year.        
        Using that fact, each part in color will be defined when it was available.
*/
        
        --Number range of all years from the first one when the color existed until the last one
        
        with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
        ) ,
        history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
        )
        SELECT * FROM history_range_years;  --Range from 1949 until 2025 created
    
    
        --Now list of all the colors per year when they were available
        
                    with start_end_year as (
                        SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                                EXTRACT(YEAR FROM MAX(Y2)) end_year
                        FROM COLORS
                    ) ,
                    history_range_years as(
                        SELECT start_year + level -1 as history_range
                        FROM start_end_year
                        CONNECT BY LEVEL <= end_year - start_year + 1
                    ),
                    colors_per_year as (
                        SELECT history_range, c.ID color_id
                        FROM history_range_years hry
                        LEFT JOIN COLORS c
                        ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
                    )
                    SELECT *
                    FROM colors_per_year
                    ORDER BY history_range, color_id;
                    
                    --Is there a year with no colors?
                    
                     with start_end_year as (
                        SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                                EXTRACT(YEAR FROM MAX(Y2)) end_year
                        FROM COLORS
                    ) ,
                    history_range_years as(
                        SELECT start_year + level -1 as history_range
                        FROM start_end_year
                        CONNECT BY LEVEL <= end_year - start_year + 1
                    ),
                    colors_per_year as (
                        SELECT history_range, c.ID color_id
                        FROM history_range_years hry
                        LEFT JOIN COLORS c
                        ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
                    )
                    SELECT history_range
                    FROM colors_per_year
                    WHERE color_id is null;
                        --No, there isn't. All years have colors.
                        --So, it is okay to use JOIN isted of LEFT JOIN

     with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
        ) ,
        history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
        ),
        colors_per_year as (
            SELECT history_range, c.ID color_id
            FROM history_range_years hry
            JOIN COLORS c                               --CHANGED TO JOIN INSTED OF LEFT JOIN TO REDUCE MEMORY IN TABLESPACE
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
        )
        SELECT *
        FROM colors_per_year
        ORDER BY history_range, color_id;
        
    
    
    -- Since each available part is defined by color, to see when was each(part_num, color_id) available we will combine with colors_per_year
    -- Because from there we know in which years color was available so then the corresponding (part_num, color_id) was available too.
    
          with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
        ) ,
        history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
        ),
        colors_per_year as (
            SELECT history_range, c.ID color_id
            FROM history_range_years hry
            JOIN COLORS c                               
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
        )  
        SELECT DISTINCT ip.PART_NUM, ip.COLOR_ID, history_range year_color_available  --distinct because in Inventory_parts one (part_num, color_id) is available in multiple inventories
        FROM INVENTORY_PARTS ip
        JOIN colors_per_year cpy
        ON ip.color_id = cpy.color_id
        
    --Now we want to see which set was available in which year.
    --Each part+color belongs to some inventory or multiple inventories can contain it. One inventory can also contain the same part in multiple colors. Each inventory is defined by set_num and version.
    --Now we will see for which inventory had which par_num+color_id in which year on stock
    --To see which set was active when we will combine previous result with Inventories table
    
     with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
        ) ,
        history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
        ),
        colors_per_year as (
            SELECT history_range, c.ID color_id
            FROM history_range_years hry
            JOIN COLORS c                               
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
        ),
        part_in_color_per_year as(
        SELECT DISTINCT ip.PART_NUM, ip.COLOR_ID, history_range year_color_available
        FROM INVENTORY_PARTS ip
        JOIN colors_per_year cpy
        ON ip.color_id = cpy.color_id
        )
        SELECT ip.INVENTORY_ID, pcpy.YEAR_COLOR_AVAILABLE, pcpy.PART_NUM, pcpy.COLOR_ID
        FROM part_in_color_per_year pcpy
        JOIN Inventory_parts ip
        ON pcpy.part_num = ip.part_num and pcpy.color_id = ip.color_id
        ORDER BY ip.INVENTORY_ID, pcpy.YEAR_COLOR_AVAILABLE, pcpy.PART_NUM, pcpy.COLOR_ID;
    
  --We need to get to the point to be able to say which set was available in which year.
  --If inventory id is available that means that the Set_num from Inventories_sets is also available in that time
  
  
         with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
        ) ,
        history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
        ),
        colors_per_year as (
            SELECT history_range, c.ID color_id
            FROM history_range_years hry
            JOIN COLORS c                               
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
        ),
        part_in_color_per_year as(
            SELECT DISTINCT ip.PART_NUM, ip.COLOR_ID, history_range year_color_available
            FROM INVENTORY_PARTS ip
            JOIN colors_per_year cpy
            ON ip.color_id = cpy.color_id
        )--,
       -- part_in_color_per_year_in_inventory as(
            SELECT ip.INVENTORY_ID, pcpy.YEAR_COLOR_AVAILABLE, pcpy.PART_NUM, pcpy.COLOR_ID
            FROM part_in_color_per_year pcpy
            JOIN Inventory_parts ip
            ON pcpy.part_num = ip.part_num and pcpy.color_id = ip.color_id ;
        
  
  
        --this code is very large so to reduce my memory tablespace i will insert all " with as " tables in one fixed table
        
        CREATE TABLE part_in_color_per_year_in_inventory (       
        INVENTORY_ID NUMBER , 
        YEAR_COLOR_AVAILABLE NUMBER, 
        PART_NUM VARCHAR2(20), 
        COLOR_ID NUMBER        
        );
        COMMIT;
        INSERT INTO part_in_color_per_year_in_inventory (       
        INVENTORY_ID  , 
        YEAR_COLOR_AVAILABLE , 
        PART_NUM , 
        COLOR_ID         
        )
          with start_end_year as (
            SELECT  EXTRACT(YEAR FROM MIN(Y1)) start_year,
                    EXTRACT(YEAR FROM MAX(Y2)) end_year
            FROM COLORS
        ) ,
        history_range_years as(
            SELECT start_year + level -1 as history_range
            FROM start_end_year
            CONNECT BY LEVEL <= end_year - start_year + 1
        ),
        colors_per_year as (
            SELECT history_range, c.ID color_id
            FROM history_range_years hry
            JOIN COLORS c                               
            ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2)         
        ),
        part_in_color_per_year as(
        SELECT DISTINCT ip.PART_NUM, ip.COLOR_ID, history_range year_color_available
        FROM INVENTORY_PARTS ip
        JOIN colors_per_year cpy
        ON ip.color_id = cpy.color_id
        )
        SELECT ip.INVENTORY_ID, pcpy.YEAR_COLOR_AVAILABLE, pcpy.PART_NUM, pcpy.COLOR_ID
        FROM part_in_color_per_year pcpy
        JOIN Inventory_parts ip
        ON pcpy.part_num = ip.part_num and pcpy.color_id = ip.color_id
        ORDER BY ip.INVENTORY_ID, pcpy.YEAR_COLOR_AVAILABLE, pcpy.PART_NUM, pcpy.COLOR_ID;
        COMMIT;
        
        --------------------------------------------
        ----TABLE CREATED
        ---------------------------------------------
        --Now we have information which (part_num, color_id) is available in each inventory_id in which year. If there are parts in color available in inventory that that means that inventory id is then active.
        
        --timespan when does each inventory_id has available parts
        SELECT DISTINCT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts
        FROM part_in_color_per_year_in_inventory
        ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE;
        
        -- How many inventories there are in a year that have parts available(in quantity)
        with inventory_active as (
            SELECT DISTINCT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts
            FROM part_in_color_per_year_in_inventory
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE)
        select year_inventory_id_has_available_parts, count(INVENTORY_ID)
        from inventory_active
        group by year_inventory_id_has_available_parts
        order by year_inventory_id_has_available_parts;
        --give statistics and graph
        
        --Now we have information which inventory_id is available which year and how many available distinct parts+color it is consisted of.
        
            SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE;
        
        --how many parts+color were available in each year for all inventories in that year?
        
        with inventory_year_num_of_parts as(
            SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            )
            SELECT year_inventory_id_has_available_parts, sum(num_of_parts_available_per_year)
            from inventory_year_num_of_parts
            group by year_inventory_id_has_available_parts
            order by year_inventory_id_has_available_parts,year_inventory_id_has_available_parts;
            
        
        
                
        --Based on inventory_id we can also see which sets were available in which year since set_num belongs to some inventory_id if they are available
        
        with year_inventory_id_available_part_num as (
             SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
        )
        SELECT yiia.* , invs.set_num
        FROM year_inventory_id_available_part_num yiia
        JOIN Inventory_sets invs
        ON yiia.inventory_id = invs.inventory_id
        ORDER BY yiia.INVENTORY_ID, year_inventory_id_has_available_parts, invs.SET_NUM ;
            --Now we got the list that shows per inventory id which year it had some available sets and how many distinct parts_in_colors were available
       
        --Let's do the same but talk from a set_num perspective
        
        with year_inventory_id_available_part_num as (
             SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts_id_available, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
        )
        SELECT invs.set_num, yiia.year_inventory_id_has_available_parts_id_available, yiia.INVENTORY_ID   , yiia. num_of_parts_available_per_year
        FROM year_inventory_id_available_part_num yiia
        JOIN Inventory_sets invs
        ON yiia.inventory_id = invs.inventory_id
        ORDER BY  invs.SET_NUM, year_inventory_id_has_available_parts_id_available,yiia.INVENTORY_ID, num_of_parts_available_per_year ;
            -- for the xx set_num in year_inventory_id_available when it was part of inventory_id yy inventory had num_of_parts_available_per_year on stock that could be used for set_num
            --one set in one year can be available within multiple inventories. depending on in which inventory is contained it can have sifferent number of available parts and those parts between inventories do no have to match but can
        
    --All removed rows when set_num didn't exist yet 
        
        with year_inventory_id_available_part_num as (
             SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
        ),
        year_inventory_set_num_num_parts_available as(
            SELECT yiia.* , invs.set_num
            FROM year_inventory_id_available_part_num yiia
            JOIN Inventory_sets invs
            ON yiia.inventory_id = invs.inventory_id
            ORDER BY yiia.INVENTORY_ID, year_inventory_id_has_available_parts, invs.SET_NUM 
        ) 
        SELECT pa.*, s.year  set_created
        FROM year_inventory_set_num_num_parts_available pa
        join Sets s
        ON pa.SET_NUM = s.SET_NUM
        WHERE  pa.year_inventory_id_has_available_parts >= EXTRACT(YEAR FROM s.year) ; -- need to remove all rows where set_num didn't exist yet
   
   
---  avg_each_year_num_of_parts_all_inventories
                    with inventory_year_num_of_parts as(
                                                            SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
                                                            FROM part_in_color_per_year_in_inventory
                                                            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
                                                            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
                                                            )
                                                            SELECT year_inventory_id_has_available_parts, round(avg(num_of_parts_available_per_year)) average_num_parts
                                                            from inventory_year_num_of_parts
                                                            group by year_inventory_id_has_available_parts
                                                            order by year_inventory_id_has_available_parts,year_inventory_id_has_available_parts;


   
   

   
   --Lets see what happens with number of parts available based on the sets in each year 
   
   with year_inventory_id_available_part_num as (
             SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
        ),
        year_inventory_set_num_num_parts_available as(
            SELECT yiia.* , invs.set_num
            FROM year_inventory_id_available_part_num yiia
            JOIN Inventory_sets invs
            ON yiia.inventory_id = invs.inventory_id
            ORDER BY yiia.INVENTORY_ID, year_inventory_id_has_available_parts, invs.SET_NUM 
        ) , 
        only_valid_year_inventory_set_num_num_parts_available as (
        SELECT pa.*, s.year  set_created
        FROM year_inventory_set_num_num_parts_available pa
        join Sets s
        ON pa.SET_NUM = s.SET_NUM
        WHERE  pa.year_inventory_id_has_available_parts >= EXTRACT(YEAR FROM s.year)
        )
        SELECT year_inventory_id_has_available_parts, 
        round(AVG(num_of_parts_available_per_year)) average_num_parts, 
        MIN(num_of_parts_available_per_year) minimum_num_parts, 
        MAX(num_of_parts_available_per_year) max_num_parts,
        ROUND(STDDEV(num_of_parts_available_per_year),2) stddev_num_parts
        FROM only_valid_year_inventory_set_num_num_parts_available
        GROUP BY year_inventory_id_has_available_parts
        ORDER BY year_inventory_id_has_available_parts;
   
           
        --RESULTS start from the 1969. 
        --That got me wondering weather is that okay, so I checked all set num that were able to get inventory_id num_of_parts if they are founded before 1969? 
        --It turns out they a not.
        
        SELECT MIN(YEAR) FROM SETS WHERE SET_NUM IN (
                                            SELECT DISTINCT SET_NUM 
                                            FROM INVENTORY_SETS 
                                            WHERE INVENTORY_ID IN (     select distinct inventory_id from inventory_parts
                                                                        intersect 
                                                                        select distinct inventory_id from inventory_sets  ) ) 
                                            ORDER BY YEAR 
        --The oldest set with available parts is created in 1969 so this is okay
   
   
   
    -- First year of the set_num when it was available in quantity > 0 
       
       with year_inventory_id_available_part_num as (
             SELECT INVENTORY_ID, YEAR_COLOR_AVAILABLE year_inventory_id_has_available_parts, COUNT(DISTINCT COLOR_ID ||' - '|| PART_NUM ) num_of_parts_available_per_year
            FROM part_in_color_per_year_in_inventory
            GROUP BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
            ORDER BY INVENTORY_ID, YEAR_COLOR_AVAILABLE
        ),
        year_inventory_set_num_num_parts_available as(
            SELECT yiia.* , invs.set_num
            FROM year_inventory_id_available_part_num yiia
            JOIN Inventory_sets invs
            ON yiia.inventory_id = invs.inventory_id
            ORDER BY yiia.INVENTORY_ID, year_inventory_id_has_available_parts, invs.SET_NUM 
        ), 
        inventory_active_vs_set_num_year as(
        SELECT pa.*, s.year year_set_created
        FROM year_inventory_set_num_num_parts_available pa
        join Sets s
        ON pa.SET_NUM = s.SET_NUM
        WHERE  pa.year_inventory_id_has_available_parts >= EXTRACT(YEAR FROM s.year) 
       ), 
       years_compared as (
       SELECT set_num,  INVENTORY_ID , num_of_parts_available_per_year, CASE WHEN EXTRACT(YEAR FROM year_set_created) >= year_inventory_id_has_available_parts THEN EXTRACT(YEAR FROM year_set_created) ELSE year_inventory_id_has_available_parts END  FIRST_YEAR_INTRODUCED_QUANTITY
       FROM inventory_active_vs_set_num_year
       ),
       starting_year_for_the_set_in_inventory as (
       SELECT SET_NUM, INVENTORY_ID,num_of_parts_available_per_year, MIN(FIRST_YEAR_INTRODUCED_QUANTITY)  Starting_year
       FROM years_compared
       GROUP BY SET_NUM, INVENTORY_ID,num_of_parts_available_per_year
       ORDER BY Starting_year, num_of_parts_available_per_year, SET_NUM, INVENTORY_ID
       )
       select Starting_year, COUNT(*)
       FROM starting_year_for_the_set_in_inventory
       GROUP BY Starting_year
       ORDER BY Starting_year;
       
     
    
     
     
     
