# getColumnName

i have two apache doris environments named 'prd' and 'dev', i use jdbc to connect them, the same logic in two environments
got different result. the code as follows:
```java
Class.forName("com.mysql.jdbc.Driver");
// useOldAliasMetadataBehavior=true
String url = "jdbc:mysql://sofia:9030/demo";
Connection conn = DriverManager.getConnection(url,"root","root");
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("select c1 as a1 from demo.test_get_col");
ResultSetMetaData md = rs.getMetaData();
//
System.out.println("getColumnName: " + md.getColumnName(1));
System.out.println("getColumnLabel: " + md.getColumnLabel(1));
```

in the 'dev' got
```
getColumnName: a1
getColumnLabel: a1
```
in the 'prd' got
```
getColumnName: c1
getColumnLabel: a1
```

could you give me the perhaps reason of the different.
Note: one week before, the prd also got two 'a1' like dev.

