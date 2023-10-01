//1 artIDConstr
CREATE CONSTRAINT artIdConstr for (a:Article) REQUIRE a.articleId  IS UNIQUE

//2 Author Index
CREATE INDEX FOR (a:Author) ON (a.name)

//3 Article Node Creation
LOAD CSV FROM "file:///ArticleNodes.csv" AS row
CREATE(a:Article{articleId:toInteger(row[0]),title:row[1],year:toInteger(row[2]),abstract:row[4]})

//4 Journal Node Creation
LOAD CSV FROM "file:///ArticleNodes.csv" AS row
With row WHERE row[3] is not null
MERGE (j:Journal{journalName:row[3]})

//5 Relationship Article-Journal
LOAD CSV FROM "file:///ArticleNodes.csv" AS row
WITH row WHERE row[3] IS NOT NULL AND row[3] <> ''
MATCH (a:Article {articleId: toInteger(row[0])})
MATCH (j:Journal {journalName: row[3]})
MERGE (a)-[:PUBLISHEDIN]->(j)

//6 Relationship Article-Article
LOAD CSV FROM "file:///Citations.csv" AS row FIELDTERMINATOR '\t'
MATCH (m:Article {articleId: toInteger(row[0])}), (n:Article {articleId: toInteger(row[1])})
MERGE (m)-[:CITES]->(n)

//7 Author Node & Relationship Author-Article
LOAD CSV FROM "file:///AuthorNodes.csv" AS row
MERGE(m:Article{articleId:toInteger(row[0])})
MERGE(a:Author{name:row[1]})
MERGE(a)-[:AUTHORED]->(m)

//Q1
MATCH (a:Author)-[:AUTHORED]->(:Article)<-[:CITES]-(:Article)
WITH a, COUNT(*) AS citationCount
RETURN a.name AS authorName, citationCount
ORDER BY citationCount DESC
LIMIT 5;

//Q10
MATCH (a:Author {name:'Edward Witten'})
MATCH p=shortestPath((a)-[:AUTHORED*]-(m:Author))
WHERE a.name <> m.name AND ALL(node IN nodes(p) WHERE (node:Author OR node:Article))
WITH m.name AS AuthorName, length(p) AS Length, [n IN nodes(p) | 
  CASE 
    WHEN n:Article THEN n.title
    WHEN n:Author THEN 'N/A'
  END
] AS PaperTitles
WHERE Length > 25
RETURN AuthorName, Length, PaperTitles
ORDER BY Length, AuthorName, PaperTitles;

//Q2
MATCH(a:Author)-[:AUTHORED]->(:Article)<-[:AUTHORED]-(b:Author)
WHERE a.name<>b.name
RETURN a.name, count(distinct b)
ORDER BY count(distinct b) DESC
LIMIT 5;

//Q3
MATCH (a:Author)-[:AUTHORED]->(j:Article)
WHERE NOT EXISTS {
  MATCH (a:Author)-[:AUTHORED]->(j:Article)<-[:AUTHORED]-(b:Author)
  WHERE a.name <> b.name}
RETURN a.name, count(j)
ORDER BY count(j) DESC
LIMIT 1;

//Q4
MATCH(a:Author)
MATCH(j:Article{year:2001})
MATCH(a:Author)-[:AUTHORED]->(j:Article)
RETURN a.name, count(j)
ORDER BY count(j) DESC
LIMIT 1;

//Q5
MATCH(a:Article)
MATCH(j:Journal)
WHERE a.year=1998 AND a.title CONTAINS 'gravity'
MATCH(a:Article)-[:PUBLISHEDIN]->(j:Journal)
RETURN j.journalName, count(a)
ORDER BY count(a) DESC
LIMIT 1;

//Q6
MATCH(a:Article)-[:CITES]->(b:Article)
RETURN b.title, count(a)
ORDER BY count(a) DESC
LIMIT 5;

//Q7
MATCH(a:Author)-[:AUTHORED]->(j:Article)
WHERE j.abstract CONTAINS 'holography' OR j.abstract CONTAINS 'anti de sitter'
RETURN a.name, j.title
ORDER BY j.title, a.name;

//Q8
MATCH p=shortestPath((a:Author{name:'C.N. Pope'})-[*]-(f:Author{name:'M. Schweda'}))
RETURN [n in nodes(p) | 
  CASE 
    WHEN n:Article THEN n.title
    WHEN n:Author THEN n.name
    WHEN n:Journal THEN n.journalName
    ELSE "Unknown"
  END
] AS ShortestPath, length(p) as Lengths

//Q9
MATCH p=shortestPath((a:Author{name:'C.N. Pope'})-[*]-(f:Author{name:'M. Schweda'}))
WHERE ALL(node IN nodes(p) WHERE node:Author OR node:Article)
RETURN [n in nodes(p) | 
  CASE 
    WHEN n:Article THEN n.title
    WHEN n:Author THEN n.name
  END
] AS ShortestPath, length(p) as Length