drop source if exists pim1_catalog_product cascade;
create source pim1_catalog_product
  from kafka broker 'redpanda:9092'
  topic 'pim_1.pim_1.pim_catalog_product'
  format avro
  using confluent schema registry 'http://redpanda:8081'
  envelope debezium
;

create materialized view test as
select * from pim1_catalog_product;
