/*
    3.
    How many distinct colors are available? What can you tell us about how 
    the color scheme changed over the years? Is there any theme with a single color scheme?
*/


-- How many distinct colors are available? 
    SELECT COUNT(ID) -- id is primary key
    FROM COLORS; 
        --There are 273 colors available in colors registry
        
-- What can you tell us about how the color scheme changed over the years?

    --Let's create a list of years from the oldest year when some color appeared until the newest one.
    
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
        SELECT * FROM history_range_years; -- Range from 1949 until 2025
        
    --Which color was available to use in which year?
            
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
                SELECT history_range, c.ID color_id
                FROM history_range_years hry
                JOIN COLORS c                             
                ON hry.history_range BETWEEN EXTRACT(YEAR FROM Y1) AND EXTRACT(YEAR FROM Y2);
                
    --Which colors were used the most through the years?
        
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
            num_of_years_color as(
            SELECT COLOR_ID, COUNT(history_range) num_of_years_for_color
            FROM colors_per_year
            GROUP BY COLOR_ID
            ORDER BY num_of_years_for_color desc, color_id
            )
            SELECT nyc.num_of_years_for_color, c.* 
            FROM num_of_years_color nyc
            JOIN Colors c
            ON nyc.color_id = c.id
            where num_of_years_for_color = (SELECT MAX(num_of_years_for_color) FROM num_of_years_color);
    
                
    --Number of colors available to use in each year    
    
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
            SELECT history_range, COUNT(color_id) num_of_colors_per_year
            FROM colors_per_year
            GROUP BY history_range
            ORDER BY history_range;
            
        -- Transparency for colors available to use in each year ?   
    
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
            SELECT history_range,IS_TRANS, COUNT(color_id) num_of_colors_per_year
            FROM colors_per_year cpy
            JOIN Colors c 
            ON cpy.color_id =c.id
            GROUP BY history_range, IS_TRANS
            ORDER BY history_range,IS_TRANS, num_of_colors_per_year ;
    
    --Which color was introduced in which year?
            
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
            SELECT color_id, MIN(history_range)  implementation_year
            FROM colors_per_year
            GROUP BY color_id
            ORDER BY implementation_year, color_id;
     
                 
    --How many colors were introduced in which year?
    
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
            implemented_colors_per_year as (
            SELECT color_id, MIN(history_range)  implementation_year
            FROM colors_per_year
            GROUP BY color_id
            ORDER BY implementation_year, color_id
            )
            SELECT implementation_year, COUNT(COLOR_ID) num_of_new_colors
            FROM implemented_colors_per_year
            GROUP BY implementation_year 
            ORDER BY implementation_year, num_of_new_colors;
      
          --Transparency in new colors?
          
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
            implemented_colors_per_year as (
            SELECT color_id, MIN(history_range)  implementation_year
            FROM colors_per_year
            GROUP BY color_id
            ORDER BY implementation_year, color_id
            )
            SELECT implementation_year, IS_TRANS, COUNT(COLOR_ID) num_of_new_colors
            FROM implemented_colors_per_year cpy
            JOIN Colors c 
            ON cpy.color_id =c.id
            GROUP BY implementation_year, IS_TRANS 
            ORDER BY implementation_year,IS_TRANS, num_of_new_colors;
      
            
      --Which color is the most popular one for sets?
      
        SELECT * 
        FROM COLORS
        WHERE NUM_SETS IN (SELECT MAX(NUM_SETS) FROM COLORS); -- ID = 0 
                
     --Which color is the most popular one for parts?
      
        SELECT *
        FROM COLORS
        WHERE NUM_PARTS IN (SELECT MAX(NUM_PARTS) FROM COLORS); -- ID = 0 
        
   
   -- Which color was the most popular one for each year for parts in inventory?
   
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
        SELECT ycp.* , c.*
        FROM (
            SELECT year_color_available, COLOR_ID, count(PART_NUM) num_of_parts , RANK() OVER (PARTITION BY year_color_available ORDER BY count(PART_NUM) DESC ) RN
            from part_in_color_per_year
            group by year_color_available, COLOR_ID
            ) ycp
       JOIN COLORS c
       ON ycp.color_id = c.id
       WHERE RN =1 
       ORDER BY year_color_available; --In every year ID=15 ->15	White	FFFFFF	False	482729	141524	01-NOV-49	01-NOV-25
   

    ---- Which top 5 colors were the most popular ones for each year for parts in inventory?
   
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
        ),
        top5_col_per_year as(
        SELECT ycp.* , c.*
        FROM (
            SELECT year_color_available, COLOR_ID, count(PART_NUM) num_of_parts , RANK() OVER (PARTITION BY year_color_available ORDER BY count(PART_NUM) DESC ) RN
            from part_in_color_per_year
            group by year_color_available, COLOR_ID
            ) ycp
       JOIN COLORS c
       ON ycp.color_id = c.id
       WHERE RN <= 5 
       ORDER BY year_color_available, RN
       )
        SELECT RN, RN2, num_col_per_year,color_id, name
        FROM (
                SELECT RN, COLOR_ID, NAME, COUNT (year_color_available) num_col_per_year, RANK() OVER ( PARTITION BY RN ORDER BY  COUNT (year_color_available) DESC) RN2
                FROM top5_col_per_year
                GROUP BY  RN, COLOR_ID, NAME
            );
            --We have listed for each year top 5 colors per year.
            --Wanted to check throughout the history which colors are in rank 1,2,3,4,5 and how many times do they appear in that rank within the history range.
   
 
 --What can you tell us about how the color scheme changed over the years?   
    --tu dodaj zakljucak o ovome koliko ima boja novih po godini, kako raste ili pada spektar boja u skadu s time kako prolazi vrijeme
    
    
 --Is there any theme with a single color scheme?
    SELECT s.THEME_ID, t.NAME, COUNT(DISTINCT ip.COLOR_ID) AS num_colors
        FROM SETS s
        JOIN THEMES t ON s.THEME_ID = t.ID
        JOIN INVENTORIES i ON s.SET_NUM = i.SET_NUM
        JOIN INVENTORY_PARTS ip ON i.ID = ip.INVENTORY_ID    
        GROUP BY s.THEME_ID, t.NAME
        HAVING COUNT(DISTINCT ip.COLOR_ID) = 1
        ORDER BY t.NAME;
        --yes, there are 3 tables that have some all parts in just one color!
        --557	DFB Minifigures
        --241	Supplemental
        --559	Value Packs
        
        
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
                                                SELECT cpy.color_id,MIN(history_range)  implementation_year
                                                FROM colors_per_year cpy
                                                
                                                SELECT COUNT(*) FROM COLORS WHERE EXTRACT(YEAR FROM Y1)=1963;
                                        
                                                GROUP BY cpy.color_id
                                                ORDER BY implementation_year;
                                                

select * from colors where id = 9999;

select count(*) from inventory_parts where color_id = 9999;
    