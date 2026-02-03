//cada pelicula debe tener un id unico
CREATE CONSTRAINT pelicula_id_unico IF NOT EXISTS
FOR (m:Pelicula) 
REQUIRE m.id IS UNIQUE;

//cada director debe tener un id unico
CREATE CONSTRAINT director_id_unico IF NOT EXISTS
FOR (d:Director) 
REQUIRE d.nombre IS UNIQUE;

// creacion de los nodos pelicula,director y la relacion DIRIGIDA_POR 
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "MERGE (p:Pelicula {id: row.id}) 
   SET 
   p.title = row.title, 
   p.overview = row.overview
   MERGE (d:Director {nombre: row.director})
   MERGE (m)-[:DIRIGIDA_POR]->(d)",
  {batchSize: 1000, parallel: FALSE}
);

// actor unico
CREATE CONSTRAINT unique_actor IF NOT EXISTS
FOR (a:Actor)
REQUIRE a.name IS UNIQUE

// creacion de nodo actores 
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///movies_with_overview.csv' AS row RETURN row",
  "WITH split(row.cast, ',') AS actors
   UNWIND actors AS actorName
   // 3. Actor
   MERGE (a:Actor {name: trim(lower(actorName))})",
  {batchSize: 1000, parallel: FALSE}
);

// año unico
CREATE CONSTRAINT unique_año IF NOT EXISTS
FOR (a:Año)
REQUIRE a.valor IS UNIQUE

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

  MATCH (m:Movie {id: row.id})
  MATCH (a:Año {valor: year})

  MERGE (m)-[:LANZADA_EN]->(a)
  ",
  {batchSize: 1000, parallel: false}
);
