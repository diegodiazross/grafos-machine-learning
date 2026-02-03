# Grafos Machine Learning

## Este proyecto busca modelar una base de datos que contiene los títulos e información relacionada con los lanzamientos de películas. Para esto utilizamos un modelo de grafos y el framework corresponde a neo4j y la librería GDS (Graph Data Science). ##

### Objetivos del proyecto: ###
1. Realizar un análisis exploratorio de los datos (EDA)
2. modelar la base utilizando grafos, utilizar el lenguaje cypher (GQL) para demostrar la versatilidad del enfoque propuesto y contrastar con un modelamiento más tradicional como puede ser un modelo relacional
3. Utilizar algunas técnicas de machine learning para idear un sistema de recomendación.

### Dataset ###
El conjunto de datos proviene de kaggle y corresponde al conjunto 
The Ultimate 1Million Movies Dataset (TMDB + IMDb):	
https://www.kaggle.com/datasets/alanvourch/tmdb-movies-daily-updates

### Modelo de datos (Grafo): ###
Modelo de datos (Grafo): Para visualizar el modelo conviene instalar la extensión de visual studio code DOT (Graphviz Interactive Preview) la cual te permite definir un modelo de grafos y visualizarlo.
luego de esto abrir el archivo modelo-grafo.dot.

### Tecnologías utilizada ###
1. Python
2. Pandas 
3. Docker / Docker-Compose
4. Neo4j 
5. Cypher 
6. APOC
7. DGS

### Requisitos ###
- Docker
- Docker-Compose
- Python
- Jupyter Notebook

### Instrucciones ###
1. Ejecuta el notebook **analisis_exploratorio.ipynb**, en este se descargan los datos y se realiza un análisis exploratorio,un preprocesamiento y filtrado de algunos campos para los análisis posteriores.
2. En el **archivo modelo-grafo.dot** está definido nuestro modelo de grafos, si quieres puedes instalar la extensión dot (Graphviz Interactive Preview) que te permite visualizar el modelo.
3. Para crear nuestra base de datos utilizamos el motor Neo4j que viene con una interfaz gráfica basada en la web que permite ejecutar consultas utilizando el lenguaje cypher.(GQL). Para tener un entorno reproducible utilizamos docker.
- cambiate al directorio docker,una vez ahi ejecuta `docker-compose up` este comando creara el contenedor donde correra nuestra app en el puerto 7474.
- abre una pestaña e ingresa a **http://localhost:7474/**
4. Una vez dentro de la app puedes ejecutar cada una de las consultas que están en **docker/consultas.cypher** con esto crearemos los nodos y relaciones definidas en nuestro modelo de grafos.  