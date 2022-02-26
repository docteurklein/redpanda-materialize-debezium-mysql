```
dcu
dce -T mysql mysql -uroot -proot <<< 'create database pim_1'
dce -T mysql mysql -uroot -proot pim_1 < sql/mysql.sql

curl --request POST --url http://localhost:8083/connectors --header 'Content-Type: application/json' --data '{
  "name": "pim_1-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "root",
    "database.password": "root",
    "database.server.id": "184054",
    "database.server.name": "pim_1",
    "database.include.list": "pim_1",
    "database.history.kafka.bootstrap.servers": "redpanda:9092",
    "database.history.kafka.topic": "schema-changes.pim_1",
    "database.allowPublicKeyRetrieval": true
  }
}'|jq

dcr mzcli < sql/materialize.sql

dce -T mysql mysql -uroot -proot pim_1 << 'SQL'
    update pim_catalog_product set raw_values =
    json_set(raw_values, '$.name."<all_channels>"."<all_locales>"', 'NEW NAME')
    where id = 1
SQL

dce redpanda rpk topic consume all_pim_product_value_edited
```
