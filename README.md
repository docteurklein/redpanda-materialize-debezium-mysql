```
dcu
sh bin/connect-mysql-to-redpanda.sh pim1
dcr mzcli < sql/materialize.sql

dce -T mysql mysql -uroot -proot pim1 << 'SQL'
    update pim_catalog_product set raw_values =
    json_set(raw_values, '$.name."<all_channels>"."<all_locales>"', 'NEW NAME')
    where id = 1
SQL

dce redpanda rpk topic consume all_pim_product_value_edited
```
