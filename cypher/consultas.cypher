//creamos la base de datos (una vez creada debemos seleccionarla)
CREATE DATABASE peliculas;

// iniciar la base de datos
START DATABASE peliculas;

//cada pelicula debe tener un id unico
CREATE CONSTRAINT pelicula_id_unico IF NOT EXISTS
FOR (m:Pelicula) 
REQUIRE m.id IS UNIQUE;

//creacion de indice para pelicula
CREATE INDEX pelicula_titulo IF NOT EXISTS
FOR (p:Pelicula) ON (p.nombre);

// actor unico
CREATE CONSTRAINT unique_actor IF NOT EXISTS
FOR (a:Actor)
REQUIRE a.nombre IS UNIQUE


//cada director debe tener un id unico
CREATE CONSTRAINT director_id_unico IF NOT EXISTS
FOR (d:Director) 
REQUIRE d.nombre IS UNIQUE;


// año unico
CREATE CONSTRAINT unique_año IF NOT EXISTS
FOR (a:Año)
REQUIRE a.valor IS UNIQUE

// genero unico
CREATE CONSTRAINT genero_unico IF NOT EXISTS
FOR (g:Genero)
REQUIRE g.nombre IS UNIQUE

// creacion de los nodos pelicula,director y la relacion DIRIGIDA_POR 
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "
  WITH row
  MERGE (p:Pelicula {id: row.id})
  SET p.nombre = row.title
  MERGE (d:Director {nombre: trim(lower(row.director))})
  MERGE (p)-[:DIRIGIDA_POR]->(d)
  ",
  {batchSize: 1000, parallel: false}
);

// creacion de nodo actores y la relacion actuo_en
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "WITH row,split(row.cast, ',') AS actors
   UNWIND actors AS actorName
   MERGE (a:Actor {nombre: trim(lower(actorName))})
   WITH a,row
   MATCH(p:Pelicula {id: row.id}) 
   MERGE (p)<-[:ACTUO_EN]-(a)",
  {batchSize: 1000, parallel: FALSE}
);


// creacion de los nodos de año 
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "
  WITH toInteger(toFloat(row.year)) AS year
  WHERE year IS NOT NULL
  MERGE (:Año {valor: year})
  ",
  {batchSize: 1000, parallel: false}
);

// creacion de las relacion año de lanzamiento
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "
  WITH row, toInteger(toFloat(row.year)) AS year
  WHERE year IS NOT NULL
  MATCH (m:Pelicula {id: row.id})
  MATCH (a:Año {valor: year})
  MERGE (m)-[:LANZADA_EN]->(a)
  ",
  {batchSize: 1000, parallel: false}
);

// creacion de los nodos de genero, y las relaciones de la pelicula con cada genero
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "WITH row,split(row.genre, ',') AS genres
   UNWIND genres AS genre
   MERGE (g:Genero {nombre: trim(lower(genre))})
   WITH g,row
   MATCH(p:Pelicula {id: row.id}) 
   MERGE (g)<-[:PERTENECE_A]-(p)",
  {batchSize: 1000, parallel: false}
);


// 2) CONSULTAS DESTACADAS 

// para ver la perspectiva que nos ofrece el modelo de grafo, tenemos las siguientes consultas.

// peliculas en las que actuo un determinado actor ()
MATCH path=(a:Actor {name:'clint eastwood'})-[:ACTUO_EN]->(:Pelicula)
RETURN path;

//peliculas en las que el director tambien actuo
MATCH path=(a:Actor)-[:ACTUO_EN]->(:Pelicula)-[:DIRIGIDA_POR]->(d:Director)
WHERE a.nombre = d.nombre AND a.nombre <> ""
RETURN path;

// peliculas de clint eastwood donde es actor y director 
MATCH path=(:Actor {nombre:'clint eastwood'})-[:ACTUO_EN]->(:Pelicula)-[:DIRIGIDA_POR]->(:Director {nombre:'clint eastwood'})
RETURN path;

// peliculas que pertecenen a un genero especifico
MATCH (p:Pelicula)-[:PERTENECE_A]->(g:Genero{nombre:"western"})
RETURN p;

//peliculas de un determinado actor y que pertecenen a un genero especifico
MATCH path=(a:Actor {nombre:'sylvester stallone'})-[:ACTUO_EN]->(p:Pelicula)-[:PERTENECE_A]->(g:Genero {nombre:'action'})
RETURN path;


// 3) machine learning

// red de directores (en mi pc 16gb de RAM 8 nucleos se demoro unas 3 hr)
CALL apoc.periodic.iterate(
"
  MATCH (d1:Director)<-[:DIRIGIDA_POR]-(:Pelicula)<-[:ACTUO_EN]-(a:Actor)
        -[:ACTUO_EN]->(:Pelicula)-[:DIRIGIDA_POR]->(d2:Director)
  WHERE id(d1) < id(d2)
  RETURN DISTINCT d1, d2
",
"
  MERGE (d1)-[:ACTOR_EN_COMUN]->(d2)
",
  {batchSize: 500, parallel: false}
);

// para correr algoritmos sobre la red que definimos (red de directores del paso anterior)
// primero tenemos que proyectarla.Esto es simplemente cargarla en la memoria 
MATCH (source:Director)-[:ACTOR_EN_COMUN]-(target:Director)
WITH gds.graph.project('director_net', source, target, 
{
    sourceNodeLabels: labels(source),
    targetNodeLabels: labels(target)
  }) AS g
RETURN g.graphName AS graph, g.nodeCount AS nodes, g.relationshipCount AS rels

// una vez cargada nuestra 'director_net' ,vamos a ejecutar un algoritmo(pageRank) de la familia de algoritmos 
// de centralidad, que indica la importancia de un nodo dentro de la red teniendo en cuanta sus conexiones con otros nodos 
CALL gds.pageRank.stream('director_net')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).nombre AS nombre, score
ORDER BY score DESC, nombre ASC

// nuestra definicion de red, y el algoritmo de pageRank fueron utiles
// a la hora de detectar los nombres mas importantes dentro de la insdustria del cine

// Por ultimo vamos a probar un algoritmo de deteccion de comunidad. Ideal para detectar cluster
// queremos ver si hay grupos de directores que comparten los mismos actores.

CALL gds.louvain.stream('director_net')
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).nombre AS nombre, communityId
ORDER BY communityId ASC