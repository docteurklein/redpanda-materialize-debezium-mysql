drop schema if exists all_pim cascade;
create schema all_pim;

create source all_pim.product
  from kafka broker 'redpanda:9092' 
  topic 'all_pim.pim_catalog_product'
  format avro
  using confluent schema registry 'http://redpanda:8081'
  envelope debezium
;

create materialized view all_pim.product_value as
  with by_attr (product_id, code, rest) as (
    select id, j.* from all_pim.product, jsonb_each(raw_values) j
  ),
  by_channel (product_id, code, channel, rest) as (
    select product_id, code,
        case j.key when '<all_channels>' then null else j.key end,
        j.value
    from by_attr, jsonb_each(rest) j
  ),
  by_locale (product_id, code, channel, locale, value) as (
    select product_id, code, channel,
        case j.key when '<all_locales>' then null else j.key end,
        j.value
    from by_channel, jsonb_each_text(rest) j
  )
  select * from by_locale
;

create sink all_pim.product_value_edited
from all_pim.product_value
into kafka broker 'redpanda:9092'
topic 'all_pim_product_value_edited'
consistency (
    topic 'all_pim_product_value_edited-consistency'
    format avro using confluent schema registry 'http://redpanda:8081'
)
with (reuse_topic = true)
format json
;
