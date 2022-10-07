set -exu

docker compose exec -T mysql mysql -uroot -proot -e "drop database if exists $1"
docker compose exec -T mysql mysql -uroot -proot -e "create database $1"
cat $1 | docker compose exec -T mysql mysql -uroot -proot "$1"

curl --request DELETE --url "0:8083/connectors/$1" || true
curl --request POST --url 0:8083/connectors --header 'Content-Type: application/json' --data @- << EOF
{
  "name": "$1",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "root",
    "database.password": "root",
    "database.server.name": "$1",
    "database.include.list": "$1",
    "database.history.kafka.bootstrap.servers": "redpanda:9092",
    "database.history.kafka.topic": "schema-changes.$1",
    "database.allowPublicKeyRetrieval": true,
    "transforms": "Reroute",
    "transforms.Reroute.type": "io.debezium.transforms.ByLogicalTableRouter",
    "transforms.Reroute.topic.regex": "^$1\\\.$1\\\.(.*)$",
    "transforms.Reroute.topic.replacement": "all_pim.\$1",
    "transforms.Reroute.key.field.name": "tenant",
    "transforms.Reroute.key.field.regex": ".*",
    "transforms.Reroute.key.field.replacement": "$1"
  }
}
EOF
