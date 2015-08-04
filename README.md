# corrige_setor_censitario_2010
Scripts to correct topological problems in Enumeration Districts (Setores Censitários) of the 2010 Brazilian Census

## Data
(Setores Censitários)

Available from: ftp://geoftp.ibge.gov.br/malhas_digitais/censo_2010/setores_censitarios/
See [import_data](import_data.md.txt), on how to import it into Postgresql/Postgis.


Enumeration Districts  (ED) are smallest areas for which Brazilian Census data is available. The 2010 Census had 318 thousand EDs. 
Created to facilitate Census logistics, EDs defined as areas containing from 250 to 350 households in urban areas and 150 to 250 in rural areas, so that they can be surveyed by one of Census surveyor. 
To avoid double counting or ignoring households, EDs must divide the space in a topologically consistent manner, with no overlaps or gaps. 

While this is true for the census operations, the EDs digital representation, the shape files of Setores Censitários, do have topological problems. 

## Topological problems

We were able to identify 3 types of problems: 

1. Polygon self intersections.
![self_intersections](aux_data/ring_self_intersection.png)

2. "Islands", contained inside other polygons. In reality, polygon A is surrounded by polygon B. This is common for EDs of rural villages that are a created inside the area of a larger urban EDs. Or buildings with many apartments that are defined as separate EDs inside urban EDs.  
Polygon B should have a hole where polygon A is located. But it does not, the area of polygon A is also part of polygon B. 
![islands](aux_data/islands.png)

3. Border overlaps and gaps
![borderError1](aux_data/borderError1.png)
![borderError2](aux_data/borderError2.png)

Table 1 describes the relative frequency of these problems. Because of the sheer number of EDs, we need to automate, as much as possible, the correction of these topological problems. On the other hand, we don't want corrections that would introduce larger distortions in the polygons. 




