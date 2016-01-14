-- This documents the efforts to create topologies for Setores Censitários (SC) (enumeration districts) of the Brazilian 2010 Census. 
-- The tests are run on the sectors of the state of Acre (AC), to later be extrapolated to the remaining 26 states. 
-- Bellow I include the queries and the output of each query as a comment. 

-- 0) Set up:
-- Enviroment: windows 10, 8gb laptop
select version();
-- "PostgreSQL 9.4.5, compiled by Visual C++ build 1800, 64-bit"
SELECT PostGIS_full_version();
-- "POSTGIS="2.2.1 r14555" GEOS="3.5.0-CAPI-1.9.0 r4090" PROJ="Rel. 4.9.1, 04 March 2015" GDAL="GDAL 2.0.1, released 2015/09/15 GDAL_DATA not found" LIBXML="2.7.8" LIBJSON="0.12" (core procs from "2.2.1dev r14494" need upgrade) TOPOLOGY (topology procs from "2 (...)"

-- Data preparation:
-- Source: ftp://geoftp.ibge.gov.br/malhas_digitais/censo_2010/setores_censitarios/ac/ac_setores_censitarios.zip 
-- Imported using PGAdmin point click (Plugin > PosGis Shapefile and DBF loader 2.2 > chose file > import)
SELECT UpdateGeometrySRID("12see250gc_sir",'geom',4674)

-- finding most common UTM zone
select utmzone(ST_Centroid(geom)), count(*)
FROM "12see250gc_sir"
group by utmzone(ST_Centroid(geom))
-- UTMzone;count
-- 32719;731
-- 32718;169

-- Separating multipolygons into single polygons (ST_Dump) and creating a geom reprojected to closest UTM zone. 
drop table temp_geom_ac;
CREATE table temp_geom_ac AS 
SELECT 	cd_geocodi as cod_set, gid, (ST_Dump(ST_MakeValid(geom))).path AS id_dump,
	(ST_Dump(ST_MakeValid(geom))).geom AS geom_dump,
	ST_Transform(  (ST_Dump(ST_MakeValid(geom))).geom  ,32719) AS geom_dump_utm  
FROM "12see250gc_sir";




--  1) Creating topology from UTM based geom (geom_dump_UTM) with 1m tolerance

SELECT topology.DropTopology('topo_AC');
SELECT topology.CreateTopology('topo_AC',32719);
SELECT topology.addtopogeometrycolumn('topo_AC', 'public','temp_geom_ac','tg_geom_dump_utm','POLYGON');
UPDATE temp_geom_ac SET tg_geom_dump_utm = toTopoGeom(ST_Force2D(geom_dump_utm),'topo_AC', 1, 1) ;
-- ERROR:  Spatial exception - geometry intersects edge 370
-- CONTEXT:  PL/pgSQL function totopogeom(geometry,topogeometry,double precision) line 111 at FOR over SELECT rows
-- PL/pgSQL function totopogeom(geometry,character varying,integer,double precision) line 89 at assignment

-- Comment: loading everything at once fails. Let's try to load one polygons at time:
DO $$DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM temp_geom_ac LOOP
    BEGIN
      UPDATE temp_geom_ac SET tg_geom_dump_utm = toTopoGeom(ST_Force2D(geom_dump_utm),'topo_AC', 1, 1) 
      WHERE gid= r.gid;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Loading of record % failed: %', r.gid, SQLERRM;
    END;
  END LOOP;
END$$;

-- WARNING:  Loading of record 334 failed: Spatial exception - geometry intersects edge 744
-- Query returned successfully with no result in 152160 ms.

-- 1 error. All polygons except 1 were interseted into the topology/topogeometry. 


--  2) Creating topology from UTM based geom (geom_dump_UTM) without toleranec parameter

SELECT topology.DropTopology('topo_AC2');
SELECT topology.CreateTopology('topo_AC2',32719);
SELECT topology.addtopogeometrycolumn('topo_AC2', 'public','temp_geom_ac','tg_geom_dump_utm2','POLYGON');
UPDATE temp_geom_ac SET tg_geom_dump_utm2 = toTopoGeom(ST_Force2D(geom_dump_utm),'topo_AC2', 1) ;
-- ERROR:  SQL/MM Spatial exception - geometry crosses edge 474
-- CONTEXT:  PL/pgSQL function totopogeom(geometry,topogeometry,double precision) line 111 at FOR over SELECT rows
-- PL/pgSQL function totopogeom(geometry,character varying,integer,double precision) line 89 at assignment

-- Comment: loading everything at once fails. Let's try to load one polygons at time:
DO $$DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM temp_geom_ac LOOP
    BEGIN
      UPDATE temp_geom_ac SET tg_geom_dump_utm2 = toTopoGeom(ST_Force2D(geom_dump_utm),'topo_AC2', 1) 
      WHERE gid= r.gid;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Loading of record % failed: %', r.gid, SQLERRM;
    END;
  END LOOP;
END$$;

/*
WARNING:  Loading of record 123 failed: SQL/MM Spatial exception - geometry crosses edge 2019
WARNING:  Loading of record 268 failed: SQL/MM Spatial exception - geometry crosses edge 3691
Query returned successfully with no result in 158905 ms.
*/

--  3) Creating topology based on original geom (srid ) with 0.00001 tolerance parameter

ALTER TABLE temp_geom_ac DROP COLUMN tg_geom_dump

SELECT topology.DropTopology('topo_AC3');
SELECT topology.CreateTopology('topo_AC3',4674);
SELECT topology.addtopogeometrycolumn('topo_AC3', 'public','temp_geom_ac','tg_geom_dump','POLYGON');
UPDATE temp_geom_ac SET tg_geom_dump = toTopoGeom(ST_Force2D(geom_dump),'topo_AC3', 1, 0.00001) ;
-- ERROR:  Spatial exception - geometry intersects edge 208
-- CONTEXT:  PL/pgSQL function totopogeom(geometry,topogeometry,double precision) line 111 at FOR over SELECT rows
-- PL/pgSQL function totopogeom(geometry,character varying,integer,double precision) line 89 at assignment

-- Comment: loading everything at once fails. Let's try to load one polygons at time:
DO $$DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM temp_geom_ac LOOP
    BEGIN
      UPDATE temp_geom_ac SET tg_geom_dump = toTopoGeom(ST_Force2D(geom_dump),'topo_AC3', 1, 0.00001) 
      WHERE gid= r.gid;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Loading of record % failed: %', r.gid, SQLERRM;
    END;
  END LOOP;
END$$;

-- WARNING:  Loading of record 334 failed: Spatial exception - geometry intersects edge 420
-- WARNING:  Loading of record 287 failed: Spatial exception - geometry intersects edge 785
-- Query returned successfully with no result in 151231 ms.



--  4) Creating topology based on original geom (srid ) without tolerance parameter


--update table  drop column tg_geom_dump2

SELECT topology.DropTopology('topo_AC4');
SELECT topology.CreateTopology('topo_AC4',4674);
SELECT topology.addtopogeometrycolumn('topo_AC4', 'public','temp_geom_ac','tg_geom_dump2','POLYGON');
UPDATE temp_geom_ac SET tg_geom_dump2 = toTopoGeom(ST_Force2D(geom_dump),'topo_AC4', 1 ) ;
-- ERROR:  SQL/MM Spatial exception - point not on edge
-- CONTEXT:  PL/pgSQL function totopogeom(geometry,topogeometry,double precision) line 111 at FOR over SELECT rows
-- PL/pgSQL function totopogeom(geometry,character varying,integer,double precision) line 89 at assignment


-- Comment: loading everything at once fails. Let's try to load one polygons at time:
DO $$DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM temp_geom_ac LOOP
    BEGIN
      UPDATE temp_geom_ac SET tg_geom_dump = toTopoGeom(ST_Force2D(geom_dump),'topo_AC4', 1 ) 
      WHERE gid= r.gid;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Loading of record % failed: %', r.gid, SQLERRM;
    END;
  END LOOP;
END$$;


/*
WARNING:  Loading of record 8 failed: new row for relation "temp_geom_ac" violates check constraint "check_topogeom_tg_geom_dump"
WARNING:  Loading of record 12 failed: new row for relation "temp_geom_ac" violates check constraint "check_topogeom_tg_geom_dump"
...
WARNING:  Loading of record 874 failed: new row for relation "temp_geom_ac" violates check constraint "check_topogeom_tg_geom_dump"
WARNING:  Loading of record 891 failed: new row for relation "temp_geom_ac" violates check constraint "check_topogeom_tg_geom_dump"

Query returned successfully with no result in 11457 ms.
*/
-- We get errors for all 900 polygons. (I ommited the full output above)

